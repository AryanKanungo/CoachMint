// lib/models/goal_model.dart

/// ════════════════════════════════════════════════════════════════
/// GoalModel — matches goals table exactly.
/// DB columns: id, user_id, title, target_amount, deadline, saved_amount
/// ════════════════════════════════════════════════════════════════

class GoalModel {
  final String    id;           // '' on new inserts, DB gen_random_uuid() fills it
  final String    userId;
  final String    title;
  final double    targetAmount;
  final DateTime? deadline;
  final double    savedAmount;

  GoalModel({
    this.id = '',
    required this.userId,
    required this.title,
    required this.targetAmount,
    this.deadline,
    this.savedAmount = 0.0,
  });

  // ── Serialization ───────────────────────────────────────────────

  /// Read from Supabase row (uses snake_case DB columns)
  factory GoalModel.fromJson(Map<String, dynamic> json) => GoalModel(
    id:           json['id']?.toString() ?? '',
    userId:       json['user_id']?.toString() ?? '',
    title:        json['title']?.toString() ?? '',
    targetAmount: (json['target_amount'] ?? 0).toDouble(),
    deadline:     json['deadline'] != null
        ? DateTime.parse(json['deadline'].toString())
        : null,
    savedAmount:  (json['saved_amount'] ?? 0).toDouble(),
  );

  /// Alias so GoalService.fromMap() calls compile unchanged
  factory GoalModel.fromMap(Map<String, dynamic> map) =>
      GoalModel.fromJson(map);

  /// Write to Supabase. Omits id when empty (let DB generate it).
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'user_id':      userId,
      'title':        title,
      'target_amount': targetAmount,
      'deadline':     deadline?.toIso8601String(),
      'saved_amount': savedAmount,
    };
    if (id.isNotEmpty) map['id'] = id;
    return map;
  }

  /// Alias so GoalService.toMap() calls compile unchanged
  Map<String, dynamic> toMap() => toJson();

  // ── Derived helpers used by TrackGoalsScreen ────────────────────

  /// Fraction of target saved — clamped [0.0, 1.0]
  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  /// Amount still needed
  double get remaining => (targetAmount - savedAmount).clamp(0.0, double.infinity);

  /// Goal fully funded
  bool get isComplete => savedAmount >= targetAmount;

  /// Past deadline and not yet complete
  bool get isOverdue =>
      deadline != null && DateTime.now().isAfter(deadline!) && !isComplete;

  /// Days until deadline (null if no deadline set; negative means overdue)
  int? get daysUntilDeadline =>
      deadline != null ? deadline!.difference(DateTime.now()).inDays : null;

// NOTE: The old screen used `isEmergencyFund` and `category`.
// The DB table no longer has those columns, so they are removed.
// The Emergency Fund card now uses a fixed ₹50,000 target hardcoded
// in the screen, not a special goal flag.
}