import 'dart:convert';

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';

import '../../domain/entities/jeep_campaign.dart';
import '../models/jeep_campaign_model.dart';

class JeepCampaignDataSource {
  final Dio dio;
  final String seasonEndpoint;
  final String productEndpoint;

  JeepCampaignDataSource(
    DioClient client, {
    required this.seasonEndpoint,
    required this.productEndpoint,
  }) : dio = client.client;

  Map<String, dynamic> _map(dynamic data) {
    if (data is String) {
      final rawResponse = data.trim();

      if (rawResponse.isEmpty) {
        throw const FormatException('Empty API response.');
      }

      if (rawResponse.startsWith('<')) {
        debugPrint('========= BACKEND ERROR =========');
        debugPrint(rawResponse, wrapWidth: 1024);
        debugPrint('=================================');

        throw const FormatException(
          'Server returned an HTML error instead of JSON.',
        );
      }

      data = jsonDecode(rawResponse);
    }

    if (data is! Map) {
      throw const FormatException('Invalid API response.');
    }

    return Map<String, dynamic>.from(data);
  }

  bool _success(Map<String, dynamic> data) {
    final value = data['status'];

    return value == true ||
        value == 1 ||
        value.toString().toLowerCase() == 'true';
  }

  Future<List<JeepOption>> getSeasons() async {
    if (seasonEndpoint.isEmpty) {
      throw StateError('Configure the getSeason API endpoint.');
    }

    final response = await dio.post(
      seasonEndpoint,
      data: FormData.fromMap(<String, String>{}),
    );

    final body = _map(response.data);

    if (!_success(body)) return [];

    final result = body['result'];

    if (result is! List) {
      throw const FormatException('Invalid season list.');
    }

    return result
        .map((item) {
          final data = _map(item);

          // Map the getSeason response; ID 0 is the placeholder.
          return JeepOption(
            id: (data['fld_season_id'] ?? '').toString().trim(),
            name: (data['fld_season'] ?? '').toString().trim(),
          );
        })
        .where((item) {
          return item.id.isNotEmpty && item.id != '0' && item.name.isNotEmpty;
        })
        .toList();
  }

  String _read(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString().trim() ?? '';

      if (value.isNotEmpty && value != 'null') {
        return value;
      }
    }

    return '';
  }

  Future<List<JeepOption>> searchProducts({
    required String seasonId,
    required String searchName,
  }) async {
    if (productEndpoint.trim().isEmpty) {
      throw StateError('Configure the getOrderProduct endpoint first.');
    }

    final response = await dio.post(
      productEndpoint,
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );

    final json = _map(response.data);

    if (!_success(json)) {
      return [];
    }

    final categories = json['result'];

    if (categories is! List) {
      throw const FormatException('Invalid product response.');
    }

    final products = <JeepOption>[];

    for (final category in categories) {
      if (category is! Map) continue;

      final categoryMap = Map<String, dynamic>.from(category);

      final details =
          categoryMap['productDetails'] ??
          categoryMap['product_details'] ??
          categoryMap['fld_product_details'] ??
          categoryMap['product'];

      final entries = details is List ? details : [categoryMap];

      for (final item in entries) {
        if (item is! Map) continue;

        final productMap = Map<String, dynamic>.from(item);

        final product = JeepOption(
          id: _read(productMap, [
            'fld_product_id',
            'fldProductId',
            'productId',
          ]),
          name: _read(productMap, [
            'fld_product_name',
            'fldProductName',
            'productName',
          ]).split('*_*').first.trim(),
        );

        if (product.id.isNotEmpty && product.name.isNotEmpty) {
          products.add(product);
        }
      }
    }

    final unique = <String, JeepOption>{
      for (final product in products) product.id: product,
    };

    return unique.values
        .where(
          (product) => product.name.toLowerCase().contains(
            searchName.trim().toLowerCase(),
          ),
        )
        .toList();
  }

  Future<List<MultipartFile>> _prepareImages(List<String> paths) async {
    final List<MultipartFile> images = [];

    for (final path in paths) {
      final file = File(path);

      if (!await file.exists()) {
        throw StateError('Image file not found: $path');
      }

      images.add(
        await MultipartFile.fromFile(
          path,
          filename: file.uri.pathSegments.last,
        ),
      );
    }

    return images;
  }

  Future<String> submitCampaign(JeepCampaign campaign) async {
    try {
      final fields = JeepCampaignModel(campaign).toFields();

      final form = FormData.fromMap(fields);

     
      final attachments = <String, List<String>>{
        'uploadImageAttachA': campaign.attachmentA,
        'uploadImageAttachB': campaign.attachmentB,
        'uploadImageAttachc1': campaign.attachmentC1,
        'uploadImageAttachc2': campaign.attachmentC2,
      };


      for (final entry in attachments.entries) {
      
        if (entry.value.length > 2) {
          throw Exception('${entry.key}: Maximum 2 images allowed.');
        }

        final images = await _prepareImages(entry.value);

        for (int i = 0; i < images.length; i++) {
          form.files.add(MapEntry('${entry.key}[$i]', images[i]));
        }
      }

      debugPrint('========= JEEP CAMPAIGN POST =========');

      // Print normal fields
      for (final field in form.fields) {
        debugPrint('${field.key}: ${field.value}');
      }

      // Print multipart image fields
      debugPrint('========= IMAGE ATTACHMENTS =========');

      for (final file in form.files) {
        debugPrint('${file.key}: ${file.value.filename}');
      }

      debugPrint('Total Images: ${form.files.length}');
      debugPrint('======================================');

      // API call
      final response = await dio.post(
        ApiClient.submitJeepCampaining,
        data: form,
        options: Options(responseType: ResponseType.plain),
      );

      debugPrint('========= JEEP CAMPAIGN RESPONSE =========');

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      debugPrint('Response Type: ${response.data.runtimeType}');
      debugPrint('Raw Response: ${response.data}', wrapWidth: 1024);

      debugPrint('==========================================');

      final body = _map(response.data);

      debugPrint('Jeep campaign submit response: $body');

      final message = body['message']?.toString() ?? '';

      if (!_success(body)) {
        throw Exception(
          message.isNotEmpty ? message : 'Jeep campaign submission failed.',
        );
      }

      return message.isNotEmpty
          ? message
          : 'Jeep Campaign details added successfully.';
    } on DioException catch (error, stackTrace) {
      debugPrint('Jeep campaign submission Dio error: ${error.message}');
      debugPrint('URL: ${error.requestOptions.uri}');
      debugPrint('Status code: ${error.response?.statusCode}');
      debugPrint('Response: ${error.response?.data}');
      debugPrintStack(stackTrace: stackTrace);

      final responseData = error.response?.data;

      if (responseData != null) {
        String? serverMessage;

        try {
          final body = _map(responseData);
          serverMessage = body['message']?.toString();
        } catch (_) {
          // Response is not a valid JSON object
        }

        if (serverMessage != null && serverMessage.isNotEmpty) {
          throw Exception(serverMessage);
        }
      }

      throw Exception(
        error.response != null
            ? 'Server error (${error.response?.statusCode}).'
            : 'Network error. Please check your connection.',
      );
    } catch (error, stackTrace) {
      debugPrint('Jeep campaign submission error: $error');
      debugPrintStack(stackTrace: stackTrace);

      rethrow;
    }
  }
}
