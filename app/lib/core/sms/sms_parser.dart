import 'dart:convert';
import 'package:crypto/crypto.dart';

class ParsedTransaction {
  final String type;      // 'credit' | 'debit'
  final double amount;
  final double? balance;  // Available balance from SMS
  final String? merchant;
  final double confidence;
  final String smsHash;

  const ParsedTransaction({
    required this.type,
    required this.amount,
    this.balance,
    this.merchant,
    required this.confidence,
    required this.smsHash,
  });
}

class SMSParser {
  // ── Debit patterns ────────────────────────────────────────────────────────
  static final _debitPatterns = [
    RegExp(r'(?:debited|deducted|paid|spent).{0,30}?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
    RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*).{0,30}?(?:debited|deducted|paid)',       caseSensitive: false),
    RegExp(r'transferred.{0,20}?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)',                     caseSensitive: false),
    RegExp(r'UPI.{0,30}?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*).{0,20}?(?:sent|paid|debit)', caseSensitive: false),
    RegExp(r'purchase.{0,20}?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)',                        caseSensitive: false),
  ];

  // ── Credit patterns ───────────────────────────────────────────────────────
  static final _creditPatterns = [
    RegExp(r'(?:credited|received|deposited).{0,30}?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
    RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*).{0,30}?(?:credited|received|deposited)', caseSensitive: false),
    RegExp(r'payment.{0,20}?received.{0,20}?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)',         caseSensitive: false),
    RegExp(r'(?:salary|credit).{0,20}?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)',               caseSensitive: false),
  ];

  // ── Balance ───────────────────────────────────────────────────────────────
  static final _balancePattern = RegExp(
    r'(?:Avl\.?\s*Bal|Available\s*Bal|Avail\.?\s*Balance|Bal\.?)\s*:?\s*(?:Rs\.?|INR|₹)?\s*([\d,]+\.?\d*)',
    caseSensitive: false,
  );

  // ── Merchant ──────────────────────────────────────────────────────────────
  static final _merchantPattern = RegExp(
    r'(?:to|at|from|@|UPI-)\s*([A-Za-z0-9@._\-]{3,40})',
    caseSensitive: false,
  );

  // ── Known bank sender IDs (upper-case) ───────────────────────────────────
  static const Set<String> knownBankSenders = {
    'HDFCBK', 'SBIINB', 'ICICIB', 'AXISBK', 'KOTAKB',
    'PAYTMB', 'PHONEPE', 'GPAY', 'YESBNK', 'INDUSB',
    'BOIIND', 'CANBNK', 'PNBSMS', 'UNIONB', 'CENTBK',
    'IDFCBK', 'SCBINB', 'RBLBNK', 'FEDBK', 'JSBBANK',
    'HDFCBANK', 'SBIN', 'ICICI', 'AXIS', 'KOTAK',
  };

  /// Returns null if the SMS is not from a known bank sender.
  static ParsedTransaction? parse(String smsBody, String senderId) {
    final upperSender = senderId.toUpperCase().replaceAll('-', '').trim();
    final isKnown = knownBankSenders.any((s) => upperSender.contains(s));
    if (!isKnown) return null;

    final hash = sha256.convert(utf8.encode(smsBody.trim())).toString();

    // Try debit
    for (final p in _debitPatterns) {
      final m = p.firstMatch(smsBody);
      if (m != null) {
        return ParsedTransaction(
          type: 'debit',
          amount: _amt(m.group(1)!),
          balance: _balance(smsBody),
          merchant: _merchant(smsBody),
          confidence: 0.90,
          smsHash: hash,
        );
      }
    }

    // Try credit
    for (final p in _creditPatterns) {
      final m = p.firstMatch(smsBody);
      if (m != null) {
        return ParsedTransaction(
          type: 'credit',
          amount: _amt(m.group(1)!),
          balance: _balance(smsBody),
          merchant: _merchant(smsBody),
          confidence: 0.90,
          smsHash: hash,
        );
      }
    }

    return null;
  }

  static double _amt(String raw) => double.parse(raw.replaceAll(',', ''));

  static double? _balance(String sms) {
    final m = _balancePattern.firstMatch(sms);
    if (m == null) return null;
    return double.tryParse(m.group(1)!.replaceAll(',', ''));
  }

  static String? _merchant(String sms) => _merchantPattern.firstMatch(sms)?.group(1);

  /// Auto-categorise into Essential / Non-Essential / Savings / Investments
  static Map<String, String> autoCategorise(String? merchant, double amount, String type) {
    if (type == 'credit') {
      return {'category_top': 'income', 'category_sub': 'credit'};
    }

    if (merchant == null) {
      return {'category_top': 'needs', 'category_sub': 'other'};
    }

    final m = merchant.toLowerCase();

    if (_has(m, ['electricity', 'bescom', 'msedcl', 'torrent', 'tata power',
      'petrol', 'diesel', 'hp petro', 'ioc', 'fuel',
      'apollo', 'medplus', 'netmeds', 'pharmacy', 'hospital',
      'dmart', 'reliance fresh', 'big bazaar', 'bigbasket',
      'jio', 'airtel', 'vi ', 'bsnl', 'vodafone',
      'emi', 'loan', 'bajaj', 'nbfc', 'rent'])) {
      return {'category_top': 'needs', 'category_sub': 'essential'};
    }

    if (_has(m, ['swiggy', 'zomato', 'dominos', 'mcdonalds', 'kfc', 'pizza',
      'amazon', 'flipkart', 'myntra', 'meesho', 'ajio', 'nykaa',
      'netflix', 'hotstar', 'prime', 'youtube', 'spotify'])) {
      return {'category_top': 'wants', 'category_sub': 'non_essential'};
    }

    if (_has(m, ['mutual fund', 'sip', 'zerodha', 'groww', 'ppf', 'nps'])) {
      return {'category_top': 'savings', 'category_sub': 'investment'};
    }

    if (_has(m, ['fd', 'recurring deposit', 'savings'])) {
      return {'category_top': 'savings', 'category_sub': 'savings'};
    }

    return {'category_top': 'wants', 'category_sub': 'other'};
  }

  static bool _has(String text, List<String> keywords) =>
      keywords.any((k) => text.contains(k));
}