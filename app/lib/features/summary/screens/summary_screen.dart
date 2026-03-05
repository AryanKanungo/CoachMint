import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/repositories.dart';
import '../../../shared/widgets/widgets.dart' hide formatInr;


final summariesProvider =
FutureProvider.autoDispose<List<WeeklySummary>>((ref) async {
  return ref.watch(summaryRepoProvider).getSummaries();
});

class SummaryScreen extends ConsumerWidget {
  const SummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summariesAsync = ref.watch(summariesProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Weekly Summary')),
      body: summariesAsync.when(
        loading: () =>
        const Center(child: CircularProgressIndicator(color: AppTheme.brand)),
        error: (_, __) => const Center(
            child: Text('Error', style: TextStyle(color: AppTheme.textMuted))),
        data: (summaries) {
          if (summaries.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_view_week_outlined,
              title: 'No summaries yet',
              subtitle:
              'Your first weekly summary will arrive on Sunday evening. CoachMint generates one every week.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: summaries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) => _SummaryCard(summary: summaries[i]),
          );
        },
      ),
    );
  }
}

class _SummaryCard extends StatefulWidget {
  final WeeklySummary summary;
  const _SummaryCard({required this.summary});

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final metrics = widget.summary.keyMetrics;
    final dateRange =
        '${DateFormat('d MMM').format(widget.summary.weekStart)} – ${DateFormat('d MMM').format(widget.summary.weekEnd)}';

    final rsStart = metrics['rs_start'] as int?;
    final rsEnd = metrics['rs_end'] as int?;
    final incomeTotal = (metrics['income_total'] as num?)?.toDouble();
    final spendTotal = (metrics['spend_total'] as num?)?.toDouble();

    return CMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.auto_awesome_rounded,
                      color: AppTheme.brand, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Weekly Review',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppTheme.textPrimary)),
                      Text(dateRange,
                          style: const TextStyle(
                              fontSize: 12, color: AppTheme.textMuted)),
                    ],
                  ),
                ),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),

          if (_expanded) ...[
            const SizedBox(height: 14),

            // Key metrics chips
            if (rsStart != null && rsEnd != null)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (incomeTotal != null)
                    _MetricChip(
                        label: 'Income',
                        value: formatInr(incomeTotal),
                        color: AppTheme.success),
                  if (spendTotal != null)
                    _MetricChip(
                        label: 'Spent',
                        value: formatInr(spendTotal),
                        color: AppTheme.warning),
                  _MetricChip(
                      label: 'Score start',
                      value: '$rsStart',
                      color: resilienceColor(rsStart)),
                  _MetricChip(
                      label: 'Score end',
                      value: '$rsEnd',
                      color: resilienceColor(rsEnd)),
                ],
              ),

            const SizedBox(height: 14),
            const Divider(color: AppTheme.border),
            const SizedBox(height: 14),

            // AI summary paragraph
            Text(
              widget.summary.summaryText,
              style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.6),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MetricChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label,
              style:
              const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}