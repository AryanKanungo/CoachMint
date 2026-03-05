import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/theme.dart';

// ════════════════════════════════════════════════════════════════
// Currency formatter
// ════════════════════════════════════════════════════════════════

final _inrFormatter = NumberFormat.currency(
  locale: 'en_IN',
  symbol: '₹',
  decimalDigits: 0,
);

String formatInr(double amount) => _inrFormatter.format(amount);

// ════════════════════════════════════════════════════════════════
// CMCard — base card
// Sharp corners, subtle border, no shadows
// ════════════════════════════════════════════════════════════════

class CMCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Color? borderColor;

  const CMCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor ?? AppTheme.border,
            width: 1,
          ),
        ),
        child: child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// CMButton — primary action button
// ════════════════════════════════════════════════════════════════

class CMButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;
  final IconData? icon;

  const CMButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outline = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    if (outline) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        child: _child,
      );
    }
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      child: loading
          ? const SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: AppTheme.surface,
        ),
      )
          : _child,
    );
  }

  Widget get _child => icon != null
      ? Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 16),
      const SizedBox(width: 8),
      Text(label),
    ],
  )
      : Text(label);
}

// ════════════════════════════════════════════════════════════════
// ResilienceScoreBadge
// Refined arc-style, no thick stroke, clean label
// ════════════════════════════════════════════════════════════════

class ResilienceScoreBadge extends StatelessWidget {
  final int score;
  final String label;
  final double size;

  const ResilienceScoreBadge({
    super.key,
    required this.score,
    required this.label,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final color = resilienceColor(score);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Track
            SizedBox(
              height: size,
              width: size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: 2,
                color: AppTheme.border,
              ),
            ),
            // Fill
            SizedBox(
              height: size,
              width: size,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 3,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: GoogleFonts.dmSans(
                    fontSize: size * 0.30,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  'of 100',
                  style: GoogleFonts.dmSans(
                    fontSize: size * 0.10,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textMuted,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: color.withOpacity(0.4)),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SPDDisplay — Safe to Spend Per Day
// Large editorial number treatment
// ════════════════════════════════════════════════════════════════

class SPDDisplay extends StatelessWidget {
  final double spd;
  final double survivalDays;

  const SPDDisplay({
    super.key,
    required this.spd,
    required this.survivalDays,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = spd < 0;
    final color = isNegative ? AppTheme.danger : AppTheme.brand;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SAFE TO SPEND TODAY',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMuted,
            letterSpacing: 1.6,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '₹',
              style: GoogleFonts.dmSans(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: color.withOpacity(0.7),
                height: 1,
              ),
            ),
            const SizedBox(width: 2),
            Text(
              NumberFormat('#,##,###').format(spd.abs()),
              style: GoogleFonts.dmSans(
                fontSize: 52,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: -2.5,
                height: 1,
              ),
            ),
            if (isNegative) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: AppTheme.danger.withOpacity(0.3)),
                ),
                child: Text(
                  'OVERSPENT',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: survivalDays < 7
                    ? AppTheme.danger
                    : AppTheme.textMuted,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '${survivalDays.toStringAsFixed(1)} survival days remaining',
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SeverityChip — clean label, no background fill
// ════════════════════════════════════════════════════════════════

class SeverityChip extends StatelessWidget {
  final String severity;

  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (severity) {
      case 'critical':
        color = AppTheme.danger;
        break;
      case 'warning':
        color = AppTheme.warning;
        break;
      case 'positive':
        color = AppTheme.success;
        break;
      default:
        color = AppTheme.info;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        severity.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// TrendBadge — income trend indicator
// ════════════════════════════════════════════════════════════════

class TrendBadge extends StatelessWidget {
  final String trend;
  const TrendBadge({super.key, required this.trend});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String label;
    switch (trend) {
      case 'surge':
        icon = Icons.north_east_rounded;
        color = AppTheme.success;
        label = 'Income up';
        break;
      case 'dip':
        icon = Icons.south_east_rounded;
        color = AppTheme.danger;
        label = 'Income dip';
        break;
      default:
        icon = Icons.east_rounded;
        color = AppTheme.textSecondary;
        label = 'Stable';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        border: Border.all(color: color.withOpacity(0.25)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SectionLabel — uppercase spaced label for section headers
// Replaces verbose headers with tight, professional labels
// ════════════════════════════════════════════════════════════════

class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel({super.key, required this.text, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          text.toUpperCase(),
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: AppTheme.textMuted,
            letterSpacing: 1.6,
          ),
        ),
        if (trailing != null) ...[
          const Spacer(),
          trailing!,
        ],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// StatRow — compact two-value comparison row
// Used for "before vs after" in simulate, and dashboard stats
// ════════════════════════════════════════════════════════════════

class StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final String? subValue;

  const StatRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.subValue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Spacer(),
          if (subValue != null) ...[
            Text(
              subValue!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w400,
                decoration: TextDecoration.lineThrough,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 12, color: AppTheme.textMuted),
            const SizedBox(width: 8),
          ],
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: valueColor ?? AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// RiskBanner — horizontal alert strip
// ════════════════════════════════════════════════════════════════

class RiskBanner extends StatelessWidget {
  final String message;
  final String severity;   // critical | warning | advisory
  final VoidCallback? onTap;

  const RiskBanner({
    super.key,
    required this.message,
    required this.severity,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = severity == 'critical'
        ? AppTheme.danger
        : severity == 'warning'
        ? AppTheme.warning
        : AppTheme.info;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          border: Border(
            left: BorderSide(color: color, width: 2),
            top: BorderSide(color: color.withOpacity(0.2)),
            right: BorderSide(color: color.withOpacity(0.2)),
            bottom: BorderSide(color: color.withOpacity(0.2)),
          ),
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(6),
            bottomRight: Radius.circular(6),
          ),
        ),
        child: Row(
          children: [
            Icon(
              severity == 'critical'
                  ? Icons.error_outline_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right, color: color.withOpacity(0.6), size: 16),
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// LoadingShimmer
// ════════════════════════════════════════════════════════════════

class LoadingShimmer extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.height = 60,
    this.width,
    this.borderRadius = 6,
  });

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          height: widget.height,
          width: widget.width ?? double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            gradient: LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value, 0),
              colors: const [
                AppTheme.surfaceCard,
                AppTheme.surfaceElevated,
                AppTheme.surfaceCard,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════
// EmptyState
// ════════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(icon, size: 28, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              CMButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// Divider with optional label — for section breaks
// ════════════════════════════════════════════════════════════════

class CMDivider extends StatelessWidget {
  final String? label;
  const CMDivider({super.key, this.label});

  @override
  Widget build(BuildContext context) {
    if (label == null) {
      return const Divider(color: AppTheme.border, thickness: 1, height: 1);
    }
    return Row(
      children: [
        const Expanded(child: Divider(color: AppTheme.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label!,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: AppTheme.textMuted,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppTheme.border, thickness: 1)),
      ],
    );
  }
}