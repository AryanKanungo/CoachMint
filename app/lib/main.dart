import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'core/notifications/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ── Supabase ──────────────────────────────────────────────────
  await Supabase.initialize(
    url: 'https://avutzldmqezfgozaswnz.supabase.co',
    anonKey: 'sb_publishable_ZDwebXKLBIZb3Kn6HJrjhA_djYQF8eV',
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  await Supabase.instance.client.auth.signOut();

  // ── Local notifications (init only — does NOT fire any notification) ──
  await NotificationService.init(flutterLocalNotificationsPlugin);

  runApp(const ProviderScope(child: CoachMintApp()));
}

class CoachMintApp extends ConsumerWidget {
  const CoachMintApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'CoachMint',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}