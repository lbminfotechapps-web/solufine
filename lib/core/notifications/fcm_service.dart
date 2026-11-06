import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:solufine/core/notifications/fcm_token_service.dart';
import 'package:solufine/core/notifications/local_notification_service.dart';
import 'package:solufine/core/notifications/notification_navigation_service.dart';

class FcmService {
  FcmService._();

  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  bool _initialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    // Prevent duplicate listeners if initialize() is called again.
    if (_initialized) {
      debugPrint('FCM SERVICE ALREADY INITIALIZED');
      return;
    }

    _initialized = true;

    debugPrint('======================================');
    debugPrint('FCM SERVICE INITIALIZING');
    debugPrint('======================================');

    // ============================================================
    // 1. TOKEN REFRESH LISTENER
    // IMPORTANT:
    // Start this before fetching the current token.
    // ============================================================

    FcmTokenService.instance.listenTokenRefresh();

    // ============================================================
    // 2. REQUEST NOTIFICATION PERMISSION
    // ============================================================

    final NotificationSettings settings = await _requestPermission();

    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('======================================');
      debugPrint('IOS FOREGROUND PRESENTATION ENABLED');
      debugPrint('======================================');
    }

    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await FcmTokenService.instance.saveCurrentToken();
    } else {
      debugPrint('======================================');
      debugPrint('NOTIFICATION PERMISSION NOT GRANTED');
      debugPrint('FCM TOKEN REQUEST SKIPPED');
      debugPrint('======================================');
    }

    // ============================================================
    // 4. FOREGROUND MESSAGE LISTENER
    // ============================================================

    _listenForegroundMessages();

    // ============================================================
    // 5. BACKGROUND NOTIFICATION CLICK
    // ============================================================

    _listenNotificationClick();

    // ============================================================
    // 6. LOCAL NOTIFICATION CLICK
    // ============================================================

    LocalNotificationService.instance.onNotificationTap =
        (Map<String, dynamic> data) {
          debugPrint('======================================');
          debugPrint('LOCAL NOTIFICATION CLICKED');
          debugPrint('DATA: $data');
          debugPrint('======================================');

          NotificationNavigationService.instance.handleNotification(data);
        };

    // ============================================================
    // 7. TERMINATED APP NOTIFICATION
    // ============================================================

    await _checkInitialNotification();

    debugPrint('======================================');
    debugPrint('FCM SERVICE INITIALIZED');
    debugPrint('======================================');
  }

  // ============================================================
  // PERMISSION
  // ============================================================

  Future<NotificationSettings> _requestPermission() async {
    final NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,

      // You can enable if required
      // announcement: false,
      // carPlay: false,
      // criticalAlert: false,
      // provisional: false,
    );

    debugPrint('======================================');
    debugPrint('NOTIFICATION PERMISSION');
    debugPrint('STATUS: ${settings.authorizationStatus}');
    debugPrint('======================================');

    return settings;
  }

  // ============================================================
  // FOREGROUND MESSAGE
  // ============================================================

  void _listenForegroundMessages() {
    FirebaseMessaging.onMessage.listen(
      (RemoteMessage message) async {
        debugPrint('======================================');
        debugPrint('FCM MESSAGE RECEIVED - FOREGROUND');
        debugPrint('MESSAGE ID: ${message.messageId}');
        debugPrint('NOTIFICATION TITLE: ${message.notification?.title}');
        debugPrint('NOTIFICATION BODY: ${message.notification?.body}');
        debugPrint('DATA: ${message.data}');
        debugPrint('======================================');

        final String title =
            message.data['notificationTitle']?.toString() ??
            message.notification?.title ??
            'Solufine';

        final String body =
            message.data['notificationMessage']?.toString() ??
            message.notification?.body ??
            '';

        final String notificationType =
            message.data['notificationType']?.toString() ?? '';

        debugPrint('======================================');
        debugPrint('PARSED NOTIFICATION');
        debugPrint('TITLE   : $title');
        debugPrint('MESSAGE : $body');
        debugPrint('TYPE    : $notificationType');
        debugPrint('======================================');

        if (await LocalNotificationService.instance.handleLocationNotification(
          data: message.data,
          title: title,
        )) {
          return;
        }

        if (body.trim().isEmpty) {
          debugPrint('Notification body empty.');
          return;
        }

        // Android does not display FCM notification automatically
        // while application is in foreground.
        if (Platform.isAndroid) {
          await LocalNotificationService.instance.showNotification(
            title: title,
            body: body,
            data: message.data,
          );
        }

        // iOS notification is displayed by:
        //
        // setForegroundNotificationPresentationOptions(
        //   alert: true,
        //   badge: true,
        //   sound: true,
        // );
      },
      onError: (error) {
        debugPrint('FOREGROUND FCM ERROR: $error');
      },
    );
  }
  // ============================================================
  // BACKGROUND -> USER CLICKS NOTIFICATION
  // ============================================================

  void _listenNotificationClick() {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('======================================');
      debugPrint('FCM NOTIFICATION CLICKED');
      debugPrint('STATE: BACKGROUND');
      debugPrint('DATA: ${message.data}');
      debugPrint('======================================');

      NotificationNavigationService.instance.handleNotification(message.data);
    });
  }

  // ============================================================
  // TERMINATED -> USER CLICKS NOTIFICATION
  // ============================================================

  Future<void> _checkInitialNotification() async {
    final RemoteMessage? message = await _messaging.getInitialMessage();

    if (message == null) {
      return;
    }

    debugPrint('======================================');
    debugPrint('APP OPENED FROM NOTIFICATION');
    debugPrint('PREVIOUS STATE: TERMINATED');
    debugPrint('DATA: ${message.data}');
    debugPrint('======================================');

    // Router may not be ready immediately
    // when application starts.
    Future.delayed(const Duration(seconds: 1), () {
      NotificationNavigationService.instance.handleNotification(message.data);
    });
  }
}
