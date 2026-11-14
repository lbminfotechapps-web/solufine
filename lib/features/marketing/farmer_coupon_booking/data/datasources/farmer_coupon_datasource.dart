import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';

import '../../domain/entities/farmer_coupon_entity.dart';
import '../models/farmer_coupon_model.dart';

class FarmerCouponDataSource {
  final Dio dio;
  final String farmerEndpoint;
  final String productEndpoint;

  FarmerCouponDataSource(
    DioClient client, {
    required this.farmerEndpoint,
    required this.productEndpoint,
  }) : dio = client.client;

  // ===================================================
  // RESPONSE HELPERS
  // ===================================================

  Map<String, dynamic> _responseMap(dynamic value) {
    if (value is String) value = jsonDecode(value);
    if (value is! Map) {
      throw const FormatException('Invalid server response.');
    }

    return Map<String, dynamic>.from(value);
  }

  bool _success(Map<String, dynamic> json) {
    final value = json['status'];

    return value == true ||
        value == 1 ||
        value.toString().toLowerCase() == 'true';
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

  // ===================================================
  // FARMER SEARCH
  // Same farmerName request as FarmerSchedulePage.
  // ===================================================

  Future<List<CouponFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  }) async {
    final response = await dio.post(
      farmerEndpoint,
      data: {'farmerName': searchText},
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
        responseType: ResponseType.plain,
      ),
    );

    final json = _responseMap(response.data);

    if (!_success(json)) {
      return [];
    }

    final result = json['result'];

    if (result is! List) {
      throw const FormatException('Invalid farmer list.');
    }

    return result
        .map((item) {
          final map = Map<String, dynamic>.from(item as Map);

          return CouponFarmer(
            id: _read(map, ['fld_farmer_id', 'farmerId', 'fld_id']),
            name: _read(map, ['fld_farmer_name', 'farmerName', 'fld_name']),
          );
        })
        .where((farmer) {
          return farmer.id.isNotEmpty && farmer.name.isNotEmpty;
        })
        .toList();
  }

  // ===================================================
  // PRODUCTS
  // Java: getOrderProduct()
  // JSON contains categories with productDetails.
  // ===================================================

  Future<List<CouponProduct>> getProducts() async {
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

    final json = _responseMap(response.data);

    if (!_success(json)) {
      return [];
    }

    final categories = json['result'];

    if (categories is! List) {
      throw const FormatException('Invalid product response.');
    }

    final products = <CouponProduct>[];

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

        final product = CouponProduct(
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

    final unique = <String, CouponProduct>{
      for (final product in products) product.id: product,
    };

    return unique.values.toList();
  }

  // ===================================================
  // SUBMIT FARMER COUPON
  // Confirmed API: /submitFarmerCoupon
  // ===================================================

  Future<String> submitCoupon(FarmerCouponEntity coupon) async {
    final file = File(coupon.imagePath);

    if (!await file.exists()) {
      throw StateError('Coupon image not found.');
    }

    final date = DateFormat('ddMMyyyy').format(DateTime.now());

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final extension = coupon.imagePath.contains('.')
        ? coupon.imagePath
              .substring(coupon.imagePath.lastIndexOf('.'))
              .toLowerCase()
        : '.jpg';

    final fileName = 'CouponImage${date}_$timestamp$extension';

    final fields = FarmerCouponModel(coupon).toFields();

    final formData = FormData.fromMap({
      ...fields,
      'uploadImage1': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    debugPrint('========== FARMER COUPON POST ==========');

    for (final item in fields.entries) {
      debugPrint('${item.key}: ${item.value}');
    }

    debugPrint('uploadImage1: $fileName');

    try {
      final response = await dio.post(
        ApiClient.submitFarmerCoupon,
        data: formData,
      );

      final json = _responseMap(response.data);

      final message = json['message']?.toString() ?? '';

      if (!_success(json)) {
        throw Exception(
          message.isNotEmpty ? message : 'Coupon booking failed.',
        );
      }

      return message.isNotEmpty ? message : 'Coupon booked successfully.';
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Unable to submit coupon. Check your connection.');
    }
  }
}
