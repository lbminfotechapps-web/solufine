import 'package:solufine/features/marketing/complaint_form/domain/entity/subcategory_list_entity.dart';


class SubCategoryListModel extends SubcategoryListEntity {
  const SubCategoryListModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory SubCategoryListModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubCategoryListModel(
      status: _toBool(json['status']),
      message: _toString(json['message']),
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

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {
          'fld_product_id': item.productId,
          'fld_product_name': item.productName,
          'fld_category_id': item.categoryId,
          'fld_subcategory_id': item.subcategoryId,
        };
      }).toList(),
    };
  }
}

class SubcategoryItemModel extends SubcategoryItemEntity {
  const SubcategoryItemModel({
    required super.productId,
    required super.productName,
    required super.categoryId,
    required super.subcategoryId,
  });

  factory SubcategoryItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return SubcategoryItemModel(
      productId: _toString(json['fld_product_id']),
      productName: _toString(json['fld_product_name']),
      categoryId: _toString(json['fld_category_id']),
      subcategoryId: _toString(json['fld_subcategory_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_product_id': productId,
      'fld_product_name': productName,
      'fld_category_id': categoryId,
      'fld_subcategory_id': subcategoryId,
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
