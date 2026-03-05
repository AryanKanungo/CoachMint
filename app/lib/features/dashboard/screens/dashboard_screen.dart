import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/sms/sms_service.dart';
import '../../../core/supabase/supabase_client.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/repositories.dart';
import '../../../shared/widgets/widgets.dart' hide formatInr;

// ── Providers ─────────────────────────────────────────────────────────────────

final latestSnapshotProvider =
FutureProvider.autoDispose<FinancialSnapshot?>((ref) async {
  return ref.read(snapshotRepoProvider).getLatest();
});

final recentTransactionsRawProvider =
FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await supabase
      .from('transactions')
      .select()
      .eq('user_id', currentUserId)
      .order('transaction_date', ascending: false)
      .limit(5);
  return List<Map<String, dynamic>>.from(data as List);
});

final weeklyBreakdownProvider =
FutureProvider.autoDispose<Map<String, double>>((ref) async {
  return ref.read(transactionRepoProvider).getWeeklyBreakdown();
});

// ── Screen ────────────────────────────────────────────────────────────────────

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startSmsListener());
  }

  Future<void> _startSmsListener() async {
    try {
      await SmsService().init();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final snapshotAsync  = ref.watch(latestSnapshotProvider);
    final breakdownAsync = ref.watch(weeklyBreakdownProvider);
    final recentAsync    = ref.watch(recentTransactionsRawProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: RefreshIndicator(
        color: AppTheme.brand,
        backgroundColor: AppTheme.surfaceCard,
        onRefresh: () async {
          ref.invalidate(latestSnapshotProvider);
          ref.invalidate(weeklyBreakdownProvider);
          ref.invalidate(recentTransactionsRawProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── App bar ──────────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              backgroundColor: AppTheme.surface,
              title: Row(children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text('₹',
                        style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.brand,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 10),
                const Text('CoachMint',
                    style: TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 20)),
              ]),
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_rounded, color: AppTheme.brand),
                  onPressed: () => _showAddSheet(context),
                ),
              ],
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Hero card ──────────────────────────────────────────────
                  snapshotAsync.when(
                    loading: () => const LoadingShimmer(height: 160),
                    error:   (_, __) => _NoDataCard(),
                    data:    (snap) => snap == null
                        ? _NoDataCard()
                        : _HeroCard(snapshot: snap),
                  ),
                  const SizedBox(height: 16),

                  // ── Quick stats ────────────────────────────────────────────
                  snapshotAsync.when(
                    loading: () => const LoadingShimmer(height: 80),
                    error:   (_, __) => const SizedBox.shrink(),
                    data:    (snap) => snap == null
                        ? const SizedBox.shrink()
                        : _QuickStatsRow(snapshot: snap),
                  ),
                  const SizedBox(height: 20),

                  // ── Weekly breakdown ───────────────────────────────────────
                  breakdownAsync.when(
                    loading: () => const LoadingShimmer(height: 120),
                    error:   (_, __) => const SizedBox.shrink(),
                    data:    (bd) => _SpendingBreakdown(breakdown: bd),
                  ),
                  const SizedBox(height: 20),

                  // ── Recent transactions ────────────────────────────────────
                  const Text('Recent Transactions',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary)),
                  const SizedBox(height: 12),
                  recentAsync.when(
                    loading: () => const LoadingShimmer(height: 200),
                    error:   (_, __) => const SizedBox.shrink(),
                    data:    (rows) => rows.isEmpty
                        ? const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No transactions yet',
                      subtitle: 'Your bank SMS will appear here.',
                    )
                        : _RecentTransactions(rows: rows),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddTransactionSheet(ref: ref),
    );
  }
}

// ── Hero card ─────────────────────────────────────────────────────────────────
// ✅ Fields used: safeToSpendPerDay, survivalDays, resilienceScore, resilienceLabel
// ❌ Removed: currentWallet (doesn't exist), savingsRate, protectionScore, dignityScore

