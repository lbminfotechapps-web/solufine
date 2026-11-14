import 'package:solufine/features/schedule/data/datasources/farmer_schedule_remote_data_source.dart';
import 'dart:convert';

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';

import '../../domain/entities/success_story_entity.dart';
import '../models/success_story_model.dart';

class SuccessStoryDataSource {
  final Dio dio;
  final FarmerScheduleRemoteDataSource farmerSearch;

  SuccessStoryDataSource(DioClient client, {required this.farmerSearch})
    : dio = client.client;

  Map<String, dynamic> _map(dynamic value) {
    if (value is String) value = jsonDecode(value.trim());
    if (value is! Map) {
      throw const FormatException('Invalid server response.');
    }

    return Map<String, dynamic>.from(value);
  }

  bool _success(Map<String, dynamic> value) {
    final status = value['status'];

    return status == true ||
        status == 1 ||
        status.toString().toLowerCase() == 'true';
  }

  // ===================================================
  // FARMER SEARCH
  // Reuse the farmer search service used by FieldDayPage.
  // ===================================================

  Future<List<SuccessStoryFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  }) async {
    final farmers = await farmerSearch.searchFarmer(
      searchKey: searchText.trim(),
    );
    return farmers
        .where((farmer) => farmer.farmerId.isNotEmpty && farmer.farmerId != '0')
        .map(
          (farmer) => SuccessStoryFarmer(
            id: farmer.farmerId,
            name: farmer.farmerName,
            mobile: farmer.mobileNo,
            address: farmer.address,
          ),
        )
        .toList();
  }
  // ===================================================
  // CROP LIST
  // Confirmed Java endpoint:
  // getCropAndIrigationDetails
  // Response: cropDetailsData
  // ===================================================

  Future<List<SuccessStoryCrop>> getCrops() async {
    final response = await dio.post(
      ApiClient.successStoryCrops,
      data: FormData.fromMap(<String, String>{}),
    );

    final body = _map(response.data);

    final result = body['cropDetailsData'];

    if (result is! List) {
      throw const FormatException('Invalid crop details response.');
    }

    return result
        .map((raw) {
          final item = _map(raw);

          return SuccessStoryCrop(
            id: item['fld_crop_id']?.toString() ?? '',
            name: item['fld_crop_name']?.toString() ?? '',
          );
        })
        .where((crop) {
          return crop.id.isNotEmpty && crop.name.isNotEmpty;
        })
        .toList();
  }

  // ===================================================
  // SUBMIT SUCCESS STORY
  // ===================================================

  Future<String> submitStory(SuccessStoryEntity story) async {
    final fields = SuccessStoryModel(story).toFields();

    final form = FormData.fromMap(fields);

    final videoPath = story.videoPath;

    if (videoPath != null && videoPath.isNotEmpty) {
      final file = File(videoPath);

      if (!await file.exists()) {
        throw StateError('Video file not found.');
      }

      final fileName = file.uri.pathSegments.last;

      form.files.add(
        MapEntry(
          'video',
          await MultipartFile.fromFile(file.path, filename: fileName),
        ),
      );
    } else {
      // The Java implementation sends a blank
      // multipart video part when no video is selected.
      form.files.add(
        MapEntry('video', MultipartFile.fromBytes(<int>[], filename: ' ')),
      );
    }

    debugPrint('========== SUCCESS STORY POST ==========');

    for (final entry in fields.entries) {
      debugPrint('${entry.key}: ${entry.value}');
    }

    for (final entry in form.files) {
      debugPrint('${entry.key}: ${entry.value.filename}');
    }

    try {
      final response = await dio.post(
        ApiClient.submitSuccessStory,
        data: form,
        options: Options(sendTimeout: const Duration(minutes: 3)),
      );

      final body = _map(response.data);

      final message = body['message']?.toString() ?? '';

      if (!_success(body)) {
        throw Exception(
          message.isNotEmpty ? message : 'Unable to submit success story.',
        );
      }

      return message.isNotEmpty
          ? message
          : 'Success story submitted successfully.';
    } on DioException catch (error) {
      final data = error.response?.data;

      if (data is Map && data['message'] != null) {
        throw Exception(data['message'].toString());
      }

      throw Exception('Video upload failed. Please check your connection.');
    }
  }
}
