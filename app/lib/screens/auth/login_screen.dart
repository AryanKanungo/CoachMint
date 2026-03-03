import 'dart:async'; // Needed for the animation helper
import 'package:coachmint/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';

// --- (This assumes your AppColors class is in '../utils/colors.dart') ---
// class AppColors {
//   static const Color primary = Color(0xFF0046FF);
//   static const Color primaryLight = Color(0xFF7E57C2);
//   static const Color mainText = Color(0xFFDDDDDD);
//   static const Color secondaryText = Color(0xFF939393);
//   static const Color background = Color(0xFF2C2C2C);
//   static const Color cardBackground = Color(0xFF232323);
//   static const Color redAccent = Color(0xFFF44336);
//   static const Color greenAccent = Color(0xFF4CAF50);
// }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Services and Keys
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State Management
  final RxBool _isLoading = false.obs;
  final RxBool _isPasswordVisible = false.obs;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // --- STYLED HELPER for Input Decorations ---
  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.secondaryText),
      prefixIcon: Icon(icon, color: AppColors.secondaryText, size: 20),
      filled: true,
      fillColor: AppColors.cardBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redAccent, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.redAccent, width: 2),
      ),
    );
  }

  // --- STYLED HELPER for Snackbars ---
  void _showErrorSnackbar(String message) {
    Get.snackbar(
      "Login Failed",
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.redAccent,
      colorText: Colors.white,
      margin: const EdgeInsets.all(12),
      borderRadius: 12,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    );
  }

  // --- LOGIN LOGIC ---
  Future<void> _loginWithEmail() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    _isLoading.value = true;

    try {
      final email = emailController.text.trim();
      final password = passwordController.text.trim();

      await _authService.signInWithEmailPassword(email, password);

      Get.snackbar(
        "Login Successful",
        "Welcome back!",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.greenAccent,
        colorText: Colors.white,
        margin: const EdgeInsets.all(12),
        borderRadius: 12,
        icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      );

      Get.offAllNamed('/main');
    } on FirebaseAuthException catch (e) {
      String msg = "Incorrect email or password.";
      if (e.code == 'user-not-found') {
        msg = "No account found with this email.";
      } else if (e.code == 'wrong-password') {
        msg = "Incorrect password. Please try again.";
      } else if (e.code == 'invalid-email') {
        msg = "Invalid email format.";
      }
      _showErrorSnackbar(msg);
    } catch (e) {
      _showErrorSnackbar("Something went wrong. Please try again later.");
    } finally {
      _isLoading.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.secondaryText),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // --- STAGGERED ANIMATION 1 ---
              _AnimatedFormItem(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  "Welcome Back!",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppColors.mainText,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // --- STAGGERED ANIMATION 2 ---
              _AnimatedFormItem(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  "You've been missed. Please sign in.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppColors.secondaryText,
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // --- STAGGERED ANIMATION 3: Email ---
              _AnimatedFormItem(
                delay: const Duration(milliseconds: 300),
                child: TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(color: AppColors.mainText),
                  decoration: _buildInputDecoration(
                    "Email",
                    Icons.email_outlined,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!GetUtils.isEmail(value.trim())) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 20),

              // --- STAGGERED ANIMATION 4: Password ---
              _AnimatedFormItem(
                delay: const Duration(milliseconds: 400),
                child: Obx(() => TextFormField(
                  controller: passwordController,
                  obscureText: !_isPasswordVisible.value,
                  style: GoogleFonts.inter(color: AppColors.mainText),
                  decoration: _buildInputDecoration(
                    "Password",
                    Icons.lock_outline,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible.value
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppColors.secondaryText,
                      ),
                      onPressed: () {
                        _isPasswordVisible.value = !_isPasswordVisible.value;
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                )),
              ),

              // --- STAGGERED ANIMATION 5: Forgot Password ---
              _AnimatedFormItem(
                delay: const Duration(milliseconds: 500),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Get.snackbar(
                        "Coming Soon",
                        "Forgot Password feature is not yet implemented.",
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: AppColors.cardBackground,
                        colorText: AppColors.mainText,
                      );
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.inter(
                        color: AppColors.primaryLight,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // --- STAGGERED ANIMATION 6: Login Button ---
              _AnimatedFormItem(
                delay: const Duration(milliseconds: 600),
                child: Obx(() => SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading.value ? null : _loginWithEmail,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor:
                      AppColors.primary.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    // --- ENGAGING: Smooth loading animation ---
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(opacity: animation, child: child);
                      },
                      child: _isLoading.value
                          ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 3,
                        ),
                      )
                          : Text(
                        'Sign In',
                        key: const ValueKey('text'), // Key for Switcher
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 32),

              // --- STAGGERED ANIMATION 7: Sign Up ---
              _AnimatedFormItem(
                delay: const Duration(milliseconds: 700),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account?",
                      style: GoogleFonts.inter(color: AppColors.secondaryText),
                    ),
                    TextButton(
                      onPressed:
                      _isLoading.value ? null : () => Get.toNamed('/register'),
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.inter(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// --- NEW: Animation Helper Widget ---
/// This widget handles the staggered fade-in and slide-up animation.
class _AnimatedFormItem extends StatefulWidget {
  final Widget child;
  final Duration delay;

  const _AnimatedFormItem({
    required this.child,
    required this.delay,
  });

  @override
  State<_AnimatedFormItem> createState() => _AnimatedFormItemState();
}

class _AnimatedFormItemState extends State<_AnimatedFormItem> {
  double _opacity = 0.0;
  Offset _offset = const Offset(0, 0.2);

  @override
  void initState() {
    super.initState();
    // Start the animation after the specified delay
    Timer(widget.delay, () {
      if (mounted) {
        setState(() {
          _opacity = 1.0;
          _offset = Offset.zero;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
      child: AnimatedSlide(
        offset: _offset,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}