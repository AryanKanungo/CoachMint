// lib/screens/goals/track_goals_screen.dart
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../common_widgets/widgets.dart' hide NumberFormat;
import '../../models/goal_model.dart';
import '../../services/goal_service.dart';
import '../../utils/colors.dart';

// ─────────────────────────────────────────────────────────────
// Screen-local GitHub-Dark palette
// ─────────────────────────────────────────────────────────────
const _bg      = Color(0xFF0D1117);
const _surface = Color(0xFF161B22);
const _border  = Color(0xFF30363D);
const _textPri = Color(0xFFE6EDF3);
const _textSec = Color(0xFF8B949E);
const _blue    = Color(0xFF58A6FF);
const _cyan    = Color(0xFF39D0D8);
const _green   = Color(0xFF3FB950);
const _amber   = Color(0xFFD29922);
const _red     = Color(0xFFF85149);

// ─────────────────────────────────────────────────────────────
// Emergency Fund constant
// ─────────────────────────────────────────────────────────────
const double _kEmergencyTarget = 50000.0;

// ─────────────────────────────────────────────────────────────
// Category icon + colour metadata
// ─────────────────────────────────────────────────────────────
const _kCategoryKeys = ['home', 'tech', 'travel', 'health', 'edu', 'other'];

const Map<String, Map<String, dynamic>> _kCatMeta = {
  'home':   {'icon': Icons.home_rounded,           'label': 'Home',   'color': _blue},
  'tech':   {'icon': Icons.laptop_mac_rounded,     'label': 'Tech',   'color': _cyan},
  'travel': {'icon': Icons.flight_takeoff_rounded, 'label': 'Travel', 'color': _amber},
  'health': {'icon': Icons.favorite_rounded,       'label': 'Health', 'color': _red},
  'edu':    {'icon': Icons.school_rounded,         'label': 'Edu',    'color': _green},
  'other':  {'icon': Icons.savings_rounded,        'label': 'Other',  'color': _textSec},
};

// ─────────────────────────────────────────────────────────────
// INR formatter helper
// ─────────────────────────────────────────────────────────────
final _inr = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
String _fmt(double v) => _inr.format(v);

// ═════════════════════════════════════════════════════════════
// TrackGoalsScreen
// ═════════════════════════════════════════════════════════════
class TrackGoalsScreen extends StatefulWidget {
  const TrackGoalsScreen({super.key});

  @override
  State<TrackGoalsScreen> createState() => _TrackGoalsScreenState();
}

