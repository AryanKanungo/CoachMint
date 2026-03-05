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

  // Step 1 — Income Type
  var incomeType = 'gig'.obs;

  // Step 2 — Wallet Balance
  final balanceController = TextEditingController();

  // Step 3 — Next Income
  final incomeDateController = TextEditingController();
  final incomeAmountController = TextEditingController();
  var nextIncomeDate = Rxn<DateTime>();

  // Step 4 — First Bill (Optional)
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
    incomeDateController.text = '${date.day}/${date.month}/${date.year}';
  }

  void setBillDate(DateTime date) {
    billDate.value = date;
    billDateController.text = '${date.day}/${date.month}/${date.year}';
  }

  Future<bool> saveOnboarding() async {
    isSaving.value = true;
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final balance = double.tryParse(balanceController.text) ?? 0.0;
      final expectedIncome = double.tryParse(incomeAmountController.text) ?? 0.0;
      final incomeLabelIndex = AppConstants.incomeTypes.indexOf(incomeType.value);

      // Construct your exact UserProfileModel
      final profile = UserProfileModel(
        userId: userId,
        incomeSourceLabel: AppConstants.incomeLabels[incomeLabelIndex],
        startingBalance: balance,
        expectedIncome: expectedIncome, // Now guaranteed double
        nextIncomeDate: nextIncomeDate.value, // Passed as DateTime?
        onboardingComplete: true,
      );

      // Construct your exact BillModel
      BillModel? firstBill;
      final billName = billNameController.text.trim();
      final billAmount = double.tryParse(billAmountController.text);
      final billDueDate = billDate.value;

      if (billName.isNotEmpty && billAmount != null && billDueDate != null) {
        firstBill = BillModel(
          id: '', // Explicitly empty so your toJson skips it and Supabase auto-generates UUID
          userId: userId,
          name: billName,
          amount: billAmount,
          dueDate: billDueDate,
          isPaid: false,
        );
      }

      await _service.saveOnboardingData(
        rawIncomeType: incomeType.value,
        profile: profile,
        firstBill: firstBill,
      );

      return true; // Return success so UI navigates

    } catch (e) {
      Get.snackbar(
        'Error saving',
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