import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../../core/supabase/supabase_client.dart';

// ── UserRepository ────────────────────────────────────────────────────────────
class UserRepository {
  Future<UserProfile?> getProfile() async {
    final data = await supabase
        .from('user_profile')
        .select()
        .eq('user_id', currentUserId)
        .maybeSingle();
    return data != null ? UserProfile.fromMap(data) : null;
  }

  Future<void> upsertProfile(Map<String, dynamic> data) async =>
      supabase.from('user_profile').upsert(data);

  Future<void> completeOnboarding() async => supabase
      .from('user_profile')
      .update({'onboarding_complete': true})
      .eq('user_id', currentUserId);
}

final userRepoProvider = Provider<UserRepository>((_) => UserRepository());

// ── SnapshotRepository ────────────────────────────────────────────────────────
class SnapshotRepository {
  Future<FinancialSnapshot?> getLatest() async {
    final data = await supabase
        .from('financial_snapshots')
        .select()
        .eq('user_id', currentUserId)
        .order('snapshot_date', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? FinancialSnapshot.fromMap(data) : null;
  }
}

final snapshotRepoProvider =
Provider<SnapshotRepository>((_) => SnapshotRepository());

// ── TransactionRepository ─────────────────────────────────────────────────────
class TransactionRepository {
  Future<List<Map<String, dynamic>>> getRecent({int limit = 20}) async =>
      supabase
          .from('transactions')
          .select()
          .eq('user_id', currentUserId)
          .order('transaction_date', ascending: false)
          .limit(limit);

  Future<void> addManual({
    required String type,
    required double amount,
    required String categoryTop,
    String? merchant,
  }) async =>
      supabase.from('transactions').insert({
        'user_id':          currentUserId,
        'type':             type,
        'amount':           amount,
        'category_top':     categoryTop,
        'merchant':         merchant,
        'source':           'manual',
        'transaction_date': DateTime.now().toIso8601String(),
        'needs_review':     false,
      });

  Future<Map<String, double>> getWeeklyBreakdown() async {
    final weekStart =
    DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final data = await supabase
        .from('transactions')
        .select('category_top, amount')
        .eq('user_id', currentUserId)
        .eq('type', 'debit')
        .gte('transaction_date', weekStart.toIso8601String());

    final result = <String, double>{'needs': 0, 'wants': 0, 'savings': 0};
    for (final r in data) {
      final cat = r['category_top'] as String? ?? 'wants';
      final amt = (r['amount'] as num).toDouble();
      result[cat] = (result[cat] ?? 0) + amt;
    }
    return result;
  }
}

final transactionRepoProvider =
Provider<TransactionRepository>((_) => TransactionRepository());

// ── BillRepository ────────────────────────────────────────────────────────────
class BillRepository {
  Future<List<BillModel>> getBills() async {
    final data = await supabase
        .from('bills')
        .select()
        .eq('user_id', currentUserId)
        .eq('is_paid', false)
        .order('due_date');
    return data.map((e) => BillModel.fromMap(e)).toList();
  }

  Future<void> addBill({
    required String name,
    required double amount,
    required DateTime dueDate,
    bool isRecurring = false,
    String? recurrencePeriod,
  }) async =>
      supabase.from('bills').insert({
        'user_id':           currentUserId,
        'name':              name,
        'amount':            amount,
        'due_date':          dueDate.toIso8601String().split('T')[0],
        'is_recurring':      isRecurring,
        'recurrence_period': recurrencePeriod,
      });

  Future<void> markPaid(String id) async =>
      supabase.from('bills').update({
        'is_paid': true,
        'paid_at': DateTime.now().toIso8601String(),
      }).eq('id', id);

  Future<void> deleteBill(String id) async =>
      supabase.from('bills').delete().eq('id', id);
}

final billRepoProvider = Provider<BillRepository>((_) => BillRepository());

// ── GoalRepository ────────────────────────────────────────────────────────────
class GoalRepository {
  Future<List<GoalModel>> getGoals() async {
    final data = await supabase
        .from('goals')
        .select()
        .eq('user_id', currentUserId)
        .neq('status', 'achieved')
        .order('is_emergency_fund', ascending: false);
    return data.map((e) => GoalModel.fromMap(e)).toList();
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    DateTime? deadline,
    bool isEmergencyFund = false,
  }) async =>
      supabase.from('goals').insert({
        'user_id':          currentUserId,
        'name':             name,
        'target_amount':    targetAmount,
        'saved_amount':     0,
        'deadline':         deadline?.toIso8601String().split('T')[0],
        'is_emergency_fund': isEmergencyFund,
        'status':           'in_progress',
      });

  Future<void> deleteGoal(String id) async =>
      supabase.from('goals').delete().eq('id', id);
}

final goalRepoProvider = Provider<GoalRepository>((_) => GoalRepository());

// ── AlertRepository ───────────────────────────────────────────────────────────
class AlertRepository {
  Future<List<AlertModel>> getAlerts() async {
    final data = await supabase
        .from('alerts')
        .select()
        .eq('user_id', currentUserId)
        .order('triggered_at', ascending: false)
        .limit(50);
    return data.map((e) => AlertModel.fromMap(e)).toList();
  }

  Future<void> markRead(String id) async =>
      supabase.from('alerts').update({'is_read': true}).eq('id', id);

  Future<void> markAllRead() async =>
      supabase
          .from('alerts')
          .update({'is_read': true})
          .eq('user_id', currentUserId)
          .eq('is_read', false);
}

final alertRepoProvider = Provider<AlertRepository>((_) => AlertRepository());

// ── WelfareRepository ─────────────────────────────────────────────────────────
class WelfareRepository {
  Future<List<WelfareMatch>> getMatches() async {
    final data = await supabase
        .from('welfare_matches')
        .select('*, welfare_schemes(*)')
        .eq('user_id', currentUserId)
        .eq('is_dismissed', false);
    return data.map((e) => WelfareMatch.fromMap(e)).toList();
  }

  Future<void> markApplied(String id) async =>
      supabase.from('welfare_matches').update({'is_applied': true}).eq('id', id);

  Future<void> dismiss(String id) async =>
      supabase.from('welfare_matches').update({'is_dismissed': true}).eq('id', id);
}

final welfareRepoProvider =
Provider<WelfareRepository>((_) => WelfareRepository());

// ── SummaryRepository ─────────────────────────────────────────────────────────
class SummaryRepository {
  Future<List<WeeklySummary>> getSummaries() async {
    final data = await supabase
        .from('weekly_summaries')
        .select()
        .eq('user_id', currentUserId)
        .order('week_start', ascending: false)
        .limit(10);
    return data.map((e) => WeeklySummary.fromMap(e)).toList();
  }
}

final summaryRepoProvider =
Provider<SummaryRepository>((_) => SummaryRepository());