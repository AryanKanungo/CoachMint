import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/chart_data.dart';
import '../../utils/colors.dart';

class HomeController extends GetxController {
  var isLoaded = false.obs;

  // Dummy data for daily spend
  var dailySpend = 1250.0.obs;
  var dailyCap = 2000.0.obs;

  // Dummy data for chart
  var chartData = <ChartData>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  void loadData() {
    // Simulate a network call
    Future.delayed(const Duration(milliseconds: 300), () {
      chartData.value = [
        ChartData("Food", 400, AppColors.redAccent),
        ChartData("Transport", 150, AppColors.primary),
        ChartData("Rent", 500, AppColors.greenAccent),
        ChartData("Other", 200, AppColors.secondaryText),
      ];
      isLoaded.value = true;
    });
  }

  // Prepares the data series for the Syncfusion chart
  List<DoughnutSeries<ChartData, String>> getChartSeries() {
    return <DoughnutSeries<ChartData, String>>[
      DoughnutSeries<ChartData, String>(
        dataSource: chartData,
        xValueMapper: (ChartData data, _) => data.category,
        yValueMapper: (ChartData data, _) => data.amount,
        pointColorMapper: (ChartData data, _) => data.color,
        dataLabelMapper: (ChartData data, _) => data.category,

        // --- FIX IS HERE ---
        dataLabelSettings: DataLabelSettings(
          isVisible: true,
          labelPosition: ChartDataLabelPosition.outside,
          // Use your app's text color for the labels
          textStyle: GoogleFonts.inter(
            color: AppColors.secondaryText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          // Make the connector line visible against the dark bg
          connectorLineSettings: const ConnectorLineSettings(
            color: AppColors.secondaryText,
            width: 2,
          ),
        ),
        // --- END FIX ---

        // Explodes the segment on tap
        explode: true,
        explodeIndex: 0,
        innerRadius: '60%',
      )
    ];
  }
}