class _HeroCard extends StatelessWidget {
  final FinancialSnapshot snapshot;
  const _HeroCard({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.brand.withValues(alpha: 0.15),
            AppTheme.brand.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.brand.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SPDDisplay(
              spd:          snapshot.safeToSpendPerDay,
              survivalDays: snapshot.survivalDays,
            ),
          ),
          const SizedBox(width: 12),
          ResilienceScoreBadge(
            score: snapshot.resilienceScore,
            label: snapshot.resilienceLabel,
          ),
        ],
      ),
    );
  }
}

// ── Quick stats row ───────────────────────────────────────────────────────────
// ✅ Fields used: walletBalance, upcomingBillsTotal, avgDailyExpense
// ❌ Removed: billsDueThisWeek (doesn't exist), dailyBudget (doesn't exist)

class _QuickStatsRow extends StatelessWidget {
  final FinancialSnapshot snapshot;
  const _QuickStatsRow({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _StatChip(
          label: 'Wallet',
          value: formatInr(snapshot.walletBalance),
          icon:  Icons.account_balance_wallet_rounded,
          color: AppTheme.brand,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatChip(
          label: 'Bills Due',
          value: formatInr(snapshot.upcomingBillsTotal),
          icon:  Icons.receipt_outlined,
          color: snapshot.upcomingBillsTotal > 0
              ? AppTheme.warning
              : AppTheme.success,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _StatChip(
          label: 'Daily Avg',
          value: formatInr(snapshot.avgDailyExpense),
          icon:  Icons.trending_down_rounded,
          color: AppTheme.info,
        ),
      ),
    ]);
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.textMuted)),
        ],
      ),
    );
  }
}

// ── Spending breakdown ────────────────────────────────────────────────────────

class _SpendingBreakdown extends StatelessWidget {
  final Map<String, double> breakdown;
  const _SpendingBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final needs   = breakdown['needs']   ?? 0;
    final wants   = breakdown['wants']   ?? 0;
    final savings = breakdown['savings'] ?? 0;
    final total   = needs + wants + savings;
    if (total == 0) return const SizedBox.shrink();

    return CMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('This Week',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          _Bar(label: 'Needs',   amount: needs,   total: total, color: AppTheme.warning),
          const SizedBox(height: 10),
          _Bar(label: 'Wants',   amount: wants,   total: total, color: AppTheme.danger),
          const SizedBox(height: 10),
          _Bar(label: 'Savings', amount: savings, total: total, color: AppTheme.brand),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final double amount, total;
  final Color color;
  const _Bar({
    required this.label,
    required this.amount,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (amount / total).clamp(0.0, 1.0) : 0.0;
    return Column(children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
          Text(formatInr(amount),
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
      const SizedBox(height: 5),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: pct,
          minHeight: 6,
          backgroundColor: AppTheme.border,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ),
    ]);
  }
}

// ── Recent transactions ───────────────────────────────────────────────────────

class _RecentTransactions extends StatelessWidget {
  final List<Map<String, dynamic>> rows;
  const _RecentTransactions({required this.rows});

  @override
  Widget build(BuildContext context) =>
      Column(children: rows.map((r) => _TxnRow(row: r)).toList());
}

class _TxnRow extends StatelessWidget {
  final Map<String, dynamic> row;
  const _TxnRow({required this.row});

  @override
  Widget build(BuildContext context) {
    final direction = (row['direction'] as String?) ?? 'out';
    final amount    = (row['amount']    as num?)?.toDouble() ?? 0.0;
    final payee     = (row['payee']     as String?)?.trim() ?? '';
    final category  = (row['category']  as String?) ?? '';
    final dateStr   = row['transaction_date'] as String?;

    final isIncome = direction == 'in';
    final amtColor = isIncome ? AppTheme.success : AppTheme.danger;
    final catColor = kCategoryColors[category] ?? AppTheme.textMuted;

    String dateLabel = '';
    if (dateStr != null) {
      try {
        final dt = DateTime.parse(dateStr);
        dateLabel = '${dt.day}/${dt.month}/${dt.year}';
      } catch (_) {}
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: amtColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isIncome
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: amtColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                payee.isNotEmpty ? payee : 'Unknown',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 3),
              Row(children: [
                if (dateLabel.isNotEmpty)
                  Text(dateLabel,
                      style: const TextStyle(
                          fontSize: 11, color: AppTheme.textMuted)),
                if (category.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(category,
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: catColor)),
                  ),
                ],
              ]),
            ],
          ),
        ),
        Text(
          '${isIncome ? '+' : '-'}${formatInr(amount)}',
          style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: amtColor),
        ),
      ]),
    );
  }
}

// ── No data card ──────────────────────────────────────────────────────────────

class _NoDataCard extends ConsumerWidget {
  _NoDataCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CMCard(
      child: Column(
        children: [
          const Icon(Icons.sms_outlined, size: 40, color: AppTheme.brand),
          const SizedBox(height: 14),
          Text('Import your bank SMS',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Scan the last 30 days of bank SMS to build your financial snapshot.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                height: 1.5),
          ),
          const SizedBox(height: 16),
          CMButton(
            label: 'Import Bank SMS',
            onPressed: () async {
              await SmsService().importExistingSms();
              ref.invalidate(latestSnapshotProvider);
              ref.invalidate(recentTransactionsRawProvider);
            },
            icon: Icons.download_rounded,
          ),
        ],
      ),
    );
  }
}

// ── Add transaction sheet ─────────────────────────────────────────────────────

class _AddTransactionSheet extends StatefulWidget {
  final WidgetRef ref;
  const _AddTransactionSheet({required this.ref});

  @override
  State<_AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<_AddTransactionSheet> {
  final _amtCtrl   = TextEditingController();
  final _payeeCtrl = TextEditingController();
  String _direction = 'out';
  String _category  = 'Essential';
  bool   _saving    = false;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _payeeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amt = double.tryParse(_amtCtrl.text);
    if (amt == null || amt <= 0) return;
    setState(() => _saving = true);
    try {
      await widget.ref.read(transactionRepoProvider).addManual(
        type:        _direction == 'out' ? 'debit' : 'credit',
        amount:      amt,
        categoryTop: _mapTop(_category),
        merchant:    _payeeCtrl.text.trim().isEmpty
            ? null
            : _payeeCtrl.text.trim(),
      );
      widget.ref.invalidate(recentTransactionsRawProvider);
      widget.ref.invalidate(weeklyBreakdownProvider);
      if (mounted) Navigator.pop(context);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _mapTop(String cat) {
    switch (cat) {
      case 'Essential':     return 'needs';
      case 'Non-Essential': return 'wants';
      case 'Savings':       return 'savings';
      case 'Investments':   return 'savings';
      default:              return 'wants';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          left: 20, right: 20, top: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Transaction',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 20),

          Row(children: [
            _toggle('Expense', _direction == 'out', AppTheme.danger,
                    () => setState(() => _direction = 'out')),
            const SizedBox(width: 10),
            _toggle('Income', _direction == 'in', AppTheme.success,
                    () => setState(() => _direction = 'in')),
          ]),
          const SizedBox(height: 14),

          TextField(
            controller: _amtCtrl,
            autofocus: true,
            keyboardType:
            const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                labelText: 'Amount', prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _payeeCtrl,
            decoration:
            const InputDecoration(labelText: 'Payee / Merchant'),
          ),
          const SizedBox(height: 12),

          // ✅ initialValue instead of value (value is deprecated in newer Flutter)
          DropdownButtonFormField<String>(
            initialValue: _category,
            dropdownColor: AppTheme.surfaceCard,
            decoration: const InputDecoration(labelText: 'Category'),
            items: kCategories
                .map((c) => DropdownMenuItem(
              value: c['label'] as String,
              child: Text(c['label'] as String),
            ))
                .toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: CMButton(
                label: 'Save', onPressed: _save, loading: _saving),
          ),
        ],
      ),
    );
  }

  Widget _toggle(
      String label, bool active, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active
                ? color.withValues(alpha: 0.15)
                : AppTheme.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border:
            Border.all(color: active ? color : AppTheme.border),
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: active ? color : AppTheme.textMuted)),
          ),
        ),
      ),
    );
  }
}