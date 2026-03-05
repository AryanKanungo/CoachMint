import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Import your screens here
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/dashboard/dashboard_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';


final GoRouter appRouter = GoRouter(
  initialLocation: '/login',

  // The Redirect Guard acts as our auth bouncer
  redirect: (context, state) {
    final session = Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session != null;

    // Check if the user is currently on the login or register screen
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    // If they aren't logged in, and they are trying to access a protected route
    if (!isLoggedIn && !isAuthRoute) {
      return '/login';
    }

    // If they ARE logged in, but trying to view the login screen,
    // send them to onboarding (later, we can check if they finished onboarding to send to /dashboard)
    if (isLoggedIn && isAuthRoute) {
      return '/onboarding';
    }

    // No redirect needed, let them go to the route they requested
    return null;
  },

  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => RegisterScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => OnboardingScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => DashboardScreen(),
    ),
  ],
);