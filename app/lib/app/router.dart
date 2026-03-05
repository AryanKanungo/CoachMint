import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/screens/splash_screen.dart';
import '../features/auth/screens/phone_screen.dart';
import '../features/auth/screens/otp_screen.dart';
import '../features/auth/screens/onboarding_screen.dart';
import '../features/dashboard/screens/dashboard_screen.dart';
import '../features/alerts/screens/alerts_screen.dart';
import '../features/bills/screens/bills_screen.dart';
import '../features/goals/screens/goals_screen.dart';
import '../features/welfare/screens/welfare_screen.dart';
import '../features/summary/screens/summary_screen.dart';

import '../screens/categorized_transactions/categorized_transactions_screen.dart';
import '../screens/sms_categorisation/sms_categorsation_screen.dart';
import '../shared/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final session = Supabase.instance.client.auth.currentSession;
      final isAuth = session != null;
      final loc = state.matchedLocation;
      const authRoutes = ['/splash', '/phone', '/otp', '/onboarding'];
      if (!isAuth && !authRoutes.any((r) => loc.startsWith(r))) {
        return '/phone';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash',     builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/phone',      builder: (_, __) => const PhoneScreen()),
      GoRoute(
        path: '/otp',
        builder: (_, state) => OtpScreen(phone: state.extra as String),
      ),
      GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),

      // SMS screens — reachable from notification tap or main shell badge
      GoRoute(path: '/categorize',
          builder: (_, __) => const SmsCategorisationScreen()),
      GoRoute(path: '/categorized-history',
          builder: (_, __) => const CategorizedTransactionsScreen()),

      // Main shell with bottom nav
      ShellRoute(
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(path: '/alerts',    builder: (_, __) => const AlertsScreen()),
          GoRoute(path: '/bills',     builder: (_, __) => const BillsScreen()),
          GoRoute(path: '/goals',     builder: (_, __) => const GoalsScreen()),
          GoRoute(path: '/welfare',   builder: (_, __) => const WelfareScreen()),
          GoRoute(path: '/summary',   builder: (_, __) => const SummaryScreen()),
        ],
      ),
    ],
  );
});