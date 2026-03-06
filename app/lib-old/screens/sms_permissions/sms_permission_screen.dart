import 'package:coachmint/screens/sms_permissions/sms_permission_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/colors.dart';

class SmsPermissionScreen extends GetView<SmsPermissionController> {
  const SmsPermissionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(SmsPermissionController());
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(
                Icons.sms_rounded,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              Text(
                "Enable Transaction Tracking",
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: 16),
              Text(
                "To automatically track your expenses, FinAgent needs permission to read your transaction-related SMS messages. We only read messages from banks and UPI apps.",
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                  height: 1.5,
                ),
              ),
              const Spacer(),
              Obx(
                    () => ElevatedButton(
                  onPressed: controller.isProcessing.value
                      ? null
                      : controller.requestAndSyncSms,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                  child: controller.isProcessing.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Grant Permission"),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: controller.skip,
                child: const Text("I'll add manually"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}