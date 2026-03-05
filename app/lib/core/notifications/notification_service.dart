import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notification service.
/// IMPORTANT: init() sets up the channel only — it does NOT fire any notification.
/// showTransactionAlert() is called ONLY from SmsService when a new bank SMS
/// is parsed successfully. This ensures notifications fire on transaction, NOT app open.
class NotificationService {
  static FlutterLocalNotificationsPlugin? _plugin;

  static const _channelId   = 'coachmint_txn';
  static const _channelName = 'Transaction Alerts';
  static const _channelDesc = 'Fires when a bank transaction SMS is detected';

  // ── Init (called once in main, no notification fired here) ───────────────
  static Future<void> init(FlutterLocalNotificationsPlugin plugin) async {
    _plugin = plugin;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onTap,
    );

    // Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );

    await plugin
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    debugPrint('[NotificationService] initialised — no notification fired');
  }

  // ── Tap handler ───────────────────────────────────────────────────────────
  static void _onTap(NotificationResponse response) {
    // payload == 'categorize' → app should navigate to /categorize
    // GoRouter navigation from outside widget tree:
    // store the pending route in a global notifier and let the router pick it up.
    debugPrint('[NotificationService] tapped: ${response.payload}');
    pendingRoute.value = response.payload;
  }

  /// Global pending route — router listens to this and navigates when non-null.
  static final ValueNotifier<String?> pendingRoute = ValueNotifier(null);

  // ── Fire transaction alert ─────────────────────────────────────────────────
  /// Called ONLY from SmsService._handleBankSms() after a valid transaction
  /// is parsed. Never called on app start.
  static Future<void> showTransactionAlert({
    required double amount,
    required String direction, // 'in' | 'out'
    String? payee,
  }) async {
    if (_plugin == null) {
      debugPrint('[NotificationService] plugin not initialised');
      return;
    }

    final isIncome = direction == 'in';
    final emoji    = isIncome ? '💰' : '💸';
    final verb     = isIncome ? 'received' : 'sent';
    final amtStr   = '₹${amount.toStringAsFixed(0)}';

    final title = '$emoji Transaction: $amtStr $verb';
    final body = payee != null && payee.trim().isNotEmpty
        ? '${isIncome ? 'From' : 'To'}: ${payee.trim()} — tap to categorize.'
        : 'Tap to categorize this transaction.';

    await _plugin!.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, // unique id
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          color: Color(0xFF00E5A0),
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'categorize',
    );

    debugPrint('[NotificationService] fired: $title');
  }
}