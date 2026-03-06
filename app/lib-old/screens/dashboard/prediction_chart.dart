import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../utils/colors.dart';
import '../../../utils/theme.dart';

// Data class (unchanged — functional)
class HardcodedChartData {
  HardcodedChartData(this.x, this.y);
  final String x;
  final double y;
}

class PredictionChart extends StatelessWidget {
  const PredictionChart({super.key});

  @override
  Widget build(BuildContext context) {
    final List<HardcodedChartData> chartData = [
      HardcodedChartData('1', 50),
      HardcodedChartData('2', 80),
      HardcodedChartData('3', 40),
      HardcodedChartData('4', 90),
      HardcodedChartData('5', 60),
    ];

    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Section label ─────────────────────────────────
          Text(
            'SPENDING FORECAST',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.6,
            ),
          ),
          const SizedBox(height: 4),
          // ── Chart ─────────────────────────────────────────
          Expanded(
            child: SfCartesianChart(
              plotAreaBorderWidth: 0,
              margin: EdgeInsets.zero,
              primaryXAxis: const CategoryAxis(isVisible: false),
              primaryYAxis: const NumericAxis(isVisible: false),
              series: <CartesianSeries<HardcodedChartData, String>>[
                SplineAreaSeries<HardcodedChartData, String>(
                  dataSource: chartData,
                  xValueMapper: (HardcodedChartData data, _) => data.x,
                  yValueMapper: (HardcodedChartData data, _) => data.y,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.25),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderColor: AppColors.primary,
                  borderWidth: 2.5,
                  animationDuration: 1000,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
