// import 'package:get/get.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
//
// import '../../models/transaction_model.dart';
// import '../../services/sms_service.dart';
//
// class SmsCategorizationController extends GetxController {
//   late final SmsService _smsService;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//
//   var isLoaded = false.obs;
//   var transactions = <TransactionModel>[].obs;
//   var isCategorizing = false.obs;
//   var draggingIndex = (-1).obs;
//
//   @override
//   void onInit() {
//     _smsService = Get.find<SmsService>();
//     super.onInit();
//     loadTransactions();
//   }
//
//   Future<void> loadTransactions() async {
//     isLoaded.value = false;
//
//     try {
//       final uid = _auth.currentUser?.uid;
//       if (uid == null) {
//         isLoaded.value = true;
//         return;
//       }
//
//       // 1️⃣ Fetch already categorized txn IDs from Firestore
//       final snap = await _db
//           .collection("users")
//           .doc(uid)
//           .collection("transactions")
//           .get();
//
//       final Set<String> savedTxnIds =
//       snap.docs.map((d) => d["txnId"] as String).toSet();
//
//       // 2️⃣ Read all SMS from the last 7 days
//       final allSms = await _smsService.getPastSms(7);
//
//       // 3️⃣ Filter out SMS that already exist in Firestore
//       transactions.value = allSms
//           .where((txn) =>
//       txn.status == TxnStatus.processed &&
//           !savedTxnIds.contains(txn.txnId))
//           .toList();
//     } catch (e) {
//       Get.snackbar("Error", "Could not read SMS: $e");
//     } finally {
//       isLoaded.value = true;
//     }
//   }
//
//   void startCategorizing(int index) {
//     draggingIndex.value = index;
//     isCategorizing.value = true;
//   }
//
//   void stopCategorizing() {
//     isCategorizing.value = false;
//     draggingIndex.value = -1;
//   }
//
//   List<TransactionModel> get allCategorized =>
//       transactions.where((t) => t.category != null).toList();
//
//   // 🔥 SAVE A TRANSACTION + REMOVE FROM UNCATEGORISED
//   Future<void> categorizeTransaction(
//       TransactionModel txn, String category) async {
//     final uid = _auth.currentUser?.uid;
//     if (uid == null) return;
//
//     try {
//       // save to Firestore using txnId
//       await _db
//           .collection("users")
//           .doc(uid)
//           .collection("transactions")
//           .doc(txn.txnId)
//           .set(txn.toFirestore()..["category"] = category);
//
//       await Future.delayed(const Duration(milliseconds: 50));
//
//       transactions.remove(txn);
//
//       if (transactions.isEmpty) {
//         await Future.delayed(const Duration(milliseconds: 100));
//         Get.back();
//         Get.snackbar("Done 🎉", "All transactions categorized!");
//       }
//     } catch (e) {
//       Get.snackbar("Error", "Failed to save transaction! $e");
//     }
//   }
// }
