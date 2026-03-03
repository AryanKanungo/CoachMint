import 'package:flutter/material.dart';
import 'package:get/get.dart';


import 'onboarding_controller.dart';
import '../../utils/colors.dart';

class OnboardingScreen extends GetView<OnboardingController> {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize the controller
    Get.put(OnboardingController());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Animated logo/icon
              Obx(
                    () => AnimatedOpacity(
                  opacity: controller.isIconVisible.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                        0, controller.isIconVisible.value ? 0 : 20, 0),
                    child: Image.asset(
                      'assets/logo_icon.png',
                      height: 300,
                      width: 300,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Animated Text
              Obx(
                    () => AnimatedOpacity(
                  opacity: controller.isText1Visible.value ? 1.0 : 0.0, // Use isText1Visible
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                        0, controller.isText1Visible.value ? 0 : 20, 0), // Use isText1Visible
                    child: Text(
                      "Welcome to CoachMint",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineLarge,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Obx(
                    () => AnimatedOpacity(
                  opacity: controller.isText1Visible.value ? 1.0 : 0.0, // Use isText2Visible
                  duration: const Duration(milliseconds: 500),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                        0, controller.isText1Visible.value ? 0 : 20, 0), // Use isText2Visible
                    child: Text(
                      "Your new agentic partner in\nmanaging finances.",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.secondaryText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),

              // Animated Button
              Obx(
                    () => AnimatedOpacity(
                  opacity: controller.isButtonVisible.value ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 500),
                  // delay: const Duration(milliseconds: 800), // <-- Removed invalid parameter
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                    transform: Matrix4.translationValues(
                        0, controller.isButtonVisible.value ? 0 : 20, 0),
                    child: ElevatedButton(
                      onPressed: controller.goToNextStep,
                      child: const Text("Get Started"),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}