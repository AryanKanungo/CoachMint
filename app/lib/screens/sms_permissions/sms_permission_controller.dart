import 'package:get/get.dart';

import '../../services/sms_service.dart';

class SmsPermissionController extends GetxController {
  final SmsService _smsService = Get.find<SmsService>();
  var isProcessing = false.obs;

  Future<void> requestAndSyncSms() async {
    isProcessing.value = true;
    try {
      // 1. Request permission
      final bool granted = await _smsService.requestSmsPermission();

      if (granted) {
        // 2. We don't need to sync here anymore.
        // The user will do it from the drawer.

        // 3. Move to the main app
        Get.offAllNamed('/main'); // --- UPDATED ---

      } else {
        Get.snackbar(
          "Permission Denied",
          "You can grant SMS permission later in your phone settings.",
        );
        // Still go to the main app
        Get.offAllNamed('/main'); // --- UPDATED ---
      }
    } catch (e) {
      Get.snackbar("Error", "An error occurred: $e");
    } finally {
      isProcessing.value = false;
    }
  }

  void skip() {
    // Skip SMS parsing and go to the main app
    Get.offAllNamed('/main'); // --- UPDATED ---
  }
}