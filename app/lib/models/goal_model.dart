// lib/models/goal_model.dart

/// ════════════════════════════════════════════════════════════════
/// GoalModel — mirrors the `goals` table in Supabase
///
/// Table schema:
///   id             text (uuid, PK, default gen_random_uuid())
///   user_id        text
///   title          text
///   target_amount  numeric
///   saved_amount   numeric  (default 0)
///   deadline       text     (ISO-8601 date, nullable)
///   category       text     (nullable)
///   is_emergency_fund boolean (default false)
/// ════════════════════════════════════════════════════════════════
class GoalModel {
  final String? id;
  final String userId;
  final String title;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;

  /// One of: 'home' | 'tech' | 'travel' | 'health' | 'edu' | 'other'
  final String? category;

  /// True for the emergency fund goal — used to compute the header card
  final bool isEmergencyFund;

  const GoalModel({
    this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.savedAmount = 0.0,
    this.deadline,
    this.category,
    this.isEmergencyFund = false,
  });

  // ── Derived helpers ────────────────────────────────────────────

  /// 0.0 → 1.0 clamped
  double get progressPercent =>
      targetAmount > 0
          ? (savedAmount / targetAmount).clamp(0.0, 1.0)
          : 0.0;

  double get remaining =>
      (targetAmount - savedAmount).clamp(0.0, double.infinity);

  bool get isComplete => savedAmount >= targetAmount;

  /// null when no deadline is set
  int? get daysUntilDeadline =>
      deadline == null
          ? null
          : deadline!.difference(DateTime.now()).inDays;

  bool get isOverdue =>
      deadline != null &&
      deadline!.isBefore(DateTime.now()) &&
      !isComplete;

  // ── Serialisation ──────────────────────────────────────────────

  factory GoalModel.fromMap(Map<String, dynamic> m) => GoalModel(
        id: m['id'] as String?,
        userId: (m['user_id'] as String?) ?? '',
        title: (m['title'] as String?) ?? '',
        targetAmount: _toDouble(m['target_amount']),
        savedAmount: _toDouble(m['saved_amount']),
        deadline: m['deadline'] != null
            ? DateTime.tryParse(m['deadline'] as String)
            : null,
        category: m['category'] as String?,
        isEmergencyFund: (m['is_emergency_fund'] as bool?) ?? false,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'title': title,
        'target_amount': targetAmount,
        'saved_amount': savedAmount,
        if (deadline != null)
          'deadline': deadline!.toIso8601String().split('T').first,
        if (category != null) 'category': category,
        'is_emergency_fund': isEmergencyFund,
      };

  GoalModel copyWith({
    String? id,
    String? userId,
    String? title,
    double? targetAmount,
    double? savedAmount,
    DateTime? deadline,
    String? category,
    bool? isEmergencyFund,
  }) =>
      GoalModel(
        id: id ?? this.id,
        userId: userId ?? this.userId,
        title: title ?? this.title,
        targetAmount: targetAmount ?? this.targetAmount,
        savedAmount: savedAmount ?? this.savedAmount,
        deadline: deadline ?? this.deadline,
        category: category ?? this.category,
        isEmergencyFund: isEmergencyFund ?? this.isEmergencyFund,
      );

  // ── Private helpers ────────────────────────────────────────────

  static double _toDouble(dynamic v) {
    if (v == null) return 0.0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}