class _TrackGoalsScreenState extends State<TrackGoalsScreen>
    with SingleTickerProviderStateMixin {
  final _svc = GoalService.instance;

  List<GoalModel> _goals   = [];
  bool            _loading = true;
  String?         _err;

  late AnimationController _fabCtrl;

  // ── Derived ────────────────────────────────────────────────

  /// Sum of saved_amount for goals flagged is_emergency_fund
  double get _efSaved =>
      _goals.where((g) => g.isEmergencyFund).fold(0.0, (s, g) => s + g.savedAmount);

  /// Custom goals sorted: overdue → soonest deadline → highest progress
  List<GoalModel> get _custom {
    final list = _goals.where((g) => !g.isEmergencyFund).toList();
    list.sort((a, b) {
      if (a.isOverdue && !b.isOverdue) return -1;
      if (!a.isOverdue && b.isOverdue) return 1;
      final ad = a.daysUntilDeadline ?? 99999;
      final bd = b.daysUntilDeadline ?? 99999;
      if (ad != bd) return ad.compareTo(bd);
      return b.progressPercent.compareTo(a.progressPercent);
    });
    return list;
  }

  // ── Lifecycle ──────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _load();
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
  }

  // ── Data ───────────────────────────────────────────────────
  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final data = await _svc.fetchGoals();
      if (mounted) {
        setState(() { _goals = data; _loading = false; });
        _fabCtrl.forward();
      }
    } catch (e) {
      if (mounted) setState(() { _err = "Couldn't load goals. Pull to refresh."; _loading = false; });
    }
  }

  // ── Actions ────────────────────────────────────────────────
  void _openSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddGoalSheet(
        onSave: (g) async { await _svc.addGoal(g); await _load(); },
      ),
    );
  }

  void _confirmDelete(GoalModel g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: _border)),
        title: Text('Delete goal?',
            style: GoogleFonts.dmSans(color: _textPri, fontWeight: FontWeight.w700)),
        content: Text('Remove "${g.title}" permanently?',
            style: GoogleFonts.dmSans(color: _textSec, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: GoogleFonts.dmSans(color: _textSec))),
          TextButton(
              onPressed: () async {
                Navigator.pop(context);
                if (g.id != null) { await _svc.deleteGoal(g.id!); _load(); }
              },
              child: Text('Delete',
                  style: GoogleFonts.dmSans(color: _red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _appBar(),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 2),
      floatingActionButton: ScaleTransition(
        scale: CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut),
        child: FloatingActionButton(
          onPressed: _openSheet,
          backgroundColor: _blue,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          tooltip: 'Add goal',
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      body: _loading
          ? const _Loader()
          : _err != null
              ? _ErrView(msg: _err!, onRetry: _load)
              : RefreshIndicator(
                  color: _cyan,
                  backgroundColor: _surface,
                  onRefresh: _load,
                  child: _body(),
                ),
    );
  }

  PreferredSizeWidget _appBar() => AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Track Goals',
                style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
            Text('${_custom.length} active goal${_custom.length == 1 ? '' : 's'}',
                style: GoogleFonts.dmSans(fontSize: 11, color: _textSec)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: _textSec, size: 20),
            onPressed: _load,
          ),
        ],
      );

  Widget _body() {
    final customs = _custom;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
      slivers: [
        // Emergency Fund card
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          sliver: SliverToBoxAdapter(child: _EmergencyFundCard(saved: _efSaved)),
        ),

        // Section header
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
          sliver: SliverToBoxAdapter(
            child: Row(children: [
              Text('MY GOALS',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, fontWeight: FontWeight.w700,
                      color: _textSec, letterSpacing: 1.6)),
              const Spacer(),
              if (customs.isNotEmpty)
                Text('${customs.length} total',
                    style: GoogleFonts.dmSans(fontSize: 11, color: _textSec)),
            ]),
          ),
        ),

        // Goals list or empty state
        customs.isEmpty
            ? SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onAdd: _openSheet))
            : SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _GoalCard(
                          goal: customs[i],
                          onDelete: () => _confirmDelete(customs[i])),
                    ),
                    childCount: customs.length,
                  ),
                ),
              ),

        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _EmergencyFundCard
// ═════════════════════════════════════════════════════════════
class _EmergencyFundCard extends StatelessWidget {
  final double saved;
  const _EmergencyFundCard({required this.saved});

