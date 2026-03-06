import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../utils/colors.dart';

// 1. DATA CLASS (Defined here to ensure scope is correct)
class HardcodedChartData {
  HardcodedChartData(this.x, this.y);
  final String x;
  final double y;
}

class PredictionChart extends StatelessWidget {
  const PredictionChart({super.key});

  @override
  Widget build(BuildContext context) {
    // 2. EXPLICITLY TYPED LIST
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SfCartesianChart(
        plotAreaBorderWidth: 0,
        primaryXAxis: const CategoryAxis(isVisible: false),
        primaryYAxis: const NumericAxis(isVisible: false),

        // 3. MATCHING TYPES: <DataClass, HorizontalAxisType>
        series: <CartesianSeries<HardcodedChartData, String>>[
          SplineAreaSeries<HardcodedChartData, String>(
            dataSource: chartData,
            xValueMapper: (HardcodedChartData data, _) => data.x,
            yValueMapper: (HardcodedChartData data, _) => data.y,
            gradient: LinearGradient(
              colors: [
                AppColors.greenAccent.withOpacity(0.3),
                Colors.transparent
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderColor: AppColors.greenAccent,
            borderWidth: 3,
            animationDuration: 1000,
          ),
        ],
      ),
    );
  }
}