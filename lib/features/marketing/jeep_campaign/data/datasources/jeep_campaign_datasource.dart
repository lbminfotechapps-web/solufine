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
    if (data is String) data = jsonDecode(data.trim());
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

  Future<void> _addImages(FormData form, String key, List<String> paths) async {
    for (final path in paths) {
      final file = File(path);

      if (!await file.exists()) {
        throw StateError('Image file not found: $path');
      }

      form.files.add(
        MapEntry(
          key,
          await MultipartFile.fromFile(
            path,
            filename: file.uri.pathSegments.last,
          ),
        ),
      );
    }
  }

  Future<String> submitCampaign(JeepCampaign campaign) async {
    final fields = JeepCampaignModel(campaign).toFields();

    final form = FormData.fromMap(fields);

    // Exact field names from your Java MultipartBody.Part[].
    await _addImages(form, 'uploadImageAttachA', campaign.attachmentA);

    await _addImages(form, 'uploadImageAttachB', campaign.attachmentB);

    await _addImages(form, 'uploadImageAttachc1', campaign.attachmentC1);

    await _addImages(form, 'uploadImageAttachc2', campaign.attachmentC2);

    debugPrint('========= JEEP CAMPAIGN POST =========');

    for (final entry in form.fields) {
      debugPrint('${entry.key}: ${entry.value}');
    }

    for (final entry in form.files) {
      debugPrint('${entry.key}: ${entry.value.filename}');
    }

    try {
      final response = await dio.post(
        ApiClient.submitJeepCampaining,
        data: form,
      );

      final body = _map(response.data);

      final message = body['message']?.toString() ?? '';

      if (!_success(body)) {
        throw Exception(
          message.isNotEmpty ? message : 'Jeep campaign submission failed.',
        );
      }

      return message.isNotEmpty
          ? message
          : 'Jeep Campaign details added successfully.';
    } on DioException catch (error) {
      final body = error.response?.data;

      if (body is Map && body['message'] != null) {
        throw Exception(body['message'].toString());
      }

      throw Exception('Network error. Please check your connection.');
    }
  }
}
