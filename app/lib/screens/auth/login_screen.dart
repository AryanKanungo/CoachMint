import 'package:flutter/material.dart';
import '../../utils/colors.dart';
// Import your controller/auth service here

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Welcome Animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 1200),
              builder: (context, value, child) {
                return Opacity(
                  opacity: value,
                  child: Padding(
                    padding: EdgeInsets.only(top: 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: const Text(
                "Welcome to CoachMint",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.greenAccent, // Neon accent
                ),
              ),
            ),
            const SizedBox(height: 40),
            
            // Email Field
            TextField(
              style: const TextStyle(color: AppColors.white), // Makes typed text visible
              decoration: InputDecoration(
                labelText: "Email",
                labelStyle: const TextStyle(color: AppColors.secondaryText),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.greenAccent),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Password Field
            TextField(
              obscureText: true,
              style: const TextStyle(color: AppColors.white), // Makes typed text visible
              decoration: InputDecoration(
                labelText: "Password",
                labelStyle: const TextStyle(color: AppColors.secondaryText),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.greenAccent),
                ),
              ),
            ),
            // ... add your Login button here
          ],
        ),
      ),
    );
  }
}