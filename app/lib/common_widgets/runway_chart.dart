// lib/widgets/runway_chart.dart
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../models/app_models.dart';  // FinancialSnapshotModel
import '../utils/theme.dart';         // AppTheme

// ─────────────────────────────────────────────────────────────
// Prediction contract:
//   .targetDate      → DateTime
//   .predictedAmount → double
// This file uses dynamic so you don't need a separate import.
// Swap `dynamic` → `Prediction` if you prefer strict types.
// ─────────────────────────────────────────────────────────────

// ─────────────────────────────────────────────────────────────
// Internal chart point
// ─────────────────────────────────────────────────────────────
class _Pt {
  final DateTime x;
  final double   y;
  const _Pt(this.x, this.y);
}

// ═════════════════════════════════════════════════════════════
// RunwayChart
// ═════════════════════════════════════════════════════════════
class RunwayChart extends StatelessWidget {
  final FinancialSnapshotModel           snapshot;
  final List<MapEntry<DateTime, double>> historicalSeries;
  final List<dynamic>                    predictions; // Prediction list

  const RunwayChart({
    super.key,
    required this.snapshot,
    required this.historicalSeries,
    required this.predictions,
  });

  // ── Color aliases — zero hardcoded hex ──────────────────────
  static const _cPast    = AppTheme.info;     // blue   #3D7FD4
  static const _cFuture  = AppTheme.brand;    // green  #00C896
  static const _cReserve = AppTheme.danger;   // red    #E03E52
  static const _cToday   = AppTheme.warning;  // amber  #E09520

  // ── Data builders ───────────────────────────────────────────
  DateTime _day(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  List<_Pt> _buildPast(DateTime today) => [
    for (final e in historicalSeries) _Pt(_day(e.key), e.value),
    _Pt(today, snapshot.cb), // bridge
  ];

  List<_Pt> _buildFuture(DateTime today) => [
    _Pt(today, snapshot.cb), // bridge
    for (final p in predictions)
      _Pt(_day(p.targetDate as DateTime),
          (p.predictedAmount as num).toDouble()),
  ];

  @override
  Widget build(BuildContext context) {
    final today = _day(DateTime.now());
    final past  = _buildPast(today);
    final fut   = _buildFuture(today);

    if (past.length < 2 && fut.length < 2) return _empty();

    // X range for the flat reserve line
    final all  = [...past, ...fut];
    final xMin = all.map((p) => p.x).reduce((a, b) => a.isBefore(b) ? a : b);
    final xMax = all.map((p) => p.x).reduce((a, b) => a.isAfter(b) ? a : b);
    final res  = [_Pt(xMin, snapshot.minReserve), _Pt(xMax, snapshot.minReserve)];

    // Y bounds ± 15 %
    final allY  = [...all.map((p) => p.y), snapshot.minReserve];
    final yLo   = allY.reduce(math.min);
    final yHi   = allY.reduce(math.max);
    final span  = (yHi - yLo).abs().clamp(1.0, double.infinity);
    final yMin  = yLo - span * 0.15;
    final yMax  = yHi + span * 0.15;

    final compact = NumberFormat.compactCurrency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SizedBox(
      height: 260,
      child: SfCartesianChart(
        backgroundColor: AppTheme.surfaceCard,
        plotAreaBorderWidth: 0,
        margin: const EdgeInsets.fromLTRB(0, 8, 8, 0),

        legend: Legend(
          isVisible: true,
          position: LegendPosition.top,
          alignment: ChartAlignment.far,
          overflowMode: LegendItemOverflowMode.wrap,
          textStyle: GoogleFonts.dmSans(
              color: AppTheme.textMuted, fontSize: 9, letterSpacing: 0.8),
          iconHeight: 6,
          iconWidth: 14,
        ),

        crosshairBehavior: CrosshairBehavior(
          enable: true,
          activationMode: ActivationMode.singleTap,
          lineType: CrosshairLineType.both,
          lineColor: AppTheme.textMuted,
          lineWidth: 0.8,
          lineDashArray: const [4, 3],
        ),

        tooltipBehavior: TooltipBehavior(
          enable: true,
          color: AppTheme.surfaceElevated,
          borderColor: AppTheme.border,
          borderWidth: 1,
          elevation: 0,
          textStyle: GoogleFonts.dmSans(
              color: AppTheme.textPrimary, fontSize: 11),
          format: 'point.x\npoint.y',
        ),

        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('d MMM'),
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: AppTheme.border.withOpacity(0.35),
            dashArray: const [4, 4],
          ),
          labelStyle: GoogleFonts.dmSans(
              color: AppTheme.textMuted, fontSize: 9),
          plotBands: [
            PlotBand(
              start: today,
              end: today.add(const Duration(hours: 20)),
              color: _cToday.withOpacity(0.06),
              borderColor: _cToday.withOpacity(0.55),
              borderWidth: 1,
              text: 'TODAY',
              textStyle: GoogleFonts.dmSans(
                color: _cToday,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
              verticalTextAlignment: TextAnchor.start,
              horizontalTextAlignment: TextAnchor.middle,
            ),
          ],
        ),

        primaryYAxis: NumericAxis(
          minimum: yMin,
          maximum: yMax,
          axisLine: const AxisLine(width: 0),
          majorTickLines: const MajorTickLines(size: 0),
          majorGridLines: MajorGridLines(
            width: 0.5,
            color: AppTheme.border.withOpacity(0.35),
            dashArray: const [4, 4],
          ),
          labelStyle: GoogleFonts.dmSans(
              color: AppTheme.textMuted, fontSize: 9),
          numberFormat: compact,
        ),

        series: <CartesianSeries<_Pt, DateTime>>[
          // 1 — Historical balance: solid spline + gradient fill
          SplineAreaSeries<_Pt, DateTime>(
            name: 'Balance',
            dataSource: past,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            splineType: SplineType.cardinal,
            color: _cPast.withOpacity(0.10),
            borderColor: _cPast,
            borderWidth: 2.5,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [_cPast.withOpacity(0.22), _cPast.withOpacity(0.01)],
            ),
          ),

          // 2 — Forecast: dashed spline with diamond markers
          SplineSeries<_Pt, DateTime>(
            name: 'Forecast',
            dataSource: fut,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            splineType: SplineType.cardinal,
            color: _cFuture,
            width: 2.0,
            dashArray: const [8, 5],
            markerSettings: const MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.diamond,
              height: 6,
              width: 6,
              color: _cFuture,
              borderColor: _cFuture,
              borderWidth: 1.5,
            ),
          ),

          // 3 — Min-reserve: flat dashed red threshold line
          LineSeries<_Pt, DateTime>(
            name: 'Min Reserve',
            dataSource: res,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            color: _cReserve,
            width: 1.5,
            dashArray: const [6, 4],
            markerSettings: const MarkerSettings(isVisible: false),
          ),
        ],
      ),
    );
  }

  Widget _empty() => const SizedBox(
    height: 260,
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart_rounded,
              size: 28, color: AppTheme.textMuted),
          SizedBox(height: 10),
          Text('Not enough data yet',
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 4),
          Text('Categorise transactions to see your runway',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}