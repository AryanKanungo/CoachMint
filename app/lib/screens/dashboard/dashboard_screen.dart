import 'dart:math' as math;
import 'package:coachmint/screens/dashboard/prediction_chart.dart';
import 'package:coachmint/screens/dashboard/resilience_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/app_models.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/auth_service.dart';
import '../../common_widgets/widgets.dart';
import 'bill_tile.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'engine_chart.dart';

// ─── Local typography helpers ─────────────────────────────────────────────────

TextStyle _label([Color color = AppColors.textMuted]) => GoogleFonts.dmSans(
  fontSize: 9,
  fontWeight: FontWeight.w700,
  color: color,
  letterSpacing: 1.8,
);

TextStyle _mono(double size, Color color) => GoogleFonts.dmSans(
  fontSize: size,
  fontWeight: FontWeight.w800,
  color: color,
  letterSpacing: -size * 0.04,
  height: 1.0,
);

// ─── Dot-grid painter ─────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary.withOpacity(0.055)
      ..strokeCap = StrokeCap.round;
    const gap = 22.0;
    const r   = 1.0;
    for (double x = gap; x < size.width; x += gap) {
      for (double y = gap; y < size.height; y += gap) {
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ─── Dashboard screen ─────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {

  Future<void> _handleRecalculate(BuildContext context) async {
    final supabase = Supabase.instance.client;
    final userId   = supabase.auth.currentUser?.id;
    if (userId == null) { Get.snackbar("Error", "User session not found"); return; }

    Get.showSnackbar(const GetSnackBar(
      message: "Recalculating engine...",
      duration: Duration(seconds: 2),
      snackPosition: SnackPosition.BOTTOM,
    ));

    try {
      final response = await http.post(
        Uri.parse('https://coachmint.onrender.com/engine/recalculate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"record": {"user_id": userId}}),
      );
      if (response.statusCode == 200) {
        Get.snackbar("Success", "Engine recalculated successfully! 🎉");
      } else {
        Get.snackbar("Error", "Failed to recalculate: ${response.body}");
      }
    } catch (e) {
      Get.snackbar("Error", "Connection error: $e");
    }
  }

  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DashboardController();

    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: _AppDrawer(),

      // ── AppBar — razor thin, no elevation ────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(builder: (ctx) => IconButton(
          icon: _MenuIcon(),
          onPressed: () => Scaffold.of(ctx).openDrawer(),
          splashRadius: 20,
        )),
        title: Text(
          'COACHMINT',
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 3.5,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 19),
            color: AppColors.textSecondary,
            onPressed: () => _handleRecalculate(context),
            tooltip: 'Recalculate',
            splashRadius: 20,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(Icons.receipt_long_rounded, size: 19),
              color: AppColors.textSecondary,
              onPressed: () => context.push(AppRoutes.smsCategorization),
              tooltip: 'Transactions',
              splashRadius: 20,
            ),
          ),
        ],
      ),

      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),

      // ── Body ─────────────────────────────────────────────────
      body: StreamBuilder<FinancialSnapshotModel>(
        stream: controller.snapshotStream,
        builder: (context, snapshot) {
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeOut,
            child: snapshot.hasData
                ? _DashBody(data: snapshot.data!, controller: controller)
                : const _LoadingView(),
          );
        },
      ),
    );
  }
}

// ─── Loading view ─────────────────────────────────────────────────────────────

class _LoadingView extends StatefulWidget {
  const _LoadingView();
  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.2, end: 0.6)
        .animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _anim.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, __) => Opacity(
        opacity: _fade.value,
        child: Column(
          children: [
            // Hero placeholder
            Container(
              height: 200,
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmer(60, 11),
                  const SizedBox(height: 14),
                  _shimmer(220, 52),
                  const Spacer(),
                  _shimmer(160, 36),
                ],
              ),
            ),
            const SizedBox(height: 1),
            // Stat strip placeholder
            Container(
              height: 88,
              color: AppColors.surface,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Row(
                children: [
                  Expanded(child: _shimmer(double.infinity, 14)),
                  const SizedBox(width: 32),
                  Expanded(child: _shimmer(double.infinity, 14)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _shimmer(double w, double h) => Container(
    width: w,
    height: h,
    decoration: BoxDecoration(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(4),
    ),
  );
}

// ─── Main dashboard body ──────────────────────────────────────────────────────

class _DashBody extends StatelessWidget {
  final FinancialSnapshotModel data;
  final DashboardController controller;
  const _DashBody({required this.data, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ① Hero balance panel
          _HeroPanel(cb: data.cb, spd: data.spd),

          // ── thin separator ──────────────────────────────────
          Container(height: 1, color: AppColors.border),

          // ② Stat ticker strip
          _StatStrip(survivalDays: data.survivalDays, ade: data.ade),

          Container(height: 1, color: AppColors.border),

          // ③ Resilience
          _SectionWrapper(
            label: 'RESILIENCE SCORE',
            child: ResilienceWidget(score: data.resilienceScore),
          ),

          // ④ Prediction chart
          _SectionWrapper(
            label: 'FINANCIAL ENGINE',
            child: EngineChartWidget(snapshot: data),  // data comes from your StreamBuilder
          ),

          // ⑤ Bills
          _BillsSection(controller: controller),

          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

// ─── Hero panel ───────────────────────────────────────────────────────────────

class _HeroPanel extends StatelessWidget {
  final double cb;
  final double spd;
  const _HeroPanel({required this.cb, required this.spd});

  @override
  Widget build(BuildContext context) {
    final screenW = MediaQuery.of(context).size.width;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      child: Stack(
        children: [
          // Dot grid texture
          Positioned.fill(
            child: CustomPaint(painter: const _DotGridPainter()),
          ),

          // Left edge accent bar
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 3,
              color: AppColors.primary,
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Label row ──────────────────────────────────
                Row(
                  children: [
                    Text('TOTAL BALANCE', style: _label()),
                    const Spacer(),
                    // Live indicator dot
                    Container(
                      width: 6, height: 6,
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.success.withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text('LIVE', style: _label(AppColors.success)),
                  ],
                ),

                const SizedBox(height: 10),

                // ── Massive balance number ─────────────────────
                // Sized to fill width if large enough
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '₹${_fmtHero(cb)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 64,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -3,
                      height: 1.0,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // ── Full-bleed rule ────────────────────────────
                Container(
                  height: 1,
                  color: AppColors.border,
                  margin: const EdgeInsets.symmetric(vertical: 0),
                ),

                const SizedBox(height: 20),

                // ── SPD row ────────────────────────────────────
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // SPD pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bolt_rounded,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'SAFE TO SPEND',
                            style: _label(AppColors.primary),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 14),

                    Text(
                      '₹${_fmtHero(spd)}',
                      style: GoogleFonts.dmSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: -1,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtHero(double v) {
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(2)}Cr';
    if (v >= 100000)   return '${(v / 100000).toStringAsFixed(2)}L';
    if (v >= 1000)     return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

// ─── Stat ticker strip ────────────────────────────────────────────────────────

class _StatStrip extends StatelessWidget {
  final double survivalDays;
  final double ade;
  const _StatStrip({required this.survivalDays, required this.ade});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Survival days
            Expanded(
              child: _StatBlock(
                label: 'SURVIVAL DAYS',
                value: '${survivalDays.toInt()}',
                unit: 'days left',
                accentColor: AppColors.warning,
                icon: Icons.hourglass_bottom_rounded,
                borderRight: true,
              ),
            ),

            // Daily burn
            Expanded(
              child: _StatBlock(
                label: 'DAILY BURN',
                value: '₹${ade.toInt()}',
                unit: 'avg / day',
                accentColor: AppColors.danger,
                icon: Icons.local_fire_department_outlined,
                borderRight: false,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String   label;
  final String   value;
  final String   unit;
  final Color    accentColor;
  final IconData icon;
  final bool     borderRight;

  const _StatBlock({
    required this.label,
    required this.value,
    required this.unit,
    required this.accentColor,
    required this.icon,
    required this.borderRight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      decoration: BoxDecoration(
        border: Border(
          right: borderRight
              ? const BorderSide(color: AppColors.border)
              : BorderSide.none,
          top: const BorderSide(color: Colors.transparent),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Icon(icon, size: 11, color: accentColor),
              const SizedBox(width: 5),
              Text(label, style: _label(accentColor)),
            ],
          ),
          const SizedBox(height: 10),

          // Value
          Text(value, style: _mono(30, AppColors.textPrimary)),

          const SizedBox(height: 4),

          // Unit
          Text(
            unit,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section wrapper ──────────────────────────────────────────────────────────

class _SectionWrapper extends StatelessWidget {
  final String label;
  final Widget child;
  const _SectionWrapper({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
          child: Row(
            children: [
              Text(label, style: _label()),
              const SizedBox(width: 12),
              Expanded(
                child: Container(height: 1, color: AppColors.border),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: child,
        ),
      ],
    );
  }
}

// ─── Bills section ────────────────────────────────────────────────────────────

class _BillsSection extends StatelessWidget {
  final DashboardController controller;
  const _BillsSection({required this.controller});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BillModel>>(
      stream: controller.upcomingBillsStream,
      builder: (context, snapshot) {
        final bills = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header with count
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
              child: Row(
                children: [
                  Text('UPCOMING BILLS', style: _label()),
                  if (bills.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${bills.length}',
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: AppColors.warning,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 12),
                  Expanded(child: Container(height: 1, color: AppColors.border)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (bills.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 16,
                          color: AppColors.success.withOpacity(0.7)),
                      const SizedBox(width: 10),
                      Text(
                        'No upcoming bills',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bills.length,
                  itemBuilder: (_, i) => BillTile(bill: bills[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ─── Custom hamburger icon ────────────────────────────────────────────────────

class _MenuIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20, height: 14,
      child: CustomPaint(painter: _HamburgerPainter()),
    );
  }
}

class _HamburgerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textSecondary
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    // Three lines — top full, middle 60%, bottom full
    canvas.drawLine(Offset(0, 0), Offset(size.width, 0), paint);
    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width * 0.65, size.height / 2),
        paint);
    canvas.drawLine(
        Offset(0, size.height), Offset(size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ════════════════════════════════════════════════════════════════
// App Drawer
// ════════════════════════════════════════════════════════════════

class _AppDrawer extends StatelessWidget {
  static const _navItems = [
    (Icons.home_rounded,           'Dashboard',        AppRoutes.dashboard),
    (Icons.auto_awesome_rounded,   'Ask AI',           AppRoutes.aiAgent),
    (Icons.track_changes_rounded,  'Track Goals',      AppRoutes.trackGoals),
    (Icons.account_balance_rounded,'Govt Schemes',     AppRoutes.govtSchemes),
    (Icons.receipt_long_rounded,   'SMS Transactions', AppRoutes.smsCategorization),
  ];

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.72,
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo mark
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.25)),
                    ),
                    child: Center(
                      child: Text(
                        '₹',
                        style: GoogleFonts.dmSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'CoachMint',
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Your money. Your rules.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: AppColors.border),
            const SizedBox(height: 8),

            // ── Nav items ──────────────────────────────────────
            ..._navItems.map((item) => _DrawerItem(
              icon: item.$1,
              label: item.$2,
              route: item.$3,
            )),

            const Spacer(),

            Container(height: 1, color: AppColors.border),

            // ── Logout ─────────────────────────────────────────
            InkWell(
              onTap: () async {
                await AuthService().signOut();
                if (context.mounted) context.go(AppRoutes.login);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    const Icon(Icons.logout_rounded,
                        size: 17, color: AppColors.danger),
                    const SizedBox(width: 14),
                    Text(
                      'Log out',
                      style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Text(
                'v1.0.0',
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: AppColors.textMuted.withOpacity(0.4),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        context.go(route);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 17, color: AppColors.textSecondary),
            const SizedBox(width: 16),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                letterSpacing: -0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}