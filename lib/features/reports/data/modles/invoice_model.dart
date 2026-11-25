
import '../../domain/entities/invoice_entity.dart';

class InvoiceModel extends InvoiceEntity {
  InvoiceModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory InvoiceModel.fromJson(Map<String, dynamic> json) {
    return InvoiceModel(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      result: InvoiceResultModel.fromJson(
        json['result'] is Map<String, dynamic>
            ? json['result']
            : <String, dynamic>{},
      ),
    );
  }
}

class InvoiceResultModel extends InvoiceResultEntity {
  InvoiceResultModel({
    required super.currentYearDate,
    required super.previousYearDate,
    required super.currentPreMonthDate,
    required super.allPreviousYearDate,
    required super.invoiceData,
  });

  factory InvoiceResultModel.fromJson(Map<String, dynamic> json) {
    return InvoiceResultModel(
      currentYearDate:
          json['current_year_date']?.toString() ?? '',
      previousYearDate:
          json['previous_year_date']?.toString() ?? '',
      currentPreMonthDate:
          json['current_pre_month_date']?.toString() ?? '',
      allPreviousYearDate:
          json['all_previous_year_date']?.toString() ?? '',
      invoiceData: (json['invoice_data'] as List<dynamic>? ?? [])
          .map(
            (e) => InvoiceDataModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}

class InvoiceDataModel extends InvoiceDataEntity {
  InvoiceDataModel({
    required super.rowType,
    required super.empName,
    required super.previousYearMtd,
    required super.currentMtd,
    required super.yoyDiff,
    required super.yoyGrowth,
    required super.previousMonthMtd,
    required super.momDiff,
    required super.momGrowth,
    required super.previousYearFull,
  });

  static double parseDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  factory InvoiceDataModel.fromJson(Map<String, dynamic> json) {
    return InvoiceDataModel(
      rowType: json['row_type']?.toString() ?? '',
      empName: json['emp_name']?.toString() ?? '',
      previousYearMtd: parseDouble(json['previous_year_mtd']),
      currentMtd: parseDouble(json['current_mtd']),
      yoyDiff: parseDouble(json['yoy_diff']),
      yoyGrowth: parseDouble(json['yoy_growth']),
      previousMonthMtd: parseDouble(json['previous_month_mtd']),
      momDiff: parseDouble(json['mom_diff']),
      momGrowth: parseDouble(json['mom_growth']),
      previousYearFull: parseDouble(json['previous_year_full']),
    );
  }
}
