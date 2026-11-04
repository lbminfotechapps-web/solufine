
import 'package:equatable/equatable.dart';

class MonthlyPerformanceEntity extends Equatable {
  final bool status;
  final String message;
  final List<MonthlyPerformanceItemEntity> result;

  const MonthlyPerformanceEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [
        status,
        message,
        result,
      ];
}

class MonthlyPerformanceItemEntity extends Equatable {
  final String monthlyPerformanceId;
  final String monthYear;
  final List<String> employeeNames;

  const MonthlyPerformanceItemEntity({
    required this.monthlyPerformanceId,
    required this.monthYear,
    required this.employeeNames,
  });

  @override
  List<Object?> get props => [
        monthlyPerformanceId,
        monthYear,
        employeeNames,
      ];
}
