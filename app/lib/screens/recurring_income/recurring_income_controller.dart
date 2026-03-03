import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RecurringIncomeController extends GetxController {
  var isLoaded = false.obs;

  final incomeAmountController = TextEditingController();
  final payDayController = TextEditingController();

  @override
  void onReady() {
    super.onReady();
    // Trigger animations
    Future.delayed(const Duration(milliseconds: 200), () {
      isLoaded.value = true;
    });
  }

  void goToMainApp() {
    // In a real app, save this data
    // print("Income: ${incomeAmountController.text}");
    // print("Payday: ${payDayController.text}");

    // Navigate to the main app, clearing the entire onboarding stack
    Get.offAllNamed('/main');
  }

  void skip() {
    // Also go to the main app, just without saving
    Get.offAllNamed('/main');
  }

  @override
  void onClose() {
    incomeAmountController.dispose();
    payDayController.dispose();
    super.onClose();
  }
}