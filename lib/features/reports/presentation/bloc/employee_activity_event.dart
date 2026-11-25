import 'package:equatable/equatable.dart';

abstract class EmployeeActivityEvent extends Equatable {
  const EmployeeActivityEvent();

  @override
  List<Object?> get props => [];
}

class GetEmployeeActivityEvent extends EmployeeActivityEvent {
  final String userId;
  final String searchDate;
  final String logUserId;

  const GetEmployeeActivityEvent({
    required this.userId,
    required this.searchDate,
    required this.logUserId,
  });

  @override
  List<Object?> get props => [userId, searchDate, logUserId];
}

class GetTargetSummaryEvent extends EmployeeActivityEvent {
  final String date;
  final String userId;

  final String amountType;

  const GetTargetSummaryEvent({
    required this.date,
    required this.userId,

    required this.amountType,
  });

  @override
  List<Object?> get props => [date, userId, amountType];
}

class ClearTargetSummary extends EmployeeActivityEvent {
  const ClearTargetSummary();
}

class GetProductAnalysisEvent extends EmployeeActivityEvent {
  final String fromDate;
  final String toDate;

  final String userId;

  final String outletId;
  final String productId;

  final String packing;

  const GetProductAnalysisEvent({
    required this.fromDate,
    required this.toDate,
    required this.userId,
    required this.outletId,
    required this.productId,
    required this.packing,
  });

  @override
  List<Object?> get props => [
    fromDate,
    toDate,
    userId,
    outletId,
    productId,
    packing,
  ];
}