  @override
  Widget build(BuildContext context) {
    final progress  = (saved / _kEmergencyTarget).clamp(0.0, 1.0);
    final done      = saved >= _kEmergencyTarget;
    final pct       = (progress * 100).toStringAsFixed(0);
    final remaining = (_kEmergencyTarget - saved).clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cyan.withOpacity(0.35)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_cyan.withOpacity(0.07), _surface],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cyan.withOpacity(0.3)),
                ),
                child: const Icon(Icons.shield_rounded, color: _cyan, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Starter Emergency Fund',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w700, color: _textPri)),
                    const SizedBox(height: 3),
                    Text('Your first 30 days of safety.',
                        style: GoogleFonts.dmSans(fontSize: 12, color: _textSec)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: done ? _green.withOpacity(0.14) : _cyan.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: done ? _green.withOpacity(0.4) : _cyan.withOpacity(0.35)),
                ),
                child: Text(
                  done ? '✅ DONE' : '$pct%',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, fontWeight: FontWeight.w800,
                      color: done ? _green : _cyan, letterSpacing: 0.4),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(done ? _green : _cyan),
              minHeight: 7,
            ),
          ),

          const SizedBox(height: 14),

          // Stats
          Row(
            children: [
              _Stat(label: 'SAVED',  value: _fmt(saved),              color: done ? _green : _cyan),
              const SizedBox(width: 24),
              _Stat(label: 'TARGET', value: _fmt(_kEmergencyTarget),  color: _textSec),
              if (!done) ...[
                const Spacer(),
                Text('${_fmt(remaining)} to go',
                    style: GoogleFonts.dmSans(fontSize: 12, color: _textSec)),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _GoalCard
// ═════════════════════════════════════════════════════════════
class _GoalCard extends StatelessWidget {
  final GoalModel  goal;
  final VoidCallback onDelete;
  const _GoalCard({required this.goal, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final meta  = _kCatMeta[goal.category ?? 'other'] ?? _kCatMeta['other']!;
    final icon  = meta['icon']  as IconData;
    final color = meta['color'] as Color;

    final complete  = goal.isComplete;
    final overdue   = goal.isOverdue;
    final daysLeft  = goal.daysUntilDeadline;
    final fillColor = complete ? _green : overdue ? _red : color;
    final bdrColor  = overdue ? _red.withOpacity(0.45)
                              : complete ? _green.withOpacity(0.35)
                              : _border;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bdrColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: color.withOpacity(0.28)),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(goal.title,
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w700, color: _textPri),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (goal.deadline != null) ...[
                      const SizedBox(height: 4),
                      _DeadlinePill(
                          daysLeft: daysLeft, overdue: overdue,
                          complete: complete, deadline: goal.deadline!),
                    ],
                  ],
                ),
              ),
              GestureDetector(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close_rounded,
                      size: 16, color: _textSec.withOpacity(0.45)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Saved / Target
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SAVED',
                      style: GoogleFonts.dmSans(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: _textSec, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text(_fmt(goal.savedAmount),
                      style: GoogleFonts.dmSans(
                          fontSize: 20, fontWeight: FontWeight.w700,
                          color: complete ? _green : _textPri, letterSpacing: -0.6)),
                ],
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('TARGET',
                      style: GoogleFonts.dmSans(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: _textSec, letterSpacing: 1.2)),
                  const SizedBox(height: 2),
                  Text(_fmt(goal.targetAmount),
                      style: GoogleFonts.dmSans(
                          fontSize: 15, fontWeight: FontWeight.w600, color: _textSec)),
                ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Progress bar
          Stack(
            children: [
              Container(
                  height: 5,
                  decoration: BoxDecoration(
                      color: _border, borderRadius: BorderRadius.circular(3))),
              FractionallySizedBox(
                widthFactor: goal.progressPercent,
                child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                        color: fillColor, borderRadius: BorderRadius.circular(3))),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Footer label
          Row(
            children: [
              Text('${(goal.progressPercent * 100).toInt()}% funded',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _textSec)),
              const Spacer(),
              if (complete)
                Text('🎉 Goal reached!',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: _green, fontWeight: FontWeight.w700))
              else
                Text('${_fmt(goal.remaining)} remaining',
                    style: GoogleFonts.dmSans(fontSize: 11, color: _textSec)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _DeadlinePill
// ─────────────────────────────────────────────────────────────
class _DeadlinePill extends StatelessWidget {
  final int?     daysLeft;
  final bool     overdue;
  final bool     complete;
  final DateTime deadline;
  const _DeadlinePill({
    required this.daysLeft, required this.overdue,
    required this.complete, required this.deadline,
  });

  @override
  Widget build(BuildContext context) {
    if (complete) return const SizedBox.shrink();
    final Color  color;
    final String label;
    if (overdue) {
      color = _red;  label = '⚠ Overdue';
    } else if (daysLeft != null && daysLeft! <= 7) {
      color = _amber; label = '$daysLeft day${daysLeft == 1 ? '' : 's'} left';
    } else {
      color = _textSec; label = DateFormat('d MMM y').format(deadline);
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.calendar_today_rounded, size: 10, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 11, color: color,
                fontWeight: (overdue || (daysLeft != null && daysLeft! <= 7))
                    ? FontWeight.w600 : FontWeight.w400)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// _Stat — label / value used in EF card
// ─────────────────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String label, value;
  final Color  color;
  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 9, fontWeight: FontWeight.w700,
                  color: _textSec, letterSpacing: 1.2)),
          const SizedBox(height: 2),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 17, fontWeight: FontWeight.w700,
                  color: color, letterSpacing: -0.3)),
        ],
      );
}

// ═════════════════════════════════════════════════════════════
// _AddGoalSheet
// ═════════════════════════════════════════════════════════════
class _AddGoalSheet extends StatefulWidget {
  final Future<void> Function(GoalModel) onSave;
  const _AddGoalSheet({required this.onSave});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl  = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _savedCtrl  = TextEditingController();

  String    _cat      = 'other';
  DateTime? _deadline;
  bool      _saving   = false;
  String?   _err;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _savedCtrl.dispose();
    super.dispose();
  }

  double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '').replaceAll('₹', ''));

  bool _validate() {
    if (_titleCtrl.text.trim().isEmpty) {
      setState(() => _err = 'Please enter a goal title.'); return false;
    }
    final t = _parse(_targetCtrl.text);
    if (t == null || t <= 0) {
      setState(() => _err = 'Enter a valid target amount (e.g. 25000).'); return false;
    }
    final s = _parse(_savedCtrl.text);
    if (s == null) {
      setState(() => _err = 'Enter saved amount (use 0 if starting fresh).'); return false;
    }
    if (s > t) {
      setState(() => _err = "Saved amount can't exceed target."); return false;
    }
    setState(() => _err = null);
    return true;
  }

  Future<void> _submit() async {
    if (!_validate()) return;
    setState(() => _saving = true);
    try {
      await widget.onSave(GoalModel(
        userId: '',
        title: _titleCtrl.text.trim(),
        targetAmount: _parse(_targetCtrl.text)!,
        savedAmount: _parse(_savedCtrl.text) ?? 0.0,
        deadline: _deadline,
        category: _cat,
        isEmergencyFund: false,
      ));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() { _err = 'Failed to save: $e'; _saving = false; });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: DateTime(2040),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: _blue, surface: _surface, onSurface: _textPri),
          dialogBackgroundColor: _surface,
        ),
        child: child!,
      ),
    );
    if (p != null) setState(() => _deadline = p);
  }

  @override
  Widget build(BuildContext context) {
    final kb = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + kb),
      decoration: const BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(
          top:   BorderSide(color: _border),
          left:  BorderSide(color: _border),
          right: BorderSide(color: _border),
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 36, height: 4,
                decoration: BoxDecoration(
                    color: _border, borderRadius: BorderRadius.circular(2)),
              ),
            ),

            Text('Plant a New Goal 🌱',
                style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
            const SizedBox(height: 4),
            Text('Small seeds grow into big wins.',
                style: GoogleFonts.dmSans(fontSize: 13, color: _textSec)),
            const SizedBox(height: 20),

            _Label('GOAL TITLE'),
            const SizedBox(height: 6),
            _Field(ctrl: _titleCtrl, hint: 'e.g. New Laptop, Europe Trip…'),
            const SizedBox(height: 16),

            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Label('TARGET (₹)'),
                  const SizedBox(height: 6),
                  _Field(
                    ctrl: _targetCtrl, hint: '50000',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  ),
                ]),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _Label('ALREADY SAVED (₹)'),
                  const SizedBox(height: 6),
                  _Field(
                    ctrl: _savedCtrl, hint: '0',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    formatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))],
                  ),
                ]),
              ),
            ]),
            const SizedBox(height: 16),

            _Label('CATEGORY'),
            const SizedBox(height: 8),
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _kCategoryKeys.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final key   = _kCategoryKeys[i];
                  final meta  = _kCatMeta[key]!;
                  final sel   = key == _cat;
                  final color = meta['color'] as Color;
                  return GestureDetector(
                    onTap: () => setState(() => _cat = key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: sel ? color.withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? color.withOpacity(0.55) : _border),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(meta['icon'] as IconData,
                            size: 13, color: sel ? color : _textSec),
                        const SizedBox(width: 5),
                        Text(meta['label'] as String,
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: sel ? color : _textSec,
                                fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                      ]),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),

            _Label('DEADLINE (OPTIONAL)'),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                    color: _bg, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _border)),
                child: Row(children: [
                  const Icon(Icons.calendar_month_rounded, size: 16, color: _textSec),
                  const SizedBox(width: 10),
                  Text(
                    _deadline != null
                        ? DateFormat('d MMMM y').format(_deadline!)
                        : 'Pick a date',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        color: _deadline != null ? _textPri : _textSec),
                  ),
                  const Spacer(),
                  if (_deadline != null)
                    GestureDetector(
                      onTap: () => setState(() => _deadline = null),
                      child: const Icon(Icons.close_rounded, size: 16, color: _textSec),
                    ),
                ]),
              ),
            ),

            if (_err != null) ...[
              const SizedBox(height: 10),
              Row(children: [
                const Icon(Icons.error_outline_rounded, size: 14, color: _red),
                const SizedBox(width: 6),
                Expanded(child: Text(_err!,
                    style: GoogleFonts.dmSans(fontSize: 12, color: _red))),
              ]),
            ],

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: _border,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black))
                    : Text('Save Goal',
                        style: GoogleFonts.dmSans(
                            fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Form helpers
// ─────────────────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: GoogleFonts.dmSans(
          fontSize: 9, fontWeight: FontWeight.w700,
          color: _textSec, letterSpacing: 1.4));
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? formatters;
  const _Field({
    required this.ctrl, required this.hint,
    this.keyboardType = TextInputType.text, this.formatters,
  });

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: GoogleFonts.dmSans(fontSize: 14, color: _textPri),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(fontSize: 14, color: _textSec),
          filled: true, fillColor: _bg, isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _border)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _blue, width: 1.5)),
        ),
      );
}

