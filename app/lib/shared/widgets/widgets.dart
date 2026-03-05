import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../app/theme.dart';

// ── Currency formatter ────────────────────────────────────────────────────────
final _inrFormatter =
NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
String formatInr(double amount) => _inrFormatter.format(amount);

// ── CMCard ────────────────────────────────────────────────────────────────────
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
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor ?? AppTheme.border),
        ),
        child: child,
      ),
    );
  }
}

// ── CMButton ──────────────────────────────────────────────────────────────────
class CMButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final bool outline;
  final IconData? icon;
  final Color? color;

  const CMButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.outline = false,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = loading
        ? const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppTheme.surface))
        : icon != null
        ? Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18),
        const SizedBox(width: 8),
        Text(label),
      ],
    )
        : Text(label);

    if (outline) {
      return OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color ?? AppTheme.brand,
          side: BorderSide(color: color ?? AppTheme.brand),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: child,
      );
    }
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color ?? AppTheme.brand,
        foregroundColor: AppTheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: child,
    );
  }
}

// ── ResilienceScoreBadge ──────────────────────────────────────────────────────
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
                  color: color),
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
                letterSpacing: 0.8),
          ),
        ),
      ],
    );
  }
}

// ── SPDDisplay ────────────────────────────────────────────────────────────────
class SPDDisplay extends StatelessWidget {
  final double spd;
  final double survivalDays;
  const SPDDisplay({super.key, required this.spd, required this.survivalDays});

  @override
  Widget build(BuildContext context) {
    final isNeg = spd < 0;
    final color = isNeg ? AppTheme.danger : AppTheme.brand;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Safe to Spend Today',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(
            formatInr(spd.abs()),
            style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: -1),
          ),
          if (isNeg)
            const Padding(
              padding: EdgeInsets.only(bottom: 5, left: 4),
              child: Text('OVERSPENT',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.danger)),
            ),
        ]),
        Row(children: [
          const Icon(Icons.bolt, size: 13, color: AppTheme.textMuted),
          const SizedBox(width: 4),
          Text(
            '${survivalDays.toStringAsFixed(0)} days coverage',
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
        ]),
      ],
    );
  }
}

// ── SeverityChip ──────────────────────────────────────────────────────────────
class SeverityChip extends StatelessWidget {
  final String severity;
  const SeverityChip({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (severity) {
      case 'critical': color = AppTheme.danger;  break;
      case 'warning':  color = AppTheme.warning; break;
      case 'positive': color = AppTheme.success; break;
      default:         color = AppTheme.info;
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
            letterSpacing: 0.5),
      ),
    );
  }
}

// ── TrendBadge ────────────────────────────────────────────────────────────────
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

// ── LoadingShimmer ────────────────────────────────────────────────────────────
class LoadingShimmer extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  const LoadingShimmer(
      {super.key, this.height = 60, this.width, this.borderRadius = 12});

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    _anim = Tween<double>(begin: -1, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width ?? double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.borderRadius),
          gradient: LinearGradient(
            begin: Alignment(-1 + _anim.value, 0),
            end: Alignment(1 + _anim.value, 0),
            colors: const [
              AppTheme.surfaceCard,
              AppTheme.surfaceElevated,
              AppTheme.surfaceCard
            ],
          ),
        ),
      ),
    );
  }
}

// ── EmptyState ────────────────────────────────────────────────────────────────
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
            Text(
              subtitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppTheme.textMuted),
              textAlign: TextAlign.center,
            ),
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

// ── SupabaseStatusBanner ──────────────────────────────────────────────────────
class SupabaseStatusBanner extends StatelessWidget {
  const SupabaseStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.brand.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
                color: AppTheme.brand, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          const Text(
            'Supabase connected',
            style: TextStyle(
                fontSize: 11,
                color: AppTheme.brand,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}