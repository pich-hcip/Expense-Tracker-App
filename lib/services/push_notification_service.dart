import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/api_client.dart';
import '../firebase_options.dart';

// Runs when a message arrives while the app is closed or in the background
@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

class PushNotificationService {
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Must be the same id as Spring Boot ("expense_alerts")
  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'expense_alerts',
    'Expense Alerts',
    description: 'Income, expense, budget and balance alerts',
    importance: Importance.high,
    playSound: true,
  );

  static Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);

    // 1. Request permission (iOS and Android 13+)
    NotificationSettings settings =
        await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    }

    // 2. Setup local notifications (for foreground display)
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings();

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. FCM token can change, send the new one to Spring Boot
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      _sendTokenToSpringBoot(newToken);
    });

    // 4. FCM does NOT show notifications automatically when the app is open
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              importance: Importance.high,
              priority: Priority.high,
              playSound: true,
            ),
            iOS: const DarwinNotificationDetails(presentSound: true),
          ),
        );
      }
    });
  }

  // Call this AFTER login (needs the JWT)
  static Future<void> registerToken() async {
    try {
      String? token = await FirebaseMessaging.instance.getToken();
      print('FCM TOKEN: $token');
      if (token != null) {
        await _sendTokenToSpringBoot(token);
      }
    } catch (e) {
      print("Error getting FCM token: $e");
    }
  }

  static Future<void> _sendTokenToSpringBoot(String token) async {
    try {
      // baseUrl already ends with /api
      await ApiClient.dio.post('/device-tokens', data: {
        'token': token,
        'platform': Platform.isIOS ? 'IOS' : 'ANDROID',
      });
      print("Token successfully sent to backend");
    } catch (e) {
      print("Failed to send token to backend: $e");
    }
  }
}