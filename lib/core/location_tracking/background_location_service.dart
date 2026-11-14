import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:solufine/core/location_tracking/app_database.dart';
import 'package:solufine/core/utility/location_util.dart';

@pragma('vm:entry-point')
class BackgroundLocationService {
  static Future<void> initialize() async {
    final service = FlutterBackgroundService();

    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'location_tracking',
      'Location Tracking',
      description: 'Background location tracking',
      importance: Importance.low,
    );

    final FlutterLocalNotificationsPlugin notifications =
        FlutterLocalNotificationsPlugin();

    await notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    await service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'location_tracking',
        initialNotificationTitle: 'Location Tracking',
        initialNotificationContent: 'Location tracking is active',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );
  }

  static Future<bool> isRunning() async {
    final service = FlutterBackgroundService();

    final bool running = await service.isRunning();



    return running;
  }

  static Future<void> checkServiceStatus() async {
    final service = FlutterBackgroundService();

    final bool isRunning = await service.isRunning();

  }

  static Future<void> start({required int userId}) async {
    final service = FlutterBackgroundService();

    final isRunning = await service.isRunning();

    if (!isRunning) {
      await service.startService();
    }

    service.invoke('setUserId', {'userId': userId});

    debugPrint('BACKGROUND LOCATION SERVICE: User ID sent = $userId');
  }

  static Future<void> stop() async {
    final service = FlutterBackgroundService();

    service.invoke('stopService');
  }

  @pragma('vm:entry-point')
  static void onStart(ServiceInstance service) {
    DartPluginRegistrant.ensureInitialized();

    int? userId;

    // Open Drift database in the background isolate.
    final database = AppDatabase();

    service.on('setUserId').listen((event) {
      if (event == null) return;

      userId = int.tryParse(event['userId']?.toString() ?? '');

      debugPrint('BACKGROUND LOCATION: User ID received = $userId');
    });

    if (service is AndroidServiceInstance) {
      service.setAsForegroundService();

      service.setForegroundNotificationInfo(
        title: 'Location Tracking',
        content: 'Location tracking is active',
      );
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(minutes: 5), (timer) async {
      try {
        debugPrint('========================================');
        debugPrint('BACKGROUND LOCATION');
        debugPrint('CURRENT USER ID: $userId');
        debugPrint('3 MINUTE INTERVAL TRIGGERED');
        debugPrint('Getting current location...');
        debugPrint('========================================');

        // --------------------------------------------------
        // 1. Get current location
        // --------------------------------------------------

        final position = await LocationUtil.instance.getCurrentLocation();

        if (position == null) {
          debugPrint('BACKGROUND LOCATION: Location not available');
          return;
        }

        final latitude = position.latitude.toString();
        final longitude = position.longitude.toString();

        debugPrint('BACKGROUND LOCATION: Latitude = $latitude');

        debugPrint('BACKGROUND LOCATION: Longitude = $longitude');

        debugPrint('BACKGROUND LOCATION: Accuracy = ${position.accuracy}');

        // --------------------------------------------------
        // 2. Get address
        // --------------------------------------------------

        final address = await LocationUtil.instance.getAddress(
          position.latitude,
          position.longitude,
        );

        debugPrint('BACKGROUND LOCATION: Address = $address');

        // --------------------------------------------------
        // 3. Read previous location from SQLite
        // --------------------------------------------------

        if (userId == null) {
          debugPrint('BACKGROUND LOCATION: User ID is null');
          return;
        }

        final previousLocation = await database.getLastLocation(userId!);

        double distance = 0.0;

        if (previousLocation == null) {
          debugPrint('BACKGROUND LOCATION: No previous location found');
        } else {
          final previousLatitude = double.tryParse(previousLocation.latitude);

          final previousLongitude = double.tryParse(previousLocation.longitude);

          final currentLatitude = double.tryParse(latitude);

          final currentLongitude = double.tryParse(longitude);

          if (previousLatitude != null &&
              previousLongitude != null &&
              currentLatitude != null &&
              currentLongitude != null) {
            distance = _calculateDistanceInMeters(
              previousLatitude,
              previousLongitude,
              currentLatitude,
              currentLongitude,
            );
          }

          debugPrint('========================================');
          debugPrint('DISTANCE CALCULATION');
          debugPrint('Previous Latitude: $previousLatitude');
          debugPrint('Previous Longitude: $previousLongitude');
          debugPrint('Current Latitude: $currentLatitude');
          debugPrint('Current Longitude: $currentLongitude');
          debugPrint('Distance: ${distance.toStringAsFixed(2)} meters');
          debugPrint('========================================');

        }

        // Save the first point too; it has no previous point and distance is zero.
        await database.insertLocation(
          userId: userId!,
          latitude: latitude,
          longitude: longitude,
          geoAddress: address,
          capturedAt: DateTime.now().millisecondsSinceEpoch,
          accuracy: position.accuracy,
          provider: 'gps',
          distance: distance,
        );

        debugPrint('========================================');
        debugPrint('BACKGROUND LOCATION SAVED');
        debugPrint('User ID: $userId');
        debugPrint('Latitude: $latitude');
        debugPrint('Longitude: $longitude');
        debugPrint('Accuracy: ${position.accuracy}');
        debugPrint('Distance: ${distance.toStringAsFixed(2)} meters');
        debugPrint('========================================');
        debugPrint('========================================');
      } catch (error, stackTrace) {
        debugPrint('BACKGROUND LOCATION ERROR: $error');

        debugPrint('STACK TRACE: $stackTrace');
      }
    });
  }

  @pragma('vm:entry-point')
  static Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  static double _calculateDistanceInMeters(
    double latitude1,
    double longitude1,
    double latitude2,
    double longitude2,
  ) {
    const earthRadius = 6371000.0;

    final lat1 = latitude1 * math.pi / 180;
    final lat2 = latitude2 * math.pi / 180;

    final deltaLat = (latitude2 - latitude1) * math.pi / 180;

    final deltaLongitude = (longitude2 - longitude1) * math.pi / 180;

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLongitude / 2) *
            math.sin(deltaLongitude / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }
}
