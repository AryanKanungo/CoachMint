// import 'package:flutter/foundation.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:telephony/telephony.dart';
// import 'package:permission_handler/permission_handler.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
//
// import '../supabase/supabase_client.dart';
// import 'sms_parser.dart';
//
// /// Background SMS handler — called even when app is terminated
// @pragma('vm:entry-point')
// void backgroundMessageHandler(SmsMessage message) {
//   _processSms(message);
// }
//
// Future<void> _processSms(SmsMessage message) async {
//   final body = message.body;
//   final sender = message.address;
//   if (body == null || sender == null) return;
//
//   final parsed = SMSParser.parse(body, sender);
//   if (parsed == null) return;
//
//   try {
//     final userId = Supabase.instance.client.auth.currentUser?.id;
//     if (userId == null) return;
//
//     // Check for duplicate
//     final existing = await Supabase.instance.client
//         .from('transactions')
//         .select('id')
//         .eq('raw_sms_hash', parsed.smsHash)
//         .maybeSingle();
//
//     if (existing != null) return; // Duplicate
//
//     final category = SMSParser.autoCategorise(
//       parsed.merchant,
//       parsed.amount,
//       parsed.type,
//     );
//
//     await Supabase.instance.client.from('transactions').insert({
//       'user_id': userId,
//       'type': parsed.type,
//       'amount': parsed.amount,
//       'sms_balance': parsed.balance,
//       'merchant': parsed.merchant,
//       'category_top': category['category_top'],
//       'category_sub': category['category_sub'],
//       'source': 'sms',
//       'raw_sms_hash': parsed.smsHash,
//       'parse_confidence': parsed.confidence,
//       'needs_review': parsed.confidence < 0.85,
//       'transaction_date': DateTime.now().toIso8601String(),
//     });
//
//     // Update wallet balance if SMS contains Avl Bal
//     if (parsed.balance != null) {
//       await Supabase.instance.client
//           .from('user_profile')
//           .update({'current_wallet': parsed.balance})
//           .eq('user_id', userId);
//     }
//   } catch (e) {
//     debugPrint('Error saving SMS transaction: $e');
//   }
// }
//
// class SmsListenerService {
//   final Telephony _telephony = Telephony.instance;
//
//   Future<bool> requestPermissions() async {
//     final smsStatus = await Permission.sms.request();
//     return smsStatus.isGranted;
//   }
//
//   Future<void> startListening() async {
//     final granted = await requestPermissions();
//     if (!granted) {
//       debugPrint('SMS permission not granted');
//       return;
//     }
//
//     _telephony.listenIncomingSms(
//       onNewMessage: (SmsMessage message) async {
//         await _processSms(message);
//       },
//       onBackgroundMessage: backgroundMessageHandler,
//     );
//
//     debugPrint('SMS listener started');
//   }
//
//   /// Read last 30 days of SMS for initial population
//   Future<void> importExistingSms() async {
//     try {
//       final messages = await _telephony.getInboxSms(
//         columns: [SmsColumn.ADDRESS, SmsColumn.BODY, SmsColumn.DATE],
//         filter: SmsFilter.where(SmsColumn.DATE)
//             .greaterThan(
//           DateTime.now()
//               .subtract(const Duration(days: 30))
//               .millisecondsSinceEpoch
//               .toString(),
//         ),
//       );
//
//       for (final msg in messages) {
//         await _processSms(msg);
//       }
//
//       debugPrint('Imported ${messages.length} existing SMS messages');
//     } catch (e) {
//       debugPrint('Error importing existing SMS: $e');
//     }
//   }
// }
//
// final smsListenerProvider = Provider<SmsListenerService>((ref) {
//   return SmsListenerService();
// });