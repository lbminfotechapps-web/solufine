
class InvoiceEntity {
  final bool status;
  final String message;
  final InvoiceResultEntity result;

  const InvoiceEntity({
    required this.status,
    required this.message,
    required this.result,
  });
}

class InvoiceResultEntity {
  final String currentYearDate;
  final String previousYearDate;
  final String currentPreMonthDate;
  final String allPreviousYearDate;
  final List<InvoiceDataEntity> invoiceData;

  const InvoiceResultEntity({
    required this.currentYearDate,
    required this.previousYearDate,
    required this.currentPreMonthDate,
    required this.allPreviousYearDate,
    required this.invoiceData,
  });
}

class InvoiceDataEntity {
  final String rowType;
  final String empName;
  final double previousYearMtd;
  final double currentMtd;
  final double yoyDiff;
  final double yoyGrowth;
  final double previousMonthMtd;
  final double momDiff;
  final double momGrowth;
  final double previousYearFull;

  const InvoiceDataEntity({
    required this.rowType,
    required this.empName,
    required this.previousYearMtd,
    required this.currentMtd,
    required this.yoyDiff,
    required this.yoyGrowth,
    required this.previousMonthMtd,
    required this.momDiff,
    required this.momGrowth,
    required this.previousYearFull,
  });
}
