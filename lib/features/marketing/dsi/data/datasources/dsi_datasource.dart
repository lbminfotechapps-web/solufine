import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';

import '../../domain/entities/dsi_entity.dart';
import '../models/dsi_model.dart';

class DsiDataSource {
  final Dio dio;

  DsiDataSource(DioClient client) : dio = client.client;

  Map<String, dynamic> _responseMap(dynamic data) {
    // Some API responses contain JSON but are served as plain text.
    if (data is String) {
      try {
        data = jsonDecode(data.trim());
      } on FormatException {
        throw const FormatException('Invalid API response format.');
      }
    }

    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }

    throw const FormatException('Invalid API response format.');
  }

  bool _isSuccess(Map<String, dynamic> body) {
    final status = body['status'];

    return status == true ||
        status == 1 ||
        status.toString().toLowerCase() == 'true' ||
        status.toString() == '1';
  }

  String _message(Map<String, dynamic> body) {
    return body['message']?.toString() ?? 'Something went wrong.';
  }

  // ======================================================
  // DSI LIST
  // POST: dsi_list
  // Content-Type: application/x-www-form-urlencoded
  // ======================================================

  Future<List<DsiRecord>> getDsiList(DsiFilter filter) async {
    final params = DsiRequestModel.listFields(filter);

    debugPrint('========== DSI LIST POST ==========');

    params.forEach((key, value) {
      debugPrint('$key: $value');
    });

    final response = await dio.post(
      ApiClient.dsiList,
      data: params,
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );

    debugPrint('DSI LIST RESPONSE: ${response.data}');

    final body = _responseMap(response.data);

    if (!_isSuccess(body)) {
      // "No records" is a valid empty-list state.
      // Do not retain stale list items.
      final message = _message(body).toLowerCase();

      if (message.contains('no record') ||
          message.contains('not found') ||
          body['result'] is List && (body['result'] as List).isEmpty) {
        return [];
      }

      throw Exception(_message(body));
    }

    final result = body['result'];

    if (result == null) return [];

    if (result is! List) {
      throw const FormatException('DSI result must be a list.');
    }

    return result.map<DsiRecord>((raw) {
      if (raw is! Map) {
        throw const FormatException('Invalid DSI list item.');
      }

      return DsiRecordModel.fromJson(Map<String, dynamic>.from(raw));
    }).toList();
  }

  // ======================================================
  // ADD DSI
  // POST: add_dsi
  // Content-Type: multipart/form-data
  // ======================================================

  Future<String> addDsi(AddDsiEntity entity) async {
    final params = DsiRequestModel.addFields(entity);

    final formData = FormData.fromMap(params);

    final path = entity.photoPath;

    if (path != null && path.isNotEmpty) {
      final file = File(path);

      if (!await file.exists()) {
        throw StateError('DSI photo not found.');
      }

      formData.files.add(
        MapEntry(
          'dsi_photo',
          await MultipartFile.fromFile(
            path,
            filename: 'DSI_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: DioMediaType('image', 'jpeg'),
          ),
        ),
      );
    }

    debugPrint('========== ADD DSI POST ==========');

    for (final item in formData.fields) {
      debugPrint('${item.key}: ${item.value}');
    }

    for (final item in formData.files) {
      debugPrint('${item.key}: ${item.value.filename}');
    }

    final response = await dio.post(
      ApiClient.addDsi,
      data: formData,
      options: Options(
        sendTimeout: const Duration(minutes: 2),
        receiveTimeout: const Duration(minutes: 2),
      ),
      onSendProgress: (sent, total) {
        if (total > 0) {
          debugPrint(
            'DSI Upload: '
            '${(sent * 100 / total).toStringAsFixed(1)}%',
          );
        }
      },
    );

    debugPrint('ADD DSI RESPONSE: ${response.data}');

    final body = _responseMap(response.data);

    if (!_isSuccess(body)) {
      throw Exception(_message(body));
    }

    return body['message']?.toString() ?? 'DSI submitted successfully.';
  }
}
