import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/enquiry/data/datasources/enquiry_remote_data_source.dart';
import '../../domain/entities/demo_distributor_entry.dart';

/// Supply an adapter here once the Demo Distributor API contract is confirmed.
typedef DemoDistributorSubmitAdapter =
    Future<String> Function(DemoDistributorEntry entry);

class DemoDistributorRemoteDataSource {
  final DioClient client;
  final EnquiryRemoteDataSource locations;
  final DemoDistributorSubmitAdapter? submitAdapter;
  DemoDistributorRemoteDataSource(this.client, {this.submitAdapter})
    : locations = EnquiryRemoteDataSourceImpl(dioClient: client);

  Future<List<DemoOption>> lookup(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
  }) async {
    switch (kind) {
      case DemoLookup.state:
        return (await locations.getStates(
          userId: userId,
        )).map((item) => DemoOption(item.id, item.name)).toList();
      case DemoLookup.district:
        return (await locations.getDistricts(
          userId: userId,
          stateId: parentId,
        )).map((item) => DemoOption(item.id, item.name)).toList();
      case DemoLookup.block:
        return (await locations.getTalukas(
          userId: userId,
          districtId: parentId,
        )).map((item) => DemoOption(item.talukaId, item.name)).toList();
      default:
        break;
    }
    final endpoint = switch (kind) {
      DemoLookup.crop => ApiClient.getCropRecords,
      DemoLookup.subcategory => ApiClient.getClassRecords,
      DemoLookup.variety => ApiClient.getVarietyRecords,
      DemoLookup.irrigation => ApiClient.getCropAndIrigationDetails,
      _ => throw StateError('Unsupported lookup'),
    };
    final response = await client.client.post(
      endpoint,
      data: parentId.isEmpty
          ? null
          : FormData.fromMap({'categoryId': parentId}),
    );
    final dynamic body = response.data is String
        ? jsonDecode(response.data as String)
        : response.data;
    if (body is! Map) throw const FormatException('Invalid lookup response.');
    final status = body['status'];
    if (status != null && !{true, 1, '1', 'true'}.contains(status)) {
      throw StateError(
        body['message']?.toString() ?? 'Unable to load options.',
      );
    }
    final dynamic rows =
        body[kind == DemoLookup.irrigation
            ? 'irrigationDetailsData'
            : 'result'];
    if (rows is! List) throw const FormatException('Invalid options list.');
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
          parentId: row['fld_subcategory_id']?.toString() ?? '',
        );
      }
    }
    return unique.values.toList();
  }

  Future<String> submit(DemoDistributorEntry entry) async {
    final adapter = submitAdapter;
    if (adapter == null) {
      throw StateError('Demo Distributor submission is not connected.');
    }
    return adapter(entry);
  }
}
