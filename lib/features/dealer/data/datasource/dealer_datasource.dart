import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/dealer/data/models/DealerListModel.dart';
import 'package:dio/dio.dart';
import 'package:solufine/features/dealer/data/models/dealer_products.dart';
import 'package:solufine/features/dealer/data/models/tally_company_list_model.dart';

class DealerListDataSource {
  final DioClient dioClient;

  DealerListDataSource({required this.dioClient});

  Future<List<DealerListModel>> fetchDealerList(
    String userId,
    String latitude,
    String longitude,
    String searchText,
    int startLimit,
    String type,
  ) async {
    try {
      print('');
      print('============================================');
      print('        DEALER API REQUEST START');
      print('============================================');

      print('URL: ${ApiClient.getNearByOutlets}');
      print('METHOD: POST');

      print('USER ID      : $userId');
      print('LATITUDE     : $latitude');
      print('LONGITUDE    : $longitude');
      print('SEARCH TEXT  : "$searchText"');
      print('LIMIT  : "$startLimit"');
      print('TYPE         : "$type"');

      // --------------------------------------------------
      // REQUEST BODY
      // --------------------------------------------------

      final requestData = {
        'user_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'searchText': searchText,
        'startLimit': startLimit,
        'type': type,
      };

      print('');
      print('REQUEST DATA:');
      print(jsonEncode(requestData));

      print('');
      print('============================================');
      print('        CALLING DEALER API');
      print('============================================');

      // --------------------------------------------------
      // API CALL
      // --------------------------------------------------

      final response = await dioClient.client.post(
        ApiClient.getNearByOutlets,
        data: requestData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );

      // --------------------------------------------------
      // RESPONSE DEBUG
      // --------------------------------------------------

      print('');
      print('============================================');
      print('        DEALER API RESPONSE');
      print('============================================');

      print('STATUS CODE : ${response.statusCode}');
      print('STATUS MSG  : ${response.statusMessage}');
      print('DATA TYPE   : ${response.data.runtimeType}');
      print('DATA        : ${response.data}');

      print('============================================');

      // --------------------------------------------------
      // RESPONSE PARSING
      // --------------------------------------------------

      dynamic responseData = response.data;

      // Sometimes PHP APIs return JSON as String
      if (responseData is String) {
        print('Response is String. Decoding JSON...');

        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          print('JSON DECODE ERROR: $e');

          throw const FormatException('Invalid JSON response from dealer API');
        }
      }

      // Response must be Map
      if (responseData is! Map<String, dynamic>) {
        print('INVALID RESPONSE TYPE: ${responseData.runtimeType}');

        throw FormatException(
          'Dealer API response must be a JSON object. '
          'Received: ${responseData.runtimeType}',
        );
      }

      final Map<String, dynamic> data = responseData;

      // --------------------------------------------------
      // API STATUS
      // --------------------------------------------------

      final apiStatus = data['status'];
      final message = data['message'];

      print('');
      print('API STATUS  : $apiStatus');
      print('API MESSAGE : $message');

      // --------------------------------------------------
      // API FAILURE
      // --------------------------------------------------

      if (apiStatus != true) {
        if (message?.toString().toLowerCase().contains('no dealers found') ==
            true) {
          print('API REPORTS NO DEALERS; RETURNING AN EMPTY LIST');
          return [];
        }

        throw Exception(
          message?.toString().isNotEmpty == true
              ? message.toString()
              : 'Failed to fetch dealer list',
        );
      }

      // --------------------------------------------------
      // RESULT
      // --------------------------------------------------

      final result = data['result'];

      print('');
      print('============================================');
      print('        DEALER RESULT');
      print('============================================');

      print('RESULT TYPE : ${result.runtimeType}');
      print('RESULT      : $result');

      if (result == null) {
        print('RESULT IS NULL');

        return [];
      }

      if (result is! List) {
        throw FormatException(
          'Dealer API result must be a List. '
          'Received: ${result.runtimeType}',
        );
      }

      print('TOTAL RECORDS: ${result.length}');

      // --------------------------------------------------
      // NO DEALERS
      // --------------------------------------------------

      if (result.isEmpty) {
        print('');
        print('NO DEALERS FOUND');
        print('============================================');

        return [];
      }

      // --------------------------------------------------
      // PARSE DEALERS
      // --------------------------------------------------

      final List<DealerListModel> dealers = [];

      for (int i = 0; i < result.length; i++) {
        try {
          final item = result[i];

          print('');
          print('--------------------------------------------');
          print('PARSING DEALER ${i + 1}');
          print('--------------------------------------------');

          print('RAW DATA: $item');

          if (item is Map<String, dynamic>) {
            final dealer = DealerListModel.fromJson(item);

            dealers.add(dealer);

            print('DEALER ID   : ${dealer.outletId}');
            print('DEALER NAME : ${dealer.outletName}');
            print('MOBILE      : ${dealer.outletPersonMobile}');
            print('ADDRESS     : ${dealer.outletAddress}');
            print('DISTANCE    : ${dealer.outletDistance}');
          } else if (item is Map) {
            // Handles Map<dynamic, dynamic>
            final Map<String, dynamic> dealerJson = Map<String, dynamic>.from(
              item,
            );

            final dealer = DealerListModel.fromJson(dealerJson);

            dealers.add(dealer);

            print('DEALER ID   : ${dealer.outletId}');
            print('DEALER NAME : ${dealer.outletName}');
          } else {
            print('SKIPPED INVALID DEALER TYPE: ${item.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('');
          print('DEALER PARSING ERROR');
          print('INDEX: $i');
          print('ERROR: $e');
          print('STACK: $stackTrace');

          // Continue parsing other dealers
        }
      }

      // --------------------------------------------------
      // COMPLETE
      // --------------------------------------------------

      print('');
      print('============================================');
      print('      DEALER DATASOURCE COMPLETE');
      print('============================================');

      print('TOTAL API RECORDS    : ${result.length}');
      print('TOTAL PARSED DEALERS : ${dealers.length}');

      print('============================================');

      return dealers;
    }
    // ==================================================
    // DIO ERROR
    // ==================================================
    on DioException catch (e, stackTrace) {
      print('');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('          DEALER API DIO ERROR');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

      print('');
      print('REQUEST URL:');
      print(e.requestOptions.uri);

      print('');
      print('REQUEST METHOD:');
      print(e.requestOptions.method);

      print('');
      print('REQUEST HEADERS:');
      print(e.requestOptions.headers);

      print('');
      print('REQUEST DATA:');
      print(e.requestOptions.data);

      print('');
      print('ERROR TYPE:');
      print(e.type);

      print('');
      print('STATUS CODE:');
      print(e.response?.statusCode);

      print('');
      print('STATUS MESSAGE:');
      print(e.response?.statusMessage);

      print('');
      print('SERVER RESPONSE TYPE:');
      print(e.response?.data.runtimeType);

      print('');
      print('SERVER RESPONSE DATA:');
      print(e.response?.data);

      print('');
      print('DIO MESSAGE:');
      print(e.message);

      print('');
      print('STACK TRACE:');
      print(stackTrace);

      print('');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

      // --------------------------------------------------
      // Get useful backend message
      // --------------------------------------------------

      String errorMessage = 'Failed to fetch dealer list';

      final serverData = e.response?.data;

      if (serverData is Map) {
        if (serverData['message'] != null) {
          errorMessage = serverData['message'].toString();
        }

        if (serverData['error'] != null) {
          errorMessage = serverData['error'].toString();
        }

        if (serverData['msg'] != null) {
          errorMessage = serverData['msg'].toString();
        }
      } else if (serverData is String && serverData.trim().isNotEmpty) {
        errorMessage = serverData;
      }

      throw Exception(errorMessage);
    }
    // ==================================================
    // FORMAT ERROR
    // ==================================================
    on FormatException catch (e, stackTrace) {
      print('');
      print('============================================');
      print('        DEALER FORMAT ERROR');
      print('============================================');

      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');

      print('============================================');

      throw Exception('Invalid dealer API response: ${e.message}');
    }
    // ==================================================
    // OTHER ERROR
    // ==================================================
    catch (e, stackTrace) {
      print('');
      print('============================================');
      print('        DEALER DATASOURCE ERROR');
      print('============================================');

      print('ERROR TYPE: ${e.runtimeType}');
      print('ERROR     : $e');
      print('STACK     : $stackTrace');

      print('============================================');

      rethrow;
    }
  }

  Future<Map<String, dynamic>> addDealerLocation(
    Map<String, dynamic> jsonData,
  ) async {
    try {
      // ============================================================
      // PRINT REQUEST
      // ============================================================

      debugPrint('==========================================');
      debugPrint('ADD DEALER LOCATION REQUEST');
      debugPrint('==========================================');

      jsonData.forEach((key, value) {
        debugPrint('$key : $value');
      });

      debugPrint('==========================================');

      // ============================================================
      // DIRECTLY CONVERT jsonData TO FORM DATA
      // ============================================================

      final FormData formData = FormData.fromMap(jsonData);

      // ============================================================
      // API CALL
      // ============================================================

      final response = await dioClient.client.post(
        ApiClient.addDealerLocation,
        data: formData,
      );

      // ============================================================
      // RESPONSE
      // ============================================================

      debugPrint('==========================================');
      debugPrint('ADD DEALER LOCATION RESPONSE');
      debugPrint('==========================================');

      debugPrint('STATUS CODE: ${response.statusCode}');
      debugPrint('RESPONSE: ${response.data}');

      debugPrint('==========================================');

      dynamic data = response.data;

      // ============================================================
      // IF RESPONSE COMES AS STRING
      // ============================================================

      if (data is String) {
        try {
          data = jsonDecode(data);
        } on FormatException {
          throw const FormatException(
            'Invalid JSON response from Add Dealer Location API',
          );
        }
      }

      // ============================================================
      // CHECK RESPONSE TYPE
      // ============================================================

      if (data is! Map) {
        throw const FormatException(
          'Add Dealer Location API response is not a JSON object',
        );
      }

      // ============================================================
      // RETURN RESPONSE
      // ============================================================

      final Map<String, dynamic> result = Map<String, dynamic>.from(data);

      debugPrint('==========================================');
      debugPrint('PARSED RESPONSE');
      debugPrint('status  : ${result['status']}');
      debugPrint('message : ${result['message']}');
      debugPrint('result  : ${result['result']}');
      debugPrint('==========================================');

      return result;
    } on DioException catch (e) {
      debugPrint('==========================================');
      debugPrint('ADD DEALER LOCATION DIO ERROR');
      debugPrint('==========================================');

      debugPrint('MESSAGE: ${e.message}');
      debugPrint('STATUS CODE: ${e.response?.statusCode}');
      debugPrint('RESPONSE: ${e.response?.data}');

      debugPrint('==========================================');

      rethrow;
    } catch (e, stackTrace) {
      debugPrint('==========================================');
      debugPrint('ADD DEALER LOCATION ERROR');
      debugPrint('==========================================');

      debugPrint('ERROR: $e');
      debugPrint('STACK TRACE: $stackTrace');

      debugPrint('==========================================');

      rethrow;
    }
  }

  Future<List<DealerStockProductModel>> fetchDealerProductList(
    String dealerId,
  ) async {
    try {
      print('');
      print('============================================');
      print('        PRODUCT API REQUEST START');
      print('============================================');

      print('URL: ${ApiClient.getProductDetail}');
      print('METHOD: POST');

      print('DEALER ID      : $dealerId');

      // --------------------------------------------------
      // REQUEST BODY
      // --------------------------------------------------

      final requestData = {'dealerId': dealerId};

      print('');
      print('REQUEST DATA:');
      print(jsonEncode(requestData));

      print('');
      print('============================================');
      print('        CALLING API');
      print('============================================');

      // --------------------------------------------------
      // API CALL
      // --------------------------------------------------

      final response = await dioClient.client.post(
        ApiClient.getProductDetail,
        data: requestData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.json,
        ),
      );

      // --------------------------------------------------
      // RESPONSE DEBUG
      // --------------------------------------------------

      print('');
      print('============================================');
      print('        DEALER API RESPONSE');
      print('============================================');

      print('STATUS CODE : ${response.statusCode}');
      print('STATUS MSG  : ${response.statusMessage}');
      print('DATA TYPE   : ${response.data.runtimeType}');
      print('DATA        : ${response.data}');

      print('============================================');

      // --------------------------------------------------
      // RESPONSE PARSING
      // --------------------------------------------------

      dynamic responseData = response.data;

      // Sometimes PHP APIs return JSON as String
      if (responseData is String) {
        print('Response is String. Decoding JSON...');

        try {
          responseData = jsonDecode(responseData);
        } catch (e) {
          print('JSON DECODE ERROR: $e');

          throw const FormatException('Invalid JSON response from dealer API');
        }
      }

      // Response must be Map
      if (responseData is! Map<String, dynamic>) {
        print('INVALID RESPONSE TYPE: ${responseData.runtimeType}');

        throw FormatException(
          'Dealer API response must be a JSON object. '
          'Received: ${responseData.runtimeType}',
        );
      }

      final Map<String, dynamic> data = responseData;

      // --------------------------------------------------
      // API STATUS
      // --------------------------------------------------

      final apiStatus = data['status'];
      final message = data['message'];

      print('');
      print('API STATUS  : $apiStatus');
      print('API MESSAGE : $message');

      // --------------------------------------------------
      // API FAILURE
      // --------------------------------------------------

      if (apiStatus != true) {
        throw Exception(
          message?.toString().isNotEmpty == true
              ? message.toString()
              : 'Failed to fetch product list',
        );
      }

      // --------------------------------------------------
      // RESULT
      // --------------------------------------------------

      final result = data['result'];

      print('');
      print('============================================');
      print('        DEALER RESULT');
      print('============================================');

      print('RESULT TYPE : ${result.runtimeType}');
      print('RESULT      : $result');

      if (result == null) {
        print('RESULT IS NULL');

        return [];
      }

      if (result is! List) {
        throw FormatException(
          'Dealer API result must be a List. '
          'Received: ${result.runtimeType}',
        );
      }

      print('TOTAL RECORDS: ${result.length}');

      // --------------------------------------------------
      // NO DEALERS
      // --------------------------------------------------

      if (result.isEmpty) {
        print('');
        print('NO PRODUCT FOUND');
        print('============================================');

        return [];
      }

      // --------------------------------------------------
      // PARSE DEALERS
      // --------------------------------------------------

      final List<DealerStockProductModel> products = [];

      for (int i = 0; i < result.length; i++) {
        try {
          final item = result[i];

          print('');
          print('--------------------------------------------');
          print('PARSING PRODUCT ${i + 1}');
          print('--------------------------------------------');

          print('RAW DATA: $item');

          if (item is Map<String, dynamic>) {
            final product = DealerStockProductModel.fromJson(item);

            products.add(product);

            print('PRODUCT ID   : ${product.productId}');
            print('PRODUCT NAME : ${product.productName}');
            print('PRODUCT UNITPERCASE      : ${product.unitsPerCase}');
          } else if (item is Map) {
            // Handles Map<dynamic, dynamic>
            final Map<String, dynamic> dealerJson = Map<String, dynamic>.from(
              item,
            );

            final product = DealerStockProductModel.fromJson(dealerJson);

            products.add(product);

            print('PRODUCT ID   : ${product.productId}');
            print('PRODUCT NAME : ${product.productName}');
          } else {
            print('SKIPPED INVALID PRODUCT TYPE: ${item.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('');
          print('PRODUCT PARSING ERROR');
          print('INDEX: $i');
          print('ERROR: $e');
          print('STACK: $stackTrace');

          // Continue parsing other dealers
        }
      }

      // --------------------------------------------------
      // COMPLETE
      // --------------------------------------------------

      print('');
      print('============================================');
      print('      PRODUCT DATASOURCE COMPLETE');
      print('============================================');

      print('TOTAL API RECORDS    : ${result.length}');
      print('TOTAL PARSED DEALERS : ${products.length}');

      print('============================================');

      return products;
    }
    // ==================================================
    // DIO ERROR
    // ==================================================
    on DioException catch (e, stackTrace) {
      print('');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      print('          DEALER API DIO ERROR');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

      print('');
      print('REQUEST URL:');
      print(e.requestOptions.uri);

      print('');
      print('REQUEST METHOD:');
      print(e.requestOptions.method);

      print('');
      print('REQUEST HEADERS:');
      print(e.requestOptions.headers);

      print('');
      print('REQUEST DATA:');
      print(e.requestOptions.data);

      print('');
      print('ERROR TYPE:');
      print(e.type);

      print('');
      print('STATUS CODE:');
      print(e.response?.statusCode);

      print('');
      print('STATUS MESSAGE:');
      print(e.response?.statusMessage);

      print('');
      print('SERVER RESPONSE TYPE:');
      print(e.response?.data.runtimeType);

      print('');
      print('SERVER RESPONSE DATA:');
      print(e.response?.data);

      print('');
      print('DIO MESSAGE:');
      print(e.message);

      print('');
      print('STACK TRACE:');
      print(stackTrace);

      print('');
      print('!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');

      // --------------------------------------------------
      // Get useful backend message
      // --------------------------------------------------

      String errorMessage = 'Failed to fetch dealer list';

      final serverData = e.response?.data;

      if (serverData is Map) {
        if (serverData['message'] != null) {
          errorMessage = serverData['message'].toString();
        }

        if (serverData['error'] != null) {
          errorMessage = serverData['error'].toString();
        }

        if (serverData['msg'] != null) {
          errorMessage = serverData['msg'].toString();
        }
      } else if (serverData is String && serverData.trim().isNotEmpty) {
        errorMessage = serverData;
      }

      throw Exception(errorMessage);
    }
    // ==================================================
    // FORMAT ERROR
    // ==================================================
    on FormatException catch (e, stackTrace) {
      print('');
      print('============================================');
      print('        DEALER FORMAT ERROR');
      print('============================================');

      print('ERROR: $e');
      print('STACK TRACE: $stackTrace');

      print('============================================');

      throw Exception('Invalid dealer API response: ${e.message}');
    }
    // ==================================================
    // OTHER ERROR
    // ==================================================
    catch (e, stackTrace) {
      print('');
      print('============================================');
      print('        DEALER DATASOURCE ERROR');
      print('============================================');

      print('ERROR TYPE: ${e.runtimeType}');
      print('ERROR     : $e');
      print('STACK     : $stackTrace');

      print('============================================');

      rethrow;
    }
  }

  Future<Map<String, dynamic>> addDealerStock(
    Map<String, dynamic> jsonData,
    File? dealerImage,
    String digitalSignature,
  ) async {
    try {
      final Map<String, dynamic> requestData = Map<String, dynamic>.from(
        jsonData,
      );

      // ============================================================
      // NOW SEND SERVER SIGNATURE FILE NAME AS NORMAL STRING
      // ============================================================

      requestData['digitalSignature'] = digitalSignature;

      final FormData formData = FormData.fromMap(requestData);

      // ============================================================
      // DEALER IMAGE MULTIPART
      // ============================================================

      if (dealerImage != null && await dealerImage.exists()) {
        formData.files.add(
          MapEntry(
            'dealerImage',
            await MultipartFile.fromFile(
              dealerImage.path,
              filename: dealerImage.path.split(Platform.pathSeparator).last,
            ),
          ),
        );
      }

      // ============================================================
      // DEBUG
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('ADD DEALER STOCK FINAL REQUEST');
      debugPrint('========================================');

      for (final field in formData.fields) {
        debugPrint('${field.key} : ${field.value}');
      }

      for (final file in formData.files) {
        debugPrint('${file.key} : ${file.value.filename}');
      }

      debugPrint('========================================');

      // ============================================================
      // API CALL
      // ============================================================

      final response = await dioClient.client.post(
        ApiClient.addStock,
        data: formData,
      );

      dynamic data = response.data;

      if (data is String) {
        data = jsonDecode(data);
      }

      if (data is! Map) {
        throw const FormatException('Add Dealer Stock response is invalid');
      }

      return Map<String, dynamic>.from(data);
    } catch (e, stackTrace) {
      debugPrint('ADD DEALER STOCK ERROR: $e');

      debugPrint('$stackTrace');

      rethrow;
    }
  }

  dynamic _decodeResponse(dynamic responseData) {
    if (responseData == null) {
      return null;
    }

    if (responseData is Map || responseData is List) {
      return responseData;
    }

    if (responseData is String) {
      final String value = responseData.trim();

      if (value.isEmpty) {
        return null;
      }

      try {
        return jsonDecode(value);
      } catch (_) {
        return value;
      }
    }

    return responseData;
  }

  Future<String> uploadSignature({required String signaturePath}) async {
    try {
      print('');
      print('========================================');
      print('UPLOAD SIGNATURE');
      print('========================================');

      // ============================================================
      // VALIDATE PATH
      // ============================================================

      final String cleanPath = signaturePath.trim();

      if (cleanPath.isEmpty) {
        throw Exception('Signature path is empty');
      }

      // ============================================================
      // CHECK FILE
      // ============================================================

      final File signatureFile = File(cleanPath);

      if (!await signatureFile.exists()) {
        throw Exception('Signature file does not exist: $cleanPath');
      }

      final int signatureSize = await signatureFile.length();

      if (signatureSize <= 0) {
        throw Exception('Signature file is empty');
      }

      // ============================================================
      // CREATE SERVER FILENAME
      // ============================================================

      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();

      final String fileName = 'Signature_$timestamp.png';

      // ============================================================
      // CREATE MULTIPART FILE
      // ============================================================

      final MultipartFile multipartFile = await MultipartFile.fromFile(
        signatureFile.path,
        filename: fileName,
      );

      // ============================================================
      // FORM DATA
      // ============================================================

      final FormData formData = FormData();

      // Android:
      // addFormDataPart("file", ...)
      //
      // Therefore field name MUST be "file"

      formData.files.add(MapEntry('file', multipartFile));

      // ============================================================
      // DEBUG
      // ============================================================

      print('API: upload_sign');
      print('Multipart field: file');
      print('Local path: ${signatureFile.path}');
      print('Filename: $fileName');
      print('File size: $signatureSize bytes');

      // ============================================================
      // API CALL
      // ============================================================

      final response = await dioClient.client.post(
        ApiClient.upload_sign,
        data: formData,
        options: Options(responseType: ResponseType.plain),
      );

      // ============================================================
      // RESPONSE
      // ============================================================

      print('');
      print('========================================');
      print('UPLOAD SIGNATURE RESPONSE');
      print('========================================');

      print(response.data);

      final dynamic decoded = _decodeResponse(response.data);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid upload_sign response');
      }

      // ============================================================
      // CHECK STATUS
      // ============================================================

      final String status = '${decoded['status'] ?? ''}'.toLowerCase();

      print('Upload status: $status');

      if (status != 'success') {
        throw Exception(
          decoded['message']?.toString() ?? 'Signature upload failed',
        );
      }

      // ============================================================
      // TRY TO GET FILENAME FROM SERVER RESPONSE
      // ============================================================

      String uploadedFileName = '';

      uploadedFileName = decoded['fileName']?.toString() ?? '';

      if (uploadedFileName.isEmpty) {
        uploadedFileName = decoded['filename']?.toString() ?? '';
      }

      if (uploadedFileName.isEmpty) {
        uploadedFileName = decoded['file']?.toString() ?? '';
      }

      if (uploadedFileName.isEmpty) {
        uploadedFileName = decoded['signature']?.toString() ?? '';
      }

      // ============================================================
      // IMPORTANT
      //
      // Your API currently returns:
      //
      // {"status":"success"}
      //
      // Therefore there is no filename in response.
      //
      // We already know the filename that was uploaded:
      //
      // Signature_xxxxxxxxx.png
      //
      // So use that filename.
      // ============================================================

      if (uploadedFileName.isEmpty) {
        uploadedFileName = fileName;
      }

      // ============================================================
      // FINAL VALIDATION
      // ============================================================

      if (uploadedFileName.trim().isEmpty) {
        throw Exception(
          'Signature uploaded successfully, '
          'but filename could not be determined',
        );
      }

      print('');
      print('========================================');
      print('SIGNATURE UPLOAD SUCCESS');
      print('========================================');

      print('Server filename: $uploadedFileName');

      return uploadedFileName;
    } on DioException catch (e) {
      print('');
      print('========================================');
      print('UPLOAD SIGNATURE DIO ERROR');
      print('========================================');

      print('Message: ${e.message}');

      print('Status: ${e.response?.statusCode}');

      print('Response: ${e.response?.data}');

      throw Exception(
        e.response?.data?.toString() ?? e.message ?? 'Signature upload failed',
      );
    } catch (e) {
      print('');
      print('========================================');
      print('UPLOAD SIGNATURE ERROR');
      print('========================================');

      print(e);

      rethrow;
    }
  }

  Future<TallyCompanyListModel> getTallyCompanyList() async {
    try {
      final response = await dioClient.client.post(ApiClient.getTallyCompany);

      debugPrint('========== TALLY COMPANY LIST API ==========');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.data}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid Tally Company List API response');
      }

      final model = TallyCompanyListModel.fromJson(
        Map<String, dynamic>.from(decodedData),
      );

      if (!model.status) {
        throw Exception(
          model.message.isNotEmpty
              ? model.message
              : 'Failed to fetch Tally Company List',
        );
      }

      return model;
    } on DioException catch (e) {
      debugPrint('========== TALLY COMPANY DIO ERROR ==========');
      debugPrint('URL: ${e.requestOptions.uri}');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Get Tally Company List Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getTallyPdf(
    String type,
    String dealerId,
    String fromDate,
    String toDate,
    String tallyCompanyId,
  ) async {
    try {
      final requestData = {
        'apiType': type,
        'dealerId': dealerId,
        'fromDate': fromDate,
        'toDate': toDate,
        'tallyCompanyId': tallyCompanyId,
      };

      debugPrint('========== TALLY PDF REQUEST ==========');
      debugPrint('Parameters: $requestData');

      final response = await dioClient.client.post(
        ApiClient.getDealerTallyLedgerOutstandingPdf,
        data: FormData.fromMap(requestData),
      );

      debugPrint('========== TALLY PDF RESPONSE ==========');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response: ${response.data}');

      final dynamic decodedData = response.data is String
          ? jsonDecode(response.data as String)
          : response.data;

      if (decodedData is! Map) {
        throw const FormatException('Invalid Tally PDF API response');
      }

      final result = Map<String, dynamic>.from(decodedData);

      final bool isSuccess =
          result['status'] == true ||
          result['status'] == 1 ||
          result['status']?.toString().toLowerCase() == 'true';

      if (!isSuccess) {
        throw Exception(
          result['message']?.toString() ?? 'Failed to generate Tally PDF',
        );
      }

      final pdfUrl = result['url']?.toString().trim() ?? '';
      final uri = Uri.tryParse(pdfUrl);

      if (uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        throw const FormatException(
          'Invalid or missing PDF URL in API response',
        );
      }

      return result;
    } on DioException catch (e) {
      debugPrint('========== TALLY PDF DIO ERROR ==========');
      debugPrint('URL: ${e.requestOptions.uri}');
      debugPrint('Status Code: ${e.response?.statusCode}');
      debugPrint('Response: ${e.response?.data}');
      debugPrint('Message: ${e.message}');
      rethrow;
    } catch (e, stackTrace) {
      debugPrint('Get Tally PDF Error: $e');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
