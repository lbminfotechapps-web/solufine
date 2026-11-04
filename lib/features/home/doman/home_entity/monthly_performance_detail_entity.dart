import 'package:equatable/equatable.dart';

class MonthlyPerformanceDetailEntity extends Equatable {
  final bool status;
  final String message;
  final List<MonthlyPerformanceDetailItemEntity> result;

  const MonthlyPerformanceDetailEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [status, message, result];
}

class MonthlyPerformanceDetailItemEntity extends Equatable {
  final String monthlyPerformanceId;
  final String monthYear;
  final List<MonthlyPerformanceRankEntity> ranks;

  const MonthlyPerformanceDetailItemEntity({
    required this.monthlyPerformanceId,
    required this.monthYear,
    required this.ranks,
  });

  @override
  List<Object?> get props => [monthlyPerformanceId, monthYear, ranks];
}

class MonthlyPerformanceRankEntity extends Equatable {
  final String rank;
  final String empName;
  final String empImg;

  const MonthlyPerformanceRankEntity({
    required this.rank,
    required this.empName,
    required this.empImg,
  });

  @override
  List<Object?> get props => [rank, empName, empImg];
}
