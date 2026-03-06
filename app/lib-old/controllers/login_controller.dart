import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  var isLoading = false.obs;
  var errorMessage = RxnString();

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<bool> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!GetUtils.isEmail(email)) {
      errorMessage.value = 'Please enter a valid email address';
      return false;
    }
    if (password.isEmpty) {
      errorMessage.value = 'Please enter your password';
      return false;
    }

    isLoading.value = true;
    errorMessage.value = null;

    try {
      await _authService.loginWithEmail(email: email, password: password);
      return true; // Success

    } on AuthException catch (e) {
      // Usually "Invalid login credentials"
      errorMessage.value = e.message;
      return false;
    } catch (e) {
      errorMessage.value = 'An unexpected error occurred. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }
}