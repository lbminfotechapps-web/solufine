import 'package:solufine/features/reports/domain/entities/employee_out_repo_details.dart';
import 'package:solufine/features/reports/domain/entities/invoice_entity.dart';
import 'package:solufine/features/reports/domain/entities/product_analysis_report.dart';

import '../entities/employee_activity.dart';
import '../repositories/employee_activity_repository.dart';

class GetEmployeeActivityDetails {
  final EmployeeActivityRepository repository;

  GetEmployeeActivityDetails(this.repository);

  Future<List<EmployeeActivity>> call({
    required String userId,
    required String searchDate,
    required String logUserId,
  }) {
    return repository.getEmployeeActivityDetails(
      userId: userId,
      searchDate: searchDate,
      logUserId: logUserId,
    );
  }

  Future<InvoiceEntity> getTargetSummary({
    required String date,
    required String userId,
    required String amountType,
    s,
  }) {
    return repository.getTargetSummary(
      date: date,
      userId: userId,
      amountType: amountType,
    );
  }

  Future<ProductAnalysisReport> getProductAnalysisReport(
    String fromDate,
    String toDate,
    String userId,
    String outLetId,
    String productId,
    String packing,
  ) {
    return repository.getProductAnalysisReport(
      fromDate,
      toDate,
      userId,
      outLetId,
      productId,
      packing,
    );
  }
}
