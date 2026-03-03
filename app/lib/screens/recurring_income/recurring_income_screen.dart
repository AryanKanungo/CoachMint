import 'package:coachmint/screens/recurring_income/recurring_income_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../utils/colors.dart';

class RecurringIncomeScreen extends GetView<RecurringIncomeController> {
  const RecurringIncomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RecurringIncomeController());
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: controller.skip,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Text(
                "When do you usually get paid? This helps FinAgent avoid suggesting savings on tough days.",
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
            ),
            Expanded(
              child: ListView( // <-- Removed the Obx wrapper from here
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                children: [
                  _buildAnimatedFormItem(
                    context,
                    controller: controller.incomeAmountController,
                    icon: Icons.wallet_rounded,
                    label: "Monthly Income",
                    hint: "Amount",
                    index: 0,
                  ),
                  _buildAnimatedFormItem(
                    context,
                    controller: controller.payDayController,
                    icon: Icons.calendar_today_rounded,
                    label: "Payday (e.g., 1st)",
                    hint: "Date",
                    index: 1,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: controller.goToMainApp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text("Done"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Animated list item widget
  Widget _buildAnimatedFormItem(
      BuildContext context, {
        required TextEditingController controller,
        required IconData icon,
        required String label,
        required String hint,
        required int index,
      }) {
    final textTheme = Theme.of(context).textTheme;

    return Obx(
          () => AnimatedOpacity(
        opacity: Get.find<RecurringIncomeController>().isLoaded.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300 + (index * 100)),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300 + (index * 100)),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
              0, Get.find<RecurringIncomeController>().isLoaded.value ? 0 : 30, 0),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: label,
                        hintText: hint,
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}