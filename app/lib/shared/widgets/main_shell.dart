import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/supabase/realtime_service.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = [
    _Tab(path: '/dashboard', icon: Icons.home_rounded,                label: 'Home'),
    _Tab(path: '/alerts',    icon: Icons.notifications_rounded,       label: 'Alerts'),
    _Tab(path: '/bills',     icon: Icons.receipt_long_rounded,        label: 'Bills'),
    _Tab(path: '/goals',     icon: Icons.flag_rounded,                label: 'Goals'),
    _Tab(path: '/welfare',   icon: Icons.volunteer_activism_rounded,  label: 'Welfare'),
  ];

  int _indexFromLocation(String loc) {
    for (int i = 0; i < _tabs.length; i++) {
      if (loc.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc          = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexFromLocation(loc);
    final unreadAlerts = ref.watch(unreadAlertsCountProvider).value ?? 0;
    final uncatCount   = ref.watch(uncategorizedCountProvider).value ?? 0;

    return Scaffold(
      body: Stack(
        children: [
          child,
          // Floating "categorize" badge — only shows when there are uncategorized txns
          if (uncatCount > 0)
            Positioned(
              right: 16,
              bottom: 76,
              child: GestureDetector(
                onTap: () => context.push('/categorize'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.warning,
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                          color: AppTheme.warning.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.label_rounded,
                          color: AppTheme.surface, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '$uncatCount to categorize',
                        style: const TextStyle(
                            color: AppTheme.surface,
                            fontSize: 12,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppTheme.surfaceCard,
          border: Border(top: BorderSide(color: AppTheme.border)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 60,
            child: Row(
              children: List.generate(_tabs.length, (i) {
                final tab    = _tabs[i];
                final active = i == currentIndex;
                final badge  = tab.path == '/alerts' ? unreadAlerts : 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => context.go(tab.path),
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: active
                                    ? AppTheme.brand.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(tab.icon,
                                  size: 22,
                                  color: active
                                      ? AppTheme.brand
                                      : AppTheme.textMuted),
                            ),
                            if (badge > 0)
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  decoration: const BoxDecoration(
                                      color: AppTheme.danger,
                                      shape: BoxShape.circle),
                                  child: Text(
                                    badge > 9 ? '9+' : '$badge',
                                    style: const TextStyle(
                                        fontSize: 9,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: TextStyle(
                            fontSize: 10,
                            color: active ? AppTheme.brand : AppTheme.textMuted,
                            fontWeight:
                            active ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData icon;
  final String label;
  const _Tab({required this.path, required this.icon, required this.label});
}