
import 'package:solufine/features/home/doman/home_entity/monthly_performance_entity.dart';

class MonthlyPerformanceModelNew extends MonthlyPerformanceEntity {
  const MonthlyPerformanceModelNew({
    required super.status,
    required super.message,
    required super.result,
  });

  factory MonthlyPerformanceModelNew.fromJson(
    Map<String, dynamic> json,
  ) {
    return MonthlyPerformanceModelNew(
      status: _toBool(json['status']),
      message: _toString(json['message']),
      result: json['result'] is List
          ? (json['result'] as List)
              .whereType<Map>()
              .map(
                (item) => MonthlyPerformanceItemModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <MonthlyPerformanceItemModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {
          'monthly_performance_id': item.monthlyPerformanceId,
          'month_year': item.monthYear,
          'employee_names': item.employeeNames,
        };
      }).toList(),
    };
  }
}

class MonthlyPerformanceItemModel
    extends MonthlyPerformanceItemEntity {
  const MonthlyPerformanceItemModel({
    required super.monthlyPerformanceId,
    required super.monthYear,
    required super.employeeNames,
  });

  factory MonthlyPerformanceItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MonthlyPerformanceItemModel(
      monthlyPerformanceId:
          _toString(json['monthly_performance_id']),
      monthYear: _toString(json['month_year']),
      employeeNames: json['employee_names'] is List
          ? (json['employee_names'] as List)
              .where((item) => item != null)
              .map((item) => item.toString())
              .toList()
          : <String>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly_performance_id': monthlyPerformanceId,
      'month_year': monthYear,
      'employee_names': employeeNames,
    };
  }
}

// ==========================================
// SAFE JSON CONVERSION HELPERS
// ==========================================

String _toString(dynamic value) {
  return value?.toString() ?? '';
}

bool _toBool(dynamic value) {
  if (value is bool) return value;

  if (value is num) return value == 1;

  final text = value?.toString().trim().toLowerCase();

  return text == 'true' || text == '1';
}
