class UserModel {
  final String id;
  final String email;

  UserModel({required this.id, required this.email});

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    email: json['email'] ?? '',
  );

  Map<String, dynamic> toJson() => {"id": id, "email": email};
}

class UserProfileModel {
  final String userId;
  final String incomeSourceLabel;
  final double startingBalance;
  final DateTime? nextIncomeDate;
  final double expectedIncome;
  final bool onboardingComplete;

  UserProfileModel({
    required this.userId,
    required this.incomeSourceLabel,
    required this.startingBalance,
    this.nextIncomeDate,
    required this.expectedIncome,
    this.onboardingComplete = false,
  });

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
    userId: json['user_id'] ?? '',
    incomeSourceLabel: json['income_source_label'] ?? '',
    startingBalance: (json['starting_balance'] ?? 0).toDouble(),
    nextIncomeDate: json['next_income_date'] != null ? DateTime.parse(json['next_income_date']) : null,
    expectedIncome: (json['expected_income'] ?? 0).toDouble(),
    onboardingComplete: json['onboarding_complete'] ?? false,
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId,
    "income_source_label": incomeSourceLabel,
    "starting_balance": startingBalance,
    "next_income_date": nextIncomeDate?.toIso8601String(),
    "expected_income": expectedIncome,
    "onboarding_complete": onboardingComplete,
  };
}

class BillModel {
  final String id; // Back to non-nullable!
  final String userId;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;

  BillModel({
    this.id = '', // Defaults to empty string for new inserts
    required this.userId,
    required this.name,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
  });

  factory BillModel.fromJson(Map<String, dynamic> json) => BillModel(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    dueDate: DateTime.parse(json['due_date']),
    isPaid: json['is_paid'] ?? false,
  );

  Map<String, dynamic> toJson() {
    final map = {
      "user_id": userId,
      "name": name,
      "amount": amount,
      "due_date": dueDate.toIso8601String(),
      "is_paid": isPaid,
    };

    // Supabase will auto-generate the UUID if we don't send the empty string
    if (id.isNotEmpty) {
      map["id"] = id;
    }
    return map;
  }
}

class TransactionModel {
  final String txnId; // Back to non-nullable
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
    this.txnId = '', // Defaults to empty string
    required this.userId, required this.amount,
    required this.payee, required this.direction, required this.category,
    required this.timestamp, required this.formattedDate, required this.source,
    required this.raw,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
    txnId: json['txn_id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    amount: (json['amount'] ?? 0).toDouble(),
    payee: json['payee']?.toString() ?? '',
    direction: json['direction']?.toString() ?? '',
    category: json['category']?.toString() ?? '',
    timestamp: DateTime.parse(json['timestamp']),
    formattedDate: json['formatted_date']?.toString() ?? '',
    source: json['source']?.toString() ?? 'sms',
    raw: json['raw']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() {
    final map = {
      "user_id": userId, "amount": amount, "payee": payee,
      "direction": direction, "category": category,
      "timestamp": timestamp.toIso8601String(), "formatted_date": formattedDate,
      "source": source, "raw": raw,
    };

    if (txnId.isNotEmpty) {
      map["txn_id"] = txnId;
    }
    return map;
  }
}

class GoalModel {
  final String id; // Back to non-nullable
  final String userId;
  final String title;
  final double targetAmount;
  final DateTime? deadline;
  final double savedAmount;

  GoalModel({
    this.id = '', // Defaults to empty string
    required this.userId, required this.title,
    required this.targetAmount, this.deadline, this.savedAmount = 0.0,
  });

  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id: json['id']?.toString() ?? '',
    userId: json['user_id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    targetAmount: (json['target_amount'] ?? 0).toDouble(),
    deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
    savedAmount: (json['saved_amount'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() {
    final map = {
      "user_id": userId, "title": title, "target_amount": targetAmount,
      "deadline": deadline?.toIso8601String(), "saved_amount": savedAmount,
    };

    if (id.isNotEmpty) {
      map["id"] = id;
    }
    return map;
  }
}

class FinancialSnapshotModel {
  final String userId;
  final DateTime snapshotDate;
  final double cb, ub, ade, minReserve, spd, survivalDays;
  final int nd, resilienceScore;

  FinancialSnapshotModel({
    required this.userId, required this.snapshotDate, required this.cb,
    required this.ub, required this.nd, required this.ade,
    required this.minReserve, required this.spd, required this.resilienceScore,
    required this.survivalDays,
  });

  factory FinancialSnapshotModel.fromJson(Map<String, dynamic> json) => FinancialSnapshotModel(
    userId: json['user_id'] ?? '',
    snapshotDate: DateTime.parse(json['snapshot_date']),
    cb: (json['cb'] ?? 0).toDouble(),
    ub: (json['ub'] ?? 0).toDouble(),
    nd: json['nd'] ?? 0,
    ade: (json['ade'] ?? 0).toDouble(),
    minReserve: (json['min_reserve'] ?? 0).toDouble(),
    spd: (json['spd'] ?? 0).toDouble(),
    resilienceScore: json['resilience_score'] ?? 0,
    survivalDays: (json['survival_days'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toJson() => {
    "user_id": userId, "snapshot_date": snapshotDate.toIso8601String(),
    "cb": cb, "ub": ub, "nd": nd, "ade": ade, "min_reserve": minReserve,
    "spd": spd, "resilience_score": resilienceScore, "survival_days": survivalDays,
  };
}