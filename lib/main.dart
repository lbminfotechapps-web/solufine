import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';

import 'package:solufine/app.dart';
import 'package:solufine/core/di/global_di.dart';
import 'package:solufine/core/location_tracking/background_location_service.dart';
import 'package:solufine/core/notifications/fcm_service.dart';
import 'package:solufine/core/notifications/local_notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint(
    '[LocalNotificationService] Background message received: ${message.messageId}',
  );
  // Firebase displays notification payloads in the background itself.
  // Data-only messages need a local notification.
  if (message.notification == null) {
    final title = message.data['notificationTitle']?.toString() ?? 'Solufine';
    final body =
        message.data['notificationMessage']?.toString() ??
        message.data['body']?.toString() ??
        '';
    try {
      await LocalNotificationService.instance.initialize();
      await LocalNotificationService.instance.showNotification(
        title: title,
        body: body,
        data: message.data,
      );
    } catch (error, stackTrace) {
      debugPrint(
        '[LocalNotificationService] Background notification display failed: $error',
      );
      debugPrintStack(stackTrace: stackTrace);
    }
  }
  await LocalNotificationService.instance.handleLocationNotification(
    data: message.data,
    title: message.notification?.title,
    body: message.notification?.body,
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final imagePicker = ImagePickerPlatform.instance;
  if (imagePicker is ImagePickerAndroid) {
    imagePicker.useAndroidPhotoPicker = true;
  }

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await initGlobalDi();

  await LocalNotificationService.instance.initialize();

  await FcmService.instance.initialize();

  await BackgroundLocationService.initialize();

  await BackgroundLocationService.checkServiceStatus();

  runApp(const MyApp());
}
