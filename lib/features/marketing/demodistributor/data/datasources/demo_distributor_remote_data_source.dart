import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/enquiry/data/datasources/enquiry_remote_data_source.dart';
import 'package:solufine/features/marketing/demodistributor/data/models/demo_distributor_model.dart';
import '../../domain/entities/demo_distributor_entry.dart';




class DemoDistributorRemoteDataSource {
  final DioClient client;
  final EnquiryRemoteDataSource locations;

  DemoDistributorRemoteDataSource(this.client)
      : locations = EnquiryRemoteDataSourceImpl(
          dioClient: client,
        );

  // ==========================================
  // LOOKUP API
  // ==========================================

  Future<List<DemoOption>> lookup(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
  }) async {
    switch (kind) {
      case DemoLookup.state:
        return (await locations.getStates(
          userId: userId,
        ))
            .map((item) => DemoOption(item.id, item.name))
            .toList();

      case DemoLookup.district:
        return (await locations.getDistricts(
          userId: userId,
          stateId: parentId,
        ))
            .map((item) => DemoOption(item.id, item.name))
            .toList();

      case DemoLookup.block:
        return (await locations.getTalukas(
          userId: userId,
          districtId: parentId,
        ))
            .map(
              (item) => DemoOption(
                item.talukaId,
                item.name,
              ),
            )
            .toList();

      default:
        break;
    }

    final endpoint = switch (kind) {
      DemoLookup.crop => ApiClient.getCropRecords,
      DemoLookup.subcategory => ApiClient.getClassRecords,
      DemoLookup.variety => ApiClient.getVarietyRecords,
      DemoLookup.irrigation =>
        ApiClient.getDistributorIrrigation,
      _ => throw StateError('Unsupported lookup'),
    };

    final response = await client.client.post(
      endpoint,
      data: parentId.isEmpty
          ? null
          : FormData.fromMap({
              'categoryId': parentId,
            }),
    );

    final dynamic body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;

    if (body is! Map) {
      throw const FormatException(
        'Invalid lookup response.',
      );
    }

    final status = body['status'];

    if (status != null &&
        !{true, 1, '1', 'true'}.contains(status)) {
      throw StateError(
        body['message']?.toString() ??
            'Unable to load options.',
      );
    }

    final dynamic rows = body['result'];

    if (rows is! List) {
      throw const FormatException(
        'Invalid options list.',
      );
    }

    final idKey = switch (kind) {
      DemoLookup.crop => 'fld_category_id',
      DemoLookup.subcategory => 'fld_subcategory_id',
      DemoLookup.variety => 'fld_product_id',
      _ => 'fld_id',
    };

    final nameKey = switch (kind) {
      DemoLookup.crop => 'fld_category_name',
      DemoLookup.irrigation => 'fld_irrigation_name',
      _ => 'fld_product_name',
    };

    final unique = <String, DemoOption>{};

    for (final row in rows.whereType<Map>()) {
      final id = row[idKey]?.toString() ?? '';
      final name = row[nameKey]?.toString() ?? '';

      if (id.isNotEmpty && name.isNotEmpty) {
        unique[id] = DemoOption(
          id,
          name,
          parentId:
              row['fld_subcategory_id']?.toString() ?? '',
        );
      }
    }

    return unique.values.toList();
  }

  // ==========================================
  // SUBMIT DEMO DISTRIBUTOR API
  // ==========================================

  Future<String> submit(DemoDistributorEntry entry) async {
    try {
      final model = DemoDistributorModel(entry);

      final requestData = model.toJson();

      debugPrint(
        '========== SUBMIT DEMO DISTRIBUTOR API ==========',
      );

      for (final item in requestData.entries) {
        debugPrint('${item.key}: ${item.value}');
      }

      final response = await client.client.post(
        ApiClient.submitDemoDistributorDetail,
        data: FormData.fromMap(requestData),
      );

      debugPrint('========== API RESPONSE ==========');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.data}');

      final dynamic body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (body is! Map) {
        throw const FormatException(
          'Invalid demo distributor response.',
        );
      }

      final status = body['status'];

      final message = body['message']?.toString() ??
          'Demo Distributor submitted successfully.';

      if ({true, 1, '1', 'true'}.contains(status)) {
        debugPrint('SUBMIT SUCCESS: $message');
        return message;
      }

      throw StateError(
        body['message']?.toString() ??
            'Unable to submit demo distributor.',
      );
    } on DioException catch (e) {
      debugPrint('SUBMIT API ERROR: ${e.message}');
      debugPrint('ERROR RESPONSE: ${e.response?.data}');

      final data = e.response?.data;

      String message =
          'Something went wrong. Please try again.';

      if (data is Map && data['message'] != null) {
        message = data['message'].toString();
      } else if (e.message != null) {
        message = e.message!;
      }

      throw StateError(message);
    } catch (e) {
      debugPrint('SUBMIT ERROR: $e');
      rethrow;
    }
  }
}

