// ─────────────────────────────────────────────────────────────────────────────
// TransactionModel
// All original SMS parsing logic kept 100% intact.
// REMOVED: telephony import (SmsMessage replaced with plain Map/strings)
// ADDED:   toSupabase(), fromSupabase()
// CATEGORIES: Essential / Non-Essential / Savings / Investments
// ─────────────────────────────────────────────────────────────────────────────

import 'package:intl/intl.dart';

enum TxnStatus { processed, needs_review }

class TransactionModel {
  String? category;
  final double amount;
  final String currency;
  final String text;
  final String? channel;
  final String? payee;
  final String direction; // 'in' | 'out'
  final String source;    // 'sms' | 'manual'
  final TxnStatus status;
  final DateTime timestamp;
  final String formattedDate;
  final String txnId;

  TransactionModel({
    this.category,
    required this.amount,
    this.currency = 'INR',
    required this.text,
    this.channel,
    this.payee,
    required this.direction,
    required this.source,
    required this.status,
    required this.timestamp,
    required this.formattedDate,
    required this.txnId,
  });

  // ── ID generation ─────────────────────────────────────────────────────────
  static String generateTxnId({
    required double amount,
    required DateTime timestamp,
    required String? payee,
    required String direction,
  }) {
    final p = (payee ?? 'unknown').toLowerCase().replaceAll(' ', '');
    return '${amount}_${timestamp.millisecondsSinceEpoch}_${p}_$direction';
  }

  // ── Supabase ──────────────────────────────────────────────────────────────
  Map<String, dynamic> toSupabase(String userId) => {
    'user_id':          userId,
    'amount':           amount,
    'payee':            payee,
    'direction':        direction,
    'category':         category,
    'transaction_date': timestamp.toIso8601String(),
    'source':           source,
    'raw_sms_hash':     txnId, // used as dedup key
    'type':             direction == 'in' ? 'credit' : 'debit',
    'category_top':     _mapCategoryTop(category),
    'merchant':         payee,
    'parse_confidence': status == TxnStatus.processed ? 0.90 : 0.50,
    'needs_review':     status == TxnStatus.needs_review,
  };

  String _mapCategoryTop(String? cat) {
    switch (cat) {
      case 'Essential':     return 'needs';
      case 'Non-Essential': return 'wants';
      case 'Savings':       return 'savings';
      case 'Investments':   return 'savings';
      default:              return 'uncategorised';
    }
  }

  factory TransactionModel.fromSupabase(Map<String, dynamic> map) {
    final tsField = map['transaction_date'];
    final ts = tsField is String
        ? (DateTime.tryParse(tsField) ?? DateTime.now())
        : DateTime.now();

    return TransactionModel(
      category:      map['category'] as String?,
      amount:        (map['amount'] ?? 0).toDouble(),
      payee:         map['payee'] as String?,
      direction:     (map['direction'] ?? 'out') as String,
      source:        (map['source'] ?? 'sms') as String,
      text:          '',
      status:        TxnStatus.processed,
      timestamp:     ts,
      formattedDate: dateToDDMMYYYY(ts),
      txnId:         map['raw_sms_hash'] as String? ?? '',
      currency:      'INR',
    );
  }

  static String dateToDDMMYYYY(DateTime dt) =>
      DateFormat('dd/MM/yyyy').format(dt);

  // ─────────────────────────────────────────────────────────────────────────
  // SMS PARSING — original logic, adapted to plain String instead of SmsMessage
  // ─────────────────────────────────────────────────────────────────────────

  /// Parse from raw SMS body string + timestamp millis.
  /// Replaces the old fromSms(SmsMessage) — same logic, no telephony dependency.
  factory TransactionModel.fromRaw({
    required String body,
    required int dateMillis,
    String? senderAddress,
  }) {
    final low = body.trim().toLowerCase();
    DateTime ts = DateTime.fromMillisecondsSinceEpoch(dateMillis);

    // Direction
    String direction = 'out';
    if (low.contains('credited') ||
        low.contains('received') ||
        low.contains('deposited') ||
        low.contains('credited by')) {
      direction = 'in';
    }

    // Amount
    final amtRegex = RegExp(
      r'(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d+)?)',
      caseSensitive: false,
    );
    final amtMatch = amtRegex.firstMatch(body);
    double? amount;
    if (amtMatch != null) {
      amount = double.tryParse(amtMatch.group(1)!.replaceAll(',', ''));
    } else {
      final fb = RegExp(r'\b(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\b')
          .firstMatch(body);
      if (fb != null) amount = double.tryParse(fb.group(1)!.replaceAll(',', ''));
    }

    // Date extraction
    final extractedDate = _extractDateFromText(body);
    final formattedDate = extractedDate != null
        ? dateToDDMMYYYY(extractedDate)
        : dateToDDMMYYYY(ts);
    if (extractedDate != null) ts = extractedDate;

    // Channel & payee
    String? channel;
    String? payee;

    final upiRegex = RegExp(r'([a-zA-Z0-9._%+-]+@[a-zA-Z0-9._-]+)', caseSensitive: false);
    final upiMatch = upiRegex.firstMatch(body);
    if (upiMatch != null) {
      channel = 'upi';
      payee   = upiMatch.group(1);
    }

    if (payee == null) {
      final fromRx = RegExp(
          r'(?:from|transfer from|credited by)\s+([A-Z][A-Za-z0-9 .]{2,50}?)\b(?:ref|ref no|refno|a/c|ac|account|to|\.|,|$)',
          caseSensitive: false);
      payee = fromRx.firstMatch(body)?.group(1)?.trim().replaceAll(RegExp(r'\s+'), ' ');
    }

    if (payee == null) {
      final toRx = RegExp(
          r'(?:to|credited to|debit to|sent to)\s+([\w@._-]{3,60})',
          caseSensitive: false);
      payee = toRx.firstMatch(body)?.group(1)?.trim();
    }

    if (payee == null) {
      final acRx = RegExp(
          r'(?:ac|a/c|account)\s*(?:no\.?\s*)?[:\-]?\s*([xX*#A-Za-z0-9]{3,12})',
          caseSensitive: false);
      payee = acRx.firstMatch(body)?.group(1);
    }

    final status = (amount != null && amount > 0)
        ? TxnStatus.processed
        : TxnStatus.needs_review;

    final txnId = generateTxnId(
      amount:    amount ?? 0.0,
      timestamp: ts,
      payee:     payee,
      direction: direction,
    );

    return TransactionModel(
      category:      null,
      amount:        amount ?? 0.0,
      text:          body,
      direction:     direction,
      timestamp:     ts,
      channel:       channel,
      payee:         payee,
      source:        'sms',
      status:        status,
      formattedDate: formattedDate,
      txnId:         txnId,
    );
  }

