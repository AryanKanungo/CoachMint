import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class RegisterController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var errorMessage = RxnString(); // Reactive nullable string for errors

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<bool> register() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // 1. Basic Validation
    if (!GetUtils.isEmail(email)) {
      errorMessage.value = 'Please enter a valid email address';
      return false;
    }
    if (password.length < 6) {
      errorMessage.value = 'Password must be at least 6 characters';
      return false;
    }

    // 2. Execute Registration
    isLoading.value = true;
    errorMessage.value = null; // Clear previous errors

    try {
      await _authService.registerWithEmail(email: email, password: password);
      return true; // Success!

    } on AuthException catch (e) {
      errorMessage.value = e.message; // Display Supabase's exact error message
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}