// ═════════════════════════════════════════════════════════════
// _EmptyState
// ═════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: _surface, shape: BoxShape.circle,
                  border: Border.all(color: _border)),
              child: const Text('🌱', style: TextStyle(fontSize: 42)),
            ),
            const SizedBox(height: 20),
            Text('Plant your first seed',
                style: GoogleFonts.dmSans(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
            const SizedBox(height: 8),
            Text('Goals give your savings direction.\nTap + to set your first target.',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: _textSec, height: 1.6),
                textAlign: TextAlign.center),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: onAdd,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _blue.withOpacity(0.35)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.add_rounded, color: _blue, size: 17),
                  const SizedBox(width: 7),
                  Text('Add your first goal',
                      style: GoogleFonts.dmSans(
                          fontSize: 13, fontWeight: FontWeight.w700, color: _blue)),
                ]),
              ),
            ),
          ],
        ),
      );
}

// ═════════════════════════════════════════════════════════════
// _Loader / _ErrView
// ═════════════════════════════════════════════════════════════
class _Loader extends StatelessWidget {
  const _Loader();
  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator(color: _cyan, strokeWidth: 2.5));
}

class _ErrView extends StatelessWidget {
  final String msg;
  final VoidCallback onRetry;
  const _ErrView({required this.msg, required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wifi_off_rounded, color: _red, size: 40),
              const SizedBox(height: 16),
              Text(msg,
                  style: GoogleFonts.dmSans(fontSize: 14, color: _textSec),
                  textAlign: TextAlign.center),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                      border: Border.all(color: _border),
                      borderRadius: BorderRadius.circular(8)),
                  child: Text('Retry',
                      style: GoogleFonts.dmSans(fontSize: 13, color: _textPri)),
                ),
              ),
            ],
          ),
        ),
      );
}
