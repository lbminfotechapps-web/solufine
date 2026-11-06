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
  await LocalNotificationService.instance.handleLocationNotification(
    data: message.data,
    title: message.notification?.title,
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
