import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';

// ── Design tokens — mirrors AppColors exactly ─────────────────────────────────
const _bg            = Color(0xFF121212);
const _surface       = Color(0xFF1E1E1E);
const _surfaceEl     = Color(0xFF252525);
const _border        = Color(0xFF2A2A2A);
const _brand         = Color(0xFF2E8FCC);
const _success       = Color(0xFF2ECC71);
const _danger        = Color(0xFFE74C3C);
const _warning       = Color(0xFFF39C12);
const _textPrimary   = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFB0B0B0);
const _textMuted     = Color(0xFF9E9E9E);

/// screens/sms_categorisation/categorized_transactions_screen.dart
class CategorizedTransactionsScreen extends StatefulWidget {
  const CategorizedTransactionsScreen({super.key});

  @override
  State<CategorizedTransactionsScreen> createState() =>
      _CategorizedTransactionsScreenState();
}

class _CategorizedTransactionsScreenState
    extends State<CategorizedTransactionsScreen>
    with SingleTickerProviderStateMixin {
  final _ctrl = Get.find<TransactionController>();
  late final TabController _tabCtrl;

  static const _tabs = [
    _TabMeta(
      label: 'Essential',
      category: 'essential',
      icon: Icons.shield_outlined,
      color: _success,
      emptyLabel: 'No essential expenses yet',
    ),
    _TabMeta(
      label: 'Lifestyle',
      category: 'non_essential',
      icon: Icons.local_fire_department_outlined,
      color: _danger,
      emptyLabel: 'No lifestyle expenses yet',
    ),
    _TabMeta(
      label: 'Savings',
      category: 'savings_investments',
      icon: Icons.trending_up_rounded,
      color: _brand,
      emptyLabel: 'No savings yet',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _ctrl.loadCategorized();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        iconTheme: const IconThemeData(color: _textSecondary),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 20,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: _brand,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              'Records',
              style: GoogleFonts.dmSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(49),
          child: Column(
            children: [
              Container(height: 1, color: _border),
              TabBar(
                controller: _tabCtrl,
                indicatorColor: Colors.transparent,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: _tabs.map((t) => _TabChip(meta: t, ctrl: _tabCtrl, index: _tabs.indexOf(t))).toList(),
              ),
            ],
          ),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value) return const _SkeletonLoader();

        if (_ctrl.errorMsg.value.isNotEmpty) {
          return _ErrorView(ctrl: _ctrl);
        }

        return TabBarView(
          controller: _tabCtrl,
          children: _tabs.map((meta) {
            final txns = _ctrl.categorized
                .where((t) => t.category == meta.category)
                .toList();
            return _TxnList(txns: txns, meta: meta);
          }).toList(),
        );
      }),
    );
  }
}

// ─── Tab chip ─────────────────────────────────────────────────────────────────

class _TabMeta {
  final String label;
  final String category;
  final IconData icon;
  final Color color;
  final String emptyLabel;
  const _TabMeta({
    required this.label,
    required this.category,
    required this.icon,
    required this.color,
    required this.emptyLabel,
  });
}

class _TabChip extends StatefulWidget {
  final _TabMeta meta;
  final TabController ctrl;
  final int index;
  const _TabChip({required this.meta, required this.ctrl, required this.index});

  @override
  State<_TabChip> createState() => _TabChipState();
}

class _TabChipState extends State<_TabChip> {
  @override
  void initState() {
    super.initState();
    widget.ctrl.addListener(_onTabChange);
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onTabChange);
    super.dispose();
  }

  void _onTabChange() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final active = widget.ctrl.index == widget.index;
    return Tab(
      height: 34,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active
              ? widget.meta.color.withOpacity(0.15)
              : _surfaceEl,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? widget.meta.color.withOpacity(0.5)
                : _border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.meta.icon,
              size: 13,
              color: active ? widget.meta.color : _textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              widget.meta.label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? widget.meta.color : _textMuted,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Transaction list per tab ─────────────────────────────────────────────────

class _TxnList extends StatelessWidget {
  final List<TransactionModel> txns;
  final _TabMeta meta;

  const _TxnList({required this.txns, required this.meta});

  double get _total => txns.fold(0.0, (s, t) => s + t.amount);

  @override
  Widget build(BuildContext context) {
    if (txns.isEmpty) {
      return _EmptyTab(meta: meta);
    }

    return Column(
      children: [
        // Summary bar
        Container(
          color: _surface,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(
            children: [
              // Count pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: meta.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: meta.color.withOpacity(0.2)),
                ),
                child: Text(
                  '${txns.length} txn${txns.length == 1 ? '' : 's'}',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: meta.color,
                  ),
                ),
              ),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${_formatAmt(_total)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: meta.color,
                      letterSpacing: -0.6,
                    ),
                  ),
                  Text(
                    'total spent',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: _textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(height: 1, color: _border),

        // List
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: txns.length,
            itemBuilder: (_, i) => _TxnTile(
              txn: txns[i],
              accentColor: meta.color,
            ),
          ),
        ),
      ],
    );
  }

  String _formatAmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────

class _TxnTile extends StatelessWidget {
  final TransactionModel txn;
  final Color accentColor;
  const _TxnTile({required this.txn, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    final isDebit     = txn.direction == 'debit';
    final amtColor    = isDebit ? _danger : _success;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 3,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 13),
                child: Row(
                  children: [
                    // Icon badge
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: amtColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isDebit
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 17,
                        color: amtColor,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Payee + date
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            txn.payee,
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: _textPrimary,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            txn.formattedDate,
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: _textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Amount
                    Text(
                      '${isDebit ? '−' : '+'}₹${_formatAmt(txn.amount)}',
                      style: GoogleFonts.dmSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: amtColor,
                        letterSpacing: -0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatAmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Empty tab state ──────────────────────────────────────────────────────────

class _EmptyTab extends StatelessWidget {
  final _TabMeta meta;
  const _EmptyTab({required this.meta});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: meta.color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: meta.color.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(meta.icon, size: 26, color: meta.color),
          ),
          const SizedBox(height: 16),
          Text(
            meta.emptyLabel,
            style: GoogleFonts.dmSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Drag expenses into this bucket\nfrom the Sort screen.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: _textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton loader ──────────────────────────────────────────────────────────

class _SkeletonLoader extends StatefulWidget {
  const _SkeletonLoader();

  @override
  State<_SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<_SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacity,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              // Summary bar placeholder
              Container(
                height: 58,
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _border),
                ),
                margin: const EdgeInsets.only(bottom: 16),
              ),
              ...List.generate(
                6,
                    (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _skeletonCard(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 3,
            decoration: const BoxDecoration(
              color: _border,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _surfaceEl,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _pill(100, 10),
                const SizedBox(height: 7),
                _pill(68, 8),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: _pill(52, 14),
          ),
        ],
      ),
    );
  }

  Widget _pill(double width, double height) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: _surfaceEl,
      borderRadius: BorderRadius.circular(6),
    ),
  );
}

// ─── Error view ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final TransactionController ctrl;
  const _ErrorView({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: _danger.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 30, color: _danger),
            ),
            const SizedBox(height: 18),
            Text(
              'Could not load records',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Obx(() => Text(
              ctrl.errorMsg.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: _textMuted,
                height: 1.5,
              ),
            )),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: ctrl.loadCategorized,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Try again',
                  style: GoogleFonts.dmSans(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}