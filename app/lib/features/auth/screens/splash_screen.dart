import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../app/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    _navigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      context.go('/phone');
      return;
    }

    try {
      final profile = await Supabase.instance.client
          .from('user_profile')
          .select('onboarding_complete')
          .eq('user_id', session.user.id)
          .maybeSingle();

      context.go(
        (profile == null || profile['onboarding_complete'] == false)
            ? '/onboarding'
            : '/dashboard',
      );
    } catch (_) {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: AppTheme.brand.withOpacity(0.4), width: 1.5),
                  ),
                  child: const Center(
                    child: Text(
                      '₹',
                      style: TextStyle(
                          fontSize: 36,
                          color: AppTheme.brand,
                          fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'CoachMint',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      letterSpacing: -1),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your AI Financial Coach',
                  style:
                  TextStyle(fontSize: 14, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 40),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppTheme.brand),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}