import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:governmentapp/services/notification/notification_service.dart';
import 'package:governmentapp/utils/logger.dart';

class FirebaseApi {
  // fire base messaging instance
  final _firebaseMessaging = FirebaseMessaging.instance;
  final _notificationService = NotificationService();

  // function to init notifications
  Future<void> initNotifications() async {
    // request permissions from user (will prompt user to allow notification)
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // fetch firebase cloud messaging for this device
    final fCM_Token = await _firebaseMessaging.getToken();
    AppLogger.i("FCM Token: $fCM_Token");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    initPushNotification();
  }

  // Get FCM token for testing
  Future<String?> getFCMToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.i('Got a message whilst in the foreground!');
    AppLogger.i('Message data: ${message.data}');

    if (message.notification != null) {
      AppLogger.i(
          'Message also contained a notification: ${message.notification}');
      // You can show a local notification here if needed
    }
  }

  // functions to handle received messages
  void handleMessage(RemoteMessage? message) {
    if (message == null) return;

    AppLogger.i('Handling message: ${message.data}');

    // navigate to new screen when message is received and user taps notification
    _notificationService.navigatorKey.currentState?.pushNamed(
      '/notifications',
      arguments: message,
    );
  }

  // function to init background settings
  Future<void> initPushNotification() async {
    // handle notification if the app was terminated and now opened
    _firebaseMessaging.getInitialMessage().then(handleMessage);

    // attach event listeners for when a notification opens the app
    FirebaseMessaging.onMessageOpenedApp.listen(handleMessage);
  }
}
