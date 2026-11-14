import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:solufine/core/utility/image_compression.dart';
import 'package:solufine/features/dealer/domain/repository/dealer_repo.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_event.dart';
import 'package:solufine/features/dealer/presentation/bloc/dealerlist_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DealerListBloc extends Bloc<DealerEevent, DealerListState> {
  final DealerListRepository repository;

  DealerListBloc({required this.repository}) : super(const DealerListState()) {
    on<DealerListEvent>(_onLoadDealers);
    on<AddDealerLocation>(_onAddDealerLocation);
    on<DealerProductListEvent>(_onGetDealerProducts);
    on<AddDealerStock>(_onAddDealerStock);
    on<GetTallyCompanyListEvent>(_onGetTallyCompanys);
    on<GetTallyPdfEvent>(_onGetTallyPdf);
  }

  Future<void> _onLoadDealers(
    DealerListEvent event,
    Emitter<DealerListState> emit,
  ) async {
    print('');
    print('========================================');
    print('DEALER BLOC EVENT RECEIVED');
    print('========================================');

    print('User ID     : ${event.user_id}');
    print('Latitude    : ${event.latitude}');
    print('Longitude   : ${event.longitude}');
    print('Search Key  : ${event.searchText}');
    print('Type        : Dealer');

    emit(state.copyWith(status: DealerListStatus.loading));

    print('DEALER BLOC STATUS: LOADING');

    try {
      final dealers = await repository.getDealers(
        event.user_id,
        event.latitude,
        event.longitude,
        event.searchText,
        event.type,
        event.startLimit,
      );

      print('');
      print('========================================');
      print('DEALER BLOC RESPONSE');
      print('========================================');

      print('Dealers received: ${dealers.length}');

      for (final dealer in dealers) {
        print(
          'ID: ${dealer.outletId} | '
          'Name: ${dealer.outletName} | '
          'Mobile: ${dealer.outletPersonMobile} | '
          'Distance: ${dealer.outletDistance}',
        );
      }

      emit(
        state.copyWith(status: DealerListStatus.success, dealerList: dealers),
      );

      print('DEALER BLOC STATUS: SUCCESS');
    } catch (e, stackTrace) {
      print('');
      print('========================================');
      print('DEALER BLOC ERROR');
      print('========================================');

      print('ERROR: $e');
      print('STACK: $stackTrace');

      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          errorMessage: e.toString(),
        ),
      );

      print('DEALER BLOC STATUS: FAILURE');
    }
  }

  FutureOr<void> _onAddDealerLocation(
    AddDealerLocation event,
    Emitter<DealerListState> emit,
  ) async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('ADD DEALER LOCATION EVENT RECEIVED');
    debugPrint('========================================');

    // ============================================================
    // 1. PRINT EVENT DATA
    // ============================================================

    debugPrint('Dealer ID              : ${event.dealerId}');
    debugPrint('User ID                : ${event.userId}');
    debugPrint('Location History       : ${event.locationHistoryString}');

    debugPrint('Latitude               : ${event.latitude}');
    debugPrint('Longitude              : ${event.longitude}');

    debugPrint('Network Latitude       : ${event.networkLatitude}');
    debugPrint('Network Longitude      : ${event.networkLongitude}');

    debugPrint('GPS Latitude           : ${event.gpsLatitude}');
    debugPrint('GPS Longitude          : ${event.gpsLongitude}');

    debugPrint('Geo Address            : ${event.geoAddress}');

    debugPrint('Mobile Info            : ${event.mobileInfo}');
    debugPrint('Mobile IMEI            : ${event.mobileImei}');

    debugPrint('Network Info           : ${event.networkInfo}');
    debugPrint('Battery Info           : ${event.batteryInfo}');

    debugPrint('========================================');

    // ============================================================
    // 2. LOADING
    // ============================================================

    emit(
      state.copyWith(
        status: DealerListStatus.addDealerloading,
        errorMessage: null,
      ),
    );

    debugPrint('ADD DEALER LOCATION STATUS: LOADING');

    try {
      final Map<String, dynamic> jsonData = <String, dynamic>{
        'dealerId': event.dealerId,
        'userId': event.userId,

        'locationHistoryString': event.locationHistoryString,

        // Current Location
        'latitude': event.latitude,
        'longitude': event.longitude,

        // Network Location
        'networkLatitude': event.networkLatitude,
        'networkLongitude': event.networkLongitude,

        // GPS Location
        'gpsLatitude': event.gpsLatitude,
        'gpsLongitude': event.gpsLongitude,

        // Address
        'geoAddress': event.geoAddress,

        // Mobile
        'mobile_info': event.mobileInfo,
        'mobile_imei': event.mobileImei,

        // Network / Battery
        'strNetworkInfo': event.networkInfo,
        'strBatteryInfo': event.batteryInfo,
      };

      // ============================================================
      // 4. PRINT FINAL REQUEST
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('ADD DEALER LOCATION REQUEST');
      debugPrint('========================================');

      jsonData.forEach((key, value) {
        debugPrint('$key : $value');
      });

      debugPrint('========================================');

      // ============================================================
      // 5. CALL REPOSITORY
      // ============================================================

      final Map<String, dynamic> response = await repository.addDealerLocation(
        jsonData,
      );

      // ============================================================
      // 6. PRINT RESPONSE
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('ADD DEALER LOCATION RESPONSE');
      debugPrint('========================================');

      debugPrint('FULL RESPONSE : $response');
      debugPrint('STATUS        : ${response['status']}');
      debugPrint('MESSAGE       : ${response['message']}');
      debugPrint('RESULT        : ${response['result']}');

      debugPrint('========================================');

      // ============================================================
      // 7. READ RESPONSE
      // ============================================================

      final dynamic rawStatus = response['status'];

      // Handles:
      // true
      // "true"
      // 1
      // "1"
      final bool apiStatus =
          rawStatus == true ||
          rawStatus?.toString().toLowerCase() == 'true' ||
          rawStatus?.toString() == '1';

      final String message = response['message']?.toString().trim() ?? '';

      final String result = response['result']?.toString().trim() ?? '';

      debugPrint('');
      debugPrint('========================================');
      debugPrint('PARSED DEALER LOCATION RESPONSE');
      debugPrint('========================================');

      debugPrint('API STATUS : $apiStatus');
      debugPrint('MESSAGE    : "$message"');
      debugPrint('RESULT     : "$result"');

      debugPrint('========================================');

      // ============================================================
      // 8. SUCCESS
      // ============================================================

      if (apiStatus) {
        debugPrint('');
        debugPrint('========================================');
        debugPrint('ADD DEALER LOCATION SUCCESS');
        debugPrint('========================================');

        debugPrint('Dealer ID : ${event.dealerId}');
        debugPrint('Message   : $message');
        debugPrint('Result    : $result');

        debugPrint('========================================');

        emit(
          state.copyWith(
            status: DealerListStatus.addDealerLocationSuccess,
            errorMessage: null,
          ),
        );

        return;
      }

      // ============================================================
      // 9. API FAILURE
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('ADD DEALER LOCATION FAILED');
      debugPrint('========================================');

      debugPrint('Dealer ID : ${event.dealerId}');
      debugPrint('Status    : $rawStatus');
      debugPrint('Message   : $message');
      debugPrint('Result    : $result');

      debugPrint('========================================');

      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          errorMessage: message.isNotEmpty
              ? message
              : 'Failed to update dealer location',
        ),
      );
    } catch (e, stackTrace) {
      // ============================================================
      // 10. EXCEPTION
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('ADD DEALER LOCATION ERROR');
      debugPrint('========================================');

      debugPrint('ERROR: $e');
      debugPrint('STACK: $stackTrace');

      debugPrint('========================================');

      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          errorMessage: e.toString(),
        ),
      );

      debugPrint('ADD DEALER LOCATION STATUS: FAILURE');
    }
  }

  FutureOr<void> _onGetDealerProducts(
    DealerProductListEvent event,
    Emitter<DealerListState> emit,
  ) async {
    print('');
    print('========================================');
    print('DEALER BLOC EVENT RECEIVED');
    print('========================================');

    print('User ID     : ${event.dealerId}');

    emit(state.copyWith(status: DealerListStatus.loading));

    print('DEALER BLOC STATUS: LOADING');

    try {
      final products = await repository.getDealerProduct(event.dealerId);

      print('');
      print('========================================');
      print('DEALER BLOC RESPONSE');
      print('========================================');

      print('Dealers received: ${products.length}');

      for (final product in products) {
        print(
          'ID: ${product.productId} | '
          'Name: ${product.productName} | ',
        );
      }

      emit(
        state.copyWith(status: DealerListStatus.success, productList: products),
      );

      print('DEALER BLOC STATUS: SUCCESS');
    } catch (e, stackTrace) {
      print('');
      print('========================================');
      print('DEALER BLOC ERROR');
      print('========================================');

      print('ERROR: $e');
      print('STACK: $stackTrace');

      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          errorMessage: e.toString(),
        ),
      );

      print('DEALER BLOC STATUS: FAILURE');
    }
  }

  Future<void> _onAddDealerStock(
    AddDealerStock event,
    Emitter<DealerListState> emit,
  ) async {
    debugPrint('');
    debugPrint('========================================');
    debugPrint('ADD DEALER STOCK EVENT RECEIVED');
    debugPrint('========================================');

    debugPrint('Dealer ID      : ${event.dealerId}');
    debugPrint('User ID        : ${event.userId}');
    debugPrint('Image Path     : ${event.dealerImage}');
    debugPrint('Signature Path : ${event.digitalSignature}');
    debugPrint('GeoAddress     : ${event.geoAddress}');
    debugPrint('JSONDATA       : ${event.jsonData}');

    debugPrint('========================================');

    emit(state.copyWith(status: DealerListStatus.loading, errorMessage: null));

    try {
      // ============================================================
      // 1. DEALER IMAGE
      // ============================================================

      File? dealerImageFile;

      final String dealerImagePath = event.dealerImage.trim();

      debugPrint('');
      debugPrint('========================================');
      debugPrint('DEALER IMAGE CHECK');
      debugPrint('========================================');

      debugPrint('IMAGE PATH: $dealerImagePath');

      if (dealerImagePath.isNotEmpty) {
        final File originalFile = File(dealerImagePath);

        final bool exists = await originalFile.exists();

        debugPrint('ORIGINAL IMAGE EXISTS: $exists');

        if (exists) {
          final int originalSize = await originalFile.length();

          debugPrint(
            'ORIGINAL IMAGE SIZE: '
            '$originalSize bytes',
          );

          // ========================================================
          // COMPRESS IMAGE
          // ========================================================

          final File? compressedFile = await ImageCompression.compressImage(
            originalFile,
            maxWidth: 450,
            maxHeight: 450,
            quality: 45,
          );

          if (compressedFile != null && await compressedFile.exists()) {
            dealerImageFile = compressedFile;

            debugPrint('USING COMPRESSED DEALER IMAGE');

            debugPrint(
              'COMPRESSED PATH: '
              '${dealerImageFile.path}',
            );

            debugPrint(
              'COMPRESSED SIZE: '
              '${await dealerImageFile.length()} bytes',
            );
          } else {
            dealerImageFile = originalFile;

            debugPrint(
              'COMPRESSION FAILED - '
              'USING ORIGINAL IMAGE',
            );
          }
        }
      }

      // ============================================================
      // 2. VALIDATE DEALER IMAGE
      // ============================================================

      if (dealerImageFile == null) {
        emit(
          state.copyWith(
            status: DealerListStatus.failure,
            errorMessage: 'Dealer image file not found',
          ),
        );

        return;
      }

      // ============================================================
      // 3. DIGITAL SIGNATURE PATH
      // ============================================================

      final String signaturePath = event.digitalSignature.trim();

      debugPrint('');
      debugPrint('========================================');
      debugPrint('DIGITAL SIGNATURE CHECK');
      debugPrint('========================================');

      debugPrint('SIGNATURE PATH: $signaturePath');

      if (signaturePath.isEmpty) {
        emit(
          state.copyWith(
            status: DealerListStatus.failure,
            errorMessage: 'Digital signature path is empty',
          ),
        );

        return;
      }

      final File signatureFile = File(signaturePath);

      final bool signatureExists = await signatureFile.exists();

      debugPrint('SIGNATURE EXISTS: $signatureExists');

      if (!signatureExists) {
        emit(
          state.copyWith(
            status: DealerListStatus.failure,
            errorMessage: 'Digital signature file not found',
          ),
        );

        return;
      }

      final int signatureSize = await signatureFile.length();

      debugPrint(
        'SIGNATURE SIZE: '
        '$signatureSize bytes',
      );

      if (signatureSize <= 0) {
        emit(
          state.copyWith(
            status: DealerListStatus.failure,
            errorMessage: 'Digital signature file is empty',
          ),
        );

        return;
      }

      debugPrint('========================================');

      // ============================================================
      // 4. NORMAL REQUEST DATA
      //
      // IMPORTANT:
      //
      // digitalSignature is NOT added here.
      //
      // Repository will:
      //
      // 1. upload signature
      // 2. get Signature_xxx.png
      // 3. add digitalSignature filename
      // 4. call add stock API
      //
      // ============================================================

      final Map<String, dynamic> jsonData = <String, dynamic>{
        'dealerId': event.dealerId,

        'userId': event.userId,

        'geoAddress': event.geoAddress,

        'jsonData': event.jsonData,
      };

      // ============================================================
      // 5. PRINT NORMAL DATA
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('NORMAL FORM DATA');
      debugPrint('========================================');

      jsonData.forEach((key, value) {
        debugPrint('$key : $value');
      });

      // ============================================================
      // 6. FILE INFORMATION
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('DATA TO REPOSITORY');
      debugPrint('========================================');

      debugPrint(
        'DEALER IMAGE PATH: '
        '${dealerImageFile.path}',
      );

      debugPrint(
        'DEALER IMAGE SIZE: '
        '${await dealerImageFile.length()} bytes',
      );

      debugPrint(
        'SIGNATURE LOCAL PATH: '
        '$signaturePath',
      );

      debugPrint(
        'SIGNATURE SIZE: '
        '$signatureSize bytes',
      );

      debugPrint('========================================');

      // ============================================================
      // 7. CALL REPOSITORY
      //
      // THIRD PARAMETER IS STRING PATH
      // ============================================================

      final Map<String, dynamic> response = await repository.addDealerStock(
        jsonData,
        dealerImageFile,
        signaturePath,
      );

      // ============================================================
      // 8. RESPONSE
      // ============================================================

      debugPrint('');
      debugPrint('========================================');
      debugPrint('ADD DEALER STOCK RESPONSE');
      debugPrint('========================================');

      debugPrint('FULL RESPONSE : $response');

      debugPrint('STATUS        : ${response['status']}');

      debugPrint('MESSAGE       : ${response['message']}');

      debugPrint('RESULT        : ${response['result']}');

      debugPrint('========================================');

      // ============================================================
      // 9. SUCCESS
      // ============================================================

      if (response['status'] == true) {
        debugPrint('ADD DEALER STOCK SUCCESS');

        emit(
          state.copyWith(
            status: DealerListStatus.addDealerStockSuccess,
            errorMessage: null,
          ),
        );

        return;
      }

      // ============================================================
      // 10. FAILURE
      // ============================================================

      final String message = response['message']?.toString() ?? '';

      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          errorMessage: message.isNotEmpty ? message : 'Failed to add stock',
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('ADD DEALER STOCK ERROR');
      debugPrint('========================================');

      debugPrint('ERROR: $e');

      debugPrint('STACK TRACE: $stackTrace');

      debugPrint('========================================');

      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  FutureOr<void> _onGetTallyCompanys(
    GetTallyCompanyListEvent event,
    Emitter<DealerListState> emit,
  ) async {
    try {
      emit(
        state.copyWith(status: DealerListStatus.loading, errorMessage: null),
      );
      final response = await repository.getTallyCompanyList();

      print('tally companis response $response');

      if (response.status == true) {
        emit(
          state.copyWith(
            status: DealerListStatus.success,
            tallyCompanyListModel: response,
            errorMessage: response.message,
          ),
        );
      } else {
        emit(
          state.copyWith(
            status: DealerListStatus.failure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('');
      debugPrint('========================================');
      debugPrint('Tally Company ERROR');
      debugPrint('========================================');

      debugPrint('ERROR: $e');

      debugPrint('STACK TRACE: $stackTrace');

      debugPrint('========================================');

      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetTallyPdf(
    GetTallyPdfEvent event,
    Emitter<DealerListState> emit,
  ) async {
    emit(
      state.copyWith(
        status: DealerListStatus.loading,
        tallyPdfUrl: '',
        tallyPdfError: '',
      ),
    );

    try {
      final response = await repository.getTallyPdf(
        event.type,
        event.dealerId,
        event.fromDate,
        event.toDate,
        event.tallyCompanyId,
      );

      final pdfUrl = response['url']?.toString().trim() ?? '';
      final uri = Uri.tryParse(pdfUrl);
      if (response['status'] != true ||
          uri == null ||
          !uri.hasAuthority ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        throw Exception(
          response['message']?.toString() ?? 'Unable to generate PDF.',
        );
      }

      emit(
        state.copyWith(
          status: DealerListStatus.success,
          tallyPdfUrl: pdfUrl,
          tallyPdfError: '',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DealerListStatus.failure,
          tallyPdfError: e.toString(),
        ),
      );
    }
  }
}
