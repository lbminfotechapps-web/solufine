import 'dart:async';
import 'dart:math' as math;

import 'package:solufine/core/location_tracking/background_location_service.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/features/home/doman/home_usecases/get_punch_status_usecase.dart';
import 'package:solufine/features/home/doman/home_entity/vehicle_type_entity.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class QuickAcessBloc extends Bloc<QuickAccessEvent, QuickAccessState> {
  final GetPunchStatusUsecase getPunchStatusUsecase;

  final LocationRepository repository;

  QuickAcessBloc(this.getPunchStatusUsecase, this.repository)
    : super(const QuickAccessState()) {
    on<AdvertisementEvent>(_onGetAdvertisement);
    on<PunchStatEvent>(_onGetPunchStatus);
    on<SavePunchInLocationEvent>(_onSavePunchInLocation);
    on<VehicleTypeEvent>(_onGetVehicleType);
    on<PunchInOutDetailsAddEvent>(_onPunchInOutAddDetails);
    on<ShareLocationEvent>(_onShareLocationAdd);

    on<SaveNextLocationEvent>(_onSaveNextLocation);
    on<StoreTrackLocation>(_onStoretrackLocation);
  }
  int _advertisementVersion = 0;

  Future<void> _onGetAdvertisement(
    AdvertisementEvent event,
    Emitter<QuickAccessState> emit,
  ) async {
    final version = ++_advertisementVersion;
    emit(
      state.copyWith(
        advertisementStatus: QuickAccessStatus.loading,
        advertisementError: '',
      ),
    );
    try {
      final response = await getPunchStatusUsecase.getAdvertisement(
        event.searchtype,
        event.searchtitle,
      );
      if (version != _advertisementVersion) return;
      emit(
        state.copyWith(
          advertisementStatus: response.status
              ? QuickAccessStatus.success
              : QuickAccessStatus.failure,
          advertisementData: response,
          advertisementError: response.status ? '' : response.message,
        ),
      );
    } catch (error) {
      if (version != _advertisementVersion) return;
      emit(
        state.copyWith(
          advertisementStatus: QuickAccessStatus.failure,
          advertisementError: error.toString(),
        ),
      );
    }
  }

  String? punchStatus;

  Future<void> _onGetPunchStatus(
    PunchStatEvent event,
    Emitter<QuickAccessState> emit,
  ) async {
    emit(
      state.copyWith(
        quickAccessStatus: QuickAccessStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final punchStat = await getPunchStatusUsecase.getPunchStatus(
        event.userId,
      );

      punchStatus = punchStat.inOutStatus;

      debugPrint('========================================');
      debugPrint('PUNCH STATUS API SUCCESS');
      debugPrint('USER ID: ${event.userId}');
      debugPrint('PUNCH STATUS: ${punchStat.inOutStatus}');
      debugPrint('========================================');

      // ============================================================
      // RESTORE BACKGROUND LOCATION SERVICE
      // ============================================================

      if (punchStat.inOutStatus == '1') {
        debugPrint('USER IS CURRENTLY PUNCHED IN');

        final bool isRunning = await BackgroundLocationService.isRunning();

        debugPrint('BACKGROUND SERVICE RUNNING: $isRunning');

        if (!isRunning) {
          debugPrint('RESTARTING BACKGROUND LOCATION SERVICE...');

          await BackgroundLocationService.start(userId: event.userId);

          debugPrint('BACKGROUND LOCATION SERVICE STARTED');
        } else {
          debugPrint('BACKGROUND LOCATION SERVICE ALREADY RUNNING');
        }
      } else {
        debugPrint('USER IS NOT PUNCHED IN');
        debugPrint('BACKGROUND LOCATION SERVICE NOT STARTED');
      }

      // ============================================================
      // UPDATE UI
      // ============================================================

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.success,
          punchStat: punchStat,
          punchStatus: punchStat.inOutStatus,
          errorMessage: null,
        ),
      );
    } catch (error) {
      debugPrint('========================================');
      debugPrint('PUNCH STATUS ERROR');
      debugPrint('$error');
      debugPrint('========================================');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
  // Future<void> _onGetPunchStatus(
  //   PunchStatEvent event,
  //   Emitter<QuickAccessState> emit,
  // ) async {
  //   emit(
  //     state.copyWith(
  //       quickAccessStatus: QuickAccessStatus.loading,
  //       errorMessage: null,
  //     ),
  //   );

  //   try {
  //     final punchStat = await getPunchStatusUsecase.getPunchStatus(
  //       event.userId,
  //     );
  //     punchStatus = punchStat.inOutStatus;
  //     emit(
  //       state.copyWith(
  //         quickAccessStatus: QuickAccessStatus.success,
  //         punchStat: punchStat,
  //         punchStatus: punchStat.inOutStatus,
  //         errorMessage: null,
  //       ),
  //     );
  //   } catch (error) {
  //     emit(
  //       state.copyWith(
  //         quickAccessStatus: QuickAccessStatus.failure,
  //         errorMessage: error.toString(),
  //       ),
  //     );
  //   }
  // }

  Future<void> _onGetVehicleType(
    VehicleTypeEvent event,
    Emitter<QuickAccessState> emit,
  ) async {
    emit(
      state.copyWith(
        quickAccessStatus: QuickAccessStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final vehicles = await getPunchStatusUsecase.getVehicleType(
        event.userId,
        event.lastDate,
      );

      final vehicleList = vehicles
          .where((vehicle) => vehicle.vehicleTypeId != '0')
          .toList();

      final defaultVehicle = vehicleList.cast<VehicleTypeEntity?>().firstWhere(
        (vehicle) => vehicle?.vehicleType.toLowerCase() == 'bike',
        orElse: () => vehicleList.isEmpty ? null : vehicleList.first,
      );

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.success,
          vehicleList: vehicleList,
          selectedVehicle: defaultVehicle,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onPunchInOutAddDetails(
    PunchInOutDetailsAddEvent event,
    Emitter<QuickAccessState> emit,
  ) async {
    // ============================================================
    // 1. LOADING
    // ============================================================

    emit(
      state.copyWith(
        quickAccessStatus: QuickAccessStatus.loading,
        errorMessage: null,
      ),
    );

    debugPrint('========================================');
    debugPrint('PUNCH IN/OUT STATUS: LOADING');
    debugPrint('========================================');

    try {
      // ============================================================
      // 2. BASIC REQUEST DATA
      // ============================================================

      final Map<String, dynamic> jsonData = <String, dynamic>{
        'user_id': event.userId,
        'in_out_status': event.inOutStatus,
        'differenceByAndroid': event.differenceByAndroid,
        'locationHistoryString': event.locationHistoryString,
        'strBatteryInfo': event.batteryInfo,
        'strNetworkInfo': event.networkInfo,
        'pinRemark': event.pinRemark,
        'strStartingClosingKmAmount': event.startingClosingKmAmount,
        'strVehicleTypeId': event.vehicleTypeId,
        'route': event.route,

        // Location
        'latitude': event.latitude,
        'longitude': event.longitude,

        // Network Location
        'networkLatitude': event.networkLatitude,
        'networkLongitude': event.networkLongitude,

        // GPS Location
        'gpsLatitude': event.gpsLatitude,
        'gpsLongitude': event.gpsLongitude,

        // Address
        'geoAddress': event.geoAddress,

        // Activity
        'activityId': event.activityId,
      };

      // ============================================================
      // 3. DETERMINE PUNCH TYPE
      // ============================================================

      final bool isPunchIn = event.inOutStatus == '1';

      final bool isOutPunch =
          event.inOutStatus == '2' && event.isForceOutPunch != true;

      final bool isLastForceOut =
          event.inOutStatus == '2' && event.isForceOutPunch == true;

      debugPrint('========================================');
      debugPrint('PUNCH REQUEST TYPE');
      debugPrint('========================================');

      debugPrint('isPunchIn       : $isPunchIn');

      debugPrint('isOutPunch      : $isOutPunch');

      debugPrint('isLastForceOut  : $isLastForceOut');

      debugPrint('========================================');

      // ============================================================
      // 4. PUNCH IN
      //
      // Send:
      // startingKmImage -> only when available
      //
      // Do NOT send:
      // closingKmImage
      // date
      // time
      // isForceOutPunch
      // ============================================================

      if (isPunchIn) {
        debugPrint('========================================');
        debugPrint('NORMAL PUNCH IN');
        debugPrint('========================================');

        if (event.startingKmImage != null &&
            event.startingKmImage!.isNotEmpty) {
          jsonData['startingKmImage'] = event.startingKmImage;

          debugPrint(
            'startingKmImage: '
            'BASE64 (${event.startingKmImage!.length} chars)',
          );
        } else {
          debugPrint('startingKmImage: NOT PROVIDED');
        }
      }

      // ============================================================
      // 5. NORMAL PUNCH OUT
      //
      // Send:
      // closingKmImage -> only when available
      //
      // Do NOT send:
      // startingKmImage
      // date
      // time
      // isForceOutPunch
      // ============================================================

      if (isOutPunch) {
        debugPrint('========================================');
        debugPrint('NORMAL PUNCH OUT');
        debugPrint('========================================');

        if (event.closingKmImage != null && event.closingKmImage!.isNotEmpty) {
          jsonData['closingKmImage'] = event.closingKmImage;

          debugPrint(
            'closingKmImage: '
            'BASE64 (${event.closingKmImage!.length} chars)',
          );
        } else {
          debugPrint('closingKmImage: NOT PROVIDED');
        }
      }

      // ============================================================
      // 6. LAST FORCE OUT
      //
      // Send:
      // date
      // time
      // isForceOutPunch = true
      //
      // Do NOT send:
      // startingKmImage
      // closingKmImage
      // ============================================================

      if (isLastForceOut) {
        debugPrint('========================================');
        debugPrint('LAST FORCE OUT');
        debugPrint('========================================');

        debugPrint('Date: ${event.date}');

        debugPrint('Time: ${event.newTime}');

        // Date
        if (event.date != null && event.date!.trim().isNotEmpty) {
          jsonData['date'] = event.date!.trim();
        }

        // Time
        if (event.newTime != null && event.newTime!.trim().isNotEmpty) {
          jsonData['time'] = event.newTime!.trim();
        }

        // Force Out
        jsonData['isForceOutPunch'] = true;

        // Safety:
        // Make sure images are NOT present
        jsonData.remove('startingKmImage');
        jsonData.remove('closingKmImage');
      }

      // ============================================================
      // 7. FINAL REQUEST DEBUG
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('FINAL PUNCH REQUEST');
      debugPrint('========================================');

      jsonData.forEach((key, value) {
        if (key == 'startingKmImage' || key == 'closingKmImage') {
          final String image = value?.toString() ?? '';

          debugPrint(
            '$key: '
            'BASE64 IMAGE (${image.length} chars)',
          );
        } else {
          debugPrint('$key: $value');
        }
      });

      debugPrint('========================================');

      // ============================================================
      // 8. API CALL
      // ============================================================

      final response = await getPunchStatusUsecase.savePunchDetails(jsonData);

      // ============================================================
      // 9. PRINT RESPONSE
      //
      // Your response:
      //
      // {
      //   "status": true,
      //   "message": "2",
      //   "result": "success-141"
      // }
      //
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('PUNCH DETAILS RESPONSE');
      debugPrint('========================================');

      debugPrint('FULL RESPONSE: $response');

      debugPrint('STATUS: ${response['status']}');

      debugPrint('MESSAGE: ${response['message']}');

      debugPrint('RESULT: ${response['result']}');

      debugPrint('========================================');

      // ============================================================
      // 10. GET API STATUS
      // ============================================================

      final bool apiStatus = response['status'] == true;

      // ============================================================
      // 11. GET MESSAGE
      // ============================================================

      final String apiMessage = response['message']?.toString().trim() ?? '';

      // ============================================================
      // 12. GET RESULT
      //
      // success-141
      // ============================================================

      final String responseResult =
          response['result']?.toString().trim().toLowerCase() ?? '';

      debugPrint('========================================');
      debugPrint('PUNCH RESPONSE VALUES');
      debugPrint('========================================');

      debugPrint('API STATUS  : $apiStatus');

      debugPrint('API MESSAGE : "$apiMessage"');

      debugPrint('API RESULT  : "$responseResult"');

      debugPrint('========================================');

      // ============================================================
      // 13. SPLIT RESULT
      //
      // success-141
      //
      // parts[0] = success
      // parts[1] = 141
      // ============================================================

      final List<String> parts = responseResult.split('-');

      final String mainStatus = parts.isNotEmpty ? parts.first.trim() : '';

      final String dailyTranId = parts.length > 1 ? parts[1].trim() : '';

      debugPrint('========================================');
      debugPrint('PUNCH RESPONSE PARSED');
      debugPrint('========================================');

      debugPrint('API STATUS      : $apiStatus');

      debugPrint('MAIN API STATUS : "$mainStatus"');

      debugPrint('DAILY TRAN ID   : "$dailyTranId"');

      debugPrint('MESSAGE         : "$apiMessage"');

      debugPrint('========================================');

      // ============================================================
      // 14. SUCCESS
      //
      // Both must be valid:
      //
      // status == true
      // result == success-xxx
      // ============================================================

      if (apiStatus && mainStatus == 'success') {
        // ==========================================================
        // TRANSACTION ID CHECK
        // ==========================================================

        if (dailyTranId.isEmpty) {
          debugPrint('========================================');
          debugPrint('PUNCH WARNING');
          debugPrint('========================================');

          debugPrint(
            'Punch API returned success but '
            'dailyTranId is empty',
          );

          debugPrint('Original result: "$responseResult"');

          debugPrint('========================================');

          emit(
            state.copyWith(
              quickAccessStatus: QuickAccessStatus.failure,
              errorMessage:
                  'Punch saved but transaction ID '
                  'was not received',
            ),
          );

          return;
        }

        // ==========================================================
        // COMPLETE SUCCESS
        // ==========================================================

        debugPrint('========================================');
        debugPrint('PUNCH DETAILS SUCCESS');
        debugPrint('========================================');

        debugPrint(
          'PUNCH TYPE: '
          '${isPunchIn
              ? "PUNCH IN"
              : isOutPunch
              ? "PUNCH OUT"
              : "FORCE OUT"}',
        );

        debugPrint('MAIN STATUS   : $mainStatus');

        debugPrint('DAILY TRAN ID : $dailyTranId');

        debugPrint('MESSAGE       : $apiMessage');

        debugPrint('========================================');

        emit(
          state.copyWith(
            quickAccessStatus: QuickAccessStatus.punchStatusSuccess,

            // Save transaction ID
            dailyTranId: dailyTranId,

            errorMessage: null,
          ),
        );

        return;
      }

      // ============================================================
      // 15. API FAILURE
      // ============================================================

      debugPrint('========================================');
      debugPrint('PUNCH DETAILS FAILED');
      debugPrint('========================================');

      debugPrint('API STATUS      : $apiStatus');

      debugPrint('MAIN API STATUS : "$mainStatus"');

      debugPrint('API RESULT      : "$responseResult"');

      debugPrint('API MESSAGE     : "$apiMessage"');

      debugPrint('========================================');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,

          errorMessage: apiMessage.isNotEmpty
              ? apiMessage
              : 'Failed to save punch details',
        ),
      );
    } catch (error, stackTrace) {
      // ============================================================
      // 16. EXCEPTION
      // ============================================================

      debugPrint('========================================');
      debugPrint('PUNCH DETAILS ERROR');
      debugPrint('========================================');

      debugPrint('ERROR: $error');

      debugPrint('STACK TRACE:');

      debugPrint('$stackTrace');

      debugPrint('========================================');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
  // Future<void> _onPunchInOutAddDetails(
  //   PunchInOutDetailsAddEvent event,
  //   Emitter<QuickAccessState> emit,
  // ) async {
  //   emit(
  //     state.copyWith(
  //       quickAccessStatus: QuickAccessStatus.loading,
  //       errorMessage: null,
  //     ),
  //   );

  //   try {
  //     // ============================================================
  //     // BASIC REQUEST DATA
  //     // ============================================================

  //     final Map<String, dynamic> jsonData = <String, dynamic>{
  //       'user_id': event.userId,
  //       'in_out_status': event.inOutStatus,
  //       'differenceByAndroid': event.differenceByAndroid,
  //       'locationHistoryString': event.locationHistoryString,
  //       'strBatteryInfo': event.batteryInfo,
  //       'strNetworkInfo': event.networkInfo,
  //       'pinRemark': event.pinRemark,
  //       'strStartingClosingKmAmount': event.startingClosingKmAmount,
  //       'strVehicleTypeId': event.vehicleTypeId,
  //       'route': event.route,
  //       'latitude': event.latitude,
  //       'longitude': event.longitude,
  //       'networkLatitude': event.networkLatitude,
  //       'networkLongitude': event.networkLongitude,
  //       'gpsLatitude': event.gpsLatitude,
  //       'gpsLongitude': event.gpsLongitude,
  //       'geoAddress': event.geoAddress,
  //       'activityId': event.activityId,
  //     };

  //     // ============================================================
  //     // DETERMINE PUNCH TYPE
  //     // ============================================================
  //     final bool isPunchIn = event.inOutStatus == '1';

  //     final bool isOutPunch =
  //         event.inOutStatus == '2' && event.isForceOutPunch != true;

  //     final bool isLastForceOut =
  //         event.inOutStatus == '2' && event.isForceOutPunch == true;

  //     debugPrint('========================================');
  //     debugPrint('PUNCH REQUEST TYPE');
  //     debugPrint('isPunchIn: $isPunchIn');
  //     debugPrint('isOutPunch: $isOutPunch');
  //     debugPrint('isLastForceOut: $isLastForceOut');
  //     debugPrint('========================================');

  //     // ============================================================
  //     // PUNCH IN
  //     // ============================================================
  //     // Send ONLY startingKmImage if available.
  //     //
  //     // Do NOT send closingKmImage.
  //     // Do NOT send date.
  //     // Do NOT send time.
  //     // Do NOT send isForceOutPunch.
  //     // ============================================================

  //     if (isPunchIn) {
  //       if (event.startingKmImage != null &&
  //           event.startingKmImage!.isNotEmpty) {
  //         jsonData['startingKmImage'] = event.startingKmImage;

  //         debugPrint(
  //           'startingKmImage: '
  //           'BASE64 (${event.startingKmImage!.length} chars)',
  //         );
  //       } else {
  //         debugPrint('startingKmImage: NOT PROVIDED');
  //       }
  //       debugPrint('PUNCH IN API SUCCESS');
  //       debugPrint('Saving Punch In location locally');
  //       debugPrint('========================================');
  //     }
  //     // ============================================================
  //     // NORMAL OUT PUNCH
  //     // ============================================================
  //     // Send ONLY closingKmImage if available.
  //     //
  //     // Do NOT send startingKmImage.
  //     // Do NOT send date.
  //     // Do NOT send time.
  //     // isForceOutPunch is not sent.
  //     // ============================================================

  //     if (isOutPunch) {
  //       if (event.closingKmImage != null && event.closingKmImage!.isNotEmpty) {
  //         jsonData['closingKmImage'] = event.closingKmImage;

  //         debugPrint(
  //           'closingKmImage: '
  //           'BASE64 (${event.closingKmImage!.length} chars)',
  //         );
  //       } else {
  //         debugPrint('closingKmImage: NOT PROVIDED');
  //       }
  //     }

  //     // ============================================================
  //     // LAST FORCE OUT
  //     // ============================================================
  //     // Do NOT send any image.
  //     //
  //     // Do NOT send startingKmImage.
  //     // Do NOT send closingKmImage.
  //     //
  //     // Send isForceOutPunch only if your API requires it.
  //     // ============================================================

  //     if (isLastForceOut) {
  //       debugPrint('LAST FORCE OUT');

  //       debugPrint('Date: ${event.date}');

  //       debugPrint('Time: ${event.newTime}');

  //       // Date
  //       if (event.date != null && event.date!.isNotEmpty) {
  //         jsonData['date'] = event.date;
  //       }

  //       // Time
  //       if (event.newTime != null && event.newTime!.isNotEmpty) {
  //         jsonData['time'] = event.newTime;
  //       }

  //       // Force out flag
  //       jsonData['isForceOutPunch'] = true;

  //       // IMPORTANT:
  //       // Do NOT add startingKmImage
  //       // Do NOT add closingKmImage
  //     }

  //     // ============================================================
  //     // OPTIONAL DATE
  //     // ============================================================

  //     if (event.date != null && event.date!.isNotEmpty) {
  //       jsonData['date'] = event.date;

  //       debugPrint('date: ${event.date}');
  //     }

  //     // ============================================================
  //     // OPTIONAL TIME
  //     // ============================================================

  //     if (event.newTime != null && event.newTime!.isNotEmpty) {
  //       jsonData['time'] = event.newTime;

  //       debugPrint('time: ${event.newTime}');
  //     }

  //     // ============================================================
  //     // FINAL REQUEST DEBUG
  //     // ============================================================

  //     debugPrint('');
  //     debugPrint('========== FINAL PUNCH REQUEST ==========');

  //     jsonData.forEach((key, value) {
  //       if (key == 'startingKmImage' || key == 'closingKmImage') {
  //         final String image = value?.toString() ?? '';

  //         debugPrint(
  //           '$key: BASE64 IMAGE '
  //           '($image characters)',
  //         );
  //       } else {
  //         debugPrint('$key: $value');
  //       }
  //     });

  //     debugPrint('==========================================');

  //     // ============================================================
  //     // API CALL
  //     // ============================================================

  //     final response = await getPunchStatusUsecase.savePunchDetails(jsonData);

  //     debugPrint('Punch details response: $response');

  //     emit(
  //       state.copyWith(
  //         quickAccessStatus: QuickAccessStatus.punchStatusSuccess,
  //         errorMessage: null,
  //       ),
  //     );
  //   } catch (error, stackTrace) {
  //     debugPrint('Punch details error: $error');

  //     debugPrint('StackTrace: $stackTrace');

  //     emit(
  //       state.copyWith(
  //         quickAccessStatus: QuickAccessStatus.failure,
  //         errorMessage: error.toString(),
  //       ),
  //     );
  //   }
  // }

  Future<void> _onSavePunchInLocation(
    SavePunchInLocationEvent event,
    Emitter<QuickAccessState> emit,
  ) async {
    try {
      debugPrint('========================================');
      debugPrint('LOCATION TRACKING');
      debugPrint('Saving Punch In location');
      debugPrint('User ID: ${event.userId}');
      debugPrint('Latitude: ${event.latitude}');
      debugPrint('Longitude: ${event.longitude}');
      debugPrint('Address: ${event.geoAddress}');
      debugPrint('Accuracy: ${event.accuracy}');
      debugPrint('Provider: ${event.provider}');
      debugPrint('Timestamp: ${event.capturedAt}');
      debugPrint('========================================');

      await repository.saveLocation(
        userId: event.userId,
        latitude: event.latitude,
        longitude: event.longitude,
        geoAddress: event.geoAddress,
        capturedAt: event.capturedAt,
        accuracy: event.accuracy,
        provider: event.provider,
        distance: 0.0,
      );

      debugPrint('LOCATION TRACKING: Punch In location saved');

      // TEMPORARY VERIFICATION
      final savedLocations = await repository.getAllLocations(event.userId);

      debugPrint('========================================');
      debugPrint('SAVED LOCATION RECORDS');
      debugPrint('Total records: ${savedLocations.length}');

      for (final location in savedLocations) {
        debugPrint(
          'ID: ${location.id} | '
          'UserId: ${location.userId} | '
          'Lat: ${location.latitude} | '
          'Lng: ${location.longitude} | '
          'Address: ${location.geoAddress} | '
          'Time: ${location.capturedAt} | '
          'Accuracy: ${location.accuracy} | '
          'Provider: ${location.provider} | '
          'Distance: ${location.distance}',
        );
      }

      debugPrint('========================================');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.locationTrackingSucess,
          errorMessage: null,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('LOCATION TRACKING ERROR: $error');
      debugPrint('STACK TRACE: $stackTrace');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSaveNextLocation(
    SaveNextLocationEvent event,
    Emitter<QuickAccessState> emit,
  ) async {
    try {
      debugPrint('========================================');
      debugPrint('NEXT LOCATION TRACKING');
      debugPrint('Saving next location');
      debugPrint('User ID: ${event.userId}');
      debugPrint('Latitude: ${event.latitude}');
      debugPrint('Longitude: ${event.longitude}');
      debugPrint('Address: ${event.geoAddress}');
      debugPrint('Accuracy: ${event.accuracy}');
      debugPrint('Provider: ${event.provider}');
      debugPrint('Timestamp: ${event.capturedAt}');
      debugPrint('========================================');

      final previousLocation = await repository.getLastLocation(event.userId);

      double distance = 0.0;

      if (previousLocation != null) {
        final previousLatitude = double.tryParse(previousLocation.latitude);

        final previousLongitude = double.tryParse(previousLocation.longitude);

        final currentLatitude = double.tryParse(event.latitude);

        final currentLongitude = double.tryParse(event.longitude);

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
      }

      debugPrint(
        'Distance from previous location: '
        '${distance.toStringAsFixed(2)} meters',
      );

      await repository.saveLocation(
        userId: event.userId,
        latitude: event.latitude,
        longitude: event.longitude,
        geoAddress: event.geoAddress,
        capturedAt: event.capturedAt,
        accuracy: event.accuracy,
        provider: event.provider,
        distance: distance,
      );

      debugPrint('NEXT LOCATION SAVED SUCCESSFULLY');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.locationTrackingSucess,
          errorMessage: null,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint('NEXT LOCATION ERROR: $error');
      debugPrint('STACK TRACE: $stackTrace');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  double _calculateDistanceInMeters(
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

  FutureOr<void> _onShareLocationAdd(
    ShareLocationEvent event,
    Emitter<QuickAccessState> emit,
  ) async {
    // ============================================================
    // 1. LOADING
    // ============================================================

    emit(
      state.copyWith(
        quickAccessStatus: QuickAccessStatus.loading,
        errorMessage: null,
      ),
    );

    debugPrint('========================================');
    debugPrint('SHARE LOCATION STATUS: LOADING');
    debugPrint('========================================');

    try {
      // ============================================================
      // 2. PREPARE REQUEST
      // ============================================================

      final Map<String, dynamic> jsonData = <String, dynamic>{
        'user_id': event.userId,
        'in_out_status': event.inOutStatus,
        'differenceByAndroid': event.differenceByAndroid,
        'locationHistoryString': event.locationHistoryString,
        'strBatteryInfo': event.batteryInfo,
        'strNetworkInfo': event.networkInfo,
        'pinRemark': event.pinRemark,
        'strStartingClosingKmAmount': event.startingClosingKmAmount,
        'strVehicleTypeId': event.vehicleTypeId,
        'route': event.route,

        // Location
        'latitude': event.latitude,
        'longitude': event.longitude,

        // Network Location
        'networkLatitude': event.networkLatitude,
        'networkLongitude': event.networkLongitude,

        // GPS Location
        'gpsLatitude': event.gpsLatitude,
        'gpsLongitude': event.gpsLongitude,

        // Address
        'geoAddress': event.geoAddress,

        // Images
        'startingKmImage': event.startingKmImage ?? '',
        'closingKmImage': event.closingKmImage ?? '',

        // Activity
        'activityId': event.activityId,
      };

      // ============================================================
      // 3. PRINT REQUEST
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('SHARE LOCATION REQUEST');
      debugPrint('========================================');

      jsonData.forEach((key, value) {
        // Avoid printing full Base64 image in console
        if (key == 'startingKmImage' || key == 'closingKmImage') {
          final String imageValue = value?.toString() ?? '';

          debugPrint(
            '$key : '
            '${imageValue.isNotEmpty ? "IMAGE AVAILABLE (${imageValue.length} chars)" : "EMPTY"}',
          );
        } else {
          debugPrint('$key : $value');
        }
      });

      debugPrint('========================================');

      // ============================================================
      // 4. CALL API
      // ============================================================

      final result = await getPunchStatusUsecase.savePunchDetails(jsonData);

      // ============================================================
      // 5. PRINT COMPLETE RESPONSE
      //
      // Example:
      //
      // {
      //   status: true,
      //   message: 3,
      //   result: success-129
      // }
      //
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('SHARE LOCATION RESPONSE');
      debugPrint('========================================');

      debugPrint('FULL RESPONSE: $result');

      debugPrint('STATUS: ${result['status']}');

      debugPrint('MESSAGE: ${result['message']}');

      debugPrint('RESULT: ${result['result']}');

      debugPrint('========================================');

      // ============================================================
      // 6. GET API STATUS
      // ============================================================

      final bool apiStatus = result['status'] == true;

      // ============================================================
      // 7. GET MESSAGE
      // ============================================================

      final String apiMessage = result['message']?.toString().trim() ?? '';

      // ============================================================
      // 8. GET RESULT
      //
      // Example:
      //
      // success-129
      //
      // ============================================================

      final String responseResult =
          result['result']?.toString().trim().toLowerCase() ?? '';

      debugPrint('API STATUS       : $apiStatus');

      debugPrint('API MESSAGE      : "$apiMessage"');

      debugPrint('API RESULT       : "$responseResult"');

      // ============================================================
      // 9. SPLIT RESULT
      //
      // success-129
      //
      // parts[0] = success
      // parts[1] = 129
      //
      // ============================================================

      final List<String> parts = responseResult.split('-');

      final String mainStatus = parts.isNotEmpty ? parts.first.trim() : '';

      final String dailyTranId = parts.length > 1 ? parts[1].trim() : '';

      debugPrint('========================================');
      debugPrint('SHARE LOCATION RESPONSE PARSED');
      debugPrint('========================================');

      debugPrint('API STATUS      : $apiStatus');

      debugPrint('MAIN API STATUS : "$mainStatus"');

      debugPrint('DAILY TRAN ID   : "$dailyTranId"');

      debugPrint('MESSAGE         : "$apiMessage"');

      debugPrint('========================================');

      // ============================================================
      // 10. SUCCESS
      //
      // BOTH MUST BE SUCCESS:
      //
      // status == true
      // result starts with success
      //
      // ============================================================

      if (apiStatus && mainStatus == 'success') {
        // ==========================================================
        // TRANSACTION ID CHECK
        // ==========================================================

        if (dailyTranId.isEmpty) {
          debugPrint('========================================');
          debugPrint('WARNING');
          debugPrint(
            'Share location API succeeded but '
            'dailyTranId is empty',
          );
          debugPrint('Original result: $responseResult');
          debugPrint('========================================');

          emit(
            state.copyWith(
              quickAccessStatus: QuickAccessStatus.failure,
              errorMessage:
                  'Location saved but transaction ID '
                  'was not received',
            ),
          );

          return;
        }

        // ==========================================================
        // COMPLETE SUCCESS
        // ==========================================================

        debugPrint('========================================');
        debugPrint('SHARE LOCATION SUCCESS');
        debugPrint('========================================');

        debugPrint('MAIN STATUS   : $mainStatus');

        debugPrint('DAILY TRAN ID : $dailyTranId');

        debugPrint('MESSAGE       : $apiMessage');

        debugPrint('========================================');

        emit(
          state.copyWith(
            quickAccessStatus: QuickAccessStatus.locationAddedSucces,

            // Add this in QuickAccessState
            dailyTranId: dailyTranId,

            errorMessage: null,
          ),
        );

        return;
      }

      // ============================================================
      // 11. FAILURE
      // ============================================================

      debugPrint('========================================');
      debugPrint('SHARE LOCATION FAILED');
      debugPrint('========================================');

      debugPrint('API STATUS      : $apiStatus');

      debugPrint('MAIN API STATUS : "$mainStatus"');

      debugPrint('API RESULT      : "$responseResult"');

      debugPrint('API MESSAGE     : "$apiMessage"');

      debugPrint('========================================');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: apiMessage.isNotEmpty
              ? apiMessage
              : 'Failed to share location',
        ),
      );
    } catch (e, stackTrace) {
      // ============================================================
      // 12. EXCEPTION
      // ============================================================

      debugPrint('========================================');
      debugPrint('SHARE LOCATION ERROR');
      debugPrint('========================================');

      debugPrint('ERROR: $e');

      debugPrint('STACK TRACE:');

      debugPrint('$stackTrace');

      debugPrint('========================================');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  // FutureOr<void> _onShareLocationAdd(
  //   ShareLocationEvent event,
  //   Emitter<QuickAccessState> emit,
  // ) async {
  //   emit(
  //     state.copyWith(
  //       quickAccessStatus: QuickAccessStatus.loading,
  //       errorMessage: null,
  //     ),
  //   );

  //   try {
  //     final Map<String, dynamic> jsonData = <String, dynamic>{
  //       'user_id': event.userId,
  //       'in_out_status': event.inOutStatus,
  //       'differenceByAndroid': event.differenceByAndroid,
  //       'locationHistoryString': event.locationHistoryString,
  //       'strBatteryInfo': event.batteryInfo,
  //       'strNetworkInfo': event.networkInfo,
  //       'pinRemark': event.pinRemark,
  //       'strStartingClosingKmAmount': event.startingClosingKmAmount,
  //       'strVehicleTypeId': event.vehicleTypeId,
  //       'route': event.route,
  //       'latitude': event.latitude,
  //       'longitude': event.longitude,
  //       'networkLatitude': event.networkLatitude,
  //       'networkLongitude': event.networkLongitude,
  //       'gpsLatitude': event.gpsLatitude,
  //       'gpsLongitude': event.gpsLongitude,
  //       'geoAddress': event.geoAddress,
  //       'startingKmImage': event.startingKmImage ?? '',
  //       'closingKmImage': event.closingKmImage ?? '',
  //       'activityId': event.activityId,
  //     };

  //     debugPrint('========================================');
  //     debugPrint('SHARE LOCATION REQUEST');
  //     debugPrint('========================================');

  //     jsonData.forEach((key, value) {
  //       debugPrint('$key : $value');
  //     });

  //     debugPrint('========================================');

  //     final result = await getPunchStatusUsecase.savePunchDetails(jsonData);

  //     debugPrint('========================================');
  //     debugPrint('SHARE LOCATION RESPONSE');
  //     debugPrint('========================================');
  //     debugPrint('Status: ${result}');

  //     debugPrint('========================================');

  //     if (result['status'] == true) {
  //       emit(
  //         state.copyWith(
  //           quickAccessStatus: QuickAccessStatus.locationAddedSucces,
  //           // errorMessage: result.message,
  //         ),
  //       );
  //     } else {
  //       emit(
  //         state.copyWith(
  //           quickAccessStatus: QuickAccessStatus.failure,
  //           // errorMessage: result.message,
  //         ),
  //       );
  //     }
  //   } catch (e, stackTrace) {
  //     debugPrint('========================================');
  //     debugPrint('SHARE LOCATION ERROR');
  //     debugPrint('$e');
  //     debugPrint('STACK TRACE: $stackTrace');
  //     debugPrint('========================================');

  //     emit(
  //       state.copyWith(
  //         quickAccessStatus: QuickAccessStatus.failure,
  //         errorMessage: e.toString(),
  //       ),
  //     );
  //   }
  // }

  FutureOr<void> _onStoretrackLocation(
    StoreTrackLocation event,
    Emitter<QuickAccessState> emit,
  ) async {
    emit(
      state.copyWith(
        quickAccessStatus: QuickAccessStatus.loading,
        errorMessage: null,
      ),
    );

    try {
      final Map<String, dynamic> jsonData = <String, dynamic>{
        'userId': event.userId,
        'dailyTranId': event.dailyTranId,
        'strAllLocations': event.strAllLocations,
      };

      debugPrint('========================================');
      debugPrint('STORE LOCATION REQUEST');
      debugPrint('========================================');

      jsonData.forEach((key, value) {
        debugPrint('$key : $value');
      });

      debugPrint('========================================');

      final result = await getPunchStatusUsecase.storeLocationData(jsonData);

      debugPrint('========================================');
      debugPrint('STORE LOCATION RESPONSE');
      debugPrint('========================================');
      debugPrint('Status: ${result}');

      debugPrint('========================================');

      if (result['status'] == true) {
        debugPrint('========================================');
        debugPrint('STORE LOCATION API SUCCESS');
        debugPrint('Now cleaning local location records...');
        debugPrint('========================================');

        try {
          final int? parsedUserId = int.tryParse(event.userId);

          if (parsedUserId != null) {
            // --------------------------------------------------------
            // DELETE EVERYTHING EXCEPT LATEST LOCATION
            // --------------------------------------------------------

            final int deletedCount = await repository
                .deleteAllExceptLastLocation(parsedUserId);

            debugPrint('========================================');
            debugPrint('LOCATION CLEANUP SUCCESS');
            debugPrint('DELETED RECORDS: $deletedCount');
            debugPrint('LAST LOCATION KEPT');
            debugPrint('========================================');

            // --------------------------------------------------------
            // TEMPORARY VERIFICATION
            // --------------------------------------------------------

            final remainingLocations = await repository.getAllLocations(
              parsedUserId,
            );

            debugPrint('========================================');
            debugPrint('REMAINING LOCATION RECORDS');
            debugPrint('TOTAL: ${remainingLocations.length}');

            for (final location in remainingLocations) {
              debugPrint(
                'ID: ${location.id} | '
                'Lat: ${location.latitude} | '
                'Lng: ${location.longitude} | '
                'Time: ${location.capturedAt} | '
                'Accuracy: ${location.accuracy} | '
                'Provider: ${location.provider} | '
                'Address: ${location.geoAddress} | '
                'Distance: ${location.distance}',
              );
            }

            debugPrint('========================================');
          } else {
            debugPrint('LOCATION CLEANUP: Invalid userId ${event.userId}');
          }
        } catch (error, stackTrace) {
          // The server accepted the upload; local cleanup is a separate step.
          debugPrint('Location upload succeeded, local cleanup failed: $error');
          debugPrint(stackTrace.toString());
        }

        emit(
          state.copyWith(
            quickAccessStatus: QuickAccessStatus.locationHistoryUploaded,
            errorMessage: null,
          ),
        );
      } else {
        emit(
          state.copyWith(
            quickAccessStatus: QuickAccessStatus.failure,
            errorMessage:
                'Location history upload failed: ${result['message'] ?? 'Server rejected the upload'}',
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('========================================');
      debugPrint('STORE LOCATION ERROR');
      debugPrint('$e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('========================================');

      emit(
        state.copyWith(
          quickAccessStatus: QuickAccessStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
}
