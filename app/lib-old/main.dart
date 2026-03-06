import 'package:coachmint/utils/routes.dart';
import 'package:coachmint/utils/theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load the environment variables first
  await dotenv.load(fileName: '.env');

  // 2. Initialize Supabase securely
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  runApp(const CoachMintApp());
}

class CoachMintApp extends StatelessWidget {
  const CoachMintApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp.router(
      title: 'CoachMint',
      debugShowCheckedModeBanner: false,
      // ── Global Design System Theme ────────────────────────────
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // ── Router ────────────────────────────────────────────────
      routerDelegate: appRouter.routerDelegate,
      routeInformationParser: appRouter.routeInformationParser,
      routeInformationProvider: appRouter.routeInformationProvider,
    );
  }
}
