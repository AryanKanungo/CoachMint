import 'package:coachmint/screens/dashboard/prediction_chart.dart';
import 'package:coachmint/screens/dashboard/resilience_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/app_models.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';
import '../../utils/routes.dart';
import '../../controllers/dashboard_controller.dart';
import '../../services/auth_service.dart';
import '../../common_widgets/widgets.dart';
import 'bill_tile.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = DashboardController();

    return Scaffold(
      backgroundColor: AppColors.background,
      // ── App Drawer ──────────────────────────────────────────────
      drawer: _AppDrawer(),
      // ── AppBar ───────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'CoachMint',
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.receipt_long_rounded,
                color: AppColors.primary),
            onPressed: () => context.push(AppRoutes.smsCategorization),
            tooltip: 'SMS Transactions',
          ),
          const SizedBox(width: 8),
        ],
      ),
      // ── Bottom Navigation ────────────────────────────────────────
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
      // ── Body ─────────────────────────────────────────────────────
      body: StreamBuilder<FinancialSnapshotModel>(
        stream: controller.snapshotStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final data = snapshot.data!;

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                _buildMainBalanceTile(context, data.cb, data.spd),
                const SizedBox(height: 24),
                ResilienceWidget(score: data.resilienceScore),
                const SizedBox(height: 24),
                _buildDerivativeRow(context, data.survivalDays, data.ade),
                const SizedBox(height: 32),
                const PredictionChart(),
                const SizedBox(height: 32),
                _buildBillsSection(context, controller),
                const SizedBox(height: 80), // space above bottom nav
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Main Balance Card ─────────────────────────────────────────
  Widget _buildMainBalanceTile(
      BuildContext context, double cb, double spd) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'TOTAL BALANCE',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '₹${cb.toStringAsFixed(0)}',
            style: GoogleFonts.dmSans(
              fontSize: 40,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -1.5,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primaryMuted,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flash_on_rounded,
                    color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Text(
                  'SAFE TO SPEND: ₹${spd.toStringAsFixed(0)}',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Derivative Stats Row ──────────────────────────────────────
  Widget _buildDerivativeRow(
      BuildContext context, double survival, double ade) {
    return Row(
      children: [
        Expanded(
          child: _derivativeCard(context, 'SURVIVAL DAYS',
              '${survival.toInt()}d', Icons.calendar_today_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _derivativeCard(context, 'DAILY AVERAGE',
              '₹${ade.toInt()}', Icons.bar_chart_rounded),
        ),
      ],
    );
  }

  Widget _derivativeCard(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Bills Section ─────────────────────────────────────────────
  Widget _buildBillsSection(
      BuildContext context, DashboardController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'UPCOMING BILLS',
              style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 1.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<BillModel>>(
          stream: controller.upcomingBillsStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No pending bills',
                  style: GoogleFonts.dmSans(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              );
            }
            final bills = snapshot.data!;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: bills.length,
              itemBuilder: (context, index) => BillTile(bill: bills[index]),
            );
          },
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// _AppDrawer — Drawer with Logout button in header
// ════════════════════════════════════════════════════════════════

class _AppDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drawer Header ─────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 20),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App logo mark
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text(
                        '₹',
                        style: TextStyle(
                            fontSize: 20,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CoachMint',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          'Your money. Your rules.',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // ── Logout icon button ──────────────────────
                  IconButton(
                    tooltip: 'Log Out',
                    icon: const Icon(Icons.logout_rounded,
                        color: AppColors.textMuted, size: 20),
                    onPressed: () async {
                      final authService = AuthService();
                      await authService.signOut();
                      if (context.mounted) {
                        context.go(AppRoutes.login);
                      }
                    },
                  ),
                ],
              ),
            ),

            // ── Nav Items ──────────────────────────────────────
            const SizedBox(height: 8),
            _DrawerItem(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.dashboard);
              },
            ),
            _DrawerItem(
              icon: Icons.auto_awesome_rounded,
              label: 'Ask AI',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.aiAgent);
              },
            ),
            _DrawerItem(
              icon: Icons.track_changes_rounded,
              label: 'Track Goals',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.trackGoals);
              },
            ),
            _DrawerItem(
              icon: Icons.account_balance_rounded,
              label: 'Govt Schemes',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.govtSchemes);
              },
            ),
            _DrawerItem(
              icon: Icons.receipt_long_rounded,
              label: 'SMS Transactions',
              onTap: () {
                Navigator.of(context).pop();
                context.go(AppRoutes.smsCategorization);
              },
            ),

            const Spacer(),

            // ── Footer ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'v1.0.0',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: AppColors.textMuted,
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
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading:
          Icon(icon, color: AppColors.textSecondary, size: 20),
      title: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
      horizontalTitleGap: 8,
      dense: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusSm)),
    );
  }
}
