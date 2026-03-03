import 'package:coachmint/screens/recurring_expenses/recurring_expenses_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../models/recurring_expenses_model.dart';
import '../../utils/colors.dart';

class RecurringExpensesScreen extends GetView<RecurringExpensesController> {
  const RecurringExpensesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(RecurringExpensesController());
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
              child: Text(
                "Tell us about the monthly payments you usually make so FinAgent can plan ahead for you.",
                textAlign: TextAlign.center,
                style: textTheme.headlineMedium?.copyWith(fontSize: 22),
              ),
            ),
            Expanded(
              child: Obx(
                    () => ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: controller.expenseItems.length,
                  itemBuilder: (context, index) {
                    final item = controller.expenseItems[index];
                    return _buildAnimatedFormItem(
                      context,
                      item: item,
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: ElevatedButton(
                onPressed: controller.goToNextStep,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: const Text("Continue"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Animated list item widget
  Widget _buildAnimatedFormItem(BuildContext context,
      {required ExpenseItem item}) {
    final textTheme = Theme.of(context).textTheme;

    // Use the controller's isLoaded obs to trigger the animation
    return Obx(
          () => AnimatedOpacity(
        opacity: controller.isLoaded.value ? 1.0 : 0.0,
        duration: Duration(milliseconds: 300 + (item.index * 100)),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300 + (item.index * 100)),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
              0, controller.isLoaded.value ? 0 : 30, 0),
          child: Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(item.icon, color: AppColors.primary, size: 28),
                  const SizedBox(width: 16),
                  Text(item.label, style: textTheme.bodyLarge),
                  const Spacer(),
                  SizedBox(
                    width: 100,
                    child: TextFormField(
                      controller: item.amountController,
                      keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                      ],
                      decoration: const InputDecoration(
                        prefixText: "₹",
                        hintText: "Amount",
                        isDense: true,
                        border: InputBorder.none,
                      ),
                      textAlign: TextAlign.right,
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