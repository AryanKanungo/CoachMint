import 'package:coachmint/models/recurring_expenses_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// A simple model to hold item data and its controller

class RecurringExpensesController extends GetxController {
  var isLoaded = false.obs;
  var expenseItems = <ExpenseItem>[].obs;

  @override
  void onInit() {
    super.onInit();
    // Initialize the form items
    expenseItems.value = [
      ExpenseItem(index: 0, label: "Rent", icon: Icons.house_rounded),
      ExpenseItem(index: 1, label: "EMIs", icon: Icons.payment_rounded),
      ExpenseItem(index: 2, label: "Subscriptions", icon: Icons.subscriptions_rounded),
      ExpenseItem(index: 3, label: "School Fees", icon: Icons.school_rounded),
      ExpenseItem(index: 4, label: "Transport", icon: Icons.commute_rounded),
    ];
  }

  @override
  void onReady() {
    super.onReady();
    // Trigger animations
    Future.delayed(const Duration(milliseconds: 200), () {
      isLoaded.value = true;
    });
  }

  void goToNextStep() {
    // In a real app, save this data to Firestore
    // for (var item in expenseItems) {
    //   print("${item.label}: ${item.amountController.text}");
    // }

    // Navigate to the next step, replacing this screen
    Get.offNamed('/recurring-income');
  }
}