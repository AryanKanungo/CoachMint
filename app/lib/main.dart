import 'package:coachmint/screens/auth/login_screen.dart';
import 'package:coachmint/screens/main/main_screen.dart';
import 'package:coachmint/services/firebase_service.dart';
import 'package:coachmint/services/sms_service.dart';
import 'package:coachmint/utils/routes.dart';
import 'package:coachmint/utils/theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:coachmint/firebase_options.dart';
import 'screens/sms_categorisation/sms_categorisation_controller.dart';
import 'screens/home/home_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 1️⃣ REGISTER SERVICES FIRST
  // These must exist before any controller uses them
  Get.put(SmsService(), permanent: true);
  await Get.putAsync(() => FirebaseService().init());

  // 2️⃣ REGISTER CONTROLLERS AFTER SERVICES
  Get.put(SmsCategorizationController(), permanent: true);
  Get.put(HomeController(), permanent: true);

  runApp(const FinAgentApp());
}

class FinAgentApp extends StatelessWidget {
  const FinAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'CoachMint',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      initialRoute: AppRoutes.authWrapper,
      getPages: AppRoutes.routes,
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const MainScreen();
        }

        return const LoginScreen();
      },
    );
  }
}
