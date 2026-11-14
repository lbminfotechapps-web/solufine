import '../../domain/entity/season_list_entity.dart';

class SeasonListModel extends SeasonListEntity {
  const SeasonListModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory SeasonListModel.fromJson(Map<String, dynamic> json) {
    return SeasonListModel(
      status: _toBool(json['status']),
      message: _toString(json['message']),
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      SeasonItemModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <SeasonItemModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {'fld_season_id': item.seasonId, 'fld_season': item.seasonName};
      }).toList(),
    };
  }
}

// ==========================================
// SEASON ITEM MODEL
// ==========================================

class SeasonItemModel extends SeasonItemEntity {
  const SeasonItemModel({required super.seasonId, required super.seasonName});

  factory SeasonItemModel.fromJson(Map<String, dynamic> json) {
    return SeasonItemModel(
      seasonId: _toString(json['fld_season_id']),
      seasonName: _toString(json['fld_season']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'fld_season_id': seasonId, 'fld_season': seasonName};
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
