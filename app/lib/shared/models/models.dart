import 'package:intl/intl.dart';

final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
String formatInr(double v) => _inr.format(v);

// ── UserProfile ───────────────────────────────────────────────────────────────
class UserProfile {
  final String userId;
  final double currentWallet;
  final DateTime? nextIncomeDate;
  final double? expectedIncome;
  final String incomeFrequency;
  final bool onboardingComplete;

  const UserProfile({
    required this.userId,
    required this.currentWallet,
    this.nextIncomeDate,
    this.expectedIncome,
    required this.incomeFrequency,
    required this.onboardingComplete,
  });

  factory UserProfile.fromMap(Map<String, dynamic> m) => UserProfile(
    userId:             m['user_id'],
    currentWallet:      (m['current_wallet'] as num?)?.toDouble() ?? 0,
    nextIncomeDate:     m['next_income_date'] != null
        ? DateTime.tryParse(m['next_income_date'])
        : null,
    expectedIncome:     (m['expected_income'] as num?)?.toDouble(),
    incomeFrequency:    m['income_frequency'] ?? 'monthly',
    onboardingComplete: m['onboarding_complete'] ?? false,
  );
}

// ── FinancialSnapshot ─────────────────────────────────────────────────────────
class FinancialSnapshot {
  final String id;
  final String userId;
  final DateTime snapshotDate;
  final double walletBalance;
  final double upcomingBillsTotal;
  final double avgDailyExpense;
  final double safeToSpendPerDay;
  final double survivalDays;
  final int resilienceScore;
  final String resilienceLabel;
  final String incomeTrend;
  final List<String> riskFlags;
  final List<Map<String, dynamic>> balanceCurve14d;

  const FinancialSnapshot({
    required this.id,
    required this.userId,
    required this.snapshotDate,
    required this.walletBalance,
    required this.upcomingBillsTotal,
    required this.avgDailyExpense,
    required this.safeToSpendPerDay,
    required this.survivalDays,
    required this.resilienceScore,
    required this.resilienceLabel,
    required this.incomeTrend,
    required this.riskFlags,
    required this.balanceCurve14d,
  });

  factory FinancialSnapshot.fromMap(Map<String, dynamic> m) => FinancialSnapshot(
    id:                  m['id'],
    userId:              m['user_id'],
    snapshotDate:        DateTime.parse(m['snapshot_date']),
    walletBalance:       (m['wallet_balance'] as num?)?.toDouble() ?? 0,
    upcomingBillsTotal:  (m['upcoming_bills_total'] as num?)?.toDouble() ?? 0,
    avgDailyExpense:     (m['avg_daily_expense'] as num?)?.toDouble() ?? 0,
    safeToSpendPerDay:   (m['safe_to_spend_per_day'] as num?)?.toDouble() ?? 0,
    survivalDays:        (m['survival_days'] as num?)?.toDouble() ?? 0,
    resilienceScore:     (m['resilience_score'] as num?)?.toInt() ?? 0,
    resilienceLabel:     m['resilience_label'] ?? 'FRAGILE',
    incomeTrend:         m['income_trend'] ?? 'stable',
    riskFlags:           (m['risk_flags'] as List?)?.cast<String>() ?? [],
    balanceCurve14d:     (m['balance_curve_14d'] as List?)
        ?.cast<Map<String, dynamic>>() ??
        [],
  );
}

// ── BillModel ─────────────────────────────────────────────────────────────────
class BillModel {
  final String id;
  final String name;
  final double amount;
  final DateTime dueDate;
  final bool isRecurring;
  final bool isPaid;
  final String guardStatus;

  const BillModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.isRecurring,
    required this.isPaid,
    required this.guardStatus,
  });

  factory BillModel.fromMap(Map<String, dynamic> m) => BillModel(
    id:          m['id'],
    name:        m['name'],
    amount:      (m['amount'] as num).toDouble(),
    dueDate:     DateTime.parse(m['due_date']),
    isRecurring: m['is_recurring'] ?? false,
    isPaid:      m['is_paid'] ?? false,
    guardStatus: m['guard_status'] ?? 'unknown',
  );

  int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;
}

