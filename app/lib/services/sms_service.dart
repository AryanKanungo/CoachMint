import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';

import '../core/notifications/notification_service.dart';
import '../core/supabase/supabase_client.dart';

// ── MethodChannel for live SMS from native BroadcastReceiver ──────────────────
const _smsChannel = MethodChannel('com.coachmint.app/sms');

// ── SmsWithMeta ───────────────────────────────────────────────────────────────
// Simple data holder used by sms_categorization_controller.dart

class SmsWithMeta {
  final String body;
  final String? sender;
  final DateTime date;
  const SmsWithMeta({
    required this.body,
    required this.sender,
    required this.date,
  });
}

// ── SmsService ────────────────────────────────────────────────────────────────

class SmsService {
  final SmsQuery _query = SmsQuery();
  bool _listenerStarted = false;

  /// Call after onboarding or from dashboard initState.
  /// Requests permission then starts the live MethodChannel listener.
  Future<void> init() async {
    final granted = await requestSmsPermission();
    if (!granted) {
      debugPrint('[SmsService] SMS permission denied');
      return;
    }
    _startLiveListener();
  }

  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // ── Live listener ─────────────────────────────────────────────────────────

  void _startLiveListener() {
    if (_listenerStarted) return; // idempotent

    // Flutter side receives calls from Kotlin BroadcastReceiver
    _smsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final args   = Map<String, String>.from(call.arguments as Map);
        final body   = args['body']   ?? '';
        final sender = args['sender'] ?? '';
        await _handleBankSms(body: body, sender: sender);
      }
    });

    // Tell Kotlin to register the BroadcastReceiver
    _smsChannel.invokeMethod('startSmsListener').then((_) {
      _listenerStarted = true;
      debugPrint('[SmsService] native listener started ✅');
    }).catchError((e) {
      debugPrint('[SmsService] native listener error: $e');
    });
  }

  // ── Handle a newly received bank SMS ─────────────────────────────────────
  // ⚠️  NOTIFICATION IS FIRED HERE — NOT on app open, NOT anywhere else.

  Future<void> _handleBankSms({
    required String body,
    required String sender,
  }) async {
    if (body.isEmpty) return;

    final parsed = _parseSms(body);
    if (parsed == null) return; // not a bank/UPI SMS

    // 1. Fire notification immediately
    await NotificationService.showTransactionAlert(
      amount:    parsed['amount'] as double,
      direction: parsed['direction'] as String,
      payee:     parsed['payee'] as String? ?? '',
    );

    // 2. Save to Supabase (dedup via hash)
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final hash = _hashSms(body);

      final existing = await supabase
          .from('transactions')
          .select('id')
          .eq('raw_sms_hash', hash)
          .maybeSingle();

      if (existing != null) return; // duplicate

      await supabase.from('transactions').insert({
        'user_id':          userId,
        'amount':           parsed['amount'],
        'direction':        parsed['direction'],
        'payee':            parsed['payee'],
        'source':           'sms',
        'raw_sms_hash':     hash,
        'needs_review':     true,
        'transaction_date': DateTime.now().toIso8601String(),
      });

      debugPrint('[SmsService] saved ₹${parsed['amount']} ${parsed['direction']}');
    } catch (e) {
      debugPrint('[SmsService] save error: $e');
    }
  }

  // ── Read inbox for past N days (returns SmsWithMeta list) ─────────────────

  Future<List<SmsWithMeta>> getPastSms(int days) async {
    final granted = await requestSmsPermission();
    if (!granted) return [];

    final since = DateTime.now().subtract(Duration(days: days));
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 500,
    );

    final result = <SmsWithMeta>[];
    for (final msg in messages) {
      final date = msg.dateSent ?? msg.date;
      if (date == null || date.isBefore(since)) continue;
      final body = msg.body ?? '';
      if (body.isEmpty) continue;
      result.add(SmsWithMeta(
        body:   body,
        sender: msg.sender,
        date:   date,
      ));
    }
    return result;
  }

  // ── Import last 30 days (called from "Import Bank SMS" button) ────────────
  // Does NOT fire notifications — this is a bulk historical import.

  Future<void> importExistingSms() async {
    final granted = await requestSmsPermission();
    if (!granted) return;

    final since    = DateTime.now().subtract(const Duration(days: 30));
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 500,
    );

    int saved = 0;
    for (final msg in messages) {
      final date = msg.dateSent ?? msg.date;
      if (date == null || date.isBefore(since)) continue;
      final body = msg.body ?? '';
      if (body.isEmpty) continue;

      final parsed = _parseSms(body);
      if (parsed == null) continue;

      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) break;

        final hash = _hashSms(body);

        final existing = await supabase
            .from('transactions')
            .select('id')
            .eq('raw_sms_hash', hash)
            .maybeSingle();

        if (existing != null) continue;

        await supabase.from('transactions').insert({
          'user_id':          userId,
          'amount':           parsed['amount'],
          'direction':        parsed['direction'],
          'payee':            parsed['payee'],
          'source':           'sms_import',
          'raw_sms_hash':     hash,
          'needs_review':     true,
          'transaction_date': date.toIso8601String(),
        });
        saved++;
      } catch (_) {}
    }
    debugPrint('[SmsService] imported $saved transactions');
  }

  // ── Parsing helpers ───────────────────────────────────────────────────────

  /// Returns null if not a bank SMS. Returns map with amount/direction/payee.
  Map<String, dynamic>? _parseSms(String body) {
    final low = body.toLowerCase();

    final isBankSms = low.contains('debited')   ||
        low.contains('credited')   ||
        low.contains('rs.')        ||
        low.contains('inr')        ||
        low.contains('₹')          ||
        low.contains('upi')        ||
        low.contains('neft')       ||
        low.contains('imps')       ||
        low.contains('a/c')        ||
        low.contains('acct');

    if (!isBankSms) return null;

    // Amount
    final amtRegex = RegExp(
        r'(?:rs\.?|inr|₹)\s*([0-9,]+(?:\.[0-9]+)?)',
        caseSensitive: false);
    final amtMatch = amtRegex.firstMatch(body);
    if (amtMatch == null) return null;

    final amount =
        double.tryParse(amtMatch.group(1)!.replaceAll(',', '')) ?? 0.0;
    if (amount <= 0) return null;

    // Direction
    final direction = (low.contains('credited')  ||
        low.contains('received')   ||
        low.contains('deposited')  ||
        low.contains('added'))
        ? 'in'
        : 'out';

    // Payee — try UPI ID first, then "to <name>"
    String? payee;
    final upiMatch = RegExp(
        r'[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+',
        caseSensitive: false)
        .firstMatch(body);
    if (upiMatch != null) {
      payee = upiMatch.group(0);
    } else {
      final toMatch = RegExp(
          r'(?:to|sent to|paid to|credited to)\s+([\w @.\-]{3,40})',
          caseSensitive: false)
          .firstMatch(body);
      payee = toMatch?.group(1)?.trim();
    }

    return {'amount': amount, 'direction': direction, 'payee': payee};
  }

  /// SHA-256 hash of SMS body for deduplication
  String _hashSms(String body) {
    final bytes = utf8.encode(body.trim());
    return sha256.convert(bytes).toString();
  }
}