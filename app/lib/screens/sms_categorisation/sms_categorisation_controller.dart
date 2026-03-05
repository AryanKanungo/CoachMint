import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/transaction_model.dart';
import '../../core/sms/sms_service.dart';
import '../../core/supabase/supabase_client.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class SmsCategorisationState {
  final bool isLoaded;
  final List<TransactionModel> transactions;
  final bool isCategorizing;
  final int draggingIndex;

  const SmsCategorisationState({
    this.isLoaded = false,
    this.transactions = const [],
    this.isCategorizing = false,
    this.draggingIndex = -1,
  });

  SmsCategorisationState copyWith({
    bool? isLoaded,
    List<TransactionModel>? transactions,
    bool? isCategorizing,
    int? draggingIndex,
  }) =>
      SmsCategorisationState(
        isLoaded:       isLoaded       ?? this.isLoaded,
        transactions:   transactions   ?? this.transactions,
        isCategorizing: isCategorizing ?? this.isCategorizing,
        draggingIndex:  draggingIndex  ?? this.draggingIndex,
      );
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class SmsCategorisationNotifier
    extends StateNotifier<SmsCategorisationState> {
  SmsCategorisationNotifier() : super(const SmsCategorisationState()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    state = state.copyWith(isLoaded: false);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        state = state.copyWith(isLoaded: true);
        return;
      }

      // 1. Fetch already-saved txnIds from Supabase
      final snap = await supabase
          .from('transactions')
          .select('raw_sms_hash')
          .eq('user_id', userId)
          .not('category', 'is', null);

      final savedIds = (snap as List)
          .map((r) => r['raw_sms_hash'] as String)
          .toSet();

      // 2. Read last 7 days from phone inbox via SmsService
      final smsService = SmsService();
      final rawMessages = await smsService.getPastSms(7);

      // 3. Convert to TransactionModel and filter out already-saved ones
      final pending = <TransactionModel>[];
      for (final msg in rawMessages) {
        final txn = TransactionModel.fromRaw(
          body:          msg.body,
          dateMillis:    msg.date.millisecondsSinceEpoch,
          senderAddress: msg.sender,
        );
        if (txn.status == TxnStatus.processed &&
            !savedIds.contains(txn.txnId)) {
          pending.add(txn);
        }
      }

      state = state.copyWith(isLoaded: true, transactions: pending);
    } catch (e) {
      debugPrint('SmsCategorisationNotifier.loadTransactions error: $e');
      state = state.copyWith(isLoaded: true);
    }
  }

  void startCategorizing(int index) =>
      state = state.copyWith(draggingIndex: index, isCategorizing: true);

  void stopCategorizing() =>
      state = state.copyWith(isCategorizing: false, draggingIndex: -1);

  /// Save categorised transaction to Supabase, remove from pending list.
  Future<void> categorizeTransaction(
      TransactionModel txn, String category) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final existing = await supabase
          .from('transactions')
          .select('id')
          .eq('raw_sms_hash', txn.txnId)
          .eq('user_id', userId)
          .maybeSingle();

      if (existing != null) {
        // Already exists — just update category
        await supabase.from('transactions').update({
          'category':     category,
          'category_top': _mapTop(category),
        })
            .eq('raw_sms_hash', txn.txnId)
            .eq('user_id', userId);
      } else {
        // Insert fresh row
        final data = txn.toSupabase(userId);
        data['category']     = category;
        data['category_top'] = _mapTop(category);
        await supabase.from('transactions').insert(data);
      }

      await Future.delayed(const Duration(milliseconds: 50));

      final updated = List<TransactionModel>.from(state.transactions)
        ..remove(txn);
      state = state.copyWith(transactions: updated);
    } catch (e) {
      debugPrint('categorizeTransaction error: $e');
    }
  }

  String _mapTop(String category) {
    switch (category) {
      case 'Essential':     return 'needs';
      case 'Non-Essential': return 'wants';
      case 'Savings':       return 'savings';
      case 'Investments':   return 'savings';
      default:              return 'uncategorised';
    }
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final smsCategorisationProvider = StateNotifierProvider<
    SmsCategorisationNotifier, SmsCategorisationState>(
      (_) => SmsCategorisationNotifier(),
);