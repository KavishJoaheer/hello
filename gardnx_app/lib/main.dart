import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'shared/services/notification_service.dart';

// Must be top-level for FCM background handling.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.backgroundHandler(message);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase - wrapped in try/catch for development environments
  // where Firebase may not be configured yet.
  try {
    await Firebase.initializeApp();
    // Register background FCM handler before anything else.
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    // Initialize local notifications + request FCM permission.
    await NotificationService.initialize();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
    debugPrint('Running without Firebase. Some features will be unavailable.');
  }

  // Catch Flutter framework errors and log them.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };

  runApp(
    const ProviderScope(
      child: GardNxApp(),
    ),
  );
}
