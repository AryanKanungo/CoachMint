import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'supabase_client.dart';

/// Real-time alerts stream
final alertsRealtimeProvider = StreamProvider.autoDispose((ref) {
  return supabase
      .from('alerts')
      .stream(primaryKey: ['id'])
      .eq('user_id', currentUserId)
      .order('triggered_at', ascending: false)
      .limit(50);
});

/// Real-time latest financial snapshot
final latestSnapshotRealtimeProvider = StreamProvider.autoDispose((ref) {
  return supabase
      .from('financial_snapshots')
      .stream(primaryKey: ['id'])
      .eq('user_id', currentUserId)
      .order('snapshot_date', ascending: false)
      .limit(1);
});

/// Count of unread alerts for the badge
final unreadAlertsCountProvider = StreamProvider.autoDispose<int>((ref) {
  final stream = ref.watch(alertsRealtimeProvider);
  return stream.when(
    data:    (rows) => Stream.value(rows.where((r) => r['is_read'] == false).length),
    loading: ()     => Stream.value(0),
    error:   (_, __) => Stream.value(0),
  );
});

/// Count of transactions that need categorization
final uncategorizedCountProvider = StreamProvider.autoDispose<int>((ref) {
  return supabase
      .from('transactions')
      .stream(primaryKey: ['id'])
      .eq('user_id', currentUserId)
      .order('transaction_date', ascending: false)
      .limit(200)
      .map((rows) => rows
      .where((r) =>
  r['category'] == null || r['category_top'] == 'uncategorised')
      .length);
});