import 'package:equatable/equatable.dart';
import 'package:solufine/features/reports/domain/entities/invoice_entity.dart';
import 'package:solufine/features/reports/domain/entities/product_analysis_report.dart';

import '../../domain/entities/employee_activity.dart';

enum EmployeeActivityStatus { initial, loading, success, failure }

class EmployeeActivityState extends Equatable {
  final EmployeeActivityStatus status;

  final List<EmployeeActivity> activities;
  final InvoiceEntity? invoiceEntity;
  final ProductAnalysisReport? productAnalysisReport;

  final String? errorMessage;

  const EmployeeActivityState({
    this.status = EmployeeActivityStatus.initial,
    this.activities = const [],
    this.errorMessage,
    this.invoiceEntity,
    this.productAnalysisReport,
  });

  EmployeeActivityState copyWith({
    EmployeeActivityStatus? status,
    List<EmployeeActivity>? activities,
    String? errorMessage,
    bool clearErrorMessage = false,
    InvoiceEntity? invoiceEntity,
    ProductAnalysisReport? productAnalysisReport,
  }) {
    return EmployeeActivityState(
      status: status ?? this.status,

      activities: activities ?? this.activities,

      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      invoiceEntity: invoiceEntity ?? this.invoiceEntity,
      productAnalysisReport:
          productAnalysisReport ?? this.productAnalysisReport,
    );
  }

  @override
  List<Object?> get props => [
    status,
    activities,
    errorMessage,
    invoiceEntity,
    productAnalysisReport,
  ];
}
