import 'dart:convert';
import 'dart:io';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/farmer/farmerregistration/data/model/baseresponse_model.dart';
import 'package:solufine/features/farmer/farmerregistration/data/model/district_model.dart';
import 'package:solufine/features/farmer/farmerregistration/data/model/farmer_details_model.dart';
import 'package:solufine/features/farmer/farmerregistration/data/model/state_model.dart';
import 'package:dio/dio.dart';

class FarmerregistrationDatasource {
  final DioClient dioClient;

  FarmerregistrationDatasource({
    required this.dioClient,
  });

  // ============================================================
  // FARMER REGISTRATION
  // ============================================================

  Future<BaseResponseModel> farmerRegistration({
    required Map<String, dynamic> data,
  }) async {
    final response = await dioClient.client.post(
      '/farmer-registration',
      data: data,
    );

    return BaseResponseModel.fromJson(
      response.data,
    );
  }

  // ============================================================
  // GET STATES
  // ============================================================

  Future<List<StateModel>> getStates(
    String userId,
  ) async {
    final formData = FormData.fromMap({
      'user_id': userId,
    });

    final response = await dioClient.client.post(
      ApiClient.getState,
      data: formData,
    );

    print(
      'API RESPONSE TYPE: ${response.data.runtimeType}',
    );

    print(
      'API RESPONSE: ${response.data}',
    );

    final List<dynamic> result =
        jsonDecode(
      response.data.toString(),
    );

    print(
      'STATE LIST LENGTH: ${result.length}',
    );

    final List<StateModel> states =
        result
            .map(
              (json) => StateModel.fromJson(
                Map<String, dynamic>.from(
                  json,
                ),
              ),
            )
            .toList();

    for (final state in states) {
      print(
        'STATE -> ID: ${state.stateId} | '
        'NAME: ${state.stateName}',
      );
    }

    return states;
  }

  // ============================================================
  // GET DISTRICT
  // ============================================================

  Future<Map<String, String>> getPersonCategories() async {
    final response = await dioClient.client.post(ApiClient.getPersonCategory);
    final data = response.data;
    final categories = data is String ? jsonDecode(data) : data;
    if (categories is! List) {
      throw const FormatException('Expected a list of person categories');
    }

    final namesById = <String, String>{};
    for (final category in categories.whereType<Map<String, dynamic>>()) {
      final id = category['fld_category_id']?.toString().trim() ?? '';
      final name = category['fld_category_name']?.toString().trim() ?? '';
      if (id.isNotEmpty && name.isNotEmpty) {
        namesById[id] = name;
      }
    }
    return namesById;
  }

  Future<List<DistrictModel>> getDistrict(
    String userId,
    String stateId,
  ) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'state_id': stateId,
      });

      final response =
          await dioClient.client.post(
        ApiClient.getDistrictTaluka,
        data: formData,
      );

      print(
        'API RESPONSE TYPE: ${response.data.runtimeType}',
      );

      print(
        'API RESPONSE: ${response.data}',
      );

      dynamic responseData =
          response.data;

      if (responseData is String) {
        responseData =
            jsonDecode(responseData);
      }

      if (responseData is! List) {
        throw Exception(
          'Invalid district API response',
        );
      }

      final List<DistrictModel> districts =
          responseData
              .map(
                (json) =>
                    DistrictModel.fromJson(
                  Map<String, dynamic>.from(
                    json,
                  ),
                ),
              )
              .toList();

      print(
        'DISTRICT COUNT: ${districts.length}',
      );

      for (final district in districts) {
        print(
          'DISTRICT: '
          '${district.fldDistId} - '
          '${district.fldDistName}',
        );

        print(
          'TALUKA COUNT: '
          '${district.taluka.length}',
        );

        for (final taluka
            in district.taluka) {
          print(
            'TALUKA: '
            '${taluka.fldTalukaId} - '
            '${taluka.fldName}',
          );
        }
      }

      return districts;
    } catch (e) {
      print(
        'GET DISTRICT ERROR: $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // FARMER DROP DATA
  // ============================================================

  Future<FarmerDetailsModel>
      getFarmerDropData() async {
    try {
      final response =
          await dioClient.client.post(
        ApiClient.getCropAndIrigationDetails,
      );

      print(
        'FARMER DATA RESPONSE TYPE: '
        '${response.data.runtimeType}',
      );

      print(
        'FARMER DATA RESPONSE: '
        '${response.data}',
      );

      dynamic responseData =
          response.data;

      if (responseData is String) {
        responseData =
            jsonDecode(responseData);
      }

      if (responseData
          is! Map<String, dynamic>) {
        throw Exception(
          'Invalid farmer data API response',
        );
      }

      final farmerDetails =
          FarmerDetailsModel.fromJson(
        responseData,
      );

      print(
        'CROP COUNT: '
        '${farmerDetails.cropDetailsData.length}',
      );

      print(
        'IRRIGATION COUNT: '
        '${farmerDetails.irrigationDetailsData.length}',
      );

      print(
        'PRODUCT COUNT: '
        '${farmerDetails.productDetailsData.length}',
      );

      return farmerDetails;
    } catch (e) {
      print(
        'GET FARMER DATA ERROR: $e',
      );

      rethrow;
    }
  }



  Future<Map<String, dynamic>>
      saveFarmerDetails(
    Map<String, dynamic> data,
    File? image,
  ) async {
    try {
      print(
        '==========================================',
      );
      print(
        'SAVE FARMER DETAILS - MULTIPART',
      );
      print(
        '==========================================',
      );

      // ==========================================================
      // NORMAL FORM FIELDS
      // ==========================================================

      final Map<String, dynamic> formMap =
          Map<String, dynamic>.from(
        data,
      );

      // IMPORTANT:
      // Do not send Base64/string image here.
      formMap.remove(
        'selfie_capture_image',
      );

      formMap.remove(
        'image',
      );

      print(
        '========== NORMAL FORM DATA ==========',
      );

      formMap.forEach(
        (key, value) {
          print(
            '$key: $value',
          );
        },
      );

      print(
        '======================================',
      );

      // ==========================================================
      // CREATE FORM DATA
      // ==========================================================

      final formData =
          FormData.fromMap(
        formMap,
      );

     

      if (image != null) {
        print(
          '==========================================',
        );
        print(
          'CHECKING FARMER IMAGE',
        );

        print(
          'IMAGE PATH: ${image.path}',
        );

        final bool imageExists =
            await image.exists();

        print(
          'IMAGE EXISTS: $imageExists',
        );

        if (imageExists) {
          final int imageSize =
              await image.length();

          print(
            'IMAGE SIZE: $imageSize bytes',
          );

          // ================================================
          // Get file extension
          // ================================================

          String extension = '.jpg';

          final String path =
              image.path;

          final int dotIndex =
              path.lastIndexOf('.');

          if (dotIndex != -1) {
            extension =
                path.substring(
              dotIndex,
            );
          }

          // ================================================
          // Same style as Android:
          // FarmerPhoto + date + timestamp
          // ================================================

          final DateTime now =
              DateTime.now();

          final String day =
              now.day
                  .toString()
                  .padLeft(2, '0');

          final String month =
              now.month
                  .toString()
                  .padLeft(2, '0');

          final String year =
              now.year.toString();

          final String date =
              '$day$month$year';

          final String timestamp =
              (now.millisecondsSinceEpoch ~/
                      1000)
                  .toString();

          final String fileName =
              'FarmerPhoto'
              '${date}_'
              '$timestamp'
              '$extension';

          print(
            'UPLOAD FILE NAME: $fileName',
          );

          // ================================================
          //  THIS IS THE MOST IMPORTANT CODE
          // ================================================

          final MultipartFile multipartFile =
              await MultipartFile.fromFile(
            image.path,
            filename: fileName,

            // Usually Dio detects it sufficiently.
            // Don't manually send Base64.
          );

          // ================================================
          //  EXACT SAME PARAMETER AS ANDROID
          // ================================================

          formData.files.add(
            MapEntry(
              'selfie_capture_image',
              multipartFile,
            ),
          );

          print(
            ' IMAGE ADDED AS MULTIPART FILE',
          );

          print(
            'PARAMETER NAME: '
            'selfie_capture_image',
          );

          print(
            'FILE NAME: $fileName',
          );

          print(
            'FILE SIZE: $imageSize',
          );
        } else {
          print(
            ' IMAGE FILE DOES NOT EXIST',
          );
        }

        print(
          '==========================================',
        );
      } else {
        print(
          ' IMAGE IS NULL - NO FILE RECEIVED',
        );
      }

      // ==========================================================
      // PRINT MULTIPART NORMAL FIELDS
      // ==========================================================

      print(
        '========== MULTIPART FIELDS ==========',
      );

      for (final field
          in formData.fields) {
        print(
          '${field.key}: ${field.value}',
        );
      }

      // ==========================================================
      // PRINT MULTIPART FILES
      // ==========================================================

      print(
        '========== MULTIPART FILES ===========',
      );

      if (formData.files.isEmpty) {
        print(
          ' NO FILES IN MULTIPART REQUEST',
        );
      }

      for (final file
          in formData.files) {
        print(
          'PARAMETER: ${file.key}',
        );

        print(
          'FILENAME: ${file.value.filename}',
        );

        print(
          'LENGTH: ${file.value.length}',
        );
      }

      print(
        '======================================',
      );

      print(
        'LATITUDE BEFORE REQUEST: '
        '${formMap['latitude']}',
      );

      print(
        'LONGITUDE BEFORE REQUEST: '
        '${formMap['longitude']}',
      );

      print(
        'API URL: ${ApiClient.addFarmerDetails}',
      );

      // ==========================================================
      // SEND REQUEST
      // ==========================================================

      final response =
          await dioClient.client.post(
        ApiClient.addFarmerDetails,
        data: formData,

        // Dio recognizes FormData and creates the multipart
        // boundary automatically.
        //
        // Do NOT manually create JSON request here.
      );

      print(
        '==========================================',
      );

      print(
        'SAVE FARMER STATUS CODE: '
        '${response.statusCode}',
      );

      print(
        'SAVE FARMER RESPONSE TYPE: '
        '${response.data.runtimeType}',
      );

      print(
        'SAVE FARMER RESPONSE: '
        '${response.data}',
      );

      print(
        '==========================================',
      );

      // ==========================================================
      // HANDLE RESPONSE
      // ==========================================================

      dynamic responseData =
          response.data;

      if (responseData is String) {
        responseData =
            jsonDecode(
          responseData,
        );
      }

      if (responseData
          is Map<String, dynamic>) {
        return responseData;
      }

      if (responseData is Map) {
        return Map<String, dynamic>.from(
          responseData,
        );
      }

      throw Exception(
        'Invalid save farmer API response',
      );
    } catch (e, stackTrace) {
      print(
        '==========================================',
      );

      print(
        'SAVE FARMER ERROR',
      );

      print(
        'ERROR: $e',
      );

      print(
        'STACK TRACE: $stackTrace',
      );

      print(
        '==========================================',
      );

      rethrow;
    }
  }

  // ============================================================
  // UPDATE FARMER
  // ============================================================

  Future<Map<String, dynamic>>
      updateFarmerDetails(
    Map<String, dynamic> data,
  ) async {
    try {
      final formMap =
          Map<String, dynamic>.from(
        data,
      );

      print(
        '==========================================',
      );

      print(
        'UPDATE FARMER API',
      );

      print(
        'URL: ${ApiClient.updateFarmerDtails}',
      );

      print(
        'METHOD: POST',
      );

      print(
        '==========================================',
      );

      print(
        '========== FINAL UPDATE FORM DATA ==========',
      );

      print(
        'LATITUDE: ${formMap['latitude']}',
      );

      print(
        'LONGITUDE: ${formMap['longitude']}',
      );

      final formData =
          FormData.fromMap(
        formMap,
      );

      for (final field
          in formData.fields) {
        print(
          '${field.key}: ${field.value}',
        );
      }

      print(
        '============================================',
      );

      final response =
          await dioClient.client.post(
        ApiClient.updateFarmerDtails,
        data: formData,
      );

      print(
        'UPDATE FARMER STATUS: '
        '${response.statusCode}',
      );

      print(
        'UPDATE FARMER RESPONSE TYPE: '
        '${response.data.runtimeType}',
      );

      print(
        'UPDATE FARMER RESPONSE: '
        '${response.data}',
      );

      dynamic responseData =
          response.data;

      if (responseData is String) {
        final responseString =
            responseData.trim();

        try {
          responseData =
              jsonDecode(
            responseString,
          );
        } catch (e) {
          print(
            'Normal JSON decode failed: $e',
          );

          final jsonStart =
              responseString.indexOf(
            '{',
          );

          if (jsonStart != -1) {
            final jsonPart =
                responseString
                    .substring(
                      jsonStart,
                    )
                    .trim();

            print(
              'Extracted JSON: $jsonPart',
            );

            responseData =
                jsonDecode(
              jsonPart,
            );
          } else {
            throw Exception(
              'Invalid update farmer API response: '
              '$responseString',
            );
          }
        }
      }

      if (responseData
          is Map<String, dynamic>) {
        return responseData;
      }

      if (responseData is Map) {
        return Map<String, dynamic>.from(
          responseData,
        );
      }

      throw Exception(
        'Invalid update farmer API response',
      );
    } catch (e) {
      print(
        '============================================',
      );

      print(
        'UPDATE FARMER ERROR',
      );

      print(e);

      print(
        '============================================',
      );

      rethrow;
    }
  }
}
