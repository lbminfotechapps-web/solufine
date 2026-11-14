import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/location_util.dart';

class LocalNotificationService {
  LocalNotificationService._();

  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // ============================================================
  // NOTIFICATION CLICK CALLBACK
  // ============================================================

  void Function(Map<String, dynamic> data)? onNotificationTap;

  // ============================================================
  // ANDROID NOTIFICATION CHANNEL
  // ============================================================

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel',
    'High Importance Notifications',
    description: 'Used for important notifications.',
    importance: Importance.max,
  );

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    debugPrint('======================================');
    debugPrint('INITIALIZING LOCAL NOTIFICATIONS');
    debugPrint('======================================');

    // ----------------------------------------------------------
    // Android settings
    // ----------------------------------------------------------

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // ----------------------------------------------------------
    // iOS settings
    // ----------------------------------------------------------

    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    // ----------------------------------------------------------
    // Initialization settings
    // ----------------------------------------------------------

    const InitializationSettings initializationSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    // ==========================================================
    // IMPORTANT:
    // New flutter_local_notifications API uses named "settings"
    // ==========================================================

    await _notifications.initialize(
      settings: initializationSettings,

      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('======================================');
        debugPrint('LOCAL NOTIFICATION CLICKED');
        debugPrint('ID      : ${response.id}');
        debugPrint('ACTION  : ${response.actionId}');
        debugPrint('PAYLOAD : ${response.payload}');
        debugPrint('======================================');

        _handleNotificationPayload(response.payload);
      },
    );

    // ============================================================
    // CREATE ANDROID CHANNEL
    // ============================================================

    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidImplementation?.createNotificationChannel(channel);

    debugPrint('======================================');
    debugPrint('LOCAL NOTIFICATION SERVICE INITIALIZED');
    debugPrint('======================================');
  }

  // ============================================================
  // HANDLE NOTIFICATION PAYLOAD
  // ============================================================

  void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.isEmpty) {
      debugPrint('Notification payload is empty');

      return;
    }

    try {
      debugPrint('======================================');
      debugPrint('DECODING NOTIFICATION PAYLOAD');
      debugPrint('PAYLOAD: $payload');
      debugPrint('======================================');

      final dynamic decodedData = jsonDecode(payload);

      if (decodedData is Map) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(
          decodedData,
        );

        debugPrint('======================================');
        debugPrint('NOTIFICATION DATA DECODED');
        debugPrint('DATA: $data');
        debugPrint('======================================');

        // Send notification click to FcmService
        onNotificationTap?.call(data);
      } else {
        debugPrint('Notification payload is not a Map');
      }
    } catch (e, stackTrace) {
      debugPrint('======================================');
      debugPrint('NOTIFICATION PAYLOAD ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');
      debugPrint('======================================');
    }
  }

  // ============================================================
  // SHOW NOTIFICATION
  // ============================================================

  /// Returns true when the payload matches a location request.
  /// Sends one current location per request; never requests permissions here.
  Future<bool> handleLocationNotification({
    required Map<String, dynamic> data,
    String? title,
    String? body,
  }) async {
    final trace = DateTime.now().microsecondsSinceEpoch.toString();
    final timer = Stopwatch()..start();
    void log(String message, [Object? value]) {
      if (!kDebugMode) return;
      debugPrint(
        '[LocalNotificationService][$trace][${timer.elapsedMilliseconds}ms] $message',
      );
      if (value != null) {
        debugPrint(
          '[LocalNotificationService][$trace] $value',
          wrapWidth: 1000,
        );
      }
    }

    log('Notification received', {'title': title, 'data': data});
    final notificationTitle = data['notificationTitle']?.toString() ?? title;
    final notificationMessage =
        data['notificationMessage']?.toString() ??
        data['body']?.toString() ??
        body ??
        '';
    final notificationType = data['notificationType']?.toString() ?? '';
    log('NOTIFICATION TITLE: ${notificationTitle ?? '(missing)'}');
    log('NOTIFICATION MESSAGE: $notificationMessage');
    log('NOTIFICATION TYPE: $notificationType');
    final matchingFields =
        {
              'TITLE': notificationTitle ?? '',
              'MESSAGE': notificationMessage,
              'TYPE': notificationType,
            }.entries
            .where((field) {
              final value = field.value.trim().toLowerCase();
              return value == 'live location' || value == 'location service';
            })
            .map((field) => field.key)
            .toList();
    if (matchingFields.isEmpty) {
      log(
        'Skipped location API: title, message and type do not match a location request.',
      );
      return false;
    }
    log('Location request matched fields', matchingFields);
    var stage = 'read logged-in user';
    try {
      log('Location notification matched. Reading logged-in user.');
      final userData = await SecureStorage.instance.getUserData();
      final userId = userData?['user_id']?.toString() ?? '';
      log('User ID', userId.isEmpty ? '(missing)' : userId);
      if (userId.isEmpty) {
        log('Skipped location API: no logged-in user.');
        return true;
      }
      stage = 'check location permission';
      final permission = await Geolocator.checkPermission();
      log('Location permission', permission.name);
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        log('Skipped location API: permission is not granted.');
        return true;
      }
      stage = 'check device location service';
      final locationEnabled = await Geolocator.isLocationServiceEnabled();
      log('Device location service enabled', locationEnabled);
      if (!locationEnabled) {
        log('Skipped location API: device location is disabled.');
        return true;
      }
      stage = 'get current position';
      log('Requesting current position (high accuracy, 10 second timeout).');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      log('Current position', {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'timestamp': position.timestamp.toIso8601String(),
      });
      stage = 'resolve address';
      log('Resolving address (3 second timeout).');
      final address = await LocationUtil.instance
          .getAddress(position.latitude, position.longitude)
          .timeout(
            const Duration(seconds: 3),
            onTimeout: () {
              log(
                'Address lookup timed out; continuing with an empty address.',
              );
              return '';
            },
          );
      log('Resolved address', address);
      final fields = {
        'user_id': userId,
        'lattitude': position.latitude.toString(),
        'logittude': position.longitude.toString(),
        'address': address,
      };
      print('pass notification data+++++++++++ $fields');
      final client = DioClient().client;
      stage = 'POST /sendLiveLcation';
      log('API request', {
        'method': 'POST',
        'baseUrl': client.options.baseUrl,
        'path': '/sendLiveLcation',
        'body': fields,
        'sendTimeoutSeconds': 5,
        'receiveTimeoutSeconds': 5,
      });
      final response = await client.post(
        '/sendLiveLcation',
        data: FormData.fromMap(fields),
        options: Options(
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      log('API response', {
        'url': response.requestOptions.uri.toString(),
        'statusCode': response.statusCode,
        'statusMessage': response.statusMessage,
        'body': response.data,
      });
    } on DioException catch (error, stackTrace) {
      log('API error at stage: $stage', {
        'type': error.type.name,
        'message': error.message,
        'method': error.requestOptions.method,
        'url': error.requestOptions.uri.toString(),
        'statusCode': error.response?.statusCode,
        'responseBody': error.response?.data,
        'cause': error.error?.toString(),
      });
      log('Stack trace', stackTrace);
    } catch (error, stackTrace) {
      log('Location notification failed at stage: $stage', error);
      log('Stack trace', stackTrace);
    } finally {
      log('Location notification handling finished.');
      timer.stop();
    }
    return true;
  }

  Future<void> showNotification({
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final enabled = await android?.areNotificationsEnabled();
    debugPrint(
      '[LocalNotificationService] Android notifications enabled: $enabled',
    );
    if (enabled == false) {
      debugPrint(
        '[LocalNotificationService] Notification blocked by phone settings. '
        'Enable Settings > Apps > Solufine Agritech > Notifications > Allow notifications.',
      );
      return;
    }
    // ==========================================================
    // ANDROID DETAILS
    // ==========================================================

    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'high_importance_channel',
          'High Importance Notifications',

          channelDescription: 'Used for important notifications.',

          importance: Importance.max,

          priority: Priority.high,

          playSound: true,

          enableVibration: true,

          icon: '@mipmap/ic_launcher',
        );

    // ==========================================================
    // IOS DETAILS
    // ==========================================================

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // ==========================================================
    // NOTIFICATION DETAILS
    // ==========================================================

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // ==========================================================
    // PAYLOAD
    // ==========================================================

    final String payload = jsonEncode(data ?? <String, dynamic>{});

    // ==========================================================
    // NOTIFICATION ID
    // ==========================================================

    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(
      100000,
    );

    debugPrint('======================================');
    debugPrint('SHOWING LOCAL NOTIFICATION');
    debugPrint('ID      : $notificationId');
    debugPrint('TITLE   : $title');
    debugPrint('BODY    : $body');
    debugPrint('DATA    : $data');
    debugPrint('PAYLOAD : $payload');
    debugPrint('======================================');

    // ==========================================================
    // IMPORTANT:
    // New flutter_local_notifications API uses named parameters
    // ==========================================================

    await _notifications.show(
      id: notificationId,
      title: title,
      body: body,
      notificationDetails: notificationDetails,
      payload: payload,
    );

    debugPrint('======================================');
    debugPrint('LOCAL NOTIFICATION POSTED TO SYSTEM');
    debugPrint('======================================');
  }
}
