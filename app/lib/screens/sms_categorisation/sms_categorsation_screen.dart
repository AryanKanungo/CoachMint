import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../utils/routes.dart';

// ── Design tokens — mirrors AppColors exactly ─────────────────────────────────
const _bg            = Color(0xFF121212);
const _surface       = Color(0xFF1E1E1E);
const _surfaceEl     = Color(0xFF252525);
const _surfaceHigh   = Color(0xFF2C2C2C);
const _border        = Color(0xFF2A2A2A);
const _brand         = Color(0xFF2E8FCC);
const _success       = Color(0xFF2ECC71);
const _danger        = Color(0xFFE74C3C);
const _textPrimary   = Color(0xFFFFFFFF);
const _textSecondary = Color(0xFFB0B0B0);
const _textMuted     = Color(0xFF9E9E9E);

// File-level RegExp — never recreated on rebuild
final _vpaDisplayRe = RegExp(r'[\w.\-]+@\w+', caseSensitive: false);

/// screens/sms_categorisation/sms_categorsation_screen.dart
class SmsCategorizationScreen extends StatefulWidget {
  const SmsCategorizationScreen({super.key});

  @override
  State<SmsCategorizationScreen> createState() =>
      _SmsCategorizationScreenState();
}

class _SmsCategorizationScreenState extends State<SmsCategorizationScreen> {
  late final TransactionController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = Get.find<TransactionController>();
    _ctrl.loadSmsTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _buildAppBar(context),
      body: Obx(() {
        if (_ctrl.isLoading.value) return const _SkeletonLoader();
        if (_ctrl.errorMsg.value.isNotEmpty) return _ErrorState(ctrl: _ctrl);
        if (_ctrl.uncategorized.isEmpty)     return _EmptyState(ctrl: _ctrl);
        return _Body(ctrl: _ctrl);
      }),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: _surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _border),
      ),
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
            'Sort',
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 8),
          Obx(() {
            final count = _ctrl.uncategorized
                .where((t) => t.direction == 'debit')
                .length;
            if (count == 0) return const SizedBox.shrink();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: _danger.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _danger.withOpacity(0.3)),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: _danger,
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.push(AppRoutes.categorizedTxns),
          style: TextButton.styleFrom(
            foregroundColor: _brand,
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
          child: Text(
            'Records',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _brand,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: IconButton(
            onPressed: () => context.go(AppRoutes.dashboard),
            icon: const Icon(Icons.home_outlined,
                color: _textSecondary, size: 22),
            tooltip: 'Dashboard',
          ),
        ),
      ],
    );
  }
}

// ─── Body ─────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final TransactionController ctrl;
  const _Body({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Stats strip
        Obx(() {
          final debits  = ctrl.uncategorized.where((t) => t.direction == 'debit').toList();
          final credits = ctrl.uncategorized.where((t) => t.direction == 'credit').toList();
          final total   = debits.fold(0.0, (s, t) => s + t.amount);

          return Container(
            color: _surface,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                _StatChip(
                  label: '${debits.length} to sort',
                  color: _danger,
                  icon: Icons.arrow_upward_rounded,
                ),
                if (credits.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _StatChip(
                    label: '${credits.length} income',
                    color: _success,
                    icon: Icons.lock_outline_rounded,
                  ),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${_formatAmt(total)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _danger,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'unsorted',
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
          );
        }),

        Container(height: 1, color: _border),

        // Hint bar
        Container(
          color: _surfaceEl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          child: Row(
            children: [
              Icon(Icons.swipe_rounded, size: 13,
                  color: _brand.withOpacity(0.6)),
              const SizedBox(width: 6),
              Text(
                'Drag expenses into a bucket below',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: _textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        Container(height: 1, color: _border),

        // Transaction list
        Expanded(
          child: Obx(
                () => ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              itemCount: ctrl.uncategorized.length,
              itemBuilder: (_, i) =>
                  _TxnTile(txn: ctrl.uncategorized[i]),
            ),
          ),
        ),

        // Drop zone
        Container(
          decoration: const BoxDecoration(
            color: _surface,
            border: Border(top: BorderSide(color: _border)),
          ),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'DROP INTO BUCKET',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  _DropBucket(
                    label: 'Essential',
                    sublabel: 'rent · bills · food',
                    category: 'essential',
                    icon: Icons.shield_outlined,
                    color: _success,
                  ),
                  SizedBox(width: 10),
                  _DropBucket(
                    label: 'Lifestyle',
                    sublabel: 'fun · dining · shop',
                    category: 'non_essential',
                    icon: Icons.local_fire_department_outlined,
                    color: _danger,
                  ),
                  SizedBox(width: 10),
                  _DropBucket(
                    label: 'Savings',
                    sublabel: 'invest · SIP · goal',
                    category: 'savings_investments',
                    icon: Icons.trending_up_rounded,
                    color: _brand,
                  ),
                ],
              ),
            ],
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

// ─── Stat chip ────────────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _StatChip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Transaction tile ─────────────────────────────────────────────────────────

class _TxnTile extends StatelessWidget {
  final TransactionModel txn;
  const _TxnTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final isDebit = txn.direction == 'debit';

    if (!isDebit) return _TxnCard(txn: txn, locked: true);

    return Draggable<TransactionModel>(
      data: txn,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - 32,
          child: _TxnCard(txn: txn, isGhost: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.2,
        child: _TxnCard(txn: txn),
      ),
      child: _TxnCard(txn: txn),
    );
  }
}

class _TxnCard extends StatelessWidget {
  final TransactionModel txn;
  final bool isGhost;
  final bool locked;

  const _TxnCard({
    required this.txn,
    this.isGhost = false,
    this.locked  = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDebit     = txn.direction == 'debit';
    final accentColor = isDebit ? _danger : _success;
    final payeeIsVpa  = txn.payee.contains('@');
    final vpaFromRaw  = _vpaDisplayRe.firstMatch(txn.raw)?.group(0) ?? '';
    final showVpaSub  = !payeeIsVpa && vpaFromRaw.isNotEmpty;

    return Opacity(
      opacity: locked ? 0.45 : 1.0,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: isGhost ? _surfaceHigh : _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isGhost ? accentColor.withOpacity(0.5) : _border,
          ),
          boxShadow: isGhost
              ? [
            BoxShadow(
              color: accentColor.withOpacity(0.3),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ]
              : const [],
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

              // Card content
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
                          color: accentColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          isDebit
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          size: 18,
                          color: accentColor,
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Payee + subtitle
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
                            if (showVpaSub) ...[
                              Text(
                                vpaFromRaw,
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: _textMuted,
                                  fontStyle: FontStyle.italic,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                txn.formattedDate,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: _textMuted.withOpacity(0.6),
                                ),
                              ),
                            ] else
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

                      // Amount + drag handle
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${isDebit ? '−' : '+'}₹${_formatAmt(txn.amount)}',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: accentColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Icon(
                            locked
                                ? Icons.lock_outline_rounded
                                : Icons.drag_indicator_rounded,
                            size: locked ? 14 : 18,
                            color: _textMuted.withOpacity(0.35),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

// ─── Drop bucket ──────────────────────────────────────────────────────────────

class _DropBucket extends StatefulWidget {
  final String   label;
  final String   sublabel;
  final String   category;
  final IconData icon;
  final Color    color;

  const _DropBucket({
    required this.label,
    required this.sublabel,
    required this.category,
    required this.icon,
    required this.color,
  });

  @override
  State<_DropBucket> createState() => _DropBucketState();
}

class _DropBucketState extends State<_DropBucket>
    with SingleTickerProviderStateMixin {
  bool _hover = false;
  late final AnimationController _anim;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _anim, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<TransactionController>();

    return Expanded(
      child: DragTarget<TransactionModel>(
        onWillAcceptWithDetails: (details) {
          if (details.data.direction != 'debit') return false;
          setState(() => _hover = true);
          _anim.forward();
          return true;
        },
        onLeave: (_) {
          setState(() => _hover = false);
          _anim.reverse();
        },
        onAcceptWithDetails: (details) {
          setState(() => _hover = false);
          _anim.reverse();
          ctrl.categorize(details.data, widget.category);
        },
        builder: (_, candidateData, __) {
          final active = _hover || candidateData.isNotEmpty;
          return ScaleTransition(
            scale: _scale,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              decoration: BoxDecoration(
                color: active
                    ? widget.color.withOpacity(0.13)
                    : _surfaceEl,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active
                      ? widget.color
                      : widget.color.withOpacity(0.2),
                  width: active ? 1.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: widget.color
                          .withOpacity(active ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      widget.icon,
                      color: widget.color,
                      size: active ? 22 : 20,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    widget.label,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: active ? widget.color : _textSecondary,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.sublabel,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: active
                          ? widget.color.withOpacity(0.65)
                          : _textMuted.withOpacity(0.5),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
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
        child: Column(
          children: [
            // Stats strip placeholder
            Container(
              color: _surface,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Row(
                children: [
                  _pill(80, 24),
                  const SizedBox(width: 8),
                  _pill(72, 24),
                  const Spacer(),
                  _pill(60, 32),
                ],
              ),
            ),
            Container(height: 1, color: _border),
            Container(
              color: _surfaceEl,
              height: 32,
            ),
            Container(height: 1, color: _border),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Column(
                  children: List.generate(
                    5,
                        (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _skeletonCard(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skeletonCard() {
    return Container(
      height: 72,
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
                _pill(110, 10),
                const SizedBox(height: 7),
                _pill(76, 8),
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

  Widget _pill(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: _surfaceEl,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final TransactionController ctrl;
  const _EmptyState({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: _success.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: _success.withOpacity(0.2), width: 1.5),
              ),
              child: const Icon(Icons.check_rounded,
                  size: 34, color: _success),
            ),
            const SizedBox(height: 20),
            Text(
              'All sorted.',
              style: GoogleFonts.dmSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: _textPrimary,
                letterSpacing: -0.8,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No new UPI transactions\nto categorize.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                color: _textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 200,
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push(AppRoutes.categorizedTxns),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _brand,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        'View Records',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.dashboard),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSecondary,
                        side: const BorderSide(color: _border),
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'Dashboard',
                        style: GoogleFonts.dmSans(
                            fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error state ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final TransactionController ctrl;
  const _ErrorState({required this.ctrl});

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
                border: Border.all(
                    color: _danger.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.error_outline_rounded,
                  size: 30, color: _danger),
            ),
            const SizedBox(height: 18),
            Text(
              'Something went wrong',
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
                onPressed: ctrl.loadSmsTransactions,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _danger,
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