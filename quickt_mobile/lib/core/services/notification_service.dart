import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const _channelId = 'quicktz_main';
  static const _channelName = 'QuickTZ Alerts';
  static const _channelDesc = 'Booking confirmations, payment receipts, and travel updates';

  static const _androidDetails = AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
    enableVibration: true,
    playSound: true,
  );

  static const _notifDetails = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    ),
  );

  Future<void> init() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Request permission on Android 13+
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  int _nextId = 1;

  Future<void> show({
    required String title,
    required String body,
  }) async {
    if (!_initialized) await init();
    await _plugin.show(_nextId++, title, body, _notifDetails);
  }

  Future<void> showBookingConfirmed({
    required String origin,
    required String destination,
    required String ticketCode,
  }) =>
      show(
        title: 'Booking Confirmed! 🎫',
        body: '$origin → $destination · Ticket: $ticketCode',
      );

  Future<void> showPaymentSuccess({
    required String amount,
    required String method,
  }) =>
      show(
        title: 'Payment Successful ✅',
        body: 'XOF $amount paid via $method. Check your ticket in the app.',
      );

  Future<void> showTripReminder({
    required String origin,
    required String destination,
    required String departureTime,
  }) =>
      show(
        title: 'Trip Reminder 🚌',
        body: '$origin → $destination departs at $departureTime. Get ready!',
      );
}
