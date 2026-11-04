import 'package:solufine/features/home/doman/home_entity/monthly_performance_detail_entity.dart';

class MonthlyPerformanceDetailModel extends MonthlyPerformanceDetailEntity {
  const MonthlyPerformanceDetailModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory MonthlyPerformanceDetailModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformanceDetailModel(
      status: _toBool(json['status']),
      message: _toString(json['message']),
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map>()
                .map(
                  (item) => MonthlyPerformanceDetailItemModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <MonthlyPerformanceDetailItemModel>[],
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
          'ranks': item.ranks.map((rank) {
            return {
              'rank': rank.rank,
              'emp_name': rank.empName,
              'emp_img': rank.empImg,
            };
          }).toList(),
        };
      }).toList(),
    };
  }
}

// ==========================================
// MONTHLY PERFORMANCE ITEM MODEL
// ==========================================

class MonthlyPerformanceDetailItemModel
    extends MonthlyPerformanceDetailItemEntity {
  const MonthlyPerformanceDetailItemModel({
    required super.monthlyPerformanceId,
    required super.monthYear,
    required super.ranks,
  });

  factory MonthlyPerformanceDetailItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return MonthlyPerformanceDetailItemModel(
      monthlyPerformanceId: _toString(json['monthly_performance_id']),
      monthYear: _toString(json['month_year']),
      ranks: json['ranks'] is List
          ? (json['ranks'] as List)
                .whereType<Map>()
                .map(
                  (item) => MonthlyPerformanceRankModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <MonthlyPerformanceRankModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthly_performance_id': monthlyPerformanceId,
      'month_year': monthYear,
      'ranks': ranks.map((rank) {
        return {
          'rank': rank.rank,
          'emp_name': rank.empName,
          'emp_img': rank.empImg,
        };
      }).toList(),
    };
  }
}

// ==========================================
// MONTHLY PERFORMANCE RANK MODEL
// ==========================================

class MonthlyPerformanceRankModel extends MonthlyPerformanceRankEntity {
  const MonthlyPerformanceRankModel({
    required super.rank,
    required super.empName,
    required super.empImg,
  });

  factory MonthlyPerformanceRankModel.fromJson(Map<String, dynamic> json) {
    return MonthlyPerformanceRankModel(
      rank: _toString(json['rank']),
      empName: _toString(json['emp_name']),
      empImg: _toString(json['emp_img']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'rank': rank, 'emp_name': empName, 'emp_img': empImg};
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