  // ── Date helpers (original logic, untouched) ──────────────────────────────
  static DateTime? _extractDateFromText(String text) {
    final t = text.trim();

    final m1 = RegExp(
        r'(\d{1,2}[\-/]\d{1,2}[\-/]\d{2,4})(?:[ T](\d{1,2}:\d{2}(?::\d{2})?))',
        caseSensitive: false)
        .firstMatch(t);
    if (m1 != null) {
      final p = _tryParseWithKnownPatterns('${m1.group(1)!} ${(m1.group(2) ?? '').trim()}');
      if (p != null) return p;
    }

    final m2 = RegExp(
        r'(\d{1,2})\s*[-\/]?\s*([A-Za-z]{3,9})\s*[-\/]?\s*(\d{2,4})',
        caseSensitive: false)
        .firstMatch(t);
    if (m2 != null) {
      final p = _normalizeDayMonthYear(m2.group(1)!, m2.group(2)!, m2.group(3)!);
      if (p != null) return p;
    }

    final m3 = RegExp(r'(\d{1,2})[\-/](\d{1,2})[\-/](\d{2,4})').firstMatch(t);
    if (m3 != null) {
      final p = _tryBuildDate(m3.group(1)!, m3.group(2)!, m3.group(3)!);
      if (p != null) return p;
    }

    final m4 = RegExp(r'(\d{4})[\-/](\d{1,2})[\-/](\d{1,2})').firstMatch(t);
    if (m4 != null) {
      try {
        return DateTime(int.parse(m4.group(1)!), int.parse(m4.group(2)!), int.parse(m4.group(3)!));
      } catch (_) {}
    }

    final m5 = RegExp(r'\b(\d{6,8})\b').firstMatch(t);
    if (m5 != null) {
      final s = m5.group(1)!;
      if (s.length == 8) return _tryBuildDate(s.substring(0, 2), s.substring(2, 4), s.substring(4, 8));
      if (s.length == 6) return _tryBuildDate(s.substring(0, 2), s.substring(2, 4), s.substring(4, 6));
    }
    return null;
  }

  static DateTime? _tryParseWithKnownPatterns(String candidate) {
    for (final p in [
      'dd-MM-yyyy HH:mm:ss', 'dd-MM-yyyy HH:mm', 'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm', 'dd-MM-yy HH:mm:ss', 'dd-MM-yy HH:mm',
      'dd/MM/yy HH:mm:ss', 'dd/MM/yy HH:mm', 'dd-MM-yyyy', 'dd/MM/yyyy',
      'dd-MM-yy', 'dd/MM/yy',
    ]) {
      try { return DateFormat(p).parseLoose(candidate); } catch (_) {}
    }
    return null;
  }

  static DateTime? _normalizeDayMonthYear(String day, String monStr, String yearStr) {
    const months = {
      'jan':1,'feb':2,'mar':3,'apr':4,'may':5,'jun':6,
      'jul':7,'aug':8,'sep':9,'sept':9,'oct':10,'nov':11,'dec':12,
    };
    final m = months[monStr.toLowerCase().substring(0, 3)];
    if (m == null) return null;
    return _tryBuildDate(day, m.toString(), yearStr);
  }

  static DateTime? _tryBuildDate(String dStr, String mStr, String yStr) {
    try {
      int d = int.parse(dStr), mo = int.parse(mStr), y = int.parse(yStr);
      if (yStr.length == 2) y += (y < 70) ? 2000 : 1900;
      return DateTime(y, mo, d);
    } catch (_) { return null; }
  }
}