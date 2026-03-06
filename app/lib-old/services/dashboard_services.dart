import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardService {
  final _supabase = Supabase.instance.client;

  // Stream for the engine calculation
  Stream<List<Map<String, dynamic>>> getSnapshotStream(String userId) {
    return _supabase
        .from('financial_snapshots')
        .stream(primaryKey: ['user_id', 'snapshot_date'])
        .eq('user_id', userId)
        .order('snapshot_date', ascending: false)
        .limit(1);
  }

  // Stream for bills - only one .eq() here to avoid library errors
  Stream<List<Map<String, dynamic>>> getBillsStream(String userId) {
    return _supabase
        .from('bills')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .order('due_date', ascending: true);
  }
}