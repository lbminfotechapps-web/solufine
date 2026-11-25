import 'dart:convert';

import 'package:solufine/features/reports/data/modles/employee_activity_model.dart';
import 'package:dio/dio.dart';
import 'package:solufine/features/reports/domain/entities/invoice_entity.dart';
import 'package:solufine/features/reports/domain/entities/product_analysis_report.dart';

import '../../domain/entities/employee_activity.dart';
import '../../domain/repositories/employee_activity_repository.dart';
import '../datasources/employee_activity_remote_data_source.dart';

class EmployeeActivityRepositoryImpl implements EmployeeActivityRepository {
  final EmployeeActivityRemoteDataSource remoteDataSource;

  EmployeeActivityRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<EmployeeActivity>> getEmployeeActivityDetails({
    required String userId,
    required String searchDate,
    required String logUserId,
  }) async {
    final Response response = await remoteDataSource.getEmployeeActivityDetails(
      userId: userId,
      searchDate: searchDate,
      logUserId: logUserId,
    );

    print('');
    print('==============================================');
    print('REPOSITORY → EMPLOYEE ACTIVITY');
    print('==============================================');
    print('Response Type : ${response.data.runtimeType}');
    print('Response Data : ${response.data}');
    print('==============================================');

    dynamic data = response.data;

    // ============================================================
    // JSON STRING → MAP
    // ============================================================

    if (data is String) {
      try {
        data = jsonDecode(data);
      } catch (e) {
        throw Exception('Failed to decode server response: $e');
      }
    }

    // ============================================================
    // CHECK RESPONSE FORMAT
    // ============================================================

    if (data is! Map) {
      throw Exception('Invalid server response: ${data.runtimeType}');
    }

    final Map<String, dynamic> responseData = Map<String, dynamic>.from(data);

    final bool status = responseData['status'] == true;

    final String message = responseData['message']?.toString() ?? '';

    print('');
    print('==============================================');
    print('PARSED RESPONSE');
    print('==============================================');
    print('Status  : $status');
    print('Message : $message');
    print('==============================================');

    // ============================================================
    // NO RECORD FOUND
    //
    // This is NOT an error.
    // Return empty list so BLoC gives SUCCESS state
    // and UI displays "No Activity Found".
    // ============================================================

    if (!status) {
      final String lowerMessage = message.toLowerCase();

      if (lowerMessage.contains('record not found') ||
          lowerMessage.contains('no record') ||
          lowerMessage.contains('no records') ||
          lowerMessage.contains('record found') == false) {
        print('');
        print('==============================================');
        print('NO EMPLOYEE ACTIVITY FOUND');
        print('==============================================');
        print('Date : $searchDate');
        print('Returning empty list...');
        print('==============================================');

        return [];
      }

      // Actual API failure
      throw Exception(
        message.isNotEmpty ? message : 'Failed to get employee activity',
      );
    }

    // ============================================================
    // GET RESULT
    // ============================================================

    final result = responseData['result'];

    // No result = no records
    if (result == null) {
      print('Result is null → returning empty list');
      return [];
    }

    // ============================================================
    // RESULT MUST BE LIST
    // ============================================================

    if (result is! List) {
      throw Exception('Invalid result format: ${result.runtimeType}');
    }

    // ============================================================
    // EMPTY RESULT
    // ============================================================

    if (result.isEmpty) {
      print('');
      print('==============================================');
      print('NO EMPLOYEE ACTIVITY');
      print('==============================================');
      print('Date : $searchDate');
      print('Result list is empty');
      print('==============================================');

      return [];
    }

    // ============================================================
    // CONVERT RESULT → MODEL
    // ============================================================

    final List<EmployeeActivity> activities = [];

    for (final item in result) {
      if (item is Map) {
        activities.add(
          EmployeeActivityModel.fromJson(Map<String, dynamic>.from(item)),
        );
      }
    }

    // ============================================================
    // FINAL RESULT
    // ============================================================

    print('');
    print('==============================================');
    print('EMPLOYEE ACTIVITY RESULT');
    print('==============================================');
    print('Total Records : ${activities.length}');
    print('==============================================');

    return activities;
  }

  @override
  Future<InvoiceEntity> getTargetSummary({
    required String date,
    required String userId,
    required String amountType,
  }) {
    return remoteDataSource.getTargetSummary(date, userId, amountType);
  }

  @override
  Future<ProductAnalysisReport> getProductAnalysisReport(
    fromDate,
    toDate,
    userId,
    outLetId,
    productId,
    packing,
  ) {
    return remoteDataSource.getProductAnalysisReport(
      fromDate,
      toDate,
      userId,
      outLetId,
      productId,
      packing,
    );
  }
}
