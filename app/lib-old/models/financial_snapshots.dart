class FinancialSnapshot {
  final double cb;           // Current Balance
  final double ub;           // Total upcoming bills
  final int nd;              // Days until next income
  final double ade;          // Average Daily Expense
  final double minReserve;   // 3 * ADE
  final double spd;          // Safe to Spend Per Day (Derived: (CB-UB-MinReserve)/ND)
  final int resilienceScore; // 0-100 score
  final DateTime timestamp;

  FinancialSnapshot({
    required this.cb,
    required this.ub,
    required this.nd,
    required this.ade,
    required this.minReserve,
    required this.spd,
    required this.resilienceScore,
    required this.timestamp,
  });

  Map<String, dynamic> toFirestore() {
    return {
      "cb": cb,
      "ub": ub,
      "nd": nd,
      "ade": ade,
      "minReserve": minReserve,
      "spd": spd,
      "resilienceScore": resilienceScore,
      "timestamp": timestamp,
    };
  }
}