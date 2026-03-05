import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/theme.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/repositories.dart';
import '../../../shared/widgets/widgets.dart' hide formatInr;

final goalsProvider = FutureProvider.autoDispose<List<GoalModel>>((ref) async {
  return ref.watch(goalRepoProvider).getGoals();
});

class GoalsScreen extends ConsumerWidget {
  const GoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(title: const Text('Goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context, ref),
        backgroundColor: AppTheme.brand,
        foregroundColor: AppTheme.surface,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Goal', style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: goalsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.brand)),
        error: (_, __) => const Center(child: Text('Error', style: TextStyle(color: AppTheme.textMuted))),
        data: (goals) {
          if (goals.isEmpty) {
            return EmptyState(
              icon: Icons.flag_outlined,
              title: 'No goals yet',
              subtitle: 'Set a micro-goal to save for something meaningful.',
              actionLabel: 'Add Goal',
              onAction: () => _showAddGoalSheet(context, ref),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ...goals.map((g) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _GoalCard(
                  goal: g,
                  onDelete: () async {
                    await ref.read(goalRepoProvider).deleteGoal(g.id);
                    ref.invalidate(goalsProvider);
                  },
                ),
              )),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceCard,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddGoalSheet(onSaved: () => ref.invalidate(goalsProvider)),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback onDelete;
  const _GoalCard({required this.goal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercent;
    final color = goal.isEmergencyFund ? AppTheme.brand : AppTheme.info;
    return CMCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: Icon(goal.isEmergencyFund ? Icons.health_and_safety_rounded : Icons.flag_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
              ),
              GestureDetector(
                onTap: onDelete,
                child: const Icon(Icons.delete_outline, size: 18, color: AppTheme.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${formatInr(goal.savedAmount)} / ${formatInr(goal.targetAmount)}',
                  style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
              Text('${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
            ],
          ),
          if (goal.dailyNeeded != null && goal.dailyNeeded! > 0) ...[
            const SizedBox(height: 8),
            Text('Save ${formatInr(goal.dailyNeeded!)} / day',
                style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
          ],
        ],
      ),
    );
  }
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  final VoidCallback onSaved;
  const _AddGoalSheet({required this.onSaved});
  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isEmergencyFund = false;
  bool _saving = false;

  @override
  void dispose() { _nameController.dispose(); _amountController.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_nameController.text.isEmpty || _amountController.text.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(goalRepoProvider).addGoal(
        name: _nameController.text,
        targetAmount: double.parse(_amountController.text),
        isEmergencyFund: _isEmergencyFund,
      );
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } finally { if (mounted) setState(() => _saving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, top: 20, left: 20, right: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Goal', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: AppTheme.textPrimary)),
          const SizedBox(height: 20),
          TextField(controller: _nameController, autofocus: true, decoration: const InputDecoration(labelText: 'Goal name')),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
            decoration: const InputDecoration(labelText: 'Target amount', prefixText: 'Rs '),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Switch(value: _isEmergencyFund, onChanged: (v) => setState(() => _isEmergencyFund = v), activeColor: AppTheme.brand),
              const SizedBox(width: 8),
              const Text('Emergency Fund', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(width: double.infinity, child: CMButton(label: 'Create Goal', onPressed: _save, loading: _saving)),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}