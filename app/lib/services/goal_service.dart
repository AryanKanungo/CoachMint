// lib/services/goal_service.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/goal_model.dart';

/// ════════════════════════════════════════════════════════════════
/// GoalService — all Supabase operations for the `goals` table.
/// All methods are scoped to the currently logged-in user via
/// Supabase auth — no user_id needs to be passed in from the UI.
/// ════════════════════════════════════════════════════════════════
class GoalService {
  GoalService._();
  static final GoalService instance = GoalService._();

  final SupabaseClient _db = Supabase.instance.client;

  String get _uid => _db.auth.currentUser?.id ?? '';

  // ── Read ────────────────────────────────────────────────────────

  /// Fetch all goals for the current user.
  /// Sorted server-side: deadline ASC, nulls last.
  Future<List<GoalModel>> fetchGoals() async {
    final rows = await _db
        .from('goals')
        .select()
        .eq('user_id', _uid)
        .order('deadline', ascending: true, nullsFirst: false);

    return (rows as List<dynamic>)
        .map((r) => GoalModel.fromJson(r as Map<String, dynamic>))
        .toList();
  }

  // ── Write ───────────────────────────────────────────────────────

  /// Insert a new goal. Returns the server-assigned record (with id).
  Future<GoalModel> addGoal(GoalModel goal) async {
    final payload = goal.toJson();
    // Always stamp with real auth uid — ignore anything caller passed
    payload['user_id'] = _uid;
    // Never send id on insert — let Supabase generate it
    payload.remove('id');

    final row = await _db
        .from('goals')
        .insert(payload)
        .select()
        .single();

    return GoalModel.fromJson(row as Map<String, dynamic>);
  }

  /// Patch only the saved_amount field (e.g. from a progress modal).
  Future<void> updateSavedAmount({
    required String goalId,
    required double newAmount,
  }) async {
    await _db
        .from('goals')
        .update({'saved_amount': newAmount})
        .eq('id', goalId)
        .eq('user_id', _uid);
  }

  // ── Delete ──────────────────────────────────────────────────────

  Future<void> deleteGoal(String goalId) async {
    await _db
        .from('goals')
        .delete()
        .eq('id', goalId)
        .eq('user_id', _uid);
  }
}