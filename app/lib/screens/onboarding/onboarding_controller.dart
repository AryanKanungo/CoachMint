import 'package:get/get.dart';

class OnboardingController extends GetxController {
  var isIconVisible = false.obs;
  // var isTextVisible = false.obs; // Old way
  var isText1Visible = false.obs; // Replaced with separate bools
  var isText2Visible = false.obs; // for a true stagger
  var isButtonVisible = false.obs;

  @override
  void onReady() {
    super.onReady();
    // Trigger staggered animations
    Future.delayed(const Duration(milliseconds: 200), () => isIconVisible.value = true);
    // Future.delayed(const Duration(milliseconds: 500), () => isTextVisible.value = true);
    Future.delayed(const Duration(milliseconds: 500), () => isText1Visible.value = true); // First text
    Future.delayed(const Duration(milliseconds: 700), () => isText2Visible.value = true); // Second text
    Future.delayed(const Duration(milliseconds: 1000), () => isButtonVisible.value = true); // Button last
  }

  void goToNextStep() {
    // In a real app, this would go to the SMS permission screen.
    // For now, we go to the main app screen.

    // --- UPDATED LINE ---
    // Was: Get.offAllNamed('/main');
    Get.offNamed('/recurring-expenses'); // Replaces onboarding with the next step
  }
}