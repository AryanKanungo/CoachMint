import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/transaction_model.dart';
import '../../services/sms_service.dart';
import '../services/sms_supabase_service.dart';

class TransactionController extends GetxController {
  final _smsService      = SmsService();
  final _supabaseService = SupabaseTransactionService();

  final uncategorized = <TransactionModel>[].obs;
  final categorized   = <TransactionModel>[].obs;
  final isLoading     = false.obs;
  final errorMsg      = ''.obs;

  String get userId =>
      Supabase.instance.client.auth.currentUser?.id ?? '';

  // ── Permission ────────────────────────────────────────────────────────────

  Future<bool> requestSmsPermission() => _smsService.requestPermission();
  Future<bool> hasSmsPermission()     => _smsService.hasPermission();

  // ── Load SMS transactions ─────────────────────────────────────────────────

  Future<void> loadSmsTransactions() async {
    isLoading.value = true;
    errorMsg.value  = '';

    try {
      final all = await _smsService.fetchTransactions(userId);

      // Dedup against Supabase — non-fatal if DB call fails
      Set<String> existingRaws = {};
      try {
        existingRaws = await _supabaseService.fetchExistingRaws(userId);
      } catch (_) {}

      uncategorized.value =
          all.where((t) => !existingRaws.contains(t.raw)).toList();
    } catch (e) {
      errorMsg.value = 'Could not read SMS: $e';
    } finally {
      isLoading.value = false;
    }
  }

  // ── Categorize (drag-drop) ────────────────────────────────────────────────

  Future<void> categorize(TransactionModel txn, String category) async {
    // Optimistic remove
    uncategorized.removeWhere((t) => t.raw == txn.raw);

    final updated = txn.copyWith(category: category);

    try {
      if (txn.txnId.isNotEmpty) {
        await _supabaseService.updateCategory(txn.txnId, category);
      } else {
        await _supabaseService.saveTransaction(updated);
      }
      categorized.insert(0, updated);
    } catch (e) {
      // Rollback on failure — tile goes back into the list
      uncategorized.insert(0, txn);
      errorMsg.value = 'Save failed — try again';
    }
  }

  // ── Fetch categorized records ─────────────────────────────────────────────

  Future<void> loadCategorized() async {
    isLoading.value = true;
    errorMsg.value  = '';

    try {
      categorized.value = await _supabaseService.fetchCategorized(userId);
    } catch (e) {
      errorMsg.value = 'Could not load records: $e';
    } finally {
      isLoading.value = false;
    }
  }
}