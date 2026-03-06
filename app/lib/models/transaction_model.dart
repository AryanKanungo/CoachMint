class TransactionModel {
  final String txnId;
  final String userId;
  final double amount;
  final String payee;
  final String direction;
  final String category;
  final DateTime timestamp;
  final String formattedDate;
  final String source;
  final String raw;

  TransactionModel({
    this.txnId = '',
    required this.userId,
    required this.amount,
    required this.payee,
    required this.direction,
    required this.category,
    required this.timestamp,
    required this.formattedDate,
    required this.source,
    required this.raw,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    txnId:         json['txn_id']?.toString() ?? '',
    userId:        json['user_id']?.toString() ?? '',
    amount:        (json['amount'] ?? 0).toDouble(),
    payee:         json['payee']?.toString() ?? '',
    direction:     json['direction']?.toString() ?? '',
    category:      json['category']?.toString() ?? '',
    timestamp:     DateTime.parse(json['timestamp']),
    formattedDate: json['formatted_date']?.toString() ?? '',
    source:        json['source']?.toString() ?? 'sms',
    raw:           json['raw']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id':        userId,
      'amount':         amount,
      'payee':          payee,
      'direction':      direction,
      'category':       category,
      'timestamp':      timestamp.toIso8601String(),
      'formatted_date': formattedDate,
      'source':         source,
      'raw':            raw,
    };
    // Never send txn_id on new inserts — Supabase generates it via DEFAULT gen_random_uuid()
    if (txnId.isNotEmpty) map['txn_id'] = txnId;
    return map;
  }

  TransactionModel copyWith({String? category, String? txnId}) {
    return TransactionModel(
      txnId:         txnId ?? this.txnId,
      userId:        userId,
      amount:        amount,
      payee:         payee,
      direction:     direction,
      category:      category ?? this.category,
      timestamp:     timestamp,
      formattedDate: formattedDate,
      source:        source,
      raw:           raw,
    );
  }
}