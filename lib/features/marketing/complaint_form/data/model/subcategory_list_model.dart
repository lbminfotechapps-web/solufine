import 'package:solufine/features/marketing/complaint_form/domain/entity/subcategory_list_entity.dart';

class SubCategoryListModel extends SubcategoryListEntity {
  const SubCategoryListModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory SubCategoryListModel.fromJson(Map<String, dynamic> json) {
    return SubCategoryListModel(
      message: json['message'] ?? '',
      status: json['status'] ?? false,
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map>()
                .map(
                  (item) => SubcategoryItemModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <SubcategoryItemModel>[],
    );
  }
}

class SubcategoryItemModel extends SubcategoryItemEntity {
  const SubcategoryItemModel({
    required super.subcategoryId,
    required super.subcategoryName,
  });

  factory SubcategoryItemModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryItemModel(
      subcategoryId: _toString(json['fld_subcategory_id']),
      subcategoryName: _toString(json['fld_subcategory_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_subcategory_id': subcategoryId,
      'fld_subcategory_name': subcategoryName,
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
