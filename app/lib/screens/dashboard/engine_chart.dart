// lib/screens/dashboard/engine_chart.dart
// ignore_for_file: constant_identifier_names
//
// DROP-IN for the dashboard. Replace the broken ④ FORECAST section with:
//
//   _SectionWrapper(
//     label: 'FINANCIAL ENGINE',
//     child: EngineChartWidget(snapshot: data),
//   ),
//
// This widget is fully self-contained — it fetches predictions and
// transactions from Supabase internally, matching the pattern used
// by prediction_chart.dart and resilience_widget.dart.
// ─────────────────────────────────────────────────────────────────

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../../models/app_models.dart';
import '../../utils/colors.dart';

// ─────────────────────────────────────────────────────────────
// Supabase row types (mapped inline — no extra model files)
// predictions: id, user_id, target_date, predicted_amount, type
// transactions: txn_id, user_id, amount, direction, timestamp
// ─────────────────────────────────────────────────────────────

class _Pred {
  final DateTime date;
  final double   amount;
  _Pred(this.date, this.amount);
}

class _Txn {
  final DateTime date;
  final double   amount;
  final bool     isDebit;
  _Txn(this.date, this.amount, this.isDebit);
}

class _Pt {
  final DateTime x;
  final double   y;
  const _Pt(this.x, this.y);
}

// ═════════════════════════════════════════════════════════════
// EngineChartWidget — self-contained, fetches its own data
// ═════════════════════════════════════════════════════════════
class EngineChartWidget extends StatefulWidget {
  final FinancialSnapshotModel snapshot;

  const EngineChartWidget({super.key, required this.snapshot});

  @override
  State<EngineChartWidget> createState() => _EngineChartWidgetState();
}

class _EngineChartWidgetState extends State<EngineChartWidget> {
  bool            _loading = true;
  String?         _err;
  List<_Pred>     _preds   = [];
  List<_Pt>       _hist    = [];
  bool            _runway  = true;   // true=runway, false=radar

  final _db = Supabase.instance.client;
  String get _uid => _db.auth.currentUser?.id ?? '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _err = null; });
    try {
      final results = await Future.wait([
        _fetchPredictions(),
        _fetchTransactions(),
      ]);
      if (!mounted) return;
      setState(() {
        _preds   = results[0] as List<_Pred>;
        _hist    = results[1] as List<_Pt>;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() { _err = e.toString(); _loading = false; });
    }
  }

  Future<List<_Pred>> _fetchPredictions() async {
    if (_uid.isEmpty) return [];
    final rows = await _db
        .from('predictions')
        .select('target_date, predicted_amount')
        .eq('user_id', _uid)
        .eq('type', 'balance')
        .order('target_date', ascending: true)
        .limit(30);
    return (rows as List).map((r) => _Pred(
      DateTime.parse(r['target_date'].toString()),
      (r['predicted_amount'] as num).toDouble(),
    )).toList();
  }

  Future<List<_Pt>> _fetchTransactions() async {
    if (_uid.isEmpty) return [];
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final rows = await _db
        .from('transactions')
        .select('amount, direction, timestamp')
        .eq('user_id', _uid)
        .gte('timestamp', cutoff.toIso8601String())
        .order('timestamp', ascending: false)
        .limit(200);

    final txns = (rows as List).map((r) {
      final dir = r['direction']?.toString().toLowerCase() ?? '';
      return _Txn(
        DateTime.parse(r['timestamp'].toString()),
        (r['amount'] as num).toDouble(),
        ['debit', 'out', 'dr'].contains(dir),
      );
    }).toList();

    return _buildHistoricalSeries(widget.snapshot.cb, txns);
  }

  // Walk backwards from current balance to reconstruct daily balance series
  List<_Pt> _buildHistoricalSeries(double cb, List<_Txn> txns) {
    double running = cb;
    // Group by day
    final Map<DateTime, double> byDay = {};
    byDay[_day(DateTime.now())] = cb;

    for (final t in txns) {
      // Reverse: if debit already happened, add back; if credit, subtract
      running = t.isDebit ? running + t.amount : running - t.amount;
      final d = _day(t.date);
      byDay[d] = running;
    }

    final sorted = byDay.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return sorted.map((e) => _Pt(e.key, e.value)).toList();
  }

  DateTime _day(DateTime dt) => DateTime(dt.year, dt.month, dt.day);

  void _toggle(bool runway) {
    if (_runway == runway) return;
    HapticFeedback.selectionClick();
    setState(() => _runway = runway);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header row ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _TitleBlock(runway: _runway)),
                const SizedBox(width: 12),
                _PillToggle(runway: _runway, onToggle: _toggle),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ── Chart body ──────────────────────────────────────
          SizedBox(
            height: 264,
            child: _loading
                ? _Shimmer()
                : _err != null
                ? _ErrState(onRetry: _load)
                : AnimatedCrossFade(
              duration: const Duration(milliseconds: 360),
              reverseDuration: const Duration(milliseconds: 260),
              crossFadeState: _runway
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              layoutBuilder:
                  (top, topKey, bot, botKey) => Stack(children: [
                Positioned.fill(
                    key: botKey,
                    child: Align(
                        alignment: Alignment.topCenter,
                        child: bot)),
                Positioned.fill(
                    key: topKey,
                    child: Align(
                        alignment: Alignment.topCenter,
                        child: top)),
              ]),
              firstChild: SizedBox(
                  height: 264,
                  child: _RunwayChart(
                    snapshot: widget.snapshot,
                    hist: _hist,
                    preds: _preds,
                  )),
              secondChild: SizedBox(
                  height: 264,
                  child: _RadarChart(
                    score: widget.snapshot.resilienceScore,
                  )),
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _TitleBlock
// ═════════════════════════════════════════════════════════════
class _TitleBlock extends StatelessWidget {
  final bool runway;
  const _TitleBlock({required this.runway});

  @override
  Widget build(BuildContext context) {
    final tag = runway ? 'FINANCIAL RUNWAY' : 'RESILIENCE RADAR';
    final sub = runway
        ? 'Cash forecast vs. reserve threshold'
        : 'Five-pillar health breakdown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            border: Border.all(color: AppColors.primary.withOpacity(0.28)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(tag,
                key: ValueKey(tag),
                style: GoogleFonts.dmSans(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4)),
          ),
        ),
        const SizedBox(height: 5),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Text(sub,
              key: ValueKey(sub),
              style: GoogleFonts.dmSans(
                  color: AppColors.textMuted, fontSize: 11, height: 1.4)),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _PillToggle
// ═════════════════════════════════════════════════════════════
class _PillToggle extends StatelessWidget {
  final bool runway;
  final void Function(bool) onToggle;
  const _PillToggle({required this.runway, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
              label: 'RUNWAY',
              active: runway,
              activeColor: AppColors.info,
              onTap: () => onToggle(true)),
          const SizedBox(width: 2),
          _Btn(
              label: 'RADAR',
              active: !runway,
              activeColor: AppColors.primary,
              onTap: () => onToggle(false)),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String     label;
  final bool       active;
  final Color      activeColor;
  final VoidCallback onTap;
  const _Btn({required this.label, required this.active,
    required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? activeColor.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color:
          active ? activeColor.withOpacity(0.50) : Colors.transparent,
        ),
      ),
      child: Text(label,
          style: GoogleFonts.dmSans(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: active ? activeColor : AppColors.textMuted,
              letterSpacing: 1.0)),
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// _RunwayChart — Syncfusion spline chart
// ═════════════════════════════════════════════════════════════
class _RunwayChart extends StatelessWidget {
  final FinancialSnapshotModel snapshot;
  final List<_Pt>              hist;
  final List<_Pred>            preds;
  const _RunwayChart(
      {required this.snapshot, required this.hist, required this.preds});

  @override
  Widget build(BuildContext context) {
    final today = DateTime(
        DateTime.now().year, DateTime.now().month, DateTime.now().day);

    // Build past series, bridge at today
    final past = <_Pt>[...hist, _Pt(today, snapshot.cb)];
    // Remove duplicate if last hist point is already today
    final pastDeduped = past.length > 1 &&
        past[past.length - 2].x == today
        ? past.sublist(0, past.length - 1)
        : past;

    // Build future series, bridge at today
    final futureRaw = <_Pt>[
      _Pt(today, snapshot.cb),
      for (final p in preds)
        _Pt(DateTime(p.date.year, p.date.month, p.date.day), p.amount),
    ];

    if (pastDeduped.length < 2 && futureRaw.length < 2) {
      return _emptyState('Not enough data.\nCategorise some transactions first.');
    }

    // X range for reserve line
    final allPts = [...pastDeduped, ...futureRaw];
    final xMin = allPts.map((p) => p.x).reduce((a, b) => a.isBefore(b) ? a : b);
    final xMax = allPts.map((p) => p.x).reduce((a, b) => a.isAfter(b) ? a : b);
    final reserve = [_Pt(xMin, snapshot.minReserve), _Pt(xMax, snapshot.minReserve)];

    // Y bounds
    final allY = [...allPts.map((p) => p.y), snapshot.minReserve];
    final yLo  = allY.reduce(math.min);
    final yHi  = allY.reduce(math.max);
    final span = (yHi - yLo).abs().clamp(1.0, double.infinity);

    final compact = NumberFormat.compactCurrency(
        locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return SfCartesianChart(
      backgroundColor: Colors.transparent,
      plotAreaBorderWidth: 0,
      margin: const EdgeInsets.fromLTRB(0, 4, 8, 0),

      legend: Legend(
        isVisible: true,
        position: LegendPosition.top,
        alignment: ChartAlignment.far,
        overflowMode: LegendItemOverflowMode.wrap,
        textStyle: GoogleFonts.dmSans(
            color: AppColors.textMuted, fontSize: 9, letterSpacing: 0.5),
        iconHeight: 6,
        iconWidth: 14,
      ),

      crosshairBehavior: CrosshairBehavior(
        enable: true,
        activationMode: ActivationMode.singleTap,
        lineType: CrosshairLineType.both,
        lineColor: AppColors.textMuted,
        lineWidth: 0.8,
        lineDashArray: const [4, 3],
      ),

      tooltipBehavior: TooltipBehavior(
        enable: true,
        color: AppColors.surfaceElevated,
        borderColor: AppColors.border,
        borderWidth: 1,
        elevation: 0,
        textStyle: GoogleFonts.dmSans(
            color: AppColors.textPrimary, fontSize: 11),
        format: 'point.x\npoint.y',
      ),

      primaryXAxis: DateTimeAxis(
        dateFormat: DateFormat('d MMM'),
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
            width: 0.5,
            color: AppColors.border.withOpacity(0.4),
            dashArray: const [4, 4]),
        labelStyle: GoogleFonts.dmSans(
            color: AppColors.textMuted, fontSize: 9),
        plotBands: [
          PlotBand(
            start: today,
            end: today.add(const Duration(hours: 20)),
            color: AppColors.warning.withOpacity(0.06),
            borderColor: AppColors.warning.withOpacity(0.50),
            borderWidth: 1,
            text: 'TODAY',
            textStyle: GoogleFonts.dmSans(
                color: AppColors.warning,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0),
            verticalTextAlignment: TextAnchor.start,
            horizontalTextAlignment: TextAnchor.middle,
          ),
        ],
      ),

      primaryYAxis: NumericAxis(
        minimum: yLo - span * 0.15,
        maximum: yHi + span * 0.15,
        axisLine: const AxisLine(width: 0),
        majorTickLines: const MajorTickLines(size: 0),
        majorGridLines: MajorGridLines(
            width: 0.5,
            color: AppColors.border.withOpacity(0.4),
            dashArray: const [4, 4]),
        labelStyle: GoogleFonts.dmSans(
            color: AppColors.textMuted, fontSize: 9),
        numberFormat: compact,
      ),

      series: <CartesianSeries<_Pt, DateTime>>[
        // 1 — Historical balance: solid + gradient area
        SplineAreaSeries<_Pt, DateTime>(
          name: 'Balance',
          dataSource: pastDeduped,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          splineType: SplineType.cardinal,
          color: AppColors.info.withOpacity(0.10),
          borderColor: AppColors.info,
          borderWidth: 2.5,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.info.withOpacity(0.22),
              AppColors.info.withOpacity(0.01),
            ],
          ),
        ),

        // 2 — Forecast: dashed + diamond markers
        if (futureRaw.length > 1)
          SplineSeries<_Pt, DateTime>(
            name: 'Forecast',
            dataSource: futureRaw,
            xValueMapper: (p, _) => p.x,
            yValueMapper: (p, _) => p.y,
            splineType: SplineType.cardinal,
            color: AppColors.primary,
            width: 2.0,
            dashArray: const [8, 5],
            markerSettings: MarkerSettings(
              isVisible: true,
              shape: DataMarkerType.diamond,
              height: 6,
              width: 6,
              color: AppColors.primary,
              borderColor: AppColors.primary,
              borderWidth: 1.5,
            ),
          ),

        // 3 — Min-reserve threshold
        LineSeries<_Pt, DateTime>(
          name: 'Min Reserve',
          dataSource: reserve,
          xValueMapper: (p, _) => p.x,
          yValueMapper: (p, _) => p.y,
          color: AppColors.danger,
          width: 1.5,
          dashArray: const [6, 4],
          markerSettings: const MarkerSettings(isVisible: false),
        ),
      ],
    );
  }

  Widget _emptyState(String msg) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.show_chart_rounded, size: 28, color: AppColors.textMuted),
        const SizedBox(height: 10),
        Text(msg,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 11, height: 1.5)),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════
// _RadarChart — CustomPainter pentagon radar
// Uses resilienceScore since FinancialSnapshotModel has no
// pillar_scores field yet. Swap in PillarScores when ready.
// ═════════════════════════════════════════════════════════════
class _RadarChart extends StatefulWidget {
  final int score;
  const _RadarChart({required this.score});

  @override
  State<_RadarChart> createState() => _RadarChartState();
}

class _RadarChartState extends State<_RadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  // Synthetic pillar approximation from the single resilience score.
  // Replace with real PillarScores.normalized when your DB has it.
  List<double> get _normalized {
    final s = widget.score.toDouble();
    return [
      (s * 0.90).clamp(0, 100),  // Survival Coverage  — tends lower
      (s * 1.00).clamp(0, 100),  // Bill Protection
      (s * 0.85).clamp(0, 100),  // Spending Discipline — usually hardest
      (s * 1.05).clamp(0, 100),  // Income Stability
      (s * 0.80).clamp(0, 100),  // Emergency Fund     — tends lowest
    ];
  }

  static const _labels = [
    'Survival\nCoverage',
    'Bill\nProtection',
    'Spending\nDiscipline',
    'Income\nStability',
    'Emergency\nFund',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _PentagonPainter(
                  normalized: _normalized,
                  labels: _labels,
                  progress: _anim.value),
              child: const SizedBox.expand(),
            ),
          ),
        ),
        // Pillar legend
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
          child: Row(
            children: List.generate(_normalized.length, (i) {
              final v     = _normalized[i];
              final color = v >= 75 ? AppColors.success
                  : v >= 45 ? AppColors.primary
                  : v >= 25 ? AppColors.warning
                  :           AppColors.danger;
              final short = _labels[i].split('\n').first;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(short,
                          style: GoogleFonts.dmSans(
                              color: AppColors.textMuted,
                              fontSize: 8,
                              letterSpacing: 0.2),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 3),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: v / 100,
                          backgroundColor: AppColors.border,
                          valueColor: AlwaysStoppedAnimation(color),
                          minHeight: 3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text('${v.toStringAsFixed(0)}%',
                          style: GoogleFonts.dmSans(
                              color: color,
                              fontSize: 9,
                              fontWeight: FontWeight.w700),
                          textAlign: TextAlign.center),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _PentagonPainter
// ═════════════════════════════════════════════════════════════
class _PentagonPainter extends CustomPainter {
  final List<double> normalized;
  final List<String> labels;
  final double       progress;

  static const int    _n       = 5;
  static const double _rings   = 4;
  static const double _pad     = 26.0;

  const _PentagonPainter({
    required this.normalized,
    required this.labels,
    required this.progress,
  });

  double _angle(int i) => (2 * math.pi * i / _n) - math.pi / 2;

  Offset _v(Offset c, double r, int i) {
    final a = _angle(i);
    return Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final c    = Offset(size.width / 2, size.height / 2);
    final maxR = (math.min(size.width, size.height) / 2) - _pad;

    _grid(canvas, c, maxR);
    _spokes(canvas, c, maxR);
    _ringPcts(canvas, c, maxR);
    _polygon(canvas, c, maxR);
    _dots(canvas, c, maxR);
    _vertexLabels(canvas, c, maxR);
  }

  void _grid(Canvas canvas, Offset c, double maxR) {
    final p = Paint()
      ..color = AppColors.border.withOpacity(0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    for (int ring = 1; ring <= _rings; ring++) {
      final r    = maxR * ring / _rings;
      final path = Path();
      for (int i = 0; i < _n; i++) {
        final v = _v(c, r, i);
        i == 0 ? path.moveTo(v.dx, v.dy) : path.lineTo(v.dx, v.dy);
      }
      path.close();
      canvas.drawPath(path, p);
    }
  }

  void _spokes(Canvas canvas, Offset c, double maxR) {
    final p = Paint()
      ..color = AppColors.border.withOpacity(0.55)
      ..strokeWidth = 0.8;
    for (int i = 0; i < _n; i++) {
      canvas.drawLine(c, _v(c, maxR, i), p);
    }
  }

  void _ringPcts(Canvas canvas, Offset c, double maxR) {
    const pcts = ['25', '50', '75', '100'];
    for (int ring = 1; ring <= _rings; ring++) {
      final r = maxR * ring / _rings;
      final v = _v(c, r, 1); // right spoke
      _text(canvas, '${pcts[ring - 1]}%', v + const Offset(2, -5),
          _ts(AppColors.textMuted, 7), 24);
    }
  }

  void _polygon(Canvas canvas, Offset c, double maxR) {
    if (normalized.length < _n) return;
    final path = Path();
    for (int i = 0; i < _n; i++) {
      final frac = ((normalized[i] / 100.0) * progress).clamp(0.0, 1.0);
      final v    = _v(c, maxR * frac, i);
      i == 0 ? path.moveTo(v.dx, v.dy) : path.lineTo(v.dx, v.dy);
    }
    path.close();
    canvas.drawPath(path,
        Paint()..color = AppColors.primary.withOpacity(0.14)..style = PaintingStyle.fill);
    canvas.drawPath(path,
        Paint()
          ..color = AppColors.primary.withOpacity(0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeJoin = StrokeJoin.round);
  }

  void _dots(Canvas canvas, Offset c, double maxR) {
    if (normalized.length < _n) return;
    for (int i = 0; i < _n; i++) {
      final frac = ((normalized[i] / 100.0) * progress).clamp(0.0, 1.0);
      final v    = _v(c, maxR * frac, i);
      canvas.drawCircle(v, 4,
          Paint()..color = AppColors.primary..style = PaintingStyle.fill);
      canvas.drawCircle(v, 2.5,
          Paint()..color = AppColors.surface..style = PaintingStyle.fill);
    }
  }

  void _vertexLabels(Canvas canvas, Offset c, double maxR) {
    for (int i = 0; i < _n && i < labels.length; i++) {
      final a      = _angle(i);
      final labelR = maxR + _pad - 4;
      final anchor = Offset(c.dx + labelR * math.cos(a),
          c.dy + labelR * math.sin(a));
      // Name
      _text(canvas, labels[i], anchor + const Offset(0, -8),
          _ts(AppColors.textSecondary, 8.5), 56, center: true);
      // Percent (appears as animation progresses)
      if (progress > 0.3) {
        _text(canvas, '${normalized[i].toStringAsFixed(0)}%',
            anchor + const Offset(0, 6),
            _ts(AppColors.primary, 9.5,
                weight: FontWeight.w700),
            36, center: true);
      }
    }
  }

  TextStyle _ts(Color color, double size, {FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.dmSans(color: color, fontSize: size, fontWeight: weight, height: 1.3);

  void _text(Canvas canvas, String s, Offset pos, TextStyle style, double maxW,
      {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: style),
      textDirection: ui.TextDirection.ltr,
      textAlign: center ? TextAlign.center : TextAlign.left,
    )..layout(maxWidth: maxW);
    final offset = center
        ? Offset(pos.dx - tp.width / 2, pos.dy - tp.height / 2)
        : pos;
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_PentagonPainter old) =>
      old.progress != progress || old.normalized != normalized;
}

// ═════════════════════════════════════════════════════════════
// UI helpers
// ═════════════════════════════════════════════════════════════
class _Shimmer extends StatefulWidget {
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double>   _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _a = Tween<double>(begin: -1.5, end: 2.5)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut));
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          begin: Alignment(_a.value - 1, 0),
          end: Alignment(_a.value, 0),
          colors: const [
            AppColors.surface,
            AppColors.surfaceElevated,
            AppColors.surface,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    ),
  );
}

class _ErrState extends StatelessWidget {
  final VoidCallback onRetry;
  const _ErrState({required this.onRetry});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.wifi_off_rounded, size: 24, color: AppColors.textMuted),
        const SizedBox(height: 10),
        Text('Failed to load chart data',
            style: GoogleFonts.dmSans(
                color: AppColors.textMuted, fontSize: 12)),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(6)),
            child: Text('Retry',
                style: GoogleFonts.dmSans(
                    color: AppColors.textPrimary, fontSize: 12)),
          ),
        ),
      ],
    ),
  );
}