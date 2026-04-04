import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  static Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    // Handle foreground notifications
  }

  static void _handleMessageOpenedApp(RemoteMessage message) {
    // Handle notification tap when app was in background
  }
}
