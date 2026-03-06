import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/transaction_model.dart';
import '../../services/sms_service.dart';
import '../../services/supabase_transaction_service.dart';

class TransactionController extends GetxController {
  final SmsService _smsService = SmsService();
  final SupabaseTransactionService _supabaseService = SupabaseTransactionService();

  final RxList<TransactionModel> uncategorized = <TransactionModel>[].obs;
  final RxList<TransactionModel> categorized = <TransactionModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString error = ''.obs;

  String get userId => Supabase.instance.client.auth.currentUser?.id ?? '';

  // --- SMS Permission ---

  Future<bool> requestSmsPermission() async {
    return await _smsService.requestPermission();
  }

  Future<bool> hasSmsPermission() async {
    return await _smsService.hasPermission();
  }

  // --- Load uncategorized SMS txns ---

  Future<void> loadSmsTransactions() async {
    isLoading.value = true;
    error.value = '';

    try {
      final all = await _smsService.fetchTransactions(userId);
      final existingRaws = await _supabaseService.fetchExistingRaws(userId);
      uncategorized.value =
          all.where((t) => !existingRaws.contains(t.raw)).toList();
    } catch (e) {
      error.value = 'Failed to load SMS: $e';
    }

    isLoading.value = false;
  }

  // --- Categorize a txn (drag-drop) ---

  Future<void> categorize(TransactionModel txn, String category) async {
    final updated = txn.copyWith(category: category);

    try {
      if (txn.txnId.isNotEmpty) {
        await _supabaseService.updateCategory(txn.txnId, category);
      } else {
        await _supabaseService.saveTransaction(updated);
      }
      uncategorized.removeWhere((t) => t.raw == txn.raw);
      categorized.insert(0, updated);
    } catch (e) {
      error.value = 'Failed to save: $e';
    }
  }

  // --- Fetch already-categorized records from Supabase ---

  Future<void> loadCategorized() async {
    isLoading.value = true;
    error.value = '';

    try {
      categorized.value = await _supabaseService.fetchCategorized(userId);
    } catch (e) {
      error.value = 'Failed to fetch records: $e';
    }

    isLoading.value = false;
  }
}