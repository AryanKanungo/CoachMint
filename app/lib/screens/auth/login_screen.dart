import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../common widgets/widgets.dart';
import '../../controllers/login_controller.dart';
import '../../utils/theme.dart';


class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final LoginController controller = Get.put(LoginController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              // This math ensures the layout takes exactly the screen height
              // minus padding, allowing Spacers to work while scrolling!
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

                  // Logo
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppTheme.brand.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.brand.withOpacity(0.3)),
                    ),
                    child: const Center(
                      child: Text('₹',
                          style: TextStyle(fontSize: 24, color: AppTheme.brand)),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text(
                    'Welcome Back',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Pick up right where you left off.',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Email Input
                  Text('Email Address',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: AppTheme.textSecondary)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      controller: controller.emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: 'hello@coachmint.com',
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Password Input
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Password',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: AppTheme.textSecondary)),
                      // Optional: Forgot Password Button
                      GestureDetector(
                        onTap: () {
                          // TODO: Route to forgot password screen
                        },
                        child: const Text('Forgot?',
                            style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.brand,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: TextField(
                      controller: controller.passwordController,
                      obscureText: true,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600),
                      decoration: const InputDecoration(
                        hintText: '••••••••',
                        contentPadding: EdgeInsets.all(16),
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) async {
                        if (await controller.login() && context.mounted) {
                          context.go('/dashboard');
                        }
                      },
                    ),
                  ),

                  // Error Message
                  Obx(() {
                    if (controller.errorMessage.value != null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          controller.errorMessage.value!,
                          style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }),

                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: Obx(() => CMButton(
                      label: 'Log In',
                      loading: controller.isLoading.value,
                      icon: Icons.arrow_forward_rounded,
                      onPressed: () async {
                        bool success = await controller.login();
                        if (success && context.mounted) {
                          context.go('/dashboard'); // Route to dashboard on success
                        }
                      },
                    )),
                  ),

                  const SizedBox(height: 16),

                  // Register redirect
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/register'),
                      child: const Text(
                        'Don\'t have an account? Sign up',
                        style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.brand,
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