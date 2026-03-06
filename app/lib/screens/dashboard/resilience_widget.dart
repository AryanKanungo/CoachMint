import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../utils/colors.dart';
import '../../../utils/theme.dart';

class ResilienceWidget extends StatelessWidget {
  final int score;
  const ResilienceWidget({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final scoreColor = AppTheme.resilienceColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // ── Label ──────────────────────────────────────────
          Text(
            'RESILIENCE SCORE',
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 20),

          // ── Animated Score Ring ────────────────────────────
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: score),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return SizedBox(
                width: 160,
                height: 160,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background ring
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 2,
                        color: AppColors.border,
                      ),
                    ),
                    // Score arc
                    SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: value / 100,
                        strokeWidth: 4,
                        backgroundColor: Colors.transparent,
                        valueColor:
                            AlwaysStoppedAnimation(scoreColor),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    // Glow overlay
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: scoreColor.withOpacity(0.12),
                            blurRadius: 30,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    // Score number
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$value',
                          style: GoogleFonts.dmSans(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: scoreColor,
                            height: 1,
                            letterSpacing: -2,
                          ),
                        ),
                        Text(
                          'of 100',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // ── Score label badge ─────────────────────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: scoreColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              border: Border.all(color: scoreColor.withOpacity(0.35)),
            ),
            child: Text(
              _scoreLabel(score),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: scoreColor,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _scoreLabel(int score) {
    if (score >= 70) return 'STRONG';
    if (score >= 40) return 'MODERATE';
    return 'AT RISK';
  }
}
