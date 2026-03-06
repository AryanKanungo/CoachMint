import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../common_widgets/widgets.dart';
import '../../controllers/login_controller.dart';
import '../../utils/colors.dart';
import '../../utils/theme.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 1),

                  // ── Logo ──────────────────────────────────────
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.primaryMuted,
                      borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text('₹',
                          style: TextStyle(
                              fontSize: 24,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Welcome Back', style: tt.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Pick up right where you left off.',
                    style: tt.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // ── Email ─────────────────────────────────────
                  Text('Email Address',
                      style: tt.titleSmall
                          ?.copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: controller.emailController,
                    hint: 'hello@coachmint.com',
                    keyboardType: TextInputType.emailAddress,
                    autofocus: true,
                  ),

                  const SizedBox(height: 20),

                  // ── Password ──────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Password',
                          style: tt.titleSmall
                              ?.copyWith(color: AppColors.textSecondary)),
                      GestureDetector(
                        onTap: () {
                          // TODO: Route to forgot password screen
                        },
                        child: const Text(
                          'Forgot?',
                          style: TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _InputField(
                    controller: controller.passwordController,
                    hint: '••••••••',
                    obscureText: true,
                    onSubmitted: (_) async {
                      if (await controller.login() && context.mounted) {
                        context.go('/dashboard');
                      }
                    },
                  ),

                  // ── Error Message ─────────────────────────────
                  Obx(() {
                    if (controller.errorMessage.value != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          controller.errorMessage.value!,
                          style: const TextStyle(
                              color: AppColors.danger, fontSize: 13),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 32),

                  // ── Submit Button ─────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => CMButton(
                          label: 'Log In',
                          loading: controller.isLoading.value,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: () async {
                            bool success = await controller.login();
                            if (success && context.mounted) {
                              context.go('/dashboard');
                            }
                          },
                        )),
                  ),

                  const SizedBox(height: 16),

                  // ── Register redirect ─────────────────────────
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        "Don't have an account? Sign up",
                        style: TextStyle(
                            fontSize: 14,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Private reusable input field widget — keeps build method clean
// ─────────────────────────────────────────────────────────────────
class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscureText;
  final bool autofocus;
  final TextInputType? keyboardType;
  final void Function(String)? onSubmitted;

  const _InputField({
    required this.controller,
    required this.hint,
    this.obscureText = false,
    this.autofocus = false,
    this.keyboardType,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        autofocus: autofocus,
        keyboardType: keyboardType,
        onSubmitted: onSubmitted,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
          contentPadding: const EdgeInsets.all(16),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
