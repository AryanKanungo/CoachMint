// lib/widgets/togglable_engine_chart.dart
// ignore_for_file: constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_models.dart';  // FinancialSnapshotModel
import '../utils/theme.dart';         // AppTheme
import 'runway_chart.dart';
import 'radar_chart.dart';

// ═════════════════════════════════════════════════════════════
// TogglableEngineChart
//
// Drop this single widget into your DashboardScreen:
//
//   TogglableEngineChart(
//     snapshot: payload.snapshot,
//     historicalSeries: payload.historicalSeries,
//     predictions: payload.predictions,
//     pillarScores: payload.snapshot.pillarScores, // or wherever it lives
//   )
//
// ═════════════════════════════════════════════════════════════
class TogglableEngineChart extends StatefulWidget {
  final FinancialSnapshotModel           snapshot;
  final List<MapEntry<DateTime, double>> historicalSeries;
  final List<dynamic>                    predictions;  // List<Prediction>
  /// Pass snapshot.pillarScores (or equivalent). Nullable —
  /// if null, the RADAR tab shows a graceful placeholder.
  final dynamic                          pillarScores; // PillarScores?

  const TogglableEngineChart({
    super.key,
    required this.snapshot,
    required this.historicalSeries,
    required this.predictions,
    this.pillarScores,
  });

  @override
  State<TogglableEngineChart> createState() => _TogglableEngineChartState();
}

class _TogglableEngineChartState extends State<TogglableEngineChart> {
  bool _showRunway = true;

  void _toggle(bool runway) {
    if (_showRunway == runway) return;
    HapticFeedback.selectionClick();
    setState(() => _showRunway = runway);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header: title + toggle ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 14, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: tag + subtitle
              Expanded(child: _TitleBlock(showRunway: _showRunway)),
              const SizedBox(width: 12),
              // Right: pill toggle
              _PillToggle(
                  showRunway: _showRunway, onToggle: _toggle),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── Chart area: AnimatedCrossFade ──────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
          child: AnimatedCrossFade(
            duration: const Duration(milliseconds: 380),
            reverseDuration: const Duration(milliseconds: 280),
            crossFadeState: _showRunway
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            // Keep both children at fixed height so layout doesn't jump
            layoutBuilder: (top, topKey, bottom, bottomKey) => Stack(
              children: [
                Positioned.fill(
                    key: bottomKey,
                    child: Align(
                        alignment: Alignment.topCenter, child: bottom)),
                Positioned.fill(
                    key: topKey,
                    child: Align(
                        alignment: Alignment.topCenter, child: top)),
              ],
            ),
            firstChild: SizedBox(
              height: 260,
              child: RunwayChart(
                snapshot: widget.snapshot,
                historicalSeries: widget.historicalSeries,
                predictions: widget.predictions,
              ),
            ),
            secondChild: SizedBox(
              height: 260,
              child: widget.pillarScores != null
                  ? Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 12),
                child: ResilienceRadar(
                  pillarScores: widget.pillarScores,
                  resilienceScore: widget.snapshot.resilienceScore,
                ),
              )
                  : _RadarPlaceholder(),
            ),
          ),
        ),

        const SizedBox(height: 14),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _TitleBlock
// ═════════════════════════════════════════════════════════════
class _TitleBlock extends StatelessWidget {
  final bool showRunway;
  const _TitleBlock({required this.showRunway});

  @override
  Widget build(BuildContext context) {
    final tag      = showRunway ? 'FINANCIAL RUNWAY' : 'RESILIENCE RADAR';
    final subtitle = showRunway
        ? 'Cash survival & forecast vs. reserve threshold'
        : 'Five-pillar financial health breakdown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Cyan tag label
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.brand.withOpacity(0.08),
            border: Border.all(color: AppTheme.brand.withOpacity(0.30)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: Text(
              tag,
              key: ValueKey(tag),
              style: GoogleFonts.dmSans(
                color: AppTheme.brand,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 5),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: Text(
            subtitle,
            key: ValueKey(subtitle),
            style: GoogleFonts.dmSans(
                color: AppTheme.textMuted, fontSize: 11, height: 1.4),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _PillToggle — RUNWAY / RADAR animated pill
// ═════════════════════════════════════════════════════════════
class _PillToggle extends StatelessWidget {
  final bool               showRunway;
  final void Function(bool) onToggle;
  const _PillToggle({required this.showRunway, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Btn(
            label: 'RUNWAY',
            active: showRunway,
            activeColor: AppTheme.info,    // blue for runway
            onTap: () => onToggle(true),
          ),
          const SizedBox(width: 2),
          _Btn(
            label: 'RADAR',
            active: !showRunway,
            activeColor: AppTheme.brand,   // green for radar
            onTap: () => onToggle(false),
          ),
        ],
      ),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final bool   active;
  final Color  activeColor;
  final VoidCallback onTap;

  const _Btn({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? activeColor.withOpacity(0.16) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: active ? activeColor.withOpacity(0.55) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: active ? activeColor : AppTheme.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// _RadarPlaceholder — shown when pillarScores == null
// ═════════════════════════════════════════════════════════════
class _RadarPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.border),
            ),
            child: const Icon(Icons.radar_rounded,
                size: 28, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 12),
          Text(
            'Pillar scores not available',
            style: GoogleFonts.dmSans(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Engine needs at least 7 days of data',
            style: GoogleFonts.dmSans(
                color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}