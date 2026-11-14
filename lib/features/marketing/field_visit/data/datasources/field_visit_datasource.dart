import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';

import '../../domain/entities/field_visit_entity.dart';
import '../models/field_visit_model.dart';

class FieldVisitDataSource {
  final Dio dio;
  final String farmerEndpoint;
  final String cropVarietyEndpoint;

  FieldVisitDataSource(
    DioClient client, {
    required this.farmerEndpoint,
    required this.cropVarietyEndpoint,
  }) : dio = client.client;

  Map<String, dynamic> _map(dynamic data) {
    if (data is String) {
      data = jsonDecode(data.trim());
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('Unexpected API response.');
  }

  bool _success(Map<String, dynamic> data) {
    final status = data['status'];

    return status == true ||
        status == 1 ||
        status.toString().toLowerCase() == 'true' ||
        status.toString() == '1';
  }

  List<dynamic> _resultList(Map<String, dynamic> data) {
    final result = data['result'];

    if (result == null) return [];
    if (result is List) return result;

    throw const FormatException('Expected result array.');
  }

  // =====================================================
  // SEARCH FARMERS
  // =====================================================

  Future<List<FieldVisitFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  }) async {
    if (farmerEndpoint.isEmpty) {
      throw StateError('Configure farmerEndpoint in field_visit_di.dart.');
    }

    final params = {'farmerName': searchText.trim()};

    debugPrint('FIELD VISIT FARMER SEARCH: $params');

    final response = await dio.post(
      farmerEndpoint,
      data: params,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    debugPrint('FIELD VISIT FARMER RESPONSE: ${response.data}');

    final body = _map(response.data);

    if (!_success(body)) {
      return [];
    }

    return _resultList(body)
        .whereType<Map>()
        .map(
          (item) =>
              FieldVisitFarmerModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  // =====================================================
  // LOAD CROP AND VARIETY
  // =====================================================

  Future<List<FieldVisitCrop>> getCropsAndVarieties() async {
    if (cropVarietyEndpoint.isEmpty) {
      throw StateError('Configure cropVarietyEndpoint in field_visit_di.dart.');
    }

    final response = await dio.post(
      cropVarietyEndpoint,
      data: FormData.fromMap({}),
    );

    debugPrint('FIELD VISIT CROP RESPONSE: ${response.data}');

    final body = _map(response.data);

    final crops = body['cropDetailsData'];
    if (crops is! List) {
      throw const FormatException('Invalid crop details response.');
    }

    return crops
        .whereType<Map>()
        .map(
          (item) =>
              FieldVisitCropModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  // =====================================================
  // IMAGE MULTIPART
  // =====================================================

  Future<void> _addImage(
    FormData formData, {
    required String field,
    required String? path,
    required String prefix,
  }) async {
    if (path == null || path.trim().isEmpty) {
      return;
    }

    final file = File(path);

    if (!await file.exists()) {
      throw StateError('$prefix image not found.');
    }

    final ext = path.toLowerCase().endsWith('.png') ? '.png' : '.jpg';

    final timestamp = DateFormat('ddMMyyyy_HHmmss').format(DateTime.now());

    formData.files.add(
      MapEntry(
        field,
        await MultipartFile.fromFile(
          path,
          filename: '${prefix}_$timestamp$ext',
          contentType: ext == '.png'
              ? DioMediaType('image', 'png')
              : DioMediaType('image', 'jpeg'),
        ),
      ),
    );
  }

  // =====================================================
  // SUBMIT FIELD VISIT
  // =====================================================

  Future<String> submitFieldVisit(FieldVisitEntity entity) async {
    final params = FieldVisitRequestModel.toFields(entity);

    final formData = FormData.fromMap(params);

    await _addImage(
      formData,
      field: 'plotImage',
      path: entity.plotImagePath,
      prefix: 'FarmerVisitPlotImage',
    );

    await _addImage(
      formData,
      field: 'kmReadingImage',
      path: entity.kmReadingImagePath,
      prefix: 'FarmerVisitKmReadingImage',
    );

    await _addImage(
      formData,
      field: 'visitorImage',
      path: entity.visitorImagePath,
      prefix: 'FarmerVisitVisitorImage',
    );

    debugPrint('========== FIELD VISIT POST ==========');

    for (final entry in formData.fields) {
      debugPrint('${entry.key}: ${entry.value}');
    }

    for (final entry in formData.files) {
      debugPrint('${entry.key}: ${entry.value.filename}');
    }

    final response = await dio.post(
      ApiClient.insertFieldVisitForm,
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 5),
        receiveTimeout: const Duration(minutes: 2),
      ),
      onSendProgress: (sent, total) {
        if (total > 0) {
          debugPrint(
            'FIELD VISIT UPLOAD: '
            '${(sent * 100 / total).toStringAsFixed(1)}%',
          );
        }
      },
    );

    debugPrint('FIELD VISIT RESPONSE: ${response.data}');

    final body = _map(response.data);

    if (!_success(body)) {
      throw StateError(
        body['message']?.toString() ?? 'Field Visit submission failed.',
      );
    }

    return body['message']?.toString() ?? 'Field Visit submitted successfully.';
  }
}
