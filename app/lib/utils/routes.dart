// import 'package:coachmint/screens/settings/settings_screen.dart';
// import 'package:coachmint/screens/sms_categorisation/categorized_transactions_screen.dart';
// import 'package:get/get.dart';
// import '../main.dart';
// import '../screens/main/main_screen.dart';
// import '../screens/onboarding/onboarding_screen.dart';
// import '../screens/recurring_expenses/recurring_expenses_screen.dart';
// import '../screens/recurring_income/recurring_income_screen.dart';
// import '../screens/sms_categorisation/sms_categorsation_screen.dart';
// import '../screens/sms_permissions/sms_permission_screen.dart';
// import '../screens/auth/login_screen.dart';
// import '../screens/auth/register.dart';
//
//
// // Defines all the route constants and GetPage configurations for the app
// class AppRoutes {
//   static const String login = '/login';
//   static const String register = '/register';
//   // Route constants
//   static const String onboarding = '/onboarding';
//   static const String recurringExpenses = '/recurring-expenses';
//   static const String recurringIncome = '/recurring-income';
//   static const String smsPermission = '/sms-permission';
//   static const String smsCategorization = '/sms-categorization';
//   static const String main = '/main';
//   static const String authWrapper = '/auth-wrapper';
//   static const String categorizedTransactions = '/categorized-transactions';
//   static const String settings = '/settings';
//
//   // List of all pages
//   static final List<GetPage> routes = [
//     GetPage(
//       name: login,
//       page: () => const LoginScreen(),
//       transition: Transition.fade,
//     ),
//
//     GetPage(
//       name: register,
//       page: () => const RegisterScreen(),
//       transition: Transition.rightToLeftWithFade,
//     ),
//
//     GetPage(
//       name: onboarding,
//       page: () => const OnboardingScreen(),
//     ),
//     GetPage(
//       name: recurringExpenses,
//       page: () => const RecurringExpensesScreen(),
//       transition: Transition.rightToLeftWithFade,
//     ),
//     GetPage(
//       name: recurringIncome,
//       page: () => const RecurringIncomeScreen(),
//       transition: Transition.rightToLeftWithFade,
//     ),
//     GetPage(
//       name: smsPermission,
//       page: () => const SmsPermissionScreen(),
//       transition: Transition.rightToLeftWithFade,
//     ),
//     GetPage(
//       name: smsCategorization,
//       page: () => const SmsCategorizationScreen(),
//       transition: Transition.rightToLeftWithFade,
//     ),
//     GetPage(
//       name: main,
//       page: () => const MainScreen(),
//     ),
//     GetPage(
//       name: authWrapper,
//       page: () => const AuthWrapper(),
//     ),
//     GetPage(
//       name: categorizedTransactions,
//       page: () => const CategorizedTransactionsScreen(),
//     ),
//     GetPage(
//       name: settings,
//       page: () => const SettingsScreen(),
//     ),
//   ];
// }