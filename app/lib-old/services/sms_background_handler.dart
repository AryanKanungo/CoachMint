import 'package:flutter/widgets.dart';
import 'package:telephony/telephony.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import '../models/transaction_model.dart';

@pragma('vm:entry-point')
void backgroundSmsHandler(SmsMessage message) async {
  // Background isolate — be careful: keep work minimal.
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Parse message locally (do not depend on app service singletons here).
  try {
    if (message.body == null || message.body!.isEmpty) return;
    final txn = TransactionModel.fromSms(message);
    if (txn.status == TxnStatus.processed) {
      // For now, only log in background. Writing to Firestore from background
      // works but is more complex; keep it simple and safe.
      print("📦 [BG] Parsed TXN → Amount: ${txn.amount}");
    }
  } catch (e) {
    print("Error in backgroundSmsHandler: $e");
  }
}
