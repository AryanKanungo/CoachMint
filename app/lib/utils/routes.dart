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
    final session    = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    final isAuthRoute =
        state.matchedLocation == AppRoutes.login ||
            state.matchedLocation == AppRoutes.register;

    if (!isLoggedIn && !isAuthRoute) return AppRoutes.login;
    if (isLoggedIn  && isAuthRoute)  return AppRoutes.dashboard;

    return null;
  },

  routes: [
    GoRoute(path: AppRoutes.login,             builder: (_, __) => LoginScreen()),
    GoRoute(path: AppRoutes.register,          builder: (_, __) => RegisterScreen()),
    GoRoute(path: AppRoutes.onboarding,        builder: (_, __) => OnboardingScreen()),
    GoRoute(path: AppRoutes.dashboard,         builder: (_, __) => const DashboardScreen()),
    GoRoute(path: AppRoutes.aiAgent,           builder: (_, __) => const AIAgentScreen()),
    GoRoute(path: AppRoutes.trackGoals,        builder: (_, __) => const TrackGoalsScreen()),
    GoRoute(path: AppRoutes.govtSchemes,       builder: (_, __) => const GovtSchemesScreen()),
    GoRoute(path: AppRoutes.smsPermission,     builder: (_, __) => const SmsPermissionScreen()),
    GoRoute(path: AppRoutes.smsCategorization, builder: (_, __) => const SmsCategorizationScreen()),
    GoRoute(path: AppRoutes.categorizedTxns,   builder: (_, __) => const CategorizedTransactionsScreen()),
  ],
);