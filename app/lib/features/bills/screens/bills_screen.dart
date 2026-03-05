import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/repositories.dart';
import '../../../shared/widgets/widgets.dart' hide formatInr;

final billsProvider = FutureProvider.autoDispose<List<BillModel>>((ref) async {
  return ref.watch(billRepoProvider).getBills();
});

class BillsScreen extends ConsumerWidget {
  const BillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billsProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Bill Guard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBillSheet(context, ref),
        backgroundColor: AppTheme.brand,
        foregroundColor: AppTheme.surface,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Bill', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: billsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.brand)),
        error: (_, __) => const Center(
            child: Text('Error loading bills',
                style: TextStyle(color: AppTheme.textMuted))),
        data: (bills) {
          if (bills.isEmpty) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No bills tracked',
              subtitle:
              'Add your recurring bills so CoachMint can protect them.',
              actionLabel: 'Add Bill',
              onAction: () => _showAddBillSheet(context, ref),
            );
          }

          // Separate by guard status
          final atRisk = bills.where((b) => b.guardStatus == 'at_risk').toList();
          final covered = bills.where((b) => b.guardStatus != 'at_risk').toList();

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (atRisk.isNotEmpty) ...[
                _SectionHeader(
                  title: '⚠️ At Risk',
                  subtitle: '${atRisk.length} bill(s) may not be covered',
                  color: AppTheme.danger,
                ),
                const SizedBox(height: 10),
                ...atRisk.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BillCard(
                    bill: b,
                    onMarkPaid: () async {
                      await ref.read(billRepoProvider).markPaid(b.id);
                      ref.invalidate(billsProvider);
                    },
                    onDelete: () async {
                      await ref.read(billRepoProvider).deleteBill(b.id);
                      ref.invalidate(billsProvider);
                    },
                  ),
                )),
                const SizedBox(height: 16),
              ],
              if (covered.isNotEmpty) ...[
                _SectionHeader(
                  title: '✅ Covered',
                  subtitle: '${covered.length} bill(s) protected',
                  color: AppTheme.success,
                ),
                const SizedBox(height: 10),
                ...covered.map((b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _BillCard(
                    bill: b,
                    onMarkPaid: () async {
                      await ref.read(billRepoProvider).markPaid(b.id);
                      ref.invalidate(billsProvider);
                    },
                    onDelete: () async {
                      await ref.read(billRepoProvider).deleteBill(b.id);
                      ref.invalidate(billsProvider);
                    },
                  ),
                )),
              ],
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  void _showAddBillSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddBillSheet(
        onSaved: () => ref.invalidate(billsProvider),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: color)),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      ],
    );
  }
}

class _BillCard extends StatelessWidget {
  final BillModel bill;
  final VoidCallback onMarkPaid;
  final VoidCallback onDelete;

  const _BillCard({
    required this.bill,
    required this.onMarkPaid,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAtRisk = bill.guardStatus == 'at_risk';
    final statusColor = isAtRisk ? AppTheme.danger : AppTheme.success;
    final daysLeft = bill.daysUntilDue;

    return CMCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isAtRisk
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline_rounded,
              color: statusColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(bill.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                        color: AppTheme.textPrimary)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      'Due ${DateFormat('d MMM').format(bill.dueDate)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: daysLeft <= 3
                            ? AppTheme.danger.withOpacity(0.1)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        daysLeft == 0
                            ? 'Today'
                            : daysLeft < 0
                            ? 'Overdue'
                            : '$daysLeft days',
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: daysLeft <= 3
                                ? AppTheme.danger
                                : AppTheme.textMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatInr(bill.amount),
                style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  GestureDetector(
                    onTap: onMarkPaid,
                    child: const Text('Mark paid',
                        style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.brand,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onDelete,
                    child: const Icon(Icons.delete_outline,
                        size: 16, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddBillSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddBillSheet({required this.onSaved});

  @override
  ConsumerState<_AddBillSheet> createState() => _AddBillSheetState();
}

class _AddBillSheetState extends ConsumerState<_AddBillSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _dateController = TextEditingController();
  DateTime? _dueDate;
  bool _isRecurring = false;
  String _recurrencePeriod = 'monthly';
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _dueDate == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(billRepoProvider).addBill(
        name: _nameController.text,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate!,
        isRecurring: _isRecurring,
        recurrencePeriod: _isRecurring ? _recurrencePeriod : null,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Add Bill',
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration:
            const InputDecoration(labelText: 'Bill name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: const InputDecoration(
                labelText: 'Amount', prefixText: '₹ '),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                        primary: AppTheme.brand,
                        surface: AppTheme.surfaceCard),
                  ),
                  child: child!,
                ),
              );
              if (d != null) {
                setState(() {
                  _dueDate = d;
                  _dateController.text =
                      DateFormat('d MMM yyyy').format(d);
                });
              }
            },
            child: AbsorbPointer(
              child: TextField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: 'Due date',
                  suffixIcon: Icon(Icons.calendar_today_rounded,
                      color: AppTheme.brand),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(
                value: _isRecurring,
                onChanged: (v) => setState(() => _isRecurring = v),
                activeColor: AppTheme.brand,
              ),
              const SizedBox(width: 8),
              const Text('Recurring bill',
                  style: TextStyle(color: AppTheme.textSecondary)),
              if (_isRecurring) ...[
                const Spacer(),
                DropdownButton<String>(
                  value: _recurrencePeriod,
                  dropdownColor: AppTheme.surfaceElevated,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(
                        value: 'monthly', child: Text('Monthly')),
                    DropdownMenuItem(
                        value: 'quarterly', child: Text('Quarterly')),
                    DropdownMenuItem(
                        value: 'annual', child: Text('Annual')),
                  ],
                  onChanged: (v) =>
                      setState(() => _recurrencePeriod = v!),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: CMButton(
                label: 'Add Bill', onPressed: _save, loading: _saving),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}