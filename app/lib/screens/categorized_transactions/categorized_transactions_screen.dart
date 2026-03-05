import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/transaction_model.dart';
import '../../core/supabase/supabase_client.dart';
import '../../shared/widgets/widgets.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final categorizedTxnProvider =
FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  final data = await supabase
      .from('transactions')
      .select()
      .eq('user_id', currentUserId)
      .not('category', 'is', null)
      .order('transaction_date', ascending: false)
      .limit(200);

  return (data as List)
      .map((r) => TransactionModel.fromSupabase(r as Map<String, dynamic>))
      .toList();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class CategorizedTransactionsScreen extends ConsumerStatefulWidget {
  const CategorizedTransactionsScreen({super.key});

  @override
  ConsumerState<CategorizedTransactionsScreen> createState() =>
      _CategorizedTransactionsScreenState();
}

class _CategorizedTransactionsScreenState
    extends ConsumerState<CategorizedTransactionsScreen> {
  final List<String> _filters = [
    'All',
    'Essential',
    'Non-Essential',
    'Savings',
    'Investments',
  ];
  String _selected = 'All';

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(categorizedTxnProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Transaction History')),
      body: async.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.brand)),
        error: (e, _) => Center(
            child: Text('Error: $e',
                style: const TextStyle(color: AppTheme.textMuted))),
        data: (allTxns) {
          final filtered = _selected == 'All'
              ? allTxns
              : allTxns
              .where((t) => t.category == _selected)
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Filter chips ──────────────────────────────────────────
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Row(
                  children: _filters.map((f) {
                    final active = f == _selected;
                    final color = f == 'All'
                        ? AppTheme.brand
                        : (kCategoryColors[f] ?? AppTheme.brand);

                    return GestureDetector(
                      onTap: () => setState(() => _selected = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.only(right: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active
                              ? color.withOpacity(0.15)
                              : AppTheme.surfaceCard,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: active ? color : AppTheme.border,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Text(
                          f,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: active ? color : AppTheme.textMuted,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // ── Count ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Text(
                  '${filtered.length} transaction${filtered.length != 1 ? 's' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textMuted),
                ),
              ),

              // ── List ──────────────────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No transactions',
                  subtitle: 'Nothing in this category yet.',
                )
                    : ListView.separated(
                  padding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) =>
                  const SizedBox(height: 10),
                  itemBuilder: (_, i) =>
                      _TxnCard(txn: filtered[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Transaction card ──────────────────────────────────────────────────────────

class _TxnCard extends StatelessWidget {
  final TransactionModel txn;
  const _TxnCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.direction == 'in';
    final amtColor = isIncome ? AppTheme.success : AppTheme.danger;
    final catColor =
        kCategoryColors[txn.category] ?? AppTheme.textMuted;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: amtColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isIncome
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              color: amtColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.payee?.trim().isNotEmpty == true
                      ? txn.payee!
                      : 'Unknown',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(txn.formattedDate,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textMuted)),
                    if (txn.category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          txn.category!,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: catColor),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Amount
          Text(
            '${isIncome ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}',
            style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: amtColor),
          ),
        ],
      ),
    );
  }
}