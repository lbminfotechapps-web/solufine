import 'package:solufine/features/marketing/complaint_form/domain/entity/crop_category.dart';

class CropCategoryListModel extends CropCategoryListEntity {
  const CropCategoryListModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory CropCategoryListModel.fromJson(Map<String, dynamic> json) {
    return CropCategoryListModel(
      status: _toBool(json['status']),
      message: _toString(json['message']),
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map>()
                .map(
                  (item) => CropCategoryItemModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <CropCategoryItemModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {
          'fld_category_id': item.categoryId,
          'fld_category_name': item.categoryName,
        };
      }).toList(),
    };
  }
}

class CropCategoryItemModel extends CropCategoryItemEntity {
  const CropCategoryItemModel({
    required super.categoryId,
    required super.categoryName,
  });

  factory CropCategoryItemModel.fromJson(Map<String, dynamic> json) {
    return CropCategoryItemModel(
      categoryId: _toString(json['fld_category_id']),
      categoryName: _toString(json['fld_category_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {'fld_category_id': categoryId, 'fld_category_name': categoryName};
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
