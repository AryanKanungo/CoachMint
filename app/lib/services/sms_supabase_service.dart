import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

class SupabaseTransactionService {
  SupabaseClient get _db => Supabase.instance.client;
  static const _table = 'transactions';

  /// Insert a new transaction.
  /// Hard-removes txn_id from payload — DB must have DEFAULT gen_random_uuid().
  Future<void> saveTransaction(TransactionModel txn) async {
    final payload = txn.toJson()..remove('txn_id');
    await _db.from(_table).insert(payload);
  }

  /// Update category for an existing row.
  Future<void> updateCategory(String txnId, String category) async {
    await _db
        .from(_table)
        .update({'category': category})
        .eq('txn_id', txnId);
  }

  /// All categorized transactions for this user, newest first.
  Future<List<TransactionModel>> fetchCategorized(String userId) async {
    final rows = await _db
        .from(_table)
        .select()
        .eq('user_id', userId)
        .neq('category', 'uncategorized')
        .order('timestamp', ascending: false);

    return rows.map<TransactionModel>(TransactionModel.fromJson).toList();
  }

  /// Raw SMS bodies already in DB — used for dedup on re-scan.
  Future<Set<String>> fetchExistingRaws(String userId) async {
    final rows = await _db
        .from(_table)
        .select('raw')
        .eq('user_id', userId);

    return rows.map<String>((r) => r['raw'].toString()).toSet();
  }
}