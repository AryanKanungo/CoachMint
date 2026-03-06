import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/onboarding_controller.dart';
import '../../utils/app_constants.dart';
import '../../utils/routes.dart';
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

            // ── Progress bar ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Obx(() => Row(
                children: List.generate(4, (i) {
                  final done = i < controller.currentPage.value;
                  final active = i == controller.currentPage.value;
                  return Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 3,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: done || active
                            ? AppTheme.brand
                            : AppTheme.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  );
                }),
              )),
            ),

            // ── Step label ───────────────────────────────────────
            Obx(() => Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              child: Row(
                children: [
                  Text(
                    'Step ${controller.currentPage.value + 1} of 4',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textMuted,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            )),

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

            // ── Bottom nav ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 28),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              child: Obx(() => Row(
                children: [
                  if (controller.currentPage.value > 0) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: controller.back,
                        child: Text(
                          'Back',
                          style: GoogleFonts.dmSans(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 2,
                    child: Obx(() => ElevatedButton(
                      onPressed: controller.isSaving.value
                          ? null
                          : () async {
                        FocusScope.of(context).unfocus();
                        if (controller.currentPage.value < 3) {
                          controller.next();
                        } else {
                          final success = await controller.saveOnboarding();
                          if (success && context.mounted) {
                            context.go(AppRoutes.smsPermission);
                          }
                        }
                      },
                      child: controller.isSaving.value
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF080D14),
                        ),
                      )
                          : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            controller.currentPage.value == 3
                                ? 'Save & Continue'
                                : 'Continue',
                            style: GoogleFonts.dmSans(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: const Color(0xFF080D14),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            controller.currentPage.value == 3
                                ? Icons.check
                                : Icons.arrow_forward,
                            size: 16,
                            color: const Color(0xFF080D14),
                          ),
                        ],
                      ),
                    )),
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

// ── Step 1: Income Type ─────────────────────────────────────────────────────

class _Step1IncomeType extends StatelessWidget {
  final OnboardingController controller;
  const _Step1IncomeType({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How do you earn?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'We use this to personalise your dashboard and goals.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          ...List.generate(AppConstants.incomeTypes.length, (i) {
            return Obx(() {
              final isSelected =
                  controller.incomeType.value == AppConstants.incomeTypes[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GestureDetector(
                  onTap: () =>
                  controller.incomeType.value = AppConstants.incomeTypes[i],
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.brand.withOpacity(0.06)
                          : AppTheme.surfaceCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.brand.withOpacity(0.6)
                            : AppTheme.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.brand.withOpacity(0.12)
                                : AppTheme.surfaceElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            AppConstants.incomeIcons[i],
                            color: isSelected
                                ? AppTheme.brand
                                : AppTheme.textMuted,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text(
                          AppConstants.incomeLabels[i],
                          style: GoogleFonts.dmSans(
                            fontSize: 15,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.textPrimary
                                : AppTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.brand,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Color(0xFF080D14), size: 13),
                          ),
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

// ── Step 2: Balance ─────────────────────────────────────────────────────────

class _Step2Balance extends StatelessWidget {
  final OnboardingController controller;
  const _Step2Balance({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current balance',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Roughly how much is in your account today?',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),
          // Big ₹ input inside a card container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  '₹',
                  style: GoogleFonts.dmSans(
                    fontSize: 38,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.brand,
                    height: 1.2,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: controller.balanceController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d{0,2}'))
                    ],
                    autofocus: true,
                    style: GoogleFonts.dmSans(
                      fontSize: 38,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                      height: 1.2,
                    ),
                    // Override decoration inline — bypasses theme for this input
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: GoogleFonts.dmSans(
                        fontSize: 38,
                        fontWeight: FontWeight.w300,
                        color: AppTheme.border,
                        height: 1.2,
                      ),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      filled: false,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.brand.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.brand.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline,
                    size: 15, color: AppTheme.brand.withOpacity(0.7)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'This is your starting point. Your bank SMS will keep it updated automatically.',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 3: Next Income ──────────────────────────────────────────────────────

class _Step3Income extends StatelessWidget {
  final OnboardingController controller;
  const _Step3Income({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Next income',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'When do you expect to get paid next?',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),

          _FieldLabel('EXPECTED AMOUNT'),
          const SizedBox(height: 8),
          TextField(
            controller: controller.incomeAmountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '15,000',
              prefixText: '₹  ',
              prefixStyle: GoogleFonts.dmSans(
                color: AppTheme.brand,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),

          _FieldLabel('PAYMENT DATE'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              FocusScope.of(context).unfocus();
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.brand,
                      onPrimary: Color(0xFF080D14),
                      surface: AppTheme.surfaceCard,
                      onSurface: AppTheme.textPrimary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (d != null) controller.setNextIncomeDate(d);
            },
            child: AbsorbPointer(
              child: TextField(
                controller: controller.incomeDateController,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'Select a date',
                  suffixIcon: const Icon(
                    Icons.calendar_today_outlined,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step 4: Bills ────────────────────────────────────────────────────────────

class _Step4Bill extends StatelessWidget {
  final OnboardingController controller;
  const _Step4Bill({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Any upcoming bills?',
              style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          Text(
            'Add one now — or skip and add later.\nBills let us warn you before they bounce.',
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: AppTheme.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 36),

          _FieldLabel('BILL NAME'),
          const SizedBox(height: 8),
          TextField(
            controller: controller.billNameController,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            decoration: const InputDecoration(
              hintText: 'e.g. Jio Recharge, Electricity',
            ),
          ),
          const SizedBox(height: 24),

          _FieldLabel('AMOUNT'),
          const SizedBox(height: 8),
          TextField(
            controller: controller.billAmountController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: '0',
              prefixText: '₹  ',
              prefixStyle: GoogleFonts.dmSans(
                color: AppTheme.brand,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 24),

          _FieldLabel('DUE DATE'),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () async {
              FocusScope.of(context).unfocus();
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now().add(const Duration(days: 7)),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppTheme.brand,
                      onPrimary: Color(0xFF080D14),
                      surface: AppTheme.surfaceCard,
                      onSurface: AppTheme.textPrimary,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (d != null) controller.setBillDate(d);
            },
            child: AbsorbPointer(
              child: TextField(
                controller: controller.billDateController,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Select a date',
                  suffixIcon: Icon(
                    Icons.calendar_today_outlined,
                    color: AppTheme.textMuted,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Field label helper ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.dmSans(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: AppTheme.textMuted,
        letterSpacing: 1.6,
      ),
    );
  }
}