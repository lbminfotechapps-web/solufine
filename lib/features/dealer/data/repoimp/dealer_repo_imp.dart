import 'dart:io';

import 'package:flutter/material.dart';
import 'package:solufine/features/dealer/data/datasource/dealer_datasource.dart';
import 'package:solufine/features/dealer/data/models/DealerListModel.dart';
import 'package:solufine/features/dealer/data/models/dealer_products.dart';
import 'package:solufine/features/dealer/data/models/tally_company_list_model.dart';
import 'package:solufine/features/dealer/domain/repository/dealer_repo.dart';

class DealerListRepositoryImpl implements DealerListRepository {
  final DealerListDataSource dealerListDatasource;

  DealerListRepositoryImpl(this.dealerListDatasource);

  @override
  Future<List<DealerListModel>> getDealers(
    String userId,
    String lattitude,
    String logitude,
    String searchKey,
    String type,
    int startLimit,
  ) async {
    try {
      print('');
      print('========================================');
      print('DEALER REPOSITORY START');
      print('========================================');

      print('userId: $userId');
      print('latitude: $lattitude');
      print('longitude: $logitude');
      print('searchKey: $searchKey');
      print('type: $type');

      final response = await dealerListDatasource.fetchDealerList(
        userId,
        lattitude,
        logitude,
        searchKey,
        startLimit,
        type,
      );

      print('');
      print('========================================');
      print('DEALER REPOSITORY RESPONSE');
      print('========================================');

      print('Dealer count: ${response.length}');
      print('Dealers: $response');

      for (final dealer in response) {
        print(
          'Dealer ID: ${dealer.outletId} | '
          'Name: ${dealer.outletName}',
        );
      }

      return response;
    } catch (e, stackTrace) {
      print('');
      print('========================================');
      print('DEALER REPOSITORY ERROR');
      print('========================================');

      print('ERROR: $e');
      print('STACK: $stackTrace');

      throw Exception('Failed to fetch dealer list: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> addDealerLocation(
    Map<String, dynamic> jsonData,
  ) async {
    return await dealerListDatasource.addDealerLocation(jsonData);
  }

  @override
  Future<List<DealerStockProductModel>> getDealerProduct(
    String dealerId,
  ) async {
    return await dealerListDatasource.fetchDealerProductList(dealerId);
  }

  @override
  Future<Map<String, dynamic>> addDealerStock(
    Map<String, dynamic> jsonData,
    File? dealerImage,
    String? digitalSignature,
  ) async {
    // ============================================================
    // VALIDATE SIGNATURE PATH
    // ============================================================

    final String signaturePath = digitalSignature?.trim() ?? '';

    if (signaturePath.isEmpty) {
      throw Exception('Digital signature path is empty');
    }

    // ============================================================
    // UPLOAD SIGNATURE FIRST
    // ============================================================

    final String signatureFileName = await dealerListDatasource.uploadSignature(
      signaturePath: signaturePath,
    );

    debugPrint(
      'UPLOADED SIGNATURE FILE NAME: '
      '$signatureFileName',
    );

    // ============================================================
    // THEN SUBMIT DEALER STOCK
    // ============================================================

    return await dealerListDatasource.addDealerStock(
      jsonData,
      dealerImage,
      signatureFileName,
    );
  }

  @override
  Future<TallyCompanyListModel> getTallyCompanyList() async {
    return await dealerListDatasource.getTallyCompanyList();
  }

  @override
  Future<Map<String, dynamic>> getTallyPdf(
    String type,
    String dealerId,
    String fromDate,
    String toDate,
    String tallyCompanyId,
  ) {
    return dealerListDatasource.getTallyPdf(
      type,
      dealerId,
      fromDate,
      toDate,
      tallyCompanyId,
    );
  }
}
