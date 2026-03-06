// lib/models/chat_models.dart

// ─────────────────────────────────────────────────────────────
// ChatMessage — one entry in the conversation ListView
// ─────────────────────────────────────────────────────────────
class ChatMessage {
  final String role; // "user" | "model"
  final String content;
  final bool hasSimulation;
  final SimulationData? simulation;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.content,
    this.hasSimulation = false,
    this.simulation,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

// ─────────────────────────────────────────────────────────────
// ChatApiResponse — direct mapping of POST /api/chat response
// ─────────────────────────────────────────────────────────────
class ChatApiResponse {
  final String reply;
  final String? toolUsed; // "simulate_expense" | null
  final Map<String, dynamic>? simulationResult;
  final String suggestedLessonTitle;
  final String suggestedLessonSummary;

  ChatApiResponse({
    required this.reply,
    this.toolUsed,
    this.simulationResult,
    required this.suggestedLessonTitle,
    required this.suggestedLessonSummary,
  });

  factory ChatApiResponse.fromJson(Map<String, dynamic> json) {
    return ChatApiResponse(
      reply: json['reply'] as String,
      toolUsed: json['tool_used'] as String?,
      simulationResult:
          json['simulation_result'] as Map<String, dynamic>?,
      suggestedLessonTitle:
          json['suggested_lesson_title'] as String? ?? '',
      suggestedLessonSummary:
          json['suggested_lesson_summary'] as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SimulationSnapshot — before / after financial state
// ─────────────────────────────────────────────────────────────
class SimulationSnapshot {
  final double cb;
  final double spd;
  final double survivalDays;
  final int resilienceScore;
  final String resilienceLabel;
  final List<String> riskFlags;

  SimulationSnapshot({
    required this.cb,
    required this.spd,
    required this.survivalDays,
    required this.resilienceScore,
    required this.resilienceLabel,
    required this.riskFlags,
  });

  factory SimulationSnapshot.fromMap(Map<String, dynamic> m) {
    return SimulationSnapshot(
      cb: (m['cb'] ?? 0).toDouble(),
      spd: (m['spd'] ?? 0).toDouble(),
      survivalDays: (m['survival_days'] ?? 0).toDouble(),
      resilienceScore: (m['resilience_score'] ?? 0) as int,
      resilienceLabel: m['resilience_label'] as String? ?? '',
      riskFlags: List<String>.from(m['risk_flags'] ?? []),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BalancePoint — one point on the 14-day balance curve
// ─────────────────────────────────────────────────────────────
class BalancePoint {
  final DateTime date;
  final double balance;

  BalancePoint({required this.date, required this.balance});

  factory BalancePoint.fromMap(Map<String, dynamic> m) {
    return BalancePoint(
      date: DateTime.parse(m['date'] as String),
      balance: (m['balance'] ?? 0).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// BillAtRisk — bill that becomes unaffordable after the expense
// ─────────────────────────────────────────────────────────────
class BillAtRisk {
  final String name;
  final double amount;
  final String dueDate;
  final double shortfall;

  BillAtRisk({
    required this.name,
    required this.amount,
    required this.dueDate,
    required this.shortfall,
  });

  factory BillAtRisk.fromMap(Map<String, dynamic> m) {
    return BillAtRisk(
      name: m['name'] as String,
      amount: (m['amount'] ?? 0).toDouble(),
      dueDate: m['due_date'] as String? ?? '',
      shortfall: (m['shortfall'] ?? 0).toDouble(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SimulationDelta — what changes between before and after
// ─────────────────────────────────────────────────────────────
class SimulationDelta {
  final double spdChange;
  final double survivalDaysLost;
  final int resilienceDrop;
  final List<String> newFlags;
  final List<BillAtRisk> billsNowAtRisk;

  SimulationDelta({
    required this.spdChange,
    required this.survivalDaysLost,
    required this.resilienceDrop,
    required this.newFlags,
    required this.billsNowAtRisk,
  });

  factory SimulationDelta.fromMap(Map<String, dynamic> m) {
    return SimulationDelta(
      spdChange: (m['spd_change'] ?? 0).toDouble(),
      survivalDaysLost: (m['survival_days_lost'] ?? 0).toDouble(),
      resilienceDrop: (m['resilience_drop'] ?? 0) as int,
      newFlags: List<String>.from(m['new_flags'] ?? []),
      billsNowAtRisk: (m['bills_now_at_risk'] as List<dynamic>? ?? [])
          .map((b) => BillAtRisk.fromMap(b as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SimulationCurve — predicted burn + 14-day balance curve
// ─────────────────────────────────────────────────────────────
class SimulationCurve {
  final double predictedBurnRate;
  final double predictedSurvivalDays;
  final List<BalancePoint> balanceCurve;

  SimulationCurve({
    required this.predictedBurnRate,
    required this.predictedSurvivalDays,
    required this.balanceCurve,
  });

  factory SimulationCurve.fromMap(Map<String, dynamic> m) {
    return SimulationCurve(
      predictedBurnRate: (m['predicted_burn_rate'] ?? 0).toDouble(),
      predictedSurvivalDays:
          (m['predicted_survival_days'] ?? 0).toDouble(),
      balanceCurve:
          (m['balance_curve'] as List<dynamic>? ?? [])
              .map((p) =>
                  BalancePoint.fromMap(p as Map<String, dynamic>))
              .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SimulationData — top-level parsed simulation_result
// ─────────────────────────────────────────────────────────────
class SimulationData {
  final double proposedExpense;
  final String verdict; // "safe" | "risky" | "critical"
  final SimulationSnapshot before;
  final SimulationSnapshot after;
  final SimulationDelta delta;
  final SimulationCurve predictionBefore;
  final SimulationCurve predictionAfter;

  SimulationData({
    required this.proposedExpense,
    required this.verdict,
    required this.before,
    required this.after,
    required this.delta,
    required this.predictionBefore,
    required this.predictionAfter,
  });

  factory SimulationData.fromMap(Map<String, dynamic> m) {
    final prediction =
        m['prediction'] as Map<String, dynamic>? ?? {};
    return SimulationData(
      proposedExpense: (m['proposed_expense'] ?? 0).toDouble(),
      verdict: m['verdict'] as String? ?? 'risky',
      before: SimulationSnapshot.fromMap(
          m['before'] as Map<String, dynamic>),
      after: SimulationSnapshot.fromMap(
          m['after'] as Map<String, dynamic>),
      delta: SimulationDelta.fromMap(
          m['delta'] as Map<String, dynamic>),
      predictionBefore: SimulationCurve.fromMap(
          prediction['before'] as Map<String, dynamic>? ?? {}),
      predictionAfter: SimulationCurve.fromMap(
          prediction['after'] as Map<String, dynamic>? ?? {}),
    );
  }
}
