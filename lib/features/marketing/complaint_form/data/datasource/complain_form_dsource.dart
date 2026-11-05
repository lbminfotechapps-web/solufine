import 'package:solufine/features/marketing/complaint_form/complaint_debug.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/crop_category_model.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/outlet_list_model.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/season_list_model.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/subcategory_list_model.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/varienty_model.dart';

class ComplainFormDSource {
  final DioClient dioClient;

  ComplainFormDSource(this.dioClient);

  Future<Map<String, String>> getSeasons() async {
    final response = await dioClient.client.post(ApiClient.getSeason);
    final dynamic body = response.data is String
        ? jsonDecode(response.data)
        : response.data;
    if (body is! Map ||
        !(body['status'] == true ||
            body['status'].toString() == '1' ||
            body['status'].toString().toLowerCase() == 'true')) {
      throw const FormatException('Unable to load seasons');
    }
    final result = body['result'];
    if (result is! List) throw const FormatException('Invalid seasons');
    return {
      for (final item in result.whereType<Map>())
        if ((item['fld_season_id'] ?? '').toString().isNotEmpty &&
            item['fld_season_id'].toString() != '0' &&
            (item['fld_season'] ?? '').toString().isNotEmpty)
          item['fld_season'].toString(): item['fld_season_id'].toString(),
    };
  }

  Future<String> _uploadSignature(Uint8List bytes) async {
    final filename = 'Signature_${DateTime.now().millisecondsSinceEpoch}.png';
    final response = await dioClient.client.post(
      ApiClient.upload_sign,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    final dynamic body = response.data is String
        ? jsonDecode(response.data)
        : response.data;
    if (body is! Map || body['status'].toString().toLowerCase() != 'success') {
      throw StateError(
        body is Map
            ? (body['message']?.toString() ?? 'Signature upload failed')
            : 'Invalid signature response',
      );
    }
    for (final key in ['fileName', 'filename', 'file', 'signature']) {
      final value = body[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return filename;
  }

  Future<Map<String, dynamic>> submitComplaintForm(
    Map<String, dynamic> jsonData,
  ) async {
    try {
      ComplaintDebug.log(
        'API',
        'Preparing multipart complaint request',
        jsonData,
      );
      jsonData = Map<String, dynamic>.from(jsonData);
      final signature = jsonData['farmerSignature'];
      if (signature is Uint8List) {
        ComplaintDebug.log('Signature API', 'Uploading signature', signature);
        jsonData['farmerSignature'] = await _uploadSignature(signature);
        ComplaintDebug.log(
          'Signature API',
          'Upload complete',
          jsonData['farmerSignature'],
        );
      }
      final formData = FormData();

      // ============================================
      // NORMAL FORM FIELDS
      // ============================================
      for (final entry in jsonData.entries) {
        final value = entry.value;

        // Skip image files and image lists.
        if (value is File ||
            value is List<File> ||
            entry.key == 'uploadImage2' ||
            entry.key == 'uploadImage3' ||
            entry.key == 'pictures[]') {
          continue;
        }

        formData.fields.add(MapEntry(entry.key, value?.toString() ?? ''));
      }

      // ============================================
      // KM READING IMAGE
      // API KEY: uploadImage2
      // ============================================
      final kmReadingImage = jsonData['uploadImage2'];

      if (kmReadingImage is File) {
        if (!await kmReadingImage.exists()) {
          throw Exception('KM Reading image not found');
        }

        final fileName =
            'KmReadingImage${DateFormat('ddMMyyyy').format(DateTime.now())}'
            '_${DateTime.now().millisecondsSinceEpoch ~/ 1000}'
            '${_fileExtension(kmReadingImage.path)}';

        final multipartFile = await MultipartFile.fromFile(
          kmReadingImage.path,
          filename: fileName,
        );

        formData.files.add(MapEntry('uploadImage2', multipartFile));
      }

      // ============================================
      // SHOP BOARD IMAGE
      // API KEY: uploadImage3
      // ============================================
      final shopBoardImage = jsonData['uploadImage3'];

      if (shopBoardImage is File) {
        if (!await shopBoardImage.exists()) {
          throw Exception('Shop Board image not found');
        }

        final fileName =
            'ShopBoardImage${DateFormat('ddMMyyyy').format(DateTime.now())}'
            '_${DateTime.now().millisecondsSinceEpoch ~/ 1000}'
            '${_fileExtension(shopBoardImage.path)}';

        final multipartFile = await MultipartFile.fromFile(
          shopBoardImage.path,
          filename: fileName,
        );

        formData.files.add(MapEntry('uploadImage3', multipartFile));
      }

      // ============================================
      // MULTIPLE FIELD IMAGES
      // API KEY: pictures[]
      // ============================================
      final fieldImages = jsonData['pictures[]'];

      if (fieldImages is List) {
        for (int i = 0; i < fieldImages.length; i++) {
          final image = fieldImages[i];

          if (image is! File) continue;

          if (!await image.exists()) {
            throw Exception('Field image ${i + 1} not found');
          }

          final multipartFile = await MultipartFile.fromFile(
            image.path,
            filename: image.uri.pathSegments.last,
          );

          formData.files.add(MapEntry('pictures[]', multipartFile));
        }
      }

      // ============================================
      // DEBUG MULTIPART REQUEST
      // ============================================
      debugPrint('========== SUBMIT COMPLAINT REQUEST ==========');

      for (final field in formData.fields) {
        debugPrint('${field.key}: ${field.value}');
      }

      for (final file in formData.files) {
        debugPrint('${file.key}: ${file.value.filename}');
      }

      debugPrint('======================================');

      // ============================================
      // API CALL
      // ============================================
      ComplaintDebug.log(
        'API',
        'POST ' +
            dioClient.client.options.baseUrl +
            ApiClient.submitComplaintForm,
      );
      final response = await dioClient.client.post(
        ApiClient.submitComplaintForm,
        data: formData,
        options: Options(contentType: Headers.multipartFormDataContentType),
      );

      ComplaintDebug.log('API', 'HTTP response', {
        'statusCode': response.statusCode,
        'body': response.data,
      });

      debugPrint('Submit Complaint Response: ${response.data}');

      // ============================================
      // PARSE API RESPONSE
      // ============================================
      dynamic data = response.data;

      if (data is String) {
        try {
          data = jsonDecode(data);
        } catch (e) {
          throw const FormatException(
            'Invalid JSON response from submit complaint API',
          );
        }
      }

      if (data is! Map) {
        throw const FormatException(
          'Submit Complaint API response is not a JSON object',
        );
      }

      final result = Map<String, dynamic>.from(data);

      final bool success =
          result['status'] == true ||
          result['status'] == 1 ||
          result['status']?.toString().toLowerCase() == 'true';

      if (!success) {
        throw FormatException(
          result['message']?.toString() ?? 'Failed to submit complaint',
        );
      }

      ComplaintDebug.log('API', 'Complaint accepted', result);
      return result;
    } on DioException catch (e, stackTrace) {
      ComplaintDebug.error('API', e, stackTrace);
      debugPrint('========== COMPLAINT DIO ERROR ==========');
      debugPrint('URL: ${e.requestOptions.uri}');
      debugPrint('Method: ${e.requestOptions.method}');
      debugPrint('Status: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Error Type: ${e.type}');
      debugPrint('Message: ${e.message}');
      debugPrint('========================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Submit Complaint Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  // Add this helper inside the same Datasource class.
  String _fileExtension(String path) {
    final name = path.split(RegExp(r'[/\\]')).last;
    final dotIndex = name.lastIndexOf('.');

    return dotIndex >= 0 ? name.substring(dotIndex) : '.jpg';
  }

  Future<OutletListModel> getOutletList(
    String userId,
    String dealerType,
    String dealerName,
  ) async {
    try {
      final response = await dioClient.client.post(
        ApiClient.getDealerRetailerList,
        data: FormData.fromMap({
          'userId': userId,
          'dealerType': dealerType,
          'dealerName': dealerName,
        }),
      );
      debugPrint('Response: ${response.data}');
      debugPrint('========== OUTLET LIST API ==========');
      debugPrint('userId: ${userId}');
      debugPrint('dealerType: ${dealerType}');
      debugPrint('dealerName: ${dealerName}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid outlet list response');
      }

      return OutletListModel.fromJson(Map<String, dynamic>.from(decodedData));
    } catch (e, stackTrace) {
      debugPrint('Get Outlet List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<CropCategoryListModel> getCategoryList() async {
    try {
      final response = await dioClient.client.post(ApiClient.getCropRecords);

      debugPrint('========== CATEGORY LIST API ==========');
      debugPrint('Response: ${response.data}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid category list response');
      }

      return CropCategoryListModel.fromJson(
        Map<String, dynamic>.from(decodedData),
      );
    } catch (e, stackTrace) {
      debugPrint('Get Category List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<SubCategoryListModel> getSubCategoryList(String categoryId) async {
    try {
      final response = await dioClient.client.post(
        ApiClient.getClassRecords,
        data: FormData.fromMap({'categoryId': categoryId}),
      );

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      print('========== SUB CATEGORY LIST API ==========');
      print('Product Response: ${response.data}');

      if (decodedData is! Map) {
        throw const FormatException('Invalid sub category list response');
      }

      return SubCategoryListModel.fromJson(
        Map<String, dynamic>.from(decodedData),
      );
    } catch (e, stackTrace) {
      debugPrint('Get Sub Category List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<VarientyModel> getVarietyList(String categoryId) async {
    try {
      final response = await dioClient.client.post(
        ApiClient.getVarietyRecords,
        data: FormData.fromMap({'categoryId': categoryId}),
      );

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid sub category list response');
      }

      return VarientyModel.fromJson(Map<String, dynamic>.from(decodedData));
    } catch (e, stackTrace) {
      debugPrint('Get Sub Category List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }



  Future<SeasonListModel> getSeaonList() async {
    try {
      final response = await dioClient.client.post(ApiClient.getSeasons);

      debugPrint('========== Season LIST API ==========');
      debugPrint('Response: ${response.data}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid category list response');
      }

      return SeasonListModel.fromJson(
        Map<String, dynamic>.from(decodedData),
      );
    } catch (e, stackTrace) {
      debugPrint('Get Category List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
