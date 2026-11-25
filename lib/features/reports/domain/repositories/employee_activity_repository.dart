import 'package:solufine/features/reports/domain/entities/invoice_entity.dart';
import 'package:solufine/features/reports/domain/entities/product_analysis_report.dart';

import '../entities/employee_activity.dart';

abstract class EmployeeActivityRepository {
  Future<List<EmployeeActivity>> getEmployeeActivityDetails({
    required String userId,
    required String searchDate,
    required String logUserId,
  });

  Future<InvoiceEntity> getTargetSummary({
    required String date,
    required String userId,
    required String amountType,
  });

  Future<ProductAnalysisReport> getProductAnalysisReport(
    String fromDate,
    String toDate,
    String userId,
    String outLetId,
    String productId,
    String packing,
  );
}
