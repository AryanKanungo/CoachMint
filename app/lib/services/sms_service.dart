import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import '../models/transaction_model.dart';
import 'sms_background_handler.dart';
import 'package:flutter/widgets.dart';

class SmsService extends GetxService {
  final Telephony _telephony = Telephony.instance;

  Telephony get telephony => _telephony;

  @override
  void onInit() {
    super.onInit();
    // DO NOT REGISTER LISTENERS HERE (causes redraw loop)
  }

  /// Call this from HomeScreen.initState()
  Future<void> init() async {
    final granted = await requestSmsPermission();
    if (!granted) {
      print("❌ SMS Permission not granted");
      return;
    }

    // Register AFTER the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("📩 Registering SMS listeners...");
      _telephony.listenIncomingSms(
        onNewMessage: _foregroundSmsHandler,
        onBackgroundMessage: backgroundSmsHandler,
      );
    });
  }

  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    return status.isGranted;
  }

  // Foreground SMS handler
  void _foregroundSmsHandler(SmsMessage message) {
    print("📩 Foreground SMS received");
    parseAndSaveSms(message);
  }

  Future<List<TransactionModel>> getPastSms(int days) async {
    final bool permissionGranted = await requestSmsPermission();
    if (!permissionGranted) {
      Get.snackbar("Error", "SMS permission is required.");
      return [];
    }

    final DateTime since = DateTime.now().subtract(Duration(days: days));

    List<SmsMessage> messages = await _telephony.getInboxSms(
      columns: [SmsColumn.BODY, SmsColumn.DATE],
      filter: SmsFilter.where(SmsColumn.DATE)
          .greaterThan(since.millisecondsSinceEpoch.toString()),
      sortOrder: [OrderBy(SmsColumn.DATE, sort: Sort.DESC)],
    );

    return messages.map((msg) => TransactionModel.fromSms(msg)).toList();
  }

  // Parse but DO NOT update UI during build
  Future<void> parseAndSaveSms(SmsMessage message) async {
    if (message.body == null || message.body!.isEmpty) return;

    final txn = TransactionModel.fromSms(message);

    if (txn.status == TxnStatus.processed) {
      print("📦 Parsed TXN → Amount: ${txn.amount}");
    }
  }
}
