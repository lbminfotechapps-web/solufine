import 'dart:convert';
import '../../domain/entities/meeting_option.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import '../../domain/entities/meeting_submission.dart';
import '../models/meeting_submission_model.dart';

class MeetingRemoteDataSource {
  MeetingRemoteDataSource({
    required this.dio,
    this.endpoint = ApiClient.submitFarmerMeetingDetails,
  });
  final Dio dio;

  /// Confirmed legacy POST path; overridable for tests.
  final String endpoint;

  void _logError(String operation, Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;
    debugPrint('========== MEETING $operation ERROR ==========');
    if (error is DioException) {
      debugPrint('URL: ${error.requestOptions.uri}');
      debugPrint('METHOD: ${error.requestOptions.method}');
      debugPrint('TYPE: ${error.type.name}');
      debugPrint('HTTP STATUS: ${error.response?.statusCode}');
      debugPrint('RESPONSE: ${error.response?.data}');
      debugPrint('MESSAGE: ${error.message}');
      debugPrint('CAUSE: ${error.error}');
    }
    debugPrint('ERROR: $error');
    debugPrintStack(stackTrace: stackTrace);
    debugPrint('========== END MEETING ERROR ==========');
  }

  Future<List<MeetingOption>> getSeasons() =>
      _options(ApiClient.getSeason, const {}, 'fld_season_id', ['fld_season']);

  Future<List<MeetingOption>> getBudgetApprovers(String query) => _options(
    ApiClient.getMeetingBudgetApprovalReceivedFrom,
    {'searchName': query},
    'fld_id',
    ['fld_adm_name', 'fld_name', 'fld_employee_name', 'fld_user_name', 'name'],
  );

  Future<List<MeetingOption>> _options(
    String path,
    Map<String, String> fields,
    String idKey,
    List<String> nameKeys,
  ) async {
    try {
      final response = await dio.post<Object?>(
        path,
        data: fields.isEmpty ? null : FormData.fromMap(fields),
      );
      final body = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;
      final status = body is Map
          ? body['status']?.toString().trim().toLowerCase()
          : null;
      if (body is! Map ||
          !(body['status'] == true || status == '1' || status == 'true')) {
        throw MeetingSubmissionException(
          body is Map
              ? body['message']?.toString() ?? 'Unable to load meeting options'
              : 'Invalid meeting options response',
        );
      }
      final rows = body['result'];
      if (rows is! List) {
        throw const MeetingSubmissionException(
          'Invalid meeting options response',
        );
      }
      return rows
          .whereType<Map>()
          .map((row) {
            final id = row[idKey]?.toString().trim() ?? '';
            final name = nameKeys
                .map((key) => row[key]?.toString().trim() ?? '')
                .firstWhere(
                  (value) => value.isNotEmpty && value != 'null',
                  orElse: () => '',
                );
            return MeetingOption(id, name);
          })
          .where(
            (option) =>
                option.id.isNotEmpty &&
                option.id != '0' &&
                option.name.isNotEmpty,
          )
          .toList();
    } on DioException catch (error, stackTrace) {
      _logError('LOOKUP', error, stackTrace);
      throw const MeetingSubmissionException(
        'Unable to load meeting options. Please try again.',
      );
    } on FormatException catch (error, stackTrace) {
      _logError('LOOKUP PARSE', error, stackTrace);
      throw const MeetingSubmissionException(
        'Invalid meeting options response',
      );
    }
  }

  Future<MeetingSubmissionResult> submit(MeetingSubmission submission) async {
    if (endpoint.trim().isEmpty) {
      throw const MeetingSubmissionException(
        'Meeting submit endpoint is not configured',
      );
    }
    final form = MeetingSubmissionModel(submission).toFormData();
    if (kDebugMode) {
      debugPrint('========== MEETING POST PARAMETERS ==========');
      debugPrint('MEETING POST: ${dio.options.baseUrl}$endpoint');
      for (final field in form.fields) {
        debugPrint('${field.key}: ${field.value}');
      }
      for (final file in form.files) {
        debugPrint(
          '${file.key}: ${file.value.filename} (${file.value.length} bytes)',
        );
      }
    }
    try {
      final response = await dio.post<Object?>(endpoint, data: form);
      if (kDebugMode) {
        debugPrint('MEETING RESPONSE ${response.statusCode}: ${response.data}');
      }
      return MeetingSubmissionModel.parseResponse(response.data);
    } on DioException catch (error, stackTrace) {
      _logError('POST', error, stackTrace);
      final body = error.response?.data;
      final message = body is Map ? body['message']?.toString().trim() : null;
      throw MeetingSubmissionException(
        message != null && message.isNotEmpty
            ? message
            : 'Unable to submit meeting. Check your connection and try again.',
      );
    } catch (error, stackTrace) {
      _logError('POST RESPONSE', error, stackTrace);
      rethrow;
    }
  }
}
