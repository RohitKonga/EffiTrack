import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
}

class NotificationService {
  NotificationService._internal();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  AndroidNotificationChannel? _androidChannel;
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    await _requestPermissions();
    await _configureLocalNotifications();
    _listenToForegroundMessages();

    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      _syncTokenWithServer(token);
    });

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _configureLocalNotifications() async {
    _androidChannel = const AndroidNotificationChannel(
      'effitrack_announcement_channel',
      'Announcements',
      description: 'Notifications for new announcements',
      importance: Importance.high,
    );

    const androidInitialization = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitialization = DarwinInitializationSettings();

    await _localNotificationsPlugin.initialize(
      const InitializationSettings(
        android: androidInitialization,
        iOS: iosInitialization,
      ),
    );

    await _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel!);
  }

  void _listenToForegroundMessages() {
    FirebaseMessaging.onMessage.listen((message) async {
      final notification = message.notification;
      if (notification == null) return;

      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannel?.id ?? 'effitrack_default',
            _androidChannel?.name ?? 'Notifications',
            channelDescription: _androidChannel?.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: message.data['type'] ?? 'announcement',
      );
    });
  }

  Future<void> syncDeviceTokenIfNeeded() async {
    if (apiService.token == null) return;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await _syncTokenWithServer(token);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to sync FCM token: $e');
      }
    }
  }

  Future<void> clearTokenOnServer() async {
    if (apiService.token == null) return;
    try {
      await apiService.post('/profile/fcm-token', {'token': null});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to clear FCM token: $e');
      }
    }
  }

  Future<void> _syncTokenWithServer(String? token) async {
    if (token == null || apiService.token == null) return;
    try {
      await apiService.post('/profile/fcm-token', {'token': token});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to update FCM token: $e');
      }
    }
  }
}

