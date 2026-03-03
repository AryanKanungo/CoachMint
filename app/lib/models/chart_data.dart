import 'package:flutter/material.dart';

// A simple model for data used by Syncfusion charts.
class ChartData {
  ChartData(this.category, this.amount, this.color);
  final String category;
  final double amount;
  final Color color;
}