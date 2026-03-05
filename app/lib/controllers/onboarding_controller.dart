import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/onboarding_service.dart';
import '../models/app_models.dart';
import '../utils/app_constants.dart';

class OnboardingController extends GetxController {
  final OnboardingService _service = OnboardingService();

  // Page Management
  final PageController pageController = PageController();
  var currentPage = 0.obs;
  var isSaving = false.obs;

  // Step 1
  var incomeType = 'gig'.obs;

  // Step 2
  final balanceController = TextEditingController();

  // Step 3
  final incomeDateController = TextEditingController();
  final incomeAmountController = TextEditingController();
  var nextIncomeDate = Rxn<DateTime>();

  // Step 4
  final billNameController = TextEditingController();
  final billAmountController = TextEditingController();
  final billDateController = TextEditingController();
  var billDate = Rxn<DateTime>();

  @override
  void onClose() {
    pageController.dispose();
    balanceController.dispose();
    incomeDateController.dispose();
    incomeAmountController.dispose();
    billNameController.dispose();
    billAmountController.dispose();
    billDateController.dispose();
    super.onClose();
  }

  void next() {
    if (currentPage.value < 3) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      currentPage.value++;
    }
  }

  void back() {
    if (currentPage.value > 0) {
      pageController.previousPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
      currentPage.value--;
    }
  }

  void setNextIncomeDate(DateTime date) {
    nextIncomeDate.value = date;
    // Visually formatted for the UI
    incomeDateController.text = '${date.day}/${date.month}/${date.year}';
  }

  void setBillDate(DateTime date) {
    billDate.value = date;
    // Visually formatted for the UI
    billDateController.text = '${date.day}/${date.month}/${date.year}';
  }

  Future<bool> saveOnboarding() async {
    isSaving.value = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;

      // Clean string inputs (removes commas and spaces so parsing doesn't break)
      final cleanBalance = balanceController.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanIncome = incomeAmountController.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final cleanBillAmount = billAmountController.text.replaceAll(RegExp(r'[^0-9.]'), '');

      final balance = double.tryParse(cleanBalance) ?? 0.0;
      final expectedIncome = double.tryParse(cleanIncome) ?? 0.0;
      final incomeLabelIndex = AppConstants.incomeTypes.indexOf(incomeType.value);

      final profile = UserProfileModel(
        userId: userId,
        incomeSourceLabel: AppConstants.incomeLabels[incomeLabelIndex],
        startingBalance: balance,
        expectedIncome: expectedIncome,
        nextIncomeDate: nextIncomeDate.value,
        onboardingComplete: true,
      );

      BillModel? firstBill;
      final billName = billNameController.text.trim();
      final billAmount = double.tryParse(cleanBillAmount);

      print("--- SAVING ONBOARDING ---");
      print("Bill Name: '$billName'");
      print("Bill Amount: $billAmount");
      print("Bill Date: ${billDate.value}");

      // IF the user typed anything in the bill section, validate it!
      if (billName.isNotEmpty || cleanBillAmount.isNotEmpty || billDate.value != null) {

        // If any of the 3 fields are missing, stop the save and warn the user
        if (billName.isEmpty || billAmount == null || billDate.value == null) {
          Get.snackbar(
            'Incomplete Bill',
            'Please fill out the name, amount, and date for your bill, or clear all fields to skip.',
            backgroundColor: Colors.orange,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
          );
          return false; // Aborts the save process
        }

        // Use UTC to prevent Postgres from shifting the date back 1 day due to timezones
        DateTime safeDate = DateTime.utc(
            billDate.value!.year,
            billDate.value!.month,
            billDate.value!.day
        );

        firstBill = BillModel(
          id: '', // Blank lets Supabase auto-generate the UUID
          userId: userId,
          name: billName,
          amount: billAmount,
          dueDate: safeDate,
          isPaid: false,
        );
        print("-> Bill generated successfully!");
      } else {
        print("-> No bill entered. Skipping bill insert.");
      }

      // Execute database write
      await _service.saveOnboardingData(
        profile: profile,
        firstBill: firstBill,
      );

      print("--- DATABASE WRITE COMPLETE ---");
      return true;

    } catch (e) {
      print("--- SUPABASE ERROR --- : $e");
      Get.snackbar(
        'Database Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.redAccent,
        colorText: Colors.white,
      );
      return false;
    } finally {
      isSaving.value = false;
    }
  }
}