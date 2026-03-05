import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sms_inbox/flutter_sms_inbox.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../notifications/notification_service.dart';
import '../supabase/supabase_client.dart';
import 'sms_parser.dart';

/// MethodChannel — native Android BroadcastReceiver sends SMS here in real-time.
/// See android/app/src/main/kotlin/.../MainActivity.kt
const _smsChannel = MethodChannel('com.coachmint.app/sms');

class SmsService {
  final SmsQuery _query = SmsQuery();
  bool _listenerStarted = false;

  // ── Permissions ───────────────────────────────────────────────────────────
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // ── Init (called from OnboardingScreen after permission granted) ──────────
  Future<void> init() async {
    final granted = await requestSmsPermission();
    if (!granted) {
      debugPrint('[SmsService] permission denied');
      return;
    }
    await _startLiveListener();
  }

  // ── Live listener via native BroadcastReceiver ────────────────────────────
  Future<void> _startLiveListener() async {
    if (_listenerStarted) return;

    // Register method call handler BEFORE telling native to start
    _smsChannel.setMethodCallHandler((call) async {
      if (call.method == 'onSmsReceived') {
        final args   = Map<String, String>.from(call.arguments as Map);
        final body   = args['body']   ?? '';
        final sender = args['sender'] ?? '';
        // This is where the notification fires — only on new incoming SMS
        await _handleBankSms(body: body, sender: sender);
      }
    });

    try {
      await _smsChannel.invokeMethod('startSmsListener');
      _listenerStarted = true;
      debugPrint('[SmsService] native listener started');
    } catch (e) {
      debugPrint('[SmsService] native listener error: $e');
    }
  }

  /// Parses a raw SMS body, fires notification, saves to Supabase.
  /// NOTIFICATION IS FIRED HERE — not on app open.
  Future<void> _handleBankSms({
    required String body,
    required String sender,
  }) async {
    if (body.isEmpty) return;

    final parsed = SMSParser.parse(body, sender);
    if (parsed == null) return; // Not a bank SMS we care about

    // ── 1. Fire notification immediately on transaction detection ──────────
    await NotificationService.showTransactionAlert(
      amount: parsed.amount,
      direction: parsed.type == 'credit' ? 'in' : 'out',
      payee: parsed.merchant,
    );

    // ── 2. Save to Supabase (dedup via raw_sms_hash) ───────────────────────
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final existing = await supabase
          .from('transactions')
          .select('id')
          .eq('raw_sms_hash', parsed.smsHash)
          .maybeSingle();

      if (existing != null) return; // Duplicate

      final cat = SMSParser.autoCategorise(
          parsed.merchant, parsed.amount, parsed.type);

      await supabase.from('transactions').insert({
        'user_id':          userId,
        'type':             parsed.type,
        'amount':           parsed.amount,
        'sms_balance':      parsed.balance,
        'merchant':         parsed.merchant,
        'category_top':     cat['category_top'],
        'category_sub':     cat['category_sub'],
        'source':           'sms',
        'raw_sms_hash':     parsed.smsHash,
        'parse_confidence': parsed.confidence,
        'needs_review':     parsed.confidence < 0.85,
        'transaction_date': DateTime.now().toIso8601String(),
      });

      // Update wallet balance if SMS contains available balance
      if (parsed.balance != null) {
        await supabase
            .from('user_profile')
            .update({'current_wallet': parsed.balance})
            .eq('user_id', userId);
      }

      debugPrint('[SmsService] saved transaction ₹${parsed.amount}');
    } catch (e) {
      debugPrint('[SmsService] Supabase save error: $e');
    }
  }

  // ── Read inbox for past N days (one-time import) ──────────────────────────
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
      final body   = msg.body   ?? '';
      final sender = msg.sender ?? '';
      if (body.isEmpty) continue;
      result.add(SmsWithMeta(body: body, sender: sender, date: date));
    }
    return result;
  }

  /// Import last 30 days of inbox SMS — called from dashboard "Import" button.
  Future<void> importExistingSms() async {
    final granted = await requestSmsPermission();
    if (!granted) return;

    final since = DateTime.now().subtract(const Duration(days: 30));
    final messages = await _query.querySms(
      kinds: [SmsQueryKind.inbox],
      count: 500,
    );

    int saved = 0;
    for (final msg in messages) {
      final date = msg.dateSent ?? msg.date;
      if (date == null || date.isBefore(since)) continue;
      // Import does NOT fire notification — we only notify on live incoming SMS
      final body   = msg.body   ?? '';
      final sender = msg.sender ?? '';
      if (body.isEmpty) continue;

      final parsed = SMSParser.parse(body, sender);
      if (parsed == null) continue;

      try {
        final userId = supabase.auth.currentUser?.id;
        if (userId == null) continue;

        final existing = await supabase
            .from('transactions')
            .select('id')
            .eq('raw_sms_hash', parsed.smsHash)
            .maybeSingle();
        if (existing != null) continue;

        final cat = SMSParser.autoCategorise(
            parsed.merchant, parsed.amount, parsed.type);

        await supabase.from('transactions').insert({
          'user_id':          userId,
          'type':             parsed.type,
          'amount':           parsed.amount,
          'sms_balance':      parsed.balance,
          'merchant':         parsed.merchant,
          'category_top':     cat['category_top'],
          'category_sub':     cat['category_sub'],
          'source':           'sms',
          'raw_sms_hash':     parsed.smsHash,
          'parse_confidence': parsed.confidence,
          'needs_review':     true, // imported = always needs review
          'transaction_date': date.toIso8601String(),
        });
        saved++;
      } catch (_) {}
    }
    debugPrint('[SmsService] imported $saved transactions');
  }
}

/// Simple data holder for an SMS message
class SmsWithMeta {
  final String body;
  final String sender;
  final DateTime date;
  const SmsWithMeta({required this.body, required this.sender, required this.date});
}

final smsServiceProvider = Provider<SmsService>((ref) => SmsService());