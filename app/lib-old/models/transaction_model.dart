import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';

// Represents the status of the parsed transaction
enum TxnStatus { processed, needs_review }

class TransactionModel {
  String? category; // NEW FIELD
  final double amount;
  final String currency;
  final String text;
  final String? channel;
  final String? payee;
  final String direction; // 'in' or 'out'
  final String source; // 'sms', 'manual'
  final TxnStatus status; // 'processed', 'needs_review'
  final DateTime timestamp;
  // Normalized date string as requested: dd/mm/yyyy
  final String formattedDate;

  /// 🔥 UNIQUE TRANSACTION ID — needed for deduping
  final String txnId;

  TransactionModel({
    this.category, // NEW FIELD
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
    required this.txnId, // NEW FIELD
  });

  /// Create a unique ID from amount + date + payee + direction
  static String generateTxnId({
    required double amount,
    required DateTime timestamp,
    required String? payee,
    required String direction,
  }) {
    final payeePart = (payee ?? "unknown").toLowerCase().replaceAll(" ", "");
    return "${amount}_${timestamp.millisecondsSinceEpoch}_$payeePart$direction";
  }

  /// Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      "amount": amount,
      "payee": payee,
      "direction": direction,
      "category": category,
      "timestamp": timestamp,
      "formattedDate": formattedDate,
      "source": source,
      "raw": text,
      "txnId": txnId,
    };
  }

  /// Helper: formats DateTime into dd/MM/yyyy
  static String dateToDDMMYYYY(DateTime dt) {
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  /// Try to parse many common date formats in SMS texts.
  /// Returns a DateTime if found, otherwise null.
  static DateTime? _extractDateFromText(String text) {
    final t = text.trim();

    // 1) Full datetime like 13-11-2025 21:39:26 or 13/11/2025 21:39
    final fullDateTimeRegex = RegExp(
        r"(\d{1,2}[\-/]\d{1,2}[\-/]\d{2,4})(?:[ T](\d{1,2}:\d{2}(?::\d{2})?))",
        caseSensitive: false);
    final m1 = fullDateTimeRegex.firstMatch(t);
    if (m1 != null) {
      final dpart = m1.group(1)!;
      final tpart = m1.group(2) ?? '';
      final candidate = '$dpart ${tpart.trim()}';
      final parsed = _tryParseWithKnownPatterns(candidate);
      if (parsed != null) return parsed;
    }

    // 2) Dates like 10-Nov-25, 10Nov25, 10Nov2025 or 10Nov25
    final monDateRegex = RegExp(
        r"(\d{1,2})\s*[-\/]?\s*([A-Za-z]{3,9})\s*[-\/]?\s*(\d{2,4})",
        caseSensitive: false);
    final m2 = monDateRegex.firstMatch(t);
    if (m2 != null) {
      final day = m2.group(1)!;
      final mon = m2.group(2)!;
      final yr = m2.group(3)!;
      final normalized = _normalizeDayMonthYear(day, mon, yr);
      if (normalized != null) return normalized;
    }

    // 3) Numeric dates: 10-11-25 or 10/11/25 or 10-11-2025
    final numericDateRegex = RegExp(r"(\d{1,2})[\-/](\d{1,2})[\-/](\d{2,4})");
    final m3 = numericDateRegex.firstMatch(t);
    if (m3 != null) {
      final d = m3.group(1)!;
      final m = m3.group(2)!;
      final y = m3.group(3)!;
      final parsed = _tryBuildDate(d, m, y);
      if (parsed != null) return parsed;
    }

    // 4) ISO-like dates: 2025-11-13
    final isoDateRegex = RegExp(r"(\d{4})[\-/](\d{1,2})[\-/](\d{1,2})");
    final m4 = isoDateRegex.firstMatch(t);
    if (m4 != null) {
      final y = m4.group(1)!;
      final m = m4.group(2)!;
      final d = m4.group(3)!;
      try {
        return DateTime(int.parse(y), int.parse(m), int.parse(d));
      } catch (_) {}
    }

    // 5) Fallback: any 6+ digit date-ish contiguous like 13112025 or 101125
    final contiguous = RegExp(r"\b(\d{6,8})\b");
    final m5 = contiguous.firstMatch(t);
    if (m5 != null) {
      final s = m5.group(1)!;
      // try ddmmyyyy or ddmmyy
      if (s.length == 8) {
        final d = s.substring(0, 2);
        final m = s.substring(2, 4);
        final y = s.substring(4, 8);
        final parsed = _tryBuildDate(d, m, y);
        if (parsed != null) return parsed;
      } else if (s.length == 6) {
        final d = s.substring(0, 2);
        final m = s.substring(2, 4);
        final y = s.substring(4, 6);
        final parsed = _tryBuildDate(d, m, y);
        if (parsed != null) return parsed;
      }
    }

    return null;
  }

  static DateTime? _tryParseWithKnownPatterns(String candidate) {
    final patterns = [
      'dd-MM-yyyy HH:mm:ss',
      'dd-MM-yyyy HH:mm',
      'dd/MM/yyyy HH:mm:ss',
      'dd/MM/yyyy HH:mm',
      'dd-MM-yy HH:mm:ss',
      'dd-MM-yy HH:mm',
      'dd/MM/yy HH:mm:ss',
      'dd/MM/yy HH:mm',
      'dd-MM-yyyy',
      'dd/MM/yyyy',
      'dd-MM-yy',
      'dd/MM/yy',
    ];
    for (final p in patterns) {
      try {
        final dt = DateFormat(p).parseLoose(candidate);
        return dt;
      } catch (_) {}
    }
    return null;
  }

  static DateTime? _normalizeDayMonthYear(String day, String monStr, String yearStr) {
    final monthNames = {
      'jan': 1,
      'feb': 2,
      'mar': 3,
      'apr': 4,
      'may': 5,
      'jun': 6,
      'jul': 7,
      'aug': 8,
      'sep': 9,
      'sept': 9,
      'oct': 10,
      'nov': 11,
      'dec': 12
    };
    final mkey = monStr.toLowerCase().substring(0, 3);
    final m = monthNames[mkey];
    if (m == null) return null;
    return _tryBuildDate(day, m.toString(), yearStr);
  }

  static DateTime? _tryBuildDate(String dStr, String mStr, String yStr) {
    try {
      int d = int.parse(dStr);
      int m = int.parse(mStr);
      int y = int.parse(yStr);
      if (yStr.length == 2) {
        // two-digit year. assume 2000s (common for SMS receipts around 2000-2099)
        y += (y < 70) ? 2000 : 1900; // conservative: 25 -> 2025, 99 -> 1999
      }
      return DateTime(y, m, d);
    } catch (_) {
      return null;
    }
  }

  factory TransactionModel.fromSms(SmsMessage message) {
    final String body = message.body?.trim() ?? '';
    final low = body.toLowerCase();
    DateTime ts = DateTime.fromMillisecondsSinceEpoch(message.date ?? 0);

    // --- Direction ---
    String direction = 'out';
    if (low.contains('credited') ||
        low.contains('received') ||
        low.contains('deposited') ||
        low.contains('credited by')) {
      direction = 'in';
    }

    // --- Amount ---
    final amountRegex = RegExp(
      r"(?:rs\.?|inr|₹)\s*([\d,]+(?:\.\d+)?)",
      caseSensitive: false,
    );
    Match? amountMatch = amountRegex.firstMatch(body);
    double? amount;
    if (amountMatch != null) {
      String amountStr = amountMatch.group(1)!.replaceAll(',', '');
      amount = double.tryParse(amountStr);
    } else {
      // fallback: look for 'sent Rs.120.00' style without currency symbol (rare)
      final fallbackAmt = RegExp(r"\b(\d{1,3}(?:,\d{3})*(?:\.\d+)?)\b");
      final f = fallbackAmt.firstMatch(body);
      if (f != null) {
        amount = double.tryParse(f.group(1)!.replaceAll(',', ''));
      }
    }

    // --- Date extraction & normalization ---
    DateTime? extractedDate = _extractDateFromText(body);
    String formattedDate = extractedDate != null
        ? dateToDDMMYYYY(extractedDate)
        : dateToDDMMYYYY(ts); // fallback to sms timestamp

    // If SMS contains a more precise timestamp (like in sample1), prefer it as timestamp
    if (extractedDate != null) {
      ts = extractedDate;
    }

    // --- Channel & Payee ---
    String? channel;
    String? payee;

    // UPI id (vpa) detection
    final upiRegex =
    RegExp(r"([a-zA-Z0-9._%+-]+@[a-zA-Z0-9._-]+)", caseSensitive: false);
    final upiMatch = upiRegex.firstMatch(body);
    if (upiMatch != null) {
      channel = 'upi';
      payee = upiMatch.group(1);
    }

    // Check for 'from {Name}' or 'transfer from {Name}' or 'credited by' patterns
    if (payee == null) {
      final fromRegex = RegExp(
          r"(?:from|transfer from|credited by)\s+([A-Z][A-Za-z0-9 .]{2,50}?)\b(?:ref|ref no|refno|a/c|ac|account|to|\.|,|$)",
          caseSensitive: false);
      final fmatch = fromRegex.firstMatch(body);
      if (fmatch != null) {
        payee = fmatch.group(1)?.trim();
        // normalize whitespace
        if (payee != null) payee = payee.replaceAll(RegExp(r"\s+"), ' ');
      }
    }

    // Check for 'to {payee}' patterns
    if (payee == null) {
      final toRegex = RegExp(
          r"(?:to|credited to|debit to|sent to)\s+([\w@._-]{3,60})",
          caseSensitive: false);
      final tmatch = toRegex.firstMatch(body);
      if (tmatch != null) {
        payee = tmatch.group(1)?.trim();
      }
    }

    // Account number masking like 'AC X5646' or 'A/c no. XX9506'
    if (payee == null) {
      final acRegex = RegExp(
          r"(?:ac|a/c|account)\s*(?:no\.?\s*)?[:\-]?\s*([xX*#A-Za-z0-9]{3,12})",
          caseSensitive: false);
      final am = acRegex.firstMatch(body);
      if (am != null) payee = am.group(1);
    }

    // final status
    TxnStatus status = (amount != null && amount > 0)
        ? TxnStatus.processed
        : TxnStatus.needs_review;

    // 🔥 Generate unique transaction ID
    final txnId = generateTxnId(
      amount: amount ?? 0.0,
      timestamp: ts,
      payee: payee,
      direction: direction,
    );

    return TransactionModel(
      category: null, // default value
      amount: amount ?? 0.0,
      text: body,
      direction: direction,
      timestamp: ts,
      channel: channel,
      payee: payee,
      source: 'sms',
      status: status,
      formattedDate: formattedDate,
      txnId: txnId,
    );
  }
}
