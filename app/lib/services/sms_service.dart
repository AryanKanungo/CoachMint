import 'package:telephony/telephony.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

// All RegExp at file-level — avoids Dart static-field initializer errors

final _vpaRe = RegExp(r'[\w.\-]+@\w+', caseSensitive: false);

final _upiRefRe = RegExp(
  r'(?:UPI\s*Ref|UTR|Ref)\s*:?\s*(\d{10,16})',
  caseSensitive: false,
);

final _amountRe = RegExp(
  r'(?:INR|Rs\.?|₹)\s*([\d,]+(?:\.\d{1,2})?)',
  caseSensitive: false,
);

final _debitRe = RegExp(
  r'(?:\bDr\b|\bDr\.|\bdebited\b|\bdeducted\b|\bsent\b|\bpaid\b|\btransferred\b|\bspent\b|\bwithdrawn\b|\bpurchased\b|\bcharged\b|\bpayment\b)',
  caseSensitive: false,
);

final _creditRe = RegExp(
  r'(?:\bCr\b|\bCr\.|\bcredited\b|\breceived\b|\bdeposited\b|\brefunded\b|\bcashback\b|\breversed\b)',
  caseSensitive: false,
);

final _nameToRe = RegExp(
  r'\bto\s+([A-Za-z][A-Za-z0-9 &.\-]{1,40})',
  caseSensitive: false,
);

final _nameAtRe = RegExp(
  r'\bat\s+([A-Za-z][A-Za-z0-9 &.\-]{1,40})',
  caseSensitive: false,
);

final _nameLabelRe = RegExp(
  r'(?:Name|Merchant|Payee|Sender)\s*:\s*([A-Za-z][A-Za-z0-9 &.\-]{1,40})',
  caseSensitive: false,
);

final _nameTermRe = RegExp(
  r'\b(?:on|via|ref|using|with|for|upi|vpa|a/c|ac|bank|and|not|from)\b',
  caseSensitive: false,
);

final _acRefRe = RegExp(r'^a[/.]?c\.?\s*[X\dx]', caseSensitive: false);

class SmsService {
  final Telephony _telephony = Telephony.instance;

  Future<bool> requestPermission() async {
    final result = await _telephony.requestSmsPermissions;
    return result ?? false;
  }

  Future<bool> hasPermission() async {
    try {
      await _telephony.getInboxSms(
        columns: [SmsColumn.ID],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(
          DateTime.now()
              .subtract(const Duration(hours: 1))
              .millisecondsSinceEpoch
              .toString(),
        ),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<List<TransactionModel>> fetchTransactions(String userId) async {
    final cutoffMs = DateTime.now()
        .subtract(const Duration(days: 14))
        .millisecondsSinceEpoch;

    List<SmsMessage> messages;
    try {
      messages = await _telephony.getInboxSms(
        columns: [
          SmsColumn.ID,
          SmsColumn.ADDRESS,
          SmsColumn.BODY,
          SmsColumn.DATE,
        ],
        filter: SmsFilter.where(SmsColumn.DATE).greaterThan(cutoffMs.toString()),
        sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
      );
    } catch (_) {
      return [];
    }

    final results = <TransactionModel>[];
    for (final msg in messages) {
      if (!_isUpiSms(msg)) continue;
      final txn = _parse(msg, userId);
      if (txn != null) results.add(txn);
    }
    return results;
  }

  bool _isUpiSms(SmsMessage msg) {
    final body = msg.body ?? '';
    if (body.isEmpty) return false;
    if (!_amountRe.hasMatch(body)) return false;
    return _vpaRe.hasMatch(body) || _upiRefRe.hasMatch(body);
  }

  TransactionModel? _parse(SmsMessage msg, String userId) {
    final body = msg.body ?? '';

    final amountMatch = _amountRe.firstMatch(body);
    if (amountMatch == null) return null;

    final amount = double.tryParse(
      amountMatch.group(1)!.replaceAll(',', ''),
    );
    if (amount == null || amount <= 0) return null;

    final hasDebit  = _debitRe.hasMatch(body);
    final hasCredit = _creditRe.hasMatch(body);
    final direction = (hasCredit && !hasDebit) ? 'credit' : 'debit';

    String payee = _extractName(body);
    if (payee == 'Unknown') {
      final vpa = _vpaRe.firstMatch(body)?.group(0)?.trim() ?? '';
      if (vpa.isNotEmpty) payee = vpa;
    }

    final ts = msg.date != null
        ? DateTime.fromMillisecondsSinceEpoch(msg.date!)
        : DateTime.now();

    return TransactionModel(
      userId:        userId,
      amount:        amount,
      payee:         payee,
      direction:     direction,
      category:      'uncategorized',
      timestamp:     ts,
      formattedDate: DateFormat('dd MMM yyyy, hh:mm a').format(ts),
      source:        'sms',
      raw:           body,
    );
  }

  String _extractName(String body) {
    for (final re in [_nameToRe, _nameAtRe, _nameLabelRe]) {
      final m = re.firstMatch(body);
      if (m == null) continue;

      String candidate = m.group(1)?.trim() ?? '';
      if (candidate.isEmpty) continue;
      if (candidate.contains('@')) continue;
      if (_acRefRe.hasMatch(candidate)) continue;
      if (RegExp(r'^\d+$').hasMatch(candidate)) continue;

      final term = _nameTermRe.firstMatch(candidate);
      if (term != null) {
        candidate = candidate.substring(0, term.start).trim();
      }

      candidate = candidate.replaceAll(RegExp(r'[.,;:\-]+$'), '').trim();
      if (candidate.length >= 2) return _titleCase(candidate);
    }
    return 'Unknown';
  }

  String _titleCase(String s) {
    return s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}';
    }).join(' ');
  }
}