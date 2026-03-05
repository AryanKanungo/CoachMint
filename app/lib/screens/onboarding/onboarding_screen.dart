  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:go_router/go_router.dart';
  import 'package:get/get.dart';
  import 'package:google_fonts/google_fonts.dart';

  import '../../common widgets/widgets.dart';
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

              // ── Progress bar — thin lines, no rounding ──────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Obx(() => Row(
                  children: List.generate(4, (i) {
                    final isActive = i <= controller.currentPage.value;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: 2,
                        margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                        color: isActive ? AppTheme.brand : AppTheme.border,
                      ),
                    );
                  }),
                )),
              ),

              // ── Step counter ────────────────────────────────────────
              Obx(() => Padding(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                child: Row(
                  children: [
                    Text(
                      '${controller.currentPage.value + 1}',
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 13,
                        color: AppTheme.brand,
                      ),
                    ),
                    Text(
                      ' / 4',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                        fontWeight: FontWeight.w400,
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

              // ── Bottom navigation ───────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                decoration: const BoxDecoration(
                  color: AppTheme.surface,
                  border: Border(
                    top: BorderSide(color: AppTheme.border, width: 1),
                  ),
                ),
                child: Obx(() => Row(
                  children: [
                    if (controller.currentPage.value > 0) ...[
                      Expanded(
                        child: CMButton(
                          label: 'Back',
                          onPressed: controller.back,
                          outline: true,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: CMButton(
                        label: controller.currentPage.value == 3
                            ? 'Save & Continue'
                            : 'Continue',
                        loading: controller.isSaving.value,
                        icon: controller.currentPage.value == 3
                            ? Icons.check
                            : Icons.arrow_forward,
                          onPressed: () async {
                            FocusScope.of(context).unfocus();
                            if (controller.currentPage.value < 3) {
                              controller.next();
                            } else {
                              // Try to save
                              final success = await controller.saveOnboarding();

                              // If successful, show popup instead of navigating!
                              if (success && context.mounted) {
                                Get.snackbar(
                                  'Success!',
                                  'Onboarding profile & bill successfully saved to database.',
                                  snackPosition: SnackPosition.TOP,
                                  backgroundColor: Colors.green.shade600,
                                  colorText: Colors.white,
                                  duration: const Duration(seconds: 4),
                                  icon: const Icon(Icons.check_circle, color: Colors.white),
                                );

                                // context.go('/dashboard'); // <-- Commented out for testing
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
            Text(
              'How do you earn?',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This personalises your dashboard and risk calculations.',
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
                            ? AppTheme.brand.withOpacity(0.04)
                            : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(6),
                        border: Border(
                          top: BorderSide(
                              color: isSelected
                                  ? AppTheme.brand.withOpacity(0.4)
                                  : AppTheme.border),
                          right: BorderSide(
                              color: isSelected
                                  ? AppTheme.brand.withOpacity(0.4)
                                  : AppTheme.border),
                          bottom: BorderSide(
                              color: isSelected
                                  ? AppTheme.brand.withOpacity(0.4)
                                  : AppTheme.border),
                          // Gold left accent when selected
                          left: BorderSide(
                            color: isSelected
                                ? AppTheme.brand
                                : AppTheme.border,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icon container — square, not circle
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.brand.withOpacity(0.10)
                                  : AppTheme.surfaceElevated,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.brand.withOpacity(0.3)
                                    : AppTheme.border,
                              ),
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
                          // Check — line only, no filled circle
                          if (isSelected)
                            Icon(
                              Icons.check,
                              color: AppTheme.brand,
                              size: 18,
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
            Text(
              'Current balance',
              style: Theme.of(context).textTheme.displaySmall,
            ),
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

            // Amount input — borderless inside a card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    '₹',
                    style: GoogleFonts.dmSerifDisplay(
                      fontSize: 36,
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
                      style: GoogleFonts.dmSerifDisplay(
                        fontSize: 36,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                      decoration: InputDecoration(
                        hintText: '0',
                        hintStyle: GoogleFonts.dmSerifDisplay(
                          fontSize: 36,
                          color: AppTheme.border,
                          height: 1.2,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      autofocus: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Info note — left border accent style
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                border: Border(
                  left: const BorderSide(color: AppTheme.brand, width: 2),
                  top: BorderSide(color: AppTheme.border),
                  right: BorderSide(color: AppTheme.border),
                  bottom: BorderSide(color: AppTheme.border),
                ),
              ),
              child: Text(
                'This is your starting point. Your SMS will keep it updated automatically.',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                  height: 1.5,
                ),
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
            Text(
              'Next income',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'When do you expect to receive money next?',
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
              decoration: const InputDecoration(
                hintText: '15,000',
                prefixText: '₹  ',
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
                        onPrimary: AppTheme.surface,
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
                    fontSize: 18,
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

  // ── Step 4: First Bill ───────────────────────────────────────────────────────

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
            Text(
              'Any upcoming bills?',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Add one now — or skip and add later. Bills let us warn you before they bounce.',
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
              decoration: const InputDecoration(
                hintText: '0',
                prefixText: '₹  ',
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
                        onPrimary: AppTheme.surface,
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

  // ── Small helper — ALL CAPS field label ─────────────────────────────────────

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