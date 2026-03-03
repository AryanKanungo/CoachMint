import 'dart:async'; // For animations
import 'package:coachmint/utils/routes.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../common widgets/app_drawer.dart';
import 'home_controller.dart';
import '../../utils/colors.dart';
import '../../services/sms_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final home = Get.put(HomeController());
  final sms = Get.find<SmsService>();

  // --- Animation State ---
  bool _showAppBar = false;

  @override
  void initState() {
    super.initState();
    sms.init();
    // Trigger AppBar animations
    Timer(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _showAppBar = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background, // 1. Styled Scaffold
      drawer: const AppDrawer(),

      appBar: AppBar(
        surfaceTintColor: AppColors.cardBackground,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text("Coach Mint", style: textTheme.headlineMedium),
        actions: [
          Padding(padding: const EdgeInsets.all(7.0),
            child: IconButton(
              icon: const Icon(Icons.lightbulb_outlined,
                  size: 27, color: AppColors.primary),
              onPressed: () {
              },
            ),),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(
              icon: const Icon(Icons.sort,
                  size: 27, color: AppColors.primaryLight),
              onPressed: () {
                Get.toNamed(AppRoutes.smsCategorization);
              },
            ),

          ),

        ],

      ),

      body: Obx(
            () => home.isLoaded.value
            ? ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _AnimatedFadeSlide(
              show: true,
              delay: const Duration(milliseconds: 500),
              child: _buildDailySpendCard(context),
            ),
            const SizedBox(height: 20),
            _AnimatedFadeSlide(
              show: true,
              delay: const Duration(milliseconds: 600),
              child: _buildCategoryChartCard(context),
            ),
            const SizedBox(height: 20),
            _AnimatedFadeSlide(
              show: true,
              delay: const Duration(milliseconds: 700),
              child: _buildRecentTransactions(context),
            ),
          ],
        )
        // 4. Engaging Loading State
            : Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading your dashboard...',
                style: GoogleFonts.inter(color: AppColors.secondaryText),
              )
            ],
          ),
        ),
      ),
    );
  }

  // --- 5. Styled Spend Card ---
  Widget _buildDailySpendCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final double spendPercent =
    (home.dailySpend.value / home.dailyCap.value).clamp(0.0, 1.0);

    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Daily Spending",
                style: textTheme.titleLarge
                    ?.copyWith(color: AppColors.mainText)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  "₹${home.dailySpend.value.toInt()}",
                  style: textTheme.headlineLarge
                      ?.copyWith(color: AppColors.primary),
                ),
                Text(
                  "/ ₹${home.dailyCap.value.toInt()} left",
                  style: textTheme.bodyMedium
                      ?.copyWith(color: AppColors.secondaryText),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: spendPercent,
                minHeight: 12,
                backgroundColor: AppColors.background,
                valueColor: AlwaysStoppedAnimation<Color>(
                  spendPercent > 0.8
                      ? AppColors.redAccent
                      : AppColors.greenAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. Styled Chart Card ---
  Widget _buildCategoryChartCard(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Category Breakdown",
                style: textTheme.titleLarge
                    ?.copyWith(color: AppColors.mainText)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SfCircularChart(
                legend: Legend(
                  isVisible: true,
                  overflowMode: LegendItemOverflowMode.wrap,
                  position: LegendPosition.right,
                  // Style the legend text
                  textStyle: GoogleFonts.inter(
                    color: AppColors.secondaryText,
                    fontSize: 12,
                  ),
                ),
                // Style the tooltips
                tooltipBehavior: TooltipBehavior(
                  enable: true,
                  color: AppColors.background,
                  textStyle: GoogleFonts.inter(color: AppColors.mainText),
                ),
                series: home.getChartSeries(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- 7. Engaging Recent Transactions ---
  Widget _buildRecentTransactions(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Recent Transactions",
            style: textTheme.titleLarge
                ?.copyWith(color: AppColors.mainText)),
        const SizedBox(height: 12),
        _buildTransactionTile(
          context: context,
          icon: Icons.fastfood_rounded,
          iconColor: AppColors.primaryLight,
          title: "Zomato",
          subtitle: "Food",
          amount: -250,
        ),
        _buildTransactionTile(
          context: context,
          icon: Icons.directions_bus_rounded,
          iconColor: AppColors.greenAccent,
          title: "Uber Auto",
          subtitle: "Transport",
          amount: -85,
        ),
      ],
    );
  }

  // --- 8. New Transaction Tile Widget ---
  Widget _buildTransactionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double amount,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final color =
    amount < 0 ? AppColors.redAccent : AppColors.greenAccent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      // Use Material + InkWell for a clean splash effect
      child: Material(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {}, // Interactive
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withOpacity(0.1),
          highlightColor: AppColors.primary.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: iconColor.withOpacity(0.15),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.mainText),
                      ),
                      Text(
                        subtitle,
                        style: textTheme.bodyMedium
                            ?.copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
                Text(
                  "₹${amount.toInt()}",
                  style: textTheme.bodyLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- Animation Helper Widget ---
// (This is the same helper from our Login/Register screens, renamed)
enum _SlideDirection { top, left, right, bottom }

class _AnimatedFadeSlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final bool show;
  final _SlideDirection direction;

  const _AnimatedFadeSlide({
    required this.child,
    this.delay = const Duration(milliseconds: 100),
    this.show = true,
    this.direction = _SlideDirection.bottom,
  });

  @override
  State<_AnimatedFadeSlide> createState() => _AnimatedFadeSlideState();
}

class _AnimatedFadeSlideState extends State<_AnimatedFadeSlide> {
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    if (widget.show) {
      Timer(widget.delay, () {
        if (mounted) setState(() => _isVisible = true);
      });
    }
  }

  Offset get _offset {
    if (!_isVisible) {
      switch (widget.direction) {
        case _SlideDirection.top:
          return const Offset(0, -0.2);
        case _SlideDirection.left:
          return const Offset(-0.2, 0);
        case _SlideDirection.right:
          return const Offset(0.2, 0);
        case _SlideDirection.bottom:
        default:
          return const Offset(0, 0.2);
      }
    }
    return Offset.zero;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}