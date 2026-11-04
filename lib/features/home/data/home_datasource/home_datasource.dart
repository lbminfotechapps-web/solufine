import 'package:flutter/material.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/home/data/home_model/homevisit_model.dart';
import 'package:solufine/features/home/data/home_model/inpunchpending_model.dart';
import 'package:solufine/features/home/data/home_model/menu_model.dart';
import 'package:dio/dio.dart';
import 'package:solufine/features/home/data/home_model/monthly_performance_detail_model.dart';
import 'package:solufine/features/home/data/home_model/monthly_performance_model.dart';
import 'dart:convert';

import 'package:solufine/features/reports/data/modles/monthly_performance_model.dart';

class HomeDatasource {
  final DioClient dioClient;

  HomeDatasource(this.dioClient);

  Future<List<MenuModel>> fetchHomeMenu(int userId, String menuType) async {
    final formData = FormData.fromMap({
      'userId': userId,
      'menu_type': menuType,
    });

    print('userid $userId');
    print('menuid $menuType');

    final response = await dioClient.client.post(
      ApiClient.userMenu,
      data: formData,
    );

    print('Home menu status: ${response.statusCode}');
    print('Home menu response: ${response.data}');

    dynamic data = response.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } on FormatException {
        throw const FormatException('Invalid JSON response from menu API');
      }
    }

    if (data is! Map) {
      throw const FormatException('Menu API response is not a JSON object');
    }

    final result = data['result'];
    if (result is! List) {
      throw const FormatException('Menu API result is not a List');
    }

    return result
        .whereType<Map>()
        .map((item) => MenuModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<Map<String, dynamic>> fetchVisitCountGraph(
    int userId,
    String searchFromDate,
    String searchToDate,
  ) async {
    final formData = FormData.fromMap({
      'userId': userId,
      'searchfromDate': searchFromDate,
      'searchtoDate': searchToDate,
    });
    print('userId $userId');
    print('searchfromDate $searchFromDate');
    print('searchtoDate $searchToDate');

    final response = await dioClient.client.post(
      ApiClient.visitCountgraph,
      data: formData,
    );

    print('Home graph status: ${response.statusCode}');
    print('Home graph response: ${response.data}');

    dynamic data = response.data;
    if (data is String) {
      try {
        data = jsonDecode(data);
      } on FormatException {
        throw const FormatException('Invalid JSON response from menu API');
      }
    }

    if (data is! Map) {
      throw const FormatException(
        'Visit count API response is not a JSON object',
      );
    }

    final responseData = Map<String, dynamic>.from(data);
    if (!responseData.containsKey('status') ||
        !responseData.containsKey('message') ||
        !responseData.containsKey('tot_dealer_cnt') ||
        !responseData.containsKey('tot_farmer_cnt')) {
      throw const FormatException(
        'Visit count API response has an invalid format',
      );
    }

    return responseData;
  }

  Future<HomeVisitModel> getHomeVisitCount({required String userId}) async {
    try {
      print('======================================');
      print('GET HOME VISIT COUNT API');
      print('USER ID: $userId');
      print('======================================');

      final formData = FormData.fromMap({'userId': userId});

      final response = await dioClient.client.post(
        ApiClient.getEmployeeVisitCount,
        data: formData,
      );

      print('STATUS CODE: ${response.statusCode}');

      print(
        'RESPONSE TYPE: '
        '${response.data.runtimeType}',
      );

      print(
        'HOME VISIT RESPONSE: '
        '${response.data}',
      );

      dynamic data = response.data;

      // ------------------------------------------------------------
      // API STRING RESPONSE
      // ------------------------------------------------------------

      if (data is String) {
        final raw = data.trim();

        if (raw.isEmpty) {
          throw const FormatException('Empty home visit response');
        }

        data = jsonDecode(raw);
      }

      // ------------------------------------------------------------
      // VALIDATE RESPONSE
      // ------------------------------------------------------------

      if (data is! Map) {
        throw FormatException(
          'Invalid home visit response: '
          '${data.runtimeType}',
        );
      }

      final Map<String, dynamic> jsonData = Map<String, dynamic>.from(data);

      // ------------------------------------------------------------
      // MODEL
      // ------------------------------------------------------------

      final model = HomeVisitModel.fromJson(jsonData);

      print('======================================');

      print(
        'TOTAL DEALER COUNT: '
        '${model.totalDealerCount}',
      );

      print(
        'TOTAL FARMER COUNT: '
        '${model.totalFarmerCount}',
      );

      print(
        'DAY WISE COUNT: '
        '${model.dayWise.length}',
      );

      for (final item in model.dayWise) {
        print(
          '${item.date} -> '
          'Dealer: ${item.dealerCount} | '
          'Farmer: ${item.farmerCount}',
        );
      }

      print('======================================');

      return model;
    } on DioException catch (e) {
      print(
        'HOME VISIT DIO ERROR: '
        '${e.message}',
      );

      print('RESPONSE: ${e.response?.data}');

      throw Exception(e.message ?? 'Home visit network error');
    } catch (e, stackTrace) {
      print('HOME VISIT ERROR: $e');

      print('STACK TRACE: $stackTrace');

      rethrow;
    }
  }

  Future<InpunchPendingResponseModel> getInpunchPending(String userId) async {
    try {
      print('========================================');
      print('GET INPUNCH PENDING API');
      print('user_id: $userId');
      print('========================================');

      final response = await dioClient.client.post(
        ApiClient.getInpunchPending,
        data: FormData.fromMap({'user_id': userId}),
      );

      print('STATUS CODE: ${response.statusCode}');
      print('RAW RESPONSE TYPE: ${response.data.runtimeType}');
      print('RAW RESPONSE: ${response.data}');

      dynamic data = response.data;

      // --------------------------------------------------
      // DECODE STRING RESPONSE
      // --------------------------------------------------
      if (data is String) {
        print('Response is String. Decoding JSON...');

        data = jsonDecode(data.trim());

        print('DECODED DATA: $data');
      }

      // --------------------------------------------------
      // VALIDATE RESPONSE
      // --------------------------------------------------
      if (data is! Map) {
        throw Exception('Invalid response format: ${data.runtimeType}');
      }

      final json = Map<String, dynamic>.from(data);

      print('STATUS: ${json['status']}');
      print('MESSAGE: ${json['message']}');
      print(
        'TOTAL RECURSIVE EMPLOYEE: '
        '${json['total_recursive_employee']}',
      );
      print(
        'PENDING INPUNCH COUNT: '
        '${json['pending_inpunch_count']}',
      );
      print('INPUNCH TIME: ${json['inpunch_time']}');
      print('ADDRESS: ${json['address']}');

      final result = json['result'];

      print('RESULT TYPE: ${result.runtimeType}');
      print(
        'RESULT LENGTH: '
        '${result is List ? result.length : 'Not List'}',
      );
      print('RESULT: $result');

      // --------------------------------------------------
      // HANDLE RESULT
      // --------------------------------------------------
      if (result != null && result is! List) {
        throw Exception('Invalid result format: ${result.runtimeType}');
      }

      // --------------------------------------------------
      // EMPTY RESULT
      // --------------------------------------------------
      if (result is List && result.isEmpty) {
        print('No pending punch records');
      }

      // --------------------------------------------------
      // CREATE FULL RESPONSE MODEL
      // --------------------------------------------------
      final model = InpunchPendingResponseModel.fromJson(json);

      print('========================================');
      print('INPUNCH PENDING RESPONSE');
      print('STATUS: ${model.status}');
      print('MESSAGE: ${model.message}');
      print(
        'TOTAL RECURSIVE EMPLOYEE: '
        '${model.totalRecursiveEmployee}',
      );
      print(
        'PENDING INPUNCH COUNT: '
        '${model.pendingInpunchCount}',
      );
      print('INPUNCH TIME: ${model.inpunchTime}');
      print('ADDRESS: ${model.address}');
      print('RESULT COUNT: ${model.result.length}');
      print('========================================');

      for (final item in model.result) {
        print('----------------------------------------');
        print('NAME: ${item.fldAdmName}');
        print('REPORTING PERSON: ${item.fldReportingPerson}');
        print('MOBILE: ${item.fldMobileNo}');
      }

      return model;
    } on DioException catch (e) {
      print('DIO ERROR: ${e.message}');
      print('DIO RESPONSE: ${e.response?.data}');
      print('DIO STATUS: ${e.response?.statusCode}');

      throw Exception(e.message ?? 'Network error');
    } catch (e, stackTrace) {
      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');

      rethrow;
    }
  }

  Future<MonthlyPerformanceModelNew> getMonthlyPerformanceList() async {
    try {
      final response = await dioClient.client.post(
        ApiClient.getMonthlyPerformanceList,
      );

      debugPrint('========== MONTHLY PERFORMANCE API ==========');
      debugPrint('Response: ${response.data}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid monthly performance response');
      }

      return MonthlyPerformanceModelNew.fromJson(
        Map<String, dynamic>.from(decodedData),
      );
    } catch (e, stackTrace) {
      debugPrint('Get Monthly Performance List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<MonthlyPerformanceDetailModel>
  getMonthlyPerformanceDetailList() async {
    try {
      final response = await dioClient.client.post(
        ApiClient.getMonthlyPerformanceListwithImage,
      );

      debugPrint('========== MONTHLY PERFORMANCE DETAIL API ==========');
      debugPrint('Response: ${response.data}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid monthly performance response');
      }

      return MonthlyPerformanceDetailModel.fromJson(
        Map<String, dynamic>.from(decodedData),
      );
    } catch (e, stackTrace) {
      debugPrint('Get Monthly Performance List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
