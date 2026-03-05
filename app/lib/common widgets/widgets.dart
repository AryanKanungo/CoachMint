import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
// CMCard — base card with mint border
// ════════════════════════════════════════════════════════════════

class CMCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;

  const CMCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor ?? AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border),
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
        height: 20,
        width: 20,
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
      Icon(icon, size: 18),
      const SizedBox(width: 8),
      Text(label),
    ],
  )
      : Text(label);
}

// ════════════════════════════════════════════════════════════════
// ResilienceScoreBadge
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
            SizedBox(
              height: size,
              width: size,
              child: CircularProgressIndicator(
                value: score / 100,
                strokeWidth: 6,
                backgroundColor: AppTheme.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
            Text(
              '$score',
              style: TextStyle(
                fontSize: size * 0.28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SPDDisplay — Safe to Spend Per Day hero widget
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
          'Safe to Spend Today',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatInr(spd.abs()),
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: color,
                fontFamily: 'Syne',
                letterSpacing: -1,
              ),
            ),
            if (isNegative)
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  'OVERSPENT',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.danger,
                  ),
                ),
              ),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.bolt, size: 14, color: AppTheme.textMuted),
            const SizedBox(width: 4),
            Text(
              '${survivalDays.toStringAsFixed(0)} days until income risk',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════
// SeverityChip
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
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
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
        icon = Icons.trending_up;
        color = AppTheme.success;
        label = 'Income up';
        break;
      case 'dip':
        icon = Icons.trending_down;
        color = AppTheme.danger;
        label = 'Income dip';
        break;
      default:
        icon = Icons.trending_flat;
        color = AppTheme.textSecondary;
        label = 'Stable';
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12, color: color, fontWeight: FontWeight.w600)),
      ],
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
    this.borderRadius = 12,
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
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1, end: 2).animate(
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
              begin: Alignment(-1 + _animation.value, 0),
              end: Alignment(1 + _animation.value, 0),
              colors: const [
                AppTheme.surfaceCard,
                AppTheme.surfaceElevated,
                AppTheme.surfaceCard,
              ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.border),
              ),
              child: Icon(icon, size: 32, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 16),
            Text(title,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.textMuted),
                textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              CMButton(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      ),
    );
  }
}