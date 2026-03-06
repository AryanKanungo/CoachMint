import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/ai_agent/ai_agent_screen.dart';
import '../screens/goals/track_goals_screen.dart';
import '../screens/govt_schemes/govt_schemes_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/sms_categorisation/sms_categorsation_screen.dart';
import '../screens/sms_categorisation/categorized_transactions_screen.dart';
import '../screens/sms_permissions/sms_permission_screen.dart';

/// ════════════════════════════════════════════════════════════════
/// AppRouter — centralised GoRouter configuration
/// All named routes defined here. No functional logic changed.
/// ════════════════════════════════════════════════════════════════

/// Named route constants — use these instead of raw strings.
class AppRoutes {
  AppRoutes._();

  static const String login             = '/login';
  static const String register          = '/register';
  static const String onboarding        = '/onboarding';
  static const String dashboard         = '/dashboard';
  static const String aiAgent           = '/ai-agent';
  static const String trackGoals        = '/track-goals';
  static const String govtSchemes       = '/govt-schemes';
  static const String smsPermission     = '/sms-permission';
  static const String smsCategorization = '/sms-categorization';
  static const String categorizedTxns   = '/categorized-transactions';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.login,
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    final isAuthRoute = state.matchedLocation == AppRoutes.login ||
        state.matchedLocation == AppRoutes.register;

    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
    if (isLoggedIn && isAuthRoute) return AppRoutes.dashboard;

    return null;
  },
  routes: [
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (context, state) => OnboardingScreen(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.aiAgent,
      builder: (context, state) => const AIAgentScreen(),
    ),
    GoRoute(
      path: AppRoutes.trackGoals,
      builder: (context, state) => const TrackGoalsScreen(),
    ),
    GoRoute(
      path: AppRoutes.govtSchemes,
      builder: (context, state) => const GovtSchemesScreen(),
    ),
    GoRoute(
      path: AppRoutes.smsPermission,
      builder: (context, state) => const SmsPermissionScreen(),
    ),
    GoRoute(
      path: AppRoutes.smsCategorization,
      builder: (context, state) => const SmsCategorizationScreen(),
    ),
    GoRoute(
      path: AppRoutes.categorizedTxns,
      builder: (context, state) => const CategorizedTransactionsScreen(),
    ),
  ],
);
