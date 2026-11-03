import '../../domain/entity/outlet_list_entity.dart';

class OutletListModel extends OutletListEntity {
  const OutletListModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory OutletListModel.fromJson(Map<String, dynamic> json) {
    return OutletListModel(
      status: _toBool(json['status']),
      message: _toString(json['message']),
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map>()
                .map(
                  (item) =>
                      OutletItemModel.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : <OutletItemModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {
          'fld_outlet_id': item.outletId,
          'fld_outlet_name': item.outletName,
          'fld_outlet_address': item.outletAddress,
          'fld_taluka_name': item.talukaName,
          'fld_outletper_mobile': item.outletPersonMobile,
          'fld_dist_name': item.districtName,
          'fld_state_name': item.stateName,
          'fld_village': item.village,
          'fld_outlet_type': item.outletType,
        };
      }).toList(),
    };
  }
}

class OutletItemModel extends OutletItemEntity {
  const OutletItemModel({
    required super.outletId,
    required super.outletName,
    required super.outletAddress,
    required super.talukaName,
    required super.outletPersonMobile,
    required super.districtName,
    required super.stateName,
    required super.village,
    required super.outletType,
  });

  factory OutletItemModel.fromJson(Map<String, dynamic> json) {
    return OutletItemModel(
      outletId: _toString(json['fld_outlet_id']),
      outletName: _toString(json['fld_outlet_name']),
      outletAddress: _toString(json['fld_outlet_address']),
      talukaName: _toString(json['fld_taluka_name']),
      outletPersonMobile: _toString(json['fld_outletper_mobile']),
      districtName: _toString(json['fld_dist_name']),
      stateName: _toString(json['fld_state_name']),
      village: _toString(json['fld_village']),
      outletType: _toString(json['fld_outlet_type']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_outlet_id': outletId,
      'fld_outlet_name': outletName,
      'fld_outlet_address': outletAddress,
      'fld_taluka_name': talukaName,
      'fld_outletper_mobile': outletPersonMobile,
      'fld_dist_name': districtName,
      'fld_state_name': stateName,
      'fld_village': village,
      'fld_outlet_type': outletType,
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
