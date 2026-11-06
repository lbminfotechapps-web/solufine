import 'dart:convert';
import 'dart:io';

import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/farmer/famerfollowup/data/model/followuplist_model.dart';
import 'package:solufine/features/farmer/famerfollowup/data/model/submitFollowup_mode.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class FamerfollowupDatasource {
  final DioClient dioClient;

  FamerfollowupDatasource({required this.dioClient});

  Future<SubmitFollowupModel> submitFollowup({
    required String farmerId,
    required String userId,
    required String followUpDate,
    required String followUpType,
    required String remark,
    required double latitude,
    required double longitude,
    required double networkLatitude,
    required double networkLongitude,
    required double gpsLatitude,
    required double gpsLongitude,
    required String geoAddress,
    required String networkInfo,
    required String batteryInfo,
    required String differenceByAndroid,
    required String statusOfFarmer,
    required String activityId,
    required String cropDetails,
    String? imagePath,
  }) async {
    try {
      debugPrint('==========================================');
      debugPrint('SUBMIT FARMER FOLLOWUP');
      debugPrint('==========================================');

      // ==========================================================
      // CREATE FORM DATA
      // ==========================================================

      final formData = FormData.fromMap({
        'differenceByAndroid': differenceByAndroid,
        'user_id': userId,
        'farmer_id': farmerId,
        'followUpDate': followUpDate,
        'followUpType': followUpType,
        'remark': remark,

        'latitude': latitude.toString(),
        'longitude': longitude.toString(),

        'networkLatitude': networkLatitude.toString(),
        'networkLongitude': networkLongitude.toString(),

        'gpsLatitude': gpsLatitude.toString(),
        'gpsLongitude': gpsLongitude.toString(),

        'geoAddress': geoAddress,
        'strNetworkInfo': networkInfo,
        'strBatteryInfo': batteryInfo,
        'status_of_farmer': statusOfFarmer,
        'activityId': activityId,
        'crop_details': cropDetails,
      });

      // ==========================================================
      // PRINT NORMAL FORM FIELDS
      // ==========================================================

      debugPrint('========== FOLLOWUP FORM DATA ==========');

      for (final field in formData.fields) {
        debugPrint('${field.key}: ${field.value}');
      }

      debugPrint('========================================');

      // ==========================================================
      // IMAGE
      // ==========================================================

      if (imagePath != null && imagePath.trim().isNotEmpty) {
        debugPrint('==========================================');
        debugPrint('CHECKING FOLLOWUP IMAGE');
        debugPrint('IMAGE PATH: $imagePath');

        final File imageFile = File(imagePath);

        final bool imageExists = await imageFile.exists();

        debugPrint('IMAGE EXISTS: $imageExists');

        if (imageExists) {
          final int imageSize = await imageFile.length();

          debugPrint('IMAGE SIZE: $imageSize bytes');

          // ======================================================
          // GET IMAGE EXTENSION
          // ======================================================

          String extension = '.jpg';

          final int dotIndex = imagePath.lastIndexOf('.');

          if (dotIndex != -1) {
            extension = imagePath.substring(dotIndex);
          }

          // ======================================================
          // CREATE FILE NAME
          // ======================================================

          final DateTime now = DateTime.now();

          final String day = now.day.toString().padLeft(2, '0');

          final String month = now.month.toString().padLeft(2, '0');

          final String year = now.year.toString();

          final String date = '$day$month$year';

          final String timestamp = (now.millisecondsSinceEpoch ~/ 1000)
              .toString();

          final String fileName =
              'FarmerFollowupPhoto'
              '${date}_'
              '$timestamp'
              '$extension';

          debugPrint('UPLOAD FILE NAME: $fileName');

          // ======================================================
          // CREATE MULTIPART FILE
          // ======================================================

          final MultipartFile multipartFile = await MultipartFile.fromFile(
            imageFile.path,
            filename: fileName,
          );

          // ======================================================
          // IMPORTANT:
          // IMAGE PARAMETER EXPECTED BY API
          // ======================================================

          formData.files.add(MapEntry('selfie_capture_image', multipartFile));

          debugPrint('IMAGE ADDED AS MULTIPART FILE');
          debugPrint('PARAMETER NAME: selfie_capture_image');
          debugPrint('FILE NAME: $fileName');
          debugPrint('FILE SIZE: $imageSize');
        } else {
          debugPrint('IMAGE FILE DOES NOT EXIST: $imagePath');
        }

        debugPrint('==========================================');
      } else {
        debugPrint('NO IMAGE SELECTED');
      }

      // ==========================================================
      // DEBUG MULTIPART FIELDS
      // ==========================================================

      debugPrint('========== MULTIPART FIELDS ==========');

      for (final field in formData.fields) {
        debugPrint('${field.key}: ${field.value}');
      }

      // ==========================================================
      // DEBUG MULTIPART FILES
      // ==========================================================

      debugPrint('========== MULTIPART FILES ===========');

      if (formData.files.isEmpty) {
        debugPrint('NO FILES IN MULTIPART REQUEST');
      }

      for (final file in formData.files) {
        debugPrint('PARAMETER: ${file.key}');

        debugPrint('FILENAME: ${file.value.filename}');

        debugPrint('LENGTH: ${file.value.length}');
      }

      debugPrint('======================================');

      // ==========================================================
      // SEND API
      // ==========================================================

      assert(() {
        debugPrint('POST /add_remark_farmer PARAMETERS:');
        debugPrint(
          const JsonEncoder.withIndent('  ').convert(
            Map<String, String>.fromEntries(formData.fields),
          ),
        );
        return true;
      }());

      debugPrint('API URL: /add_remark_farmer');

      final response = await dioClient.client.post(
        '/add_remark_farmer',
        data: formData,
      );

      // ==========================================================
      // RESPONSE DEBUG
      // ==========================================================

      debugPrint('==========================================');
      debugPrint('FOLLOWUP STATUS CODE: ${response.statusCode}');
      debugPrint('FOLLOWUP RESPONSE TYPE: ${response.data.runtimeType}');
      debugPrint('FOLLOWUP RESPONSE: ${response.data}');
      debugPrint('==========================================');

      // ==========================================================
      // RESPONSE
      // ==========================================================

      if (response.data is Map<String, dynamic>) {
        return SubmitFollowupModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }

      if (response.data is Map) {
        return SubmitFollowupModel.fromJson(
          Map<String, dynamic>.from(response.data as Map),
        );
      }

      if (response.data is String) {
        return SubmitFollowupModel(status: response.data.toString());
      }

      throw Exception(
        'Unexpected API response type: '
        '${response.data.runtimeType}',
      );
    } on DioException catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('SUBMIT FOLLOWUP DIO ERROR');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('STATUS CODE: ${e.response?.statusCode}');
      debugPrint('RESPONSE: ${e.response?.data}');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==========================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('SUBMIT FOLLOWUP ERROR');
      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');
      debugPrint('==========================================');

      rethrow;
    }
  }

  // Future<SubmitFollowupModel> submitFollowup({
  //   required String farmerId,
  //   required String userId,
  //   required String followUpDate,
  //   required String followUpType,
  //   required String remark,
  //   required double latitude,
  //   required double longitude,
  //   required double networkLatitude,
  //   required double networkLongitude,
  //   required double gpsLatitude,
  //   required double gpsLongitude,
  //   required String geoAddress,
  //   required String networkInfo,
  //   required String batteryInfo,
  //   required String differenceByAndroid,
  //   required String statusOfFarmer,
  //   required String activityId,
  //   String? imagePath,
  // }) async {
  //   final formData = FormData.fromMap({
  //     'differenceByAndroid': differenceByAndroid,
  //     'user_id': userId,
  //     'farmer_id': farmerId,
  //     'followUpDate': followUpDate,
  //     'followUpType': followUpType,
  //     'remark': remark,
  //     'latitude': latitude.toString(),
  //     'longitude': longitude.toString(),
  //     'networkLatitude': networkLatitude.toString(),
  //     'networkLongitude': networkLongitude.toString(),
  //     'gpsLatitude': gpsLatitude.toString(),
  //     'gpsLongitude': gpsLongitude.toString(),
  //     'geoAddress': geoAddress,
  //     'strNetworkInfo': networkInfo,
  //     'strBatteryInfo': batteryInfo,
  //     'status_of_farmer': statusOfFarmer,
  //     'activityId': activityId,
  //   });

  //   // ---------------------------------------------------------
  //   // IMAGE
  //   // ---------------------------------------------------------

  //   if (imagePath != null && imagePath.trim().isNotEmpty) {
  //     final file = File(imagePath);

  //     final exists = await file.exists();

  //     if (exists) {
  //       final fileSize = await file.length();

  //       debugPrint('Image Size : $fileSize bytes');

  //       formData.files.add(
  //         MapEntry(
  //           'selfie_capture_image',
  //           await MultipartFile.fromFile(
  //             file.path,
  //             filename: file.path.split('/').last,
  //           ),
  //         ),
  //       );
  //     }
  //   } else {
  //     debugPrint('No image selected');
  //   }

  //   try {
  //     final response = await dioClient.client.post(
  //       '/add_remark_farmer',
  //       data: formData,
  //     );
  //     if (response.data is Map<String, dynamic>) {
  //       return SubmitFollowupModel.fromJson(
  //         response.data as Map<String, dynamic>,
  //       );
  //     }

  //     if (response.data is Map) {
  //       return SubmitFollowupModel.fromJson(
  //         Map<String, dynamic>.from(response.data as Map),
  //       );
  //     }

  //     if (response.data is String) {
  //       return SubmitFollowupModel(status: response.data.toString());
  //     }

  //     throw Exception(
  //       'Unexpected API response type: ${response.data.runtimeType}',
  //     );
  //   } on DioException catch (e, stackTrace) {
  //     rethrow;
  //   } catch (e, stackTrace) {
  //     rethrow;
  //   }
  // }

  Future<List<RemarkListModel>> getRemarkHistory({
    required String farmerId,
  }) async {
    try {
      debugPrint('==========================================');
      debugPrint('FARMER REMARK HISTORY API');
      debugPrint('FARMER ID = [$farmerId]');
      debugPrint('==========================================');

      final formData = FormData.fromMap({'farmer_id': farmerId});

      debugPrint('Sending FormData: farmer_id = $farmerId');

      final response = await dioClient.client.post(
        '/farmer_remark_list',
        data: formData,
      );

      debugPrint('==========================================');
      debugPrint('RAW HISTORY RESPONSE');
      debugPrint('STATUS CODE = ${response.statusCode}');
      debugPrint('RESPONSE TYPE = ${response.data.runtimeType}');
      debugPrint('RESPONSE DATA = ${response.data}');
      debugPrint('==========================================');

      final data = response.data;

      if (data is String) {
        final decoded = jsonDecode(data);

        if (decoded is Map) {
          final responseMap = Map<String, dynamic>.from(decoded);

          final historyData = responseMap['data'];

          if (historyData is List) {
            final result = historyData
                .whereType<Map>()
                .map(
                  (item) =>
                      RemarkListModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList();

            debugPrint('PARSED HISTORY COUNT = ${result.length}');

            return result;
          }

          if (responseMap['status'] == 'no_records') {
            debugPrint('API returned no_records');
            return [];
          }
        }
      }

      if (data is Map) {
        final responseMap = Map<String, dynamic>.from(data);

        final historyData = responseMap['data'];

        if (historyData is List) {
          return historyData
              .whereType<Map>()
              .map(
                (item) =>
                    RemarkListModel.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList();
        }
      }

      if (data is List) {
        return data
            .whereType<Map>()
            .map(
              (item) =>
                  RemarkListModel.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      return [];
    } on DioException catch (e) {
      debugPrint('==========================================');
      debugPrint('HISTORY DIO ERROR');
      debugPrint('MESSAGE = ${e.message}');
      debugPrint('STATUS = ${e.response?.statusCode}');
      debugPrint('RESPONSE = ${e.response?.data}');
      debugPrint('==========================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('HISTORY ERROR = $e');
      debugPrint('STACKTRACE = $stackTrace');

      rethrow;
    }
  }
}
