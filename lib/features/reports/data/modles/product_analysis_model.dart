import 'package:solufine/features/reports/domain/entities/product_analysis_report.dart';

class ProductAnalysisModel extends ProductAnalysisReport {
  ProductAnalysisModel({
    required super.status,
    required super.message,
    required super.result,
    required super.total,
  });

  factory ProductAnalysisModel.fromJson(Map<String, dynamic> json) {
    return ProductAnalysisModel(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map<String, dynamic>>()
                .map((item) => ProductAnaysisResultModel.fromJson(item))
                .toList()
          : <ProductAnalysisResult>[],
      total: ProductAnalysisTotalModel.fromJson(
        json['total'] is Map<String, dynamic>
            ? json['total'] as Map<String, dynamic>
            : <String, dynamic>{},
      ),

      //json['result'] is List ? json['result'] : <String, dynamic>{},
    );
  }
}

class ProductAnaysisResultModel extends ProductAnalysisResult {
  ProductAnaysisResultModel({
    required super.productId,
    required super.productDetailId,
    required super.productName,
    required super.qtyLitKg,
    required super.qtyNos,
    required super.effRate,
    required super.totalValue,
    required super.proportionalPer,
    required super.categoryName,
  });

  factory ProductAnaysisResultModel.fromJson(Map<String, dynamic> json) {
    return ProductAnaysisResultModel(
      productId: json['product_id']?.toString() ?? '',
      productDetailId: json['product_details_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      qtyLitKg: json['qty_lit_kg']?.toString() ?? '',
      qtyNos: json['qty_nos']?.toString() ?? '',
      effRate: json['eff_rate']?.toString() ?? '',
      totalValue: json['total_value']?.toString() ?? '',
      proportionalPer: json['proportional_perc']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ?? '',
    );
  }
}

class ProductAnalysisTotalModel extends ProductAnalysisTotal {
  ProductAnalysisTotalModel({
    required super.qtyLitKg,
    required super.qtyNos,
    required super.effRate,
    required super.totalValue,
    required super.proportionalPer,
  });

  factory ProductAnalysisTotalModel.fromJson(Map<String, dynamic> json) {
    return ProductAnalysisTotalModel(
      qtyLitKg: json['qty_lit_kg']?.toString() ?? '',
      qtyNos: json['qty_nos']?.toString() ?? '',
      effRate: json['eff_rate']?.toString() ?? '',
      totalValue: json['total_value']?.toString() ?? '',
      proportionalPer: json['proportional_perc']?.toString() ?? '',
    );
  }
}
