import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/supabase/realtime_service.dart';
import '../../../shared/models/models.dart';
import '../../../shared/repositories/repositories.dart';
import '../../../shared/widgets/widgets.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsStream = ref.watch(alertsRealtimeProvider);

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Alerts'),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(alertRepoProvider).markAllRead();
            },
            child: const Text('Mark all read',
                style: TextStyle(color: AppTheme.brand, fontSize: 13)),
          ),
        ],
      ),
      body: alertsStream.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.brand),
        ),
        error: (_, __) => const Center(
          child: Text('Failed to load alerts',
              style: TextStyle(color: AppTheme.textMuted)),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'All clear!',
              subtitle:
              'No alerts right now. CoachMint is watching your finances.',
            );
          }
          final alerts = rows.map((e) => AlertModel.fromMap(e)).toList();
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: alerts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _AlertCard(
              alert: alerts[i],
              onTap: () async {
                await ref.read(alertRepoProvider).markRead(alerts[i].id);
              },
            ),
          );
        },
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback onTap;

  const _AlertCard({required this.alert, required this.onTap});

  Color get _accentColor {
    switch (alert.severity) {
      case 'critical':
        return AppTheme.danger;
      case 'warning':
        return AppTheme.warning;
      case 'positive':
        return AppTheme.success;
      default:
        return AppTheme.info;
    }
  }

  IconData get _alertIcon {
    switch (alert.alertType) {
      case 'CRITICAL':
        return Icons.warning_amber_rounded;
      case 'BILL_RISK':
        return Icons.receipt_long_rounded;
      case 'OVERSPEND':
        return Icons.trending_up_rounded;
      case 'INCOME_DIP':
        return Icons.trending_down_rounded;
      case 'LOW_SURVIVAL':
        return Icons.hourglass_bottom_rounded;
      case 'GOAL_NUDGE':
        return Icons.flag_rounded;
      case 'WEEKLY_SUMMARY':
        return Icons.calendar_view_week_rounded;
      case 'POSITIVE':
        return Icons.emoji_events_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _accentColor;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: alert.isRead ? 0.6 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alert.isRead ? AppTheme.border : color.withOpacity(0.4),
              width: alert.isRead ? 1 : 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_alertIcon, color: color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SeverityChip(severity: alert.severity),
                  if (!alert.isRead) ...[
                    const SizedBox(width: 8),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // XAI message
              Text(
                alert.message,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _timeAgo(alert.triggeredAt),
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}