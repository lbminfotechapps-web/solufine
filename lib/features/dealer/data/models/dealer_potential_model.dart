class DealerPotentialModel {
  final bool status;
  final String message;
  final DealerPotentialResult? result;

  DealerPotentialModel({
    required this.status,
    required this.message,
    this.result,
  });

  factory DealerPotentialModel.fromJson(Map<String, dynamic> json) {
    return DealerPotentialModel(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      result: json['result'] is Map<String, dynamic>
          ? DealerPotentialResult.fromJson(json['result'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result?.toJson(),
    };
  }
}

// ======================================================
// DEALER POTENTIAL RESULT
// ======================================================

class DealerPotentialResult {
  final String thisYear;
  final String lastYear;
  final String lastYearSales;
  final String thisYearSales;
  final String dealerPotential;
  final String growthPercent;
  final List<DealerPotentialProduct> products;
  final DealerPotentialTotal total;

  DealerPotentialResult({
    required this.thisYear,
    required this.lastYear,
    required this.lastYearSales,
    required this.thisYearSales,
    required this.dealerPotential,
    required this.growthPercent,
    required this.products,
    this.total = const DealerPotentialTotal(),
  });

  factory DealerPotentialResult.fromJson(Map<String, dynamic> json) {
    return DealerPotentialResult(
      thisYear: json['this_year']?.toString() ?? '',
      lastYear: json['last_year']?.toString() ?? '',
      lastYearSales: json['last_year_sales']?.toString() ?? '0.00',
      thisYearSales: json['this_year_sales']?.toString() ?? '0.00',
      dealerPotential: json['dealer_potential']?.toString() ?? '0.00',
      growthPercent: json['growth_percent']?.toString() ?? '0.00',

      products: json['products'] is List
          ? (json['products'] as List)
                .whereType<Map<String, dynamic>>()
                .map((item) => DealerPotentialProduct.fromJson(item))
                .toList()
          : [],

      total: json['total'] is Map<String, dynamic>
          ? DealerPotentialTotal.fromJson(json['total'])
          : const DealerPotentialTotal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'this_year': thisYear,
      'last_year': lastYear,
      'last_year_sales': lastYearSales,
      'this_year_sales': thisYearSales,
      'dealer_potential': dealerPotential,
      'growth_percent': growthPercent,
      'products': products.map((item) => item.toJson()).toList(),
      'total': total.toJson(),
    };
  }
}

// ======================================================
// DEALER POTENTIAL PRODUCT
// ======================================================

class DealerPotentialProduct {
  final String productId;
  final String productName;
  final String lastYearSales;
  final String thisYearSales;
  final String potential;
  final String growthPercent;

  DealerPotentialProduct({
    required this.productId,
    required this.productName,
    required this.lastYearSales,
    required this.thisYearSales,
    required this.potential,
    required this.growthPercent,
  });

  factory DealerPotentialProduct.fromJson(Map<String, dynamic> json) {
    return DealerPotentialProduct(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      lastYearSales: json['last_year_sales']?.toString() ?? '0.00',
      thisYearSales: json['this_year_sales']?.toString() ?? '0.00',
      potential: json['potential']?.toString() ?? '0.00',
      growthPercent: json['growth_percent']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product_id': productId,
      'product_name': productName,
      'last_year_sales': lastYearSales,
      'this_year_sales': thisYearSales,
      'potential': potential,
      'growth_percent': growthPercent,
    };
  }
}

// ======================================================
// DEALER POTENTIAL TOTAL
// ======================================================

class DealerPotentialTotal {
  final String lastYearSales;
  final String thisYearSales;
  final String dealerPotential;
  final String growthPercent;

  const DealerPotentialTotal({
    this.lastYearSales = '0.00',
    this.thisYearSales = '0.00',
    this.dealerPotential = '0.00',
    this.growthPercent = '0.00',
  });

  factory DealerPotentialTotal.fromJson(Map<String, dynamic> json) {
    return DealerPotentialTotal(
      lastYearSales: json['last_year_sales']?.toString() ?? '0.00',
      thisYearSales: json['this_year_sales']?.toString() ?? '0.00',
      dealerPotential: json['dealer_potential']?.toString() ?? '0.00',
      growthPercent: json['growth_percent']?.toString() ?? '0.00',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'last_year_sales': lastYearSales,
      'this_year_sales': thisYearSales,
      'dealer_potential': dealerPotential,
      'growth_percent': growthPercent,
    };
  }
}