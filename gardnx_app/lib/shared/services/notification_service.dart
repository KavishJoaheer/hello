import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles push notification permission, FCM token, and foreground display.
///
/// Call [NotificationService.initialize] once after Firebase.initializeApp().
class NotificationService {
  NotificationService._();

  static final _messaging = FirebaseMessaging.instance;
  static final _localNotifications = FlutterLocalNotificationsPlugin();

  static const _channelId = 'gardnx_tasks';
  static const _channelName = 'Garden Tasks';
  static const _channelDesc = 'Reminders for watering, sowing, and harvesting';

  // ---------------------------------------------------------------------------
  // Init
  // ---------------------------------------------------------------------------

  static Future<void> initialize() async {
    // 1. Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Set up local notifications (for foreground FCM display on Android)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _localNotifications.initialize(initSettings);

    // 3. Create Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 4. Handle FCM messages while app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 5. Optional: log the FCM token for backend configuration
    try {
      final token = await _messaging.getToken();
      debugPrint('FCM token: $token');
    } catch (_) {
      // Token unavailable without google-services.json
    }
  }

  // ---------------------------------------------------------------------------
  // Foreground handler
  // ---------------------------------------------------------------------------

  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDesc,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Background handler (top-level, registered in main.dart)
  // ---------------------------------------------------------------------------

  /// Register as: FirebaseMessaging.onBackgroundMessage(_bgHandler)
  /// Must be a top-level function.
  static Future<void> backgroundHandler(RemoteMessage message) async {
    debugPrint('Background FCM: ${message.messageId}');
  }
}
