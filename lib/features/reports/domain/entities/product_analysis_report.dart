class ProductAnalysisReport {
  final bool status;
  final String message;

  final List<ProductAnalysisResult> result;
  final ProductAnalysisTotal total;

  ProductAnalysisReport({
    required this.status,
    required this.message,
    required this.result,
    required this.total,
  });
}

class ProductAnalysisResult {
  final String productId;
  final String categoryName;
  final String productDetailId;
  final String productName;
  final String qtyLitKg;
  final String qtyNos;
  final String effRate;
  final String totalValue;
  final String proportionalPer;

  ProductAnalysisResult({
    required this.productId,
    required this.productDetailId,
    required this.productName,
    required this.qtyLitKg,
    required this.qtyNos,
    required this.effRate,
    required this.totalValue,
    required this.proportionalPer, required this.categoryName,
  });
}

class ProductAnalysisTotal {
  final String qtyLitKg;
  final String qtyNos;
  final String effRate;
  final String totalValue;
  final String proportionalPer;

  ProductAnalysisTotal({
    required this.qtyLitKg,
    required this.qtyNos,
    required this.effRate,
    required this.totalValue,
    required this.proportionalPer,
  });
}
