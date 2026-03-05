import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../models/transaction_model.dart';
import '../../shared/widgets/widgets.dart';
import 'sms_categorisation_controller.dart';

class SmsCategorisationScreen extends ConsumerWidget {
  const SmsCategorisationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(smsCategorisationProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Categorize Transactions'),
        actions: [
          if (state.transactions.isNotEmpty)
            TextButton(
              onPressed: () => context.push('/categorized-history'),
              child: const Text(
                'History',
                style: TextStyle(color: AppTheme.brand, fontSize: 13),
              ),
            ),
        ],
      ),
      body: !state.isLoaded
          ? const Center(
          child: CircularProgressIndicator(color: AppTheme.brand))
          : state.transactions.isEmpty
          ? _EmptyState(
          onViewHistory: () => context.push('/categorized-history'))
          : _CategorizeList(state: state, ref: ref),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onViewHistory;
  const _EmptyState({required this.onViewHistory});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.brand.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                size: 48,
                color: AppTheme.brand,
              ),
            ),
            const SizedBox(height: 20),
            Text('All caught up!',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'No transactions from the last 7 days need categorizing.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppTheme.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            CMButton(
              label: 'View History',
              onPressed: onViewHistory,
              outline: true,
              icon: Icons.history_rounded,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Main list with drag-drop ──────────────────────────────────────────────────

class _CategorizeList extends StatelessWidget {
  final SmsCategorisationState state;
  final WidgetRef ref;
  const _CategorizeList({required this.state, required this.ref});

  @override
  Widget build(BuildContext context) {
    final sorted       = state.transactions;
    final draggedIndex = state.draggingIndex;
    final total        = sorted.length + (draggedIndex != -1 ? 1 : 0);

    return Column(
      children: [
        // Instruction banner
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.brand.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.brand.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              const Icon(Icons.drag_indicator_rounded,
                  color: AppTheme.brand, size: 18),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Long-press a transaction and drag it onto a category',
                  style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                      height: 1.4),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sorted.length} left',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.brand),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            itemCount: total,
            itemBuilder: (context, index) {
              if (draggedIndex != -1 && index == draggedIndex + 1) {
                return _CategoryDropPanel(ref: ref);
              }
              final realIndex =
              (draggedIndex != -1 && index > draggedIndex)
                  ? index - 1
                  : index;
              if (realIndex < 0 || realIndex >= sorted.length) {
                return const SizedBox.shrink();
              }
              return _TransactionTile(
                txn:   sorted[realIndex],
                index: realIndex,
                ref:   ref,
              );
            },
          ),
        ),
      ],
    );
  }
}

// ── Draggable transaction tile ────────────────────────────────────────────────

class _TransactionTile extends StatelessWidget {
  final TransactionModel txn;
  final int index;
  final WidgetRef ref;
  const _TransactionTile(
      {required this.txn, required this.index, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isIncome = txn.direction == 'in';
    final amtColor = isIncome ? AppTheme.success : AppTheme.danger;
    final catLabel = txn.category ?? 'Uncategorized';

    return LongPressDraggable<TransactionModel>(
      data: txn,
      onDragStarted: () => Future.microtask(() => ref
          .read(smsCategorisationProvider.notifier)
          .startCategorizing(index)),
      onDragEnd: (_) => Future.microtask(
              () => ref.read(smsCategorisationProvider.notifier).stopCategorizing()),

      // Chip shown while dragging
      feedback: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.brand,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: AppTheme.brand.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4)),
            ],
          ),
          child: Text(
            '₹${txn.amount.toStringAsFixed(0)}  •  $catLabel',
            style: const TextStyle(
                color: AppTheme.surface,
                fontWeight: FontWeight.w800,
                fontSize: 14),
          ),
        ),
      ),

      // Ghost placeholder
      childWhenDragging: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 84,
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: AppTheme.border.withOpacity(0.5),
              style: BorderStyle.solid),
        ),
      ),

      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(
          children: [
            // Direction icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: amtColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isIncome
                    ? Icons.arrow_downward_rounded
                    : Icons.arrow_upward_rounded,
                color: amtColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

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
                        fontSize: 14,
                        color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 3),
                  Text(txn.formattedDate,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                  const SizedBox(height: 5),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      catLabel,
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.brand),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isIncome ? '+' : '-'}₹${txn.amount.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: amtColor),
                ),
                const SizedBox(height: 6),
                const Icon(Icons.drag_indicator_rounded,
                    size: 20, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category drop panel ───────────────────────────────────────────────────────

class _CategoryDropPanel extends StatelessWidget {
  final WidgetRef ref;
  const _CategoryDropPanel({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18, top: 8),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brand, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppTheme.brand.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.south_rounded,
                  size: 16, color: AppTheme.brand),
              const SizedBox(width: 6),
              Text(
                'Drop here to categorize',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700, color: AppTheme.brand),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 20,
            runSpacing: 20,
            children: kCategories.map((cat) {
              return _DropTarget(
                label: cat['label'] as String,
                icon:  cat['icon']  as IconData,
                color: cat['color'] as Color,
                ref:   ref,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Individual drop target ────────────────────────────────────────────────────

class _DropTarget extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final WidgetRef ref;
  const _DropTarget({
    required this.label,
    required this.icon,
    required this.color,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<TransactionModel>(
      builder: (context, candidateData, _) {
        final hover = candidateData.isNotEmpty;
        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: hover ? 1.15 : 1.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: hover
                      ? color.withOpacity(0.85)
                      : color.withOpacity(0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hover ? color : color.withOpacity(0.3),
                    width: hover ? 2 : 1,
                  ),
                  boxShadow: hover
                      ? [
                    BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 12)
                  ]
                      : null,
                ),
                child: Icon(icon,
                    color: hover ? Colors.white : color, size: 26),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: hover ? color : AppTheme.textSecondary),
              ),
            ],
          ),
        );
      },
      onAccept: (txn) {
        Future.microtask(() async {
          await ref
              .read(smsCategorisationProvider.notifier)
              .categorizeTransaction(txn, label);
          ref.read(smsCategorisationProvider.notifier).stopCategorizing();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: color, size: 16),
                  const SizedBox(width: 8),
                  Text('Categorized as $label',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600)),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.surfaceElevated,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        });
      },
    );
  }
}