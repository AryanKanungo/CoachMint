// lib/widgets/radar_chart.dart
// ignore_for_file: constant_identifier_names

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/theme.dart'; // AppTheme

// ─────────────────────────────────────────────────────────────
// PillarScores contract (must match your frozen model exactly):
//   .normalized → List<double>  (5 values, each 0–100)
//   .labels     → List<String>  (5 pillar names, may contain \n)
// ─────────────────────────────────────────────────────────────

// ═════════════════════════════════════════════════════════════
// ResilienceRadar — animated pentagon radar chart
// ═════════════════════════════════════════════════════════════
class ResilienceRadar extends StatefulWidget {
  /// Must expose .normalized (List<double> 0–100) and .labels
  final dynamic pillarScores; // typed as dynamic → swap to PillarScores
  final int resilienceScore;

  const ResilienceRadar({
    super.key,
    required this.pillarScores,
    required this.resilienceScore,
  });

  @override
  State<ResilienceRadar> createState() => _ResilienceRadarState();
}

class _ResilienceRadarState extends State<ResilienceRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final normalized = (widget.pillarScores.normalized as List)
        .map((v) => (v as num).toDouble())
        .toList();
    final labels = (widget.pillarScores.labels as List)
        .map((l) => l.toString())
        .toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Radar canvas ──────────────────────────────────────
        AspectRatio(
          aspectRatio: 1.1,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: _RadarPainter(
                normalized: normalized,
                labels: labels,
                progress: _anim.value,
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // ── Pillar legend bar ─────────────────────────────────
        _PillarLegend(normalized: normalized, labels: labels),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _RadarPainter
// ═════════════════════════════════════════════════════════════
class _RadarPainter extends CustomPainter {
  final List<double> normalized; // 5 values 0–100
  final List<String> labels;
  final double       progress;   // 0–1 animation

  static const int    _sides    = 5;
  static const double _rings    = 4; // concentric ring count
  static const double _labelPad = 24.0;

  _RadarPainter({
    required this.normalized,
    required this.labels,
    required this.progress,
  });

  // Pentagon vertex angle: start at top (–90°)
  double _vertexAngle(int i) =>
      (2 * math.pi * i / _sides) - math.pi / 2;

  Offset _vertex(Offset center, double radius, int i) {
    final a = _vertexAngle(i);
    return Offset(center.dx + radius * math.cos(a),
        center.dy + radius * math.sin(a));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Leave room around edges for labels
    final maxR = (math.min(size.width, size.height) / 2) - _labelPad;

    _drawGrid(canvas, center, maxR);
    _drawSpokes(canvas, center, maxR);
    _drawRingLabels(canvas, center, maxR);
    _drawDataPolygon(canvas, center, maxR);
    _drawVertexDots(canvas, center, maxR);
    _drawLabels(canvas, center, maxR);
  }

  // ── Grid rings ────────────────────────────────────────────
  void _drawGrid(Canvas canvas, Offset center, double maxR) {
    final paint = Paint()
      ..color = AppTheme.border.withOpacity(0.50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (int ring = 1; ring <= _rings; ring++) {
      final r = maxR * ring / _rings;
      final path = Path();
      for (int i = 0; i < _sides; i++) {
        final v = _vertex(center, r, i);
        i == 0 ? path.moveTo(v.dx, v.dy) : path.lineTo(v.dx, v.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  // ── Spokes ────────────────────────────────────────────────
  void _drawSpokes(Canvas canvas, Offset center, double maxR) {
    final paint = Paint()
      ..color = AppTheme.border.withOpacity(0.50)
      ..strokeWidth = 0.8;

    for (int i = 0; i < _sides; i++) {
      final v = _vertex(center, maxR, i);
      canvas.drawLine(center, v, paint);
    }
  }

  // ── Ring % labels (right-center spoke) ───────────────────
  void _drawRingLabels(Canvas canvas, Offset center, double maxR) {
    const pcts = ['25', '50', '75', '100'];
    for (int ring = 1; ring <= _rings; ring++) {
      final r = maxR * ring / _rings;
      // Right-center spoke is index 1 (≈ right on pentagon)
      final v = _vertex(center, r, 1);
      _drawText(
        canvas,
        '${pcts[ring - 1]}%',
        v + const Offset(3, -6),
        GoogleFonts.dmSans(
            color: AppTheme.textMuted, fontSize: 7, letterSpacing: 0.3),
        maxWidth: 28,
      );
    }
  }

  // ── Data polygon ──────────────────────────────────────────
  void _drawDataPolygon(Canvas canvas, Offset center, double maxR) {
    if (normalized.length < _sides) return;

    final path = Path();
    for (int i = 0; i < _sides; i++) {
      final frac = ((normalized[i] / 100.0) * progress).clamp(0.0, 1.0);
      final v    = _vertex(center, maxR * frac, i);
      i == 0 ? path.moveTo(v.dx, v.dy) : path.lineTo(v.dx, v.dy);
    }
    path.close();

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.brand.withOpacity(0.15)
        ..style = PaintingStyle.fill,
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = AppTheme.brand.withOpacity(0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round,
    );
  }

  // ── Vertex dots ───────────────────────────────────────────
  void _drawVertexDots(Canvas canvas, Offset center, double maxR) {
    if (normalized.length < _sides) return;

    for (int i = 0; i < _sides; i++) {
      final frac = ((normalized[i] / 100.0) * progress).clamp(0.0, 1.0);
      final v    = _vertex(center, maxR * frac, i);

      // Outer dot
      canvas.drawCircle(v, 4,
          Paint()..color = AppTheme.brand..style = PaintingStyle.fill);
      // Inner dot
      canvas.drawCircle(v, 2.5,
          Paint()..color = AppTheme.surfaceCard..style = PaintingStyle.fill);
    }
  }

  // ── Vertex labels ─────────────────────────────────────────
  void _drawLabels(Canvas canvas, Offset center, double maxR) {
    for (int i = 0; i < _sides && i < labels.length; i++) {
      final angle   = _vertexAngle(i);
      final labelR  = maxR + _labelPad - 4;
      final anchor  = Offset(
        center.dx + labelR * math.cos(angle),
        center.dy + labelR * math.sin(angle),
      );

      // Pillar name
      final name = labels[i];
      _drawText(
        canvas,
        name,
        anchor + const Offset(0, -9),
        GoogleFonts.dmSans(
            color: AppTheme.textSecondary, fontSize: 9, height: 1.3),
        maxWidth: 60,
        centered: true,
      );

      // Normalized percent
      if (progress > 0.3) {
        final pct = '${normalized[i].toStringAsFixed(0)}%';
        _drawText(
          canvas,
          pct,
          anchor + const Offset(0, 5),
          GoogleFonts.dmSans(
              color: AppTheme.brand,
              fontSize: 10,
              fontWeight: FontWeight.w700),
          maxWidth: 40,
          centered: true,
        );
      }
    }
  }

  // ── Text helper ───────────────────────────────────────────
  void _drawText(
      Canvas canvas,
      String text,
      Offset position,
      TextStyle style, {
        double maxWidth = 80,
        bool centered = false,
      }) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: centered ? TextAlign.center : TextAlign.left,
    )..layout(maxWidth: maxWidth);

    final offset = centered
        ? Offset(position.dx - tp.width / 2, position.dy - tp.height / 2)
        : position;
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(_RadarPainter old) =>
      old.progress != progress ||
          old.normalized != normalized;
}

// ═════════════════════════════════════════════════════════════
// _PillarLegend — 5-column progress bars below the radar
// ═════════════════════════════════════════════════════════════
class _PillarLegend extends StatelessWidget {
  final List<double> normalized;
  final List<String> labels;

  const _PillarLegend({required this.normalized, required this.labels});

  Color _barColor(double v) {
    if (v >= 75) return AppTheme.success;
    if (v >= 45) return AppTheme.brand;
    if (v >= 25) return AppTheme.warning;
    return AppTheme.danger;
  }

  // Short label: first word before \n or space
  String _short(String label) =>
      label.split(RegExp(r'[\n ]')).first;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        math.min(normalized.length, labels.length),
            (i) {
          final v     = normalized[i].clamp(0.0, 100.0);
          final color = _barColor(v);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _short(labels[i]),
                    style: GoogleFonts.dmSans(
                        color: AppTheme.textMuted,
                        fontSize: 8,
                        letterSpacing: 0.3),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: v / 100,
                      backgroundColor: AppTheme.border,
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${v.toStringAsFixed(0)}%',
                    style: GoogleFonts.dmSans(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
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