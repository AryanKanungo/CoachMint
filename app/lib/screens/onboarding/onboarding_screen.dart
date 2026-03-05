import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import '../../common widgets/widgets.dart' show CMCard, CMButton;
import '../../controllers/onboarding_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/theme.dart';

class OnboardingScreen extends StatelessWidget {
  OnboardingScreen({super.key});

  final OnboardingController controller = Get.put(OnboardingController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Obx(() => Row(
                children: List.generate(4, (i) {
                  return Expanded(
                    child: Container(
                      height: 3,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= controller.currentPage.value
                            ? AppTheme.brand
                            : AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              )),
            ),

            Expanded(
              child: PageView(
                controller: controller.pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Step1IncomeType(controller: controller),
                  _Step2Balance(controller: controller),
                  _Step3Income(controller: controller),
                  _Step4Bill(controller: controller),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Obx(() => Row(
                children: [
                  if (controller.currentPage.value > 0)
                    Expanded(
                      child: CMButton(
                        label: 'Back',
                        onPressed: controller.back,
                        outline: true,
                      ),
                    ),
                  if (controller.currentPage.value > 0)
                    const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CMButton(
                      label: controller.currentPage.value == 3 ? 'Get Started' : 'Continue',
                      loading: controller.isSaving.value,
                      icon: controller.currentPage.value == 3 ? Icons.rocket_launch_rounded : null,
                      onPressed: () async {
                        if (controller.currentPage.value < 3) {
                          controller.next();
                        } else {
                          bool success = await controller.saveOnboarding();
                          if (success && context.mounted) {
                            context.go('/dashboard');
                          }
                        }
                      },
                    ),
                  ),
                ],
              )),
            ),
          ],
        ),
      ),
    );
  }
}

class _Step1IncomeType extends StatelessWidget {
  final OnboardingController controller;
  const _Step1IncomeType({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('How do you earn?', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('This helps us personalise your financial advice.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          ...List.generate(AppConstants.incomeTypes.length, (i) {
            return Obx(() {
              final isSelected = controller.incomeType.value == AppConstants.incomeTypes[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GestureDetector(
                  onTap: () => controller.incomeType.value = AppConstants.incomeTypes[i],
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.brand.withOpacity(0.1) : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppTheme.brand : AppTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.brand.withOpacity(0.2) : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(AppConstants.incomeIcons[i],
                              color: isSelected ? AppTheme.brand : AppTheme.textMuted, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Text(AppConstants.incomeLabels[i],
                          style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600,
                            color: isSelected ? AppTheme.brand : AppTheme.textPrimary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected) const Icon(Icons.check_circle_rounded, color: AppTheme.brand, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            });
          }),
        ],
      ),
    );
  }
}

class _Step2Balance extends StatelessWidget {
  final OnboardingController controller;
  const _Step2Balance({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Your wallet right now', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Roughly how much is in your account today?\nThis stays on your phone — SMS updates it automatically.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard, borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              children: [
                const Text('₹', style: TextStyle(fontSize: 32, color: AppTheme.brand, fontWeight: FontWeight.w800)),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.balanceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                    decoration: const InputDecoration(
                      hintText: '0', border: InputBorder.none,
                      enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                      filled: false,
                    ),
                    autofocus: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const CMCard(
            child: Row(
              children: [
                Icon(Icons.lock_outline, size: 16, color: AppTheme.brand),
                SizedBox(width: 8),
                Expanded(
                  child: Text('This is your starting point only. Your SMS keeps it updated automatically.',
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Step3Income extends StatelessWidget {
  final OnboardingController controller;
  const _Step3Income({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Next income', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('When do you expect to get paid next?',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 32),
          TextField(
            controller: controller.incomeAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Expected amount (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppTheme.brand, surface: AppTheme.surfaceCard),
                  ),
                  child: child!,
                ),
              );
              if (d != null) controller.setNextIncomeDate(d);
            },
            child: AbsorbPointer(
              child: TextField(
                controller: controller.incomeDateController,
                decoration: const InputDecoration(
                  labelText: 'Date of next payment',
                  suffixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step4Bill extends StatelessWidget {
  final OnboardingController controller;
  const _Step4Bill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text('Any upcoming bills?', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text('Add one to start — you can add more anytime.\nSkip if you have none right now.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary, height: 1.5)),
          const SizedBox(height: 32),
          TextField(
            controller: controller.billNameController,
            decoration: const InputDecoration(labelText: 'Bill name (e.g. Jio Recharge)'),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller.billAmountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Amount (₹)', prefixText: '₹ '),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(primary: AppTheme.brand, surface: AppTheme.surfaceCard),
                  ),
                  child: child!,
                ),
              );
              if (d != null) controller.setBillDate(d);
            },
            child: AbsorbPointer(
              child: TextField(
                controller: controller.billDateController,
                decoration: const InputDecoration(
                  labelText: 'Due date',
                  suffixIcon: Icon(Icons.calendar_today_rounded, color: AppTheme.brand),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}