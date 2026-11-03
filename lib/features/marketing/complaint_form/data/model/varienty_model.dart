import 'package:solufine/features/marketing/complaint_form/domain/entity/variety_entity.dart';

class VarientyModel extends VarietyEntity {
  const VarientyModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory VarientyModel.fromJson(Map<String, dynamic> json) {
    return VarientyModel(
      status: json['status'] ?? false,
      message: json['message'] ?? '',
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map>()
                .map(
                  (item) => VarientyItemModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <VarientyItemModel>[],
    );
  }
}

class VarientyItemModel extends VarientyItemEntity {
  const VarientyItemModel({
    required super.productId,
    required super.categoryId,
    required super.productName,
    required super.subCategoryId,
  });

  factory VarientyItemModel.fromJson(Map<String, dynamic> json) {
    return VarientyItemModel(
      productId: _toString(json['fld_product_id']),
      categoryId: _toString(json['fld_category_id']),
      productName: _toString(json['fld_product_name']),
      subCategoryId: _toString(json['fld_subcategory_id']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_product_id': productId,
      'fld_category_id': categoryId,
      'fld_product_name': productName,
      'fld_subcategory_id': subCategoryId,
    };
  }
}

String _toString(dynamic value) {
  return value?.toString() ?? '';
}

bool _toBool(dynamic value) {
  if (value is bool) return value;

  if (value is num) return value == 1;

  final text = value?.toString().trim().toLowerCase();

  return text == 'true' || text == '1';
}
