import 'dart:convert';
import 'dart:io';

import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/features/farmer/famerfollowup/domain/repository/famerfollowup_repository.dart';
import 'package:solufine/features/farmer/famerfollowup/presentation/bloc/famerfollowup_event.dart';
import 'package:solufine/features/farmer/famerfollowup/presentation/bloc/famerfollowup_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FamerfollowupBloc extends Bloc<FamerfollowupEvent, FamerfollowupState> {
  final FamerfollowupRepository repository;

  FamerfollowupBloc({required this.repository})
    : super(const FamerfollowupState()) {
    on<SubmitFollowupEvent>(_submitFollowup);
    on<GetRemarkHistoryEvent>(_getRemarkHistory);
  }

  Future<void> _submitFollowup(
    SubmitFollowupEvent event,
    Emitter<FamerfollowupState> emit,
  ) async {
    // ============================================================
    // 1. SET LOADING
    // ============================================================

    emit(
      state.copyWith(status: FamerfollowupStatus.loading, errorMessage: null),
    );

    debugPrint('==========================================');
    debugPrint('FARMER FOLLOWUP STATUS: LOADING');
    debugPrint('==========================================');

    try {
      // ============================================================
      // 2. CHECK + COMPRESS FOLLOWUP IMAGE
      // ============================================================

      File? followupImageFile;

      debugPrint('==========================================');
      debugPrint('FARMER FOLLOWUP IMAGE CHECK');
      debugPrint('EVENT IMAGE PATH: ${event.imagePath}');
      debugPrint('==========================================');

      if (event.imagePath != null && event.imagePath!.trim().isNotEmpty) {
        final File originalFile = File(event.imagePath!.trim());

        final bool exists = await originalFile.exists();

        debugPrint('ORIGINAL IMAGE EXISTS: $exists');

        if (exists) {
          debugPrint('ORIGINAL IMAGE PATH: ${originalFile.path}');

          debugPrint(
            'ORIGINAL IMAGE SIZE: '
            '${await originalFile.length()} bytes',
          );

          // ========================================================
          // COMPRESS IMAGE
          // ========================================================

          final File? compressedFile = await ImageCompression.compressImage(
            originalFile,
            maxWidth: 450,
            maxHeight: 450,
            quality: 45,
          );

          // ========================================================
          // USE COMPRESSED IMAGE
          // ========================================================

          if (compressedFile != null && await compressedFile.exists()) {
            followupImageFile = compressedFile;

            debugPrint('USING COMPRESSED FARMER FOLLOWUP IMAGE');

            debugPrint(
              'COMPRESSED PATH: '
              '${followupImageFile.path}',
            );

            debugPrint(
              'COMPRESSED SIZE: '
              '${await followupImageFile.length()} bytes',
            );
          } else {
            // ======================================================
            // COMPRESSION FAILED -> USE ORIGINAL
            // ======================================================

            followupImageFile = originalFile;

            debugPrint(
              'COMPRESSION FAILED - '
              'USING ORIGINAL FARMER FOLLOWUP IMAGE',
            );

            debugPrint(
              'IMAGE PATH: '
              '${followupImageFile.path}',
            );

            debugPrint(
              'IMAGE SIZE: '
              '${await followupImageFile.length()} bytes',
            );
          }
        } else {
          debugPrint('FARMER FOLLOWUP IMAGE FILE DOES NOT EXIST');
        }
      } else {
        debugPrint('FARMER FOLLOWUP IMAGE NOT SELECTED');
      }

      // ============================================================
      // 3. FINAL IMAGE INFORMATION
      // ============================================================

      debugPrint('==========================================');
      debugPrint('FARMER IMAGE TO REPOSITORY');
      debugPrint('==========================================');

      if (followupImageFile != null) {
        debugPrint('IMAGE AVAILABLE');

        debugPrint('PATH: ${followupImageFile.path}');

        debugPrint('EXISTS: ${await followupImageFile.exists()}');

        debugPrint('SIZE: ${await followupImageFile.length()} bytes');
      } else {
        debugPrint('IMAGE FILE IS NULL');
      }

      debugPrint('==========================================');

      // ============================================================
      // 4. PRINT REQUEST DATA
      // ============================================================

      debugPrint('');
      debugPrint('==========================================');
      debugPrint('FARMER FOLLOWUP REQUEST DATA');
      debugPrint('==========================================');

      debugPrint('farmerId: ${event.farmerId}');

      debugPrint('userId: ${event.userId}');

      debugPrint('followUpDate: ${event.followUpDate}');

      debugPrint('followUpType: ${event.followUpType}');

      debugPrint('remark: ${event.remark}');

      // Location
      debugPrint('latitude: ${event.latitude}');

      debugPrint('longitude: ${event.longitude}');

      // Network Location
      debugPrint('networkLatitude: ${event.networkLatitude}');

      debugPrint('networkLongitude: ${event.networkLongitude}');

      // GPS Location
      debugPrint('gpsLatitude: ${event.gpsLatitude}');

      debugPrint('gpsLongitude: ${event.gpsLongitude}');

      // Address
      debugPrint('geoAddress: ${event.geoAddress}');

      // Network
      debugPrint('networkInfo: ${event.networkInfo}');

      // Battery
      debugPrint('batteryInfo: ${event.batteryInfo}');

      // Difference
      debugPrint(
        'differenceByAndroid: '
        '${event.differenceByAndroid}',
      );

      // Farmer Status
      debugPrint(
        'statusOfFarmer: '
        '${event.statusOfFarmer}',
      );

      // Activity
      debugPrint('activityId: ${event.activityId}');

      // Image
      debugPrint('imagePath: ${followupImageFile?.path}');

      debugPrint('==========================================');

      // ============================================================
      // 5. CALL REPOSITORY
      // ============================================================

      debugPrint('Calling repository.submitFollowup()...');

      final response = await repository.submitFollowup(
        farmerId: event.farmerId,
        userId: event.userId,
        followUpDate: event.followUpDate,
        followUpType: event.followUpType,
        remark: event.remark,

        // Location
        latitude: event.latitude,
        longitude: event.longitude,

        // Network Location
        networkLatitude: event.networkLatitude,
        networkLongitude: event.networkLongitude,

        // GPS Location
        gpsLatitude: event.gpsLatitude,
        gpsLongitude: event.gpsLongitude,

        // Address
        geoAddress: event.geoAddress,

        // Device Information
        networkInfo: event.networkInfo,
        batteryInfo: event.batteryInfo,

        // Difference
        differenceByAndroid: event.differenceByAndroid,

        // Farmer Status
        statusOfFarmer: event.statusOfFarmer,

        // Activity
        activityId: event.activityId,
        cropDetails: event.cropDetails,

        // Image
        imagePath: followupImageFile?.path,
      );

      // ============================================================
      // 6. PRINT RAW RESPONSE
      // ============================================================

      debugPrint('');
      debugPrint('==========================================');
      debugPrint('FARMER FOLLOWUP RESPONSE');
      debugPrint('==========================================');

      debugPrint('Repository response: $response');

      debugPrint('response.status: ${response.status}');

      debugPrint(
        'response.status type: '
        '${response.status.runtimeType}',
      );

      // ============================================================
      // 7. RAW STATUS
      //
      // YOUR API RESPONSE:
      //
      // {"status":"success-118"}
      //
      // ============================================================

      final String rawResponse = response.status.toString().trim();

      debugPrint('RAW FOLLOWUP RESPONSE: $rawResponse');

      // ============================================================
      // 8. DECODE JSON RESPONSE
      // ============================================================

      String responseStatus = '';

      try {
        // ----------------------------------------------------------
        // JSON response
        //
        // {"status":"success-118"}
        //
        // becomes:
        //
        // success-118
        // ----------------------------------------------------------

        if (rawResponse.startsWith('{')) {
          final dynamic decoded = jsonDecode(rawResponse);

          debugPrint('DECODED RESPONSE: $decoded');

          if (decoded is Map) {
            responseStatus =
                decoded['status']?.toString().trim().toLowerCase() ?? '';
          }
        } else {
          // --------------------------------------------------------
          // Fallback:
          // API directly returned:
          //
          // success-118
          // --------------------------------------------------------

          responseStatus = rawResponse.trim().toLowerCase();
        }
      } catch (e) {
        debugPrint('STATUS JSON PARSE ERROR: $e');

        // Fallback
        responseStatus = rawResponse.trim().toLowerCase();
      }

      debugPrint('==========================================');

      debugPrint(
        'EXTRACTED RESPONSE STATUS: '
        '"$responseStatus"',
      );

      debugPrint('==========================================');

      // ============================================================
      // 9. SPLIT STATUS + DAILY TRAN ID
      //
      // success-118
      //
      // parts[0] = success
      // parts[1] = 118
      //
      // ============================================================

      final List<String> parts = responseStatus.split('-');

      final String mainStatus = parts.isNotEmpty ? parts.first.trim() : '';

      final String dailyTranId = parts.length > 1 ? parts[1].trim() : '';

      debugPrint('==========================================');
      debugPrint('FARMER FOLLOWUP RESPONSE PARSED');

      debugPrint('MAIN API STATUS : "$mainStatus"');

      debugPrint('DAILY TRAN ID   : "$dailyTranId"');

      debugPrint('==========================================');

      // ============================================================
      // 10. SUCCESS
      // ============================================================

      if (mainStatus == 'success') {
        debugPrint('==========================================');
        debugPrint('FARMER FOLLOWUP API SUCCESS');
        debugPrint('==========================================');

        // ==========================================================
        // TRANSACTION ID CHECK
        // ==========================================================

        if (dailyTranId.isEmpty) {
          debugPrint('==========================================');
          debugPrint('WARNING');

          debugPrint(
            'Farmer followup API returned success '
            'but dailyTranId is empty',
          );

          debugPrint(
            'Original response status: '
            '$responseStatus',
          );

          debugPrint('==========================================');

          emit(
            state.copyWith(
              status: FamerfollowupStatus.failure,
              errorMessage:
                  'Farmer followup saved but '
                  'transaction ID was not received',
            ),
          );

          return;
        }

        // ==========================================================
        // COMPLETE SUCCESS
        // ==========================================================

        debugPrint('==========================================');
        debugPrint('FARMER FOLLOWUP SUBMIT SUCCESS');

        debugPrint('MAIN STATUS   : $mainStatus');

        debugPrint('DAILY TRAN ID : $dailyTranId');

        debugPrint(
          'Daily Tran ID saved in state: '
          '$dailyTranId',
        );

        debugPrint('==========================================');

        emit(
          state.copyWith(
            status: FamerfollowupStatus.farmerFollowUpSuccess,

            dailyTranId: dailyTranId,

            errorMessage: null,
          ),
        );

        return;
      }

      // ============================================================
      // 11. API FAILURE
      // ============================================================

      debugPrint('==========================================');
      debugPrint('FARMER FOLLOWUP SUBMIT FAILURE');

      debugPrint('RAW RESPONSE: "$rawResponse"');

      debugPrint('RESPONSE STATUS: "$responseStatus"');

      debugPrint('MAIN STATUS: "$mainStatus"');

      debugPrint('==========================================');

      emit(
        state.copyWith(
          status: FamerfollowupStatus.failure,
          errorMessage: 'Failed to submit farmer followup',
        ),
      );
    } catch (e, stackTrace) {
      // ============================================================
      // 12. EXCEPTION
      // ============================================================

      debugPrint('==========================================');
      debugPrint('FARMER FOLLOWUP SUBMIT EXCEPTION');

      debugPrint('ERROR: $e');

      debugPrint('STACK TRACE:');

      debugPrint('$stackTrace');

      debugPrint('==========================================');

      emit(
        state.copyWith(
          status: FamerfollowupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }
  /*
  Future<void> _submitFollowup(
    SubmitFollowupEvent event,
    Emitter<FamerfollowupState> emit,
  ) async {
    emit(
      state.copyWith(status: FamerfollowupStatus.loading, errorMessage: null),
    );

    debugPrint('FAMER FOLLOWUP STATUS: LOADING');

    try {
      // ============================================================
      // 1. CHECK + COMPRESS FOLLOWUP IMAGE
      // ============================================================

      File? followupImageFile;

      debugPrint('==========================================');
      debugPrint('FOLLOWUP IMAGE CHECK');
      debugPrint('EVENT IMAGE PATH: ${event.imagePath}');
      debugPrint('==========================================');

      if (event.imagePath != null && event.imagePath!.trim().isNotEmpty) {
        final originalFile = File(event.imagePath!.trim());

        final bool exists = await originalFile.exists();

        debugPrint('ORIGINAL IMAGE EXISTS: $exists');

        if (exists) {
          debugPrint('ORIGINAL IMAGE PATH: ${originalFile.path}');

          debugPrint(
            'ORIGINAL IMAGE SIZE: '
            '${await originalFile.length()} bytes',
          );

          // ========================================================
          // COMPRESS IMAGE
          // Same as Farmer Add
          // ========================================================

          final compressedFile = await ImageCompression.compressImage(
            originalFile,
            maxWidth: 450,
            maxHeight: 450,
            quality: 45,
          );

          // ========================================================
          // USE COMPRESSED IMAGE IF AVAILABLE
          // OTHERWISE USE ORIGINAL IMAGE
          // ========================================================

          if (compressedFile != null && await compressedFile.exists()) {
            followupImageFile = compressedFile;

            debugPrint('USING COMPRESSED FOLLOWUP IMAGE');

            debugPrint(
              'COMPRESSED PATH: '
              '${followupImageFile.path}',
            );

            debugPrint(
              'COMPRESSED SIZE: '
              '${await followupImageFile.length()} bytes',
            );
          } else {
            followupImageFile = originalFile;

            debugPrint(
              'COMPRESSION FAILED - '
              'USING ORIGINAL FOLLOWUP IMAGE',
            );

            debugPrint(
              'IMAGE PATH: '
              '${followupImageFile.path}',
            );

            debugPrint(
              'IMAGE SIZE: '
              '${await followupImageFile.length()} bytes',
            );
          }
        } else {
          debugPrint('FOLLOWUP IMAGE FILE DOES NOT EXIST');
        }
      } else {
        debugPrint('FOLLOWUP IMAGE NOT SELECTED');
      }

      // ============================================================
      // 2. PRINT FINAL IMAGE BEING SENT
      // ============================================================

      debugPrint('==========================================');
      debugPrint('FOLLOWUP IMAGE TO REPOSITORY');
      debugPrint('==========================================');

      if (followupImageFile != null) {
        debugPrint('IMAGE AVAILABLE');

        debugPrint('PATH: ${followupImageFile.path}');

        debugPrint('EXISTS: ${await followupImageFile.exists()}');

        debugPrint('SIZE: ${await followupImageFile.length()} bytes');
      } else {
        debugPrint('IMAGE FILE IS NULL');
      }

      debugPrint('==========================================');

      // ============================================================
      // 3. CALL REPOSITORY
      // ALL EXISTING PARAMETERS REMAIN SAME
      // ============================================================

      debugPrint('Calling repository.submitFollowup()...');

      final response = await repository.submitFollowup(
        farmerId: event.farmerId,
        userId: event.userId,
        followUpDate: event.followUpDate,
        followUpType: event.followUpType,
        remark: event.remark,

        latitude: event.latitude,
        longitude: event.longitude,

        networkLatitude: event.networkLatitude,
        networkLongitude: event.networkLongitude,

        gpsLatitude: event.gpsLatitude,
        gpsLongitude: event.gpsLongitude,

        geoAddress: event.geoAddress,
        networkInfo: event.networkInfo,
        batteryInfo: event.batteryInfo,

        differenceByAndroid: event.differenceByAndroid,

        statusOfFarmer: event.statusOfFarmer,

        activityId: event.activityId,
        cropDetails: event.cropDetails,

        // ==========================================================
        // IMPORTANT CHANGE
        // Pass compressed/original final image path
        // ==========================================================
        imagePath: followupImageFile?.path,
      );

      // ============================================================
      // 4. RESPONSE
      // ============================================================

      debugPrint('Repository response received');
      debugPrint('Response object: $response');
      debugPrint('Response status: ${response.status}');
      debugPrint(
        'Response status type: '
        '${response.status.runtimeType}',
      );

      final rawStatus = response.status.trim();

      debugPrint('RAW RESPONSE STATUS = [$rawStatus]');

      String status = rawStatus;

      // ============================================================
      // 5. HANDLE STRING/JSON STATUS
      // ============================================================

      try {
        if (rawStatus.startsWith('{')) {
          final decoded = jsonDecode(rawStatus);

          if (decoded is Map) {
            status = decoded['status']?.toString().trim() ?? '';
          }
        }
      } catch (e) {
        debugPrint('STATUS JSON PARSE ERROR: $e');
      }

      debugPrint('FINAL API STATUS = [$status]');

      // ============================================================
      // 6. SUCCESS / FAILURE
      // ============================================================

      if (status.toLowerCase().startsWith('success')) {
        debugPrint('==========================================');
        debugPrint('FAMER FOLLOWUP SUBMIT SUCCESS');
        debugPrint('API STATUS: $status');
        debugPrint('==========================================');

        emit(
          state.copyWith(
            status: FamerfollowupStatus.farmerFollowUpSuccess,
            errorMessage: null,
          ),
        );
      } else {
        debugPrint('==========================================');
        debugPrint('FAMER FOLLOWUP SUBMIT FAILURE');
        debugPrint('API STATUS: $status');
        debugPrint('==========================================');

        emit(
          state.copyWith(
            status: FamerfollowupStatus.failure,
            errorMessage: 'Failed to submit record',
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('FAMER FOLLOWUP SUBMIT EXCEPTION');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==========================================');

      emit(
        state.copyWith(
          status: FamerfollowupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  */

  /*
  Future<void> _submitFollowup(
    SubmitFollowupEvent event,
    Emitter<FamerfollowupState> emit,
  ) async {
    emit(
      state.copyWith(status: FamerfollowupStatus.loading, errorMessage: null),
    );

    debugPrint('FAMER FOLLOWUP STATUS: LOADING');

    try {
      debugPrint('Calling repository.submitFollowup()...');

      final response = await repository.submitFollowup(
        farmerId: event.farmerId,
        userId: event.userId,
        followUpDate: event.followUpDate,
        followUpType: event.followUpType,
        remark: event.remark,
        latitude: event.latitude,
        longitude: event.longitude,
        networkLatitude: event.networkLatitude,
        networkLongitude: event.networkLongitude,
        gpsLatitude: event.gpsLatitude,
        gpsLongitude: event.gpsLongitude,
        geoAddress: event.geoAddress,
        networkInfo: event.networkInfo,
        batteryInfo: event.batteryInfo,
        differenceByAndroid: event.differenceByAndroid,
        statusOfFarmer: event.statusOfFarmer,
        activityId: event.activityId,
        cropDetails: event.cropDetails,
        imagePath: event.imagePath,
      );

      debugPrint('Repository response received');
      debugPrint('Response object: $response');
      debugPrint('Response status: ${response.status}');
      debugPrint('Response status type: ${response.status.runtimeType}');

      final rawStatus = response.status.trim();

      debugPrint('RAW RESPONSE STATUS = [$rawStatus]');

      String status = rawStatus;

      try {
        if (rawStatus.startsWith('{')) {
          final decoded = jsonDecode(rawStatus);

          if (decoded is Map) {
            status = decoded['status']?.toString().trim() ?? '';
          }
        }
      } catch (e) {
        debugPrint('STATUS JSON PARSE ERROR: $e');
      }

      debugPrint('FINAL API STATUS = [$status]');

      if (status.toLowerCase().startsWith('success')) {
        debugPrint('==========================================');
        debugPrint('FAMER FOLLOWUP SUBMIT SUCCESS');
        debugPrint('API STATUS: $status');
        debugPrint('==========================================');

        emit(
          state.copyWith(
            status: FamerfollowupStatus.farmerFollowUpSuccess,
            errorMessage: null,
          ),
        );
      } else {
        debugPrint('==========================================');
        debugPrint('FAMER FOLLOWUP SUBMIT FAILURE');
        debugPrint('API STATUS: $status');
        debugPrint('==========================================');

        emit(
          state.copyWith(
            status: FamerfollowupStatus.failure,
            errorMessage: 'Failed to submit record',
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('FAMER FOLLOWUP SUBMIT EXCEPTION');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==========================================');

      emit(
        state.copyWith(
          status: FamerfollowupStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }


  */

  Future<void> _getRemarkHistory(
    GetRemarkHistoryEvent event,
    Emitter<FamerfollowupState> emit,
  ) async {
    emit(
      state.copyWith(
        status: FamerfollowupStatus.loading,
        historyError: null,
        historyList: [],
      ),
    );

    try {
      debugPrint('========== HISTORY API ==========');
      debugPrint('FARMER ID: ${event.farmerId}');

      final response = await repository.getRemarkHistory(
        farmerId: event.farmerId,
      );

      debugPrint('HISTORY RESPONSE COUNT: ${response.length}');
      debugPrint('HISTORY RESPONSE: $response');

      emit(
        state.copyWith(
          status: FamerfollowupStatus.farmerHistorySuccess,
          historyList: response,
          historyError: null,
        ),
      );

      debugPrint('STATE HISTORY LIST COUNT: ${response.length}');
    } catch (e, stackTrace) {
      debugPrint('HISTORY ERROR: $e');
      debugPrint('STACKTRACE: $stackTrace');

      emit(
        state.copyWith(
          status: FamerfollowupStatus.failure,
          historyError: e.toString(),
        ),
      );
    }
  }
}
