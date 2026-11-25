import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:dio/dio.dart';
import 'package:solufine/features/reports/data/modles/invoice_model.dart';
import 'package:solufine/features/reports/data/modles/product_analysis_model.dart';

class EmployeeActivityRemoteDataSource {
  final DioClient dioClient;

  EmployeeActivityRemoteDataSource(this.dioClient);

  Future<Response> getEmployeeActivityDetails({
    required String userId,
    required String searchDate,
    required String logUserId,
  }) async {
    try {
      print('');
      print('==============================================');
      print('       EMPLOYEE ACTIVITY REPORT');
      print('==============================================');

      print('URL        : ${ApiClient.getEmployeeActivityDetails}');
      print('userId     : $userId');
      print('searchDate : $searchDate');
      print('logUserId  : $logUserId');

      print('==============================================');
      print('REQUEST TYPE : POST');
      print('REQUEST BODY : FormData');
      print('==============================================');

      final formData = FormData.fromMap({
        'userId': userId,
        'searchDate': searchDate,
        'logUserId': logUserId,
      });

      print('FORM DATA:');
      for (final field in formData.fields) {
        print('${field.key} : ${field.value}');
      }

      final response = await dioClient.client.post(
        ApiClient.getEmployeeActivityDetails,
        data: formData,
      );

      print('');
      print('==============================================');
      print('EMPLOYEE ACTIVITY API RESPONSE');
      print('==============================================');

      print('STATUS : ${response.statusCode}');
      print('BODY   : ${response.data}');

      print('==============================================');

      return response;
    } on DioException catch (e) {
      print('');
      print('==============================================');
      print('EMPLOYEE ACTIVITY DIO ERROR');
      print('==============================================');

      print('URL      : ${e.requestOptions.uri}');
      print('METHOD   : ${e.requestOptions.method}');
      print('DATA     : ${e.requestOptions.data}');
      print('HEADERS  : ${e.requestOptions.headers}');
      print('Message  : ${e.message}');
      print('Status   : ${e.response?.statusCode}');
      print('Response : ${e.response?.data}');

      print('==============================================');

      throw Exception(
        e.response?.data is String
            ? e.response?.data
            : e.message ?? 'Network error',
      );
    } catch (e) {
      print('');
      print('==============================================');
      print('EMPLOYEE ACTIVITY ERROR');
      print('==============================================');
      print('ERROR : $e');
      print('==============================================');

      throw Exception('Failed to get employee activity: $e');
    }
  }

  Future<InvoiceModel> getTargetSummary(
    String date,
    String userId,
    String amountType,
  ) async {
    try {
      final formData = FormData.fromMap({
        'date': date,
        'user_id': userId,
        'amount_type': amountType,
      });
      print('========== Target Summary Request ==========');
      print('date: $date');
      print('user_id: $userId');
      print('amountType: $amountType');
      final response = await dioClient.client.post(
        ApiClient.getTargetSummary,
        data: formData,
      );

      debugPrint('========== Target Summary API ==========');
      debugPrint('Response: ${response.data}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid Target Summary response');
      }

      return InvoiceModel.fromJson(Map<String, dynamic>.from(decodedData));
    } catch (e, stackTrace) {
      debugPrint('Get Target Summary Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<ProductAnalysisModel> getProductAnalysisReport(
    String fromDate,
    String toDate,
    String userId,
    String outLetId,
    String productId,
    String packing,
  ) async {
    try {
      final formData = FormData.fromMap({
        "from_date": fromDate,
        "to_date": toDate,
        "user_id": userId,
        "outlet_id": outLetId,
        "product_id": productId,
        "with_packing": packing,
      });

      debugPrint('========== Product Analysis Request ==========');

      for (final field in formData.fields) {
        debugPrint('${field.key}: ${field.value}');
      }

      final response = await dioClient.client.post(
        ApiClient.getProductAnalysis,
        data: formData,
      );

      debugPrint('========== Product Analysis Response ==========');
      debugPrint(response.data.toString());

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid Product Analysis Report response');
      }

      final model = ProductAnalysisModel.fromJson(
        Map<String, dynamic>.from(decodedData),
      );

      debugPrint('Status: ${model.status}');
      debugPrint('Message: ${model.message}');
      debugPrint('Total Products: ${model.result.length}');
      debugPrint('Total Value: ${model.total.totalValue}');

      return model;
    } catch (e, stackTrace) {
      debugPrint('Product Analysis Report Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