// ── GoalModel ─────────────────────────────────────────────────────────────────
class GoalModel {
  final String id;
  final String name;
  final double targetAmount;
  final double savedAmount;
  final DateTime? deadline;
  final bool isEmergencyFund;
  final String status;
  final double? dailyNeeded;

  const GoalModel({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.savedAmount,
    this.deadline,
    required this.isEmergencyFund,
    required this.status,
    this.dailyNeeded,
  });

  factory GoalModel.fromMap(Map<String, dynamic> m) => GoalModel(
    id:             m['id'],
    name:           m['name'],
    targetAmount:   (m['target_amount'] as num).toDouble(),
    savedAmount:    (m['saved_amount'] as num).toDouble(),
    deadline:       m['deadline'] != null ? DateTime.parse(m['deadline']) : null,
    isEmergencyFund: m['is_emergency_fund'] ?? false,
    status:          m['status'] ?? 'in_progress',
    dailyNeeded:     (m['daily_needed'] as num?)?.toDouble(),
  );

  double get progressPercent =>
      targetAmount > 0 ? (savedAmount / targetAmount).clamp(0.0, 1.0) : 0;
}

// ── AlertModel ────────────────────────────────────────────────────────────────
class AlertModel {
  final String id;
  final String alertType;
  final String severity;
  final String title;
  final String message;
  final bool isRead;
  final DateTime triggeredAt;

  const AlertModel({
    required this.id,
    required this.alertType,
    required this.severity,
    required this.title,
    required this.message,
    required this.isRead,
    required this.triggeredAt,
  });

  factory AlertModel.fromMap(Map<String, dynamic> m) => AlertModel(
    id:          m['id'],
    alertType:   m['alert_type'] ?? 'info',
    severity:    m['severity'] ?? 'info',
    title:       m['title'] ?? '',
    message:     m['message'] ?? '',
    isRead:      m['is_read'] ?? false,
    triggeredAt: DateTime.parse(m['triggered_at']),
  );
}

// ── WelfareMatch ──────────────────────────────────────────────────────────────
class WelfareMatch {
  final String id;
  final String schemeId;
  final String schemeName;
  final String schemeDescription;
  final List<String> documents;
  final String? applyUrl;
  final bool isApplied;
  final bool isDismissed;

  const WelfareMatch({
    required this.id,
    required this.schemeId,
    required this.schemeName,
    required this.schemeDescription,
    required this.documents,
    this.applyUrl,
    required this.isApplied,
    required this.isDismissed,
  });

  factory WelfareMatch.fromMap(Map<String, dynamic> m) {
    final scheme = m['welfare_schemes'] as Map<String, dynamic>? ?? {};
    final docs   = scheme['documents'];
    return WelfareMatch(
      id:                m['id'],
      schemeId:          m['scheme_id'],
      schemeName:        scheme['name'] ?? '',
      schemeDescription: scheme['description'] ?? '',
      documents:         docs is List ? docs.cast<String>() : [],
      applyUrl:          scheme['apply_url'],
      isApplied:         m['is_applied'] ?? false,
      isDismissed:       m['is_dismissed'] ?? false,
    );
  }
}

// ── WeeklySummary ─────────────────────────────────────────────────────────────
class WeeklySummary {
  final String id;
  final DateTime weekStart;
  final DateTime weekEnd;
  final String summaryText;
  final Map<String, dynamic> keyMetrics;

  const WeeklySummary({
    required this.id,
    required this.weekStart,
    required this.weekEnd,
    required this.summaryText,
    required this.keyMetrics,
  });

  factory WeeklySummary.fromMap(Map<String, dynamic> m) => WeeklySummary(
    id:          m['id'],
    weekStart:   DateTime.parse(m['week_start']),
    weekEnd:     DateTime.parse(m['week_end']),
    summaryText: m['summary_text'] ?? '',
    keyMetrics:  m['key_metrics'] as Map<String, dynamic>? ?? {},
  );
}