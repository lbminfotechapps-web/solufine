import 'package:solufine/features/home/doman/home_entity/advertisement_entity.dart';

class AdvertisementModel extends AdvertisementEntity {
  const AdvertisementModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory AdvertisementModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementModel(
      status: _toBool(json['status']),
      message: _toString(json['message']),
      result: json['result'] is List
          ? (json['result'] as List)
                .whereType<Map>()
                .map(
                  (item) => AdvertisementItemModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : <AdvertisementItemModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) {
        return {
          'fld_advertisement_title': item.advertisementTitle,
          'fld_advertisement_type': item.advertisementType,
          'fld_advertisement_path': item.advertisementPath,
        };
      }).toList(),
    };
  }
}

// ==========================================
// ADVERTISEMENT ITEM MODEL
// ==========================================

class AdvertisementItemModel extends AdvertisementItemEntity {
  const AdvertisementItemModel({
    required super.advertisementTitle,
    required super.advertisementType,
    required super.advertisementPath,
  });

  factory AdvertisementItemModel.fromJson(Map<String, dynamic> json) {
    return AdvertisementItemModel(
      advertisementTitle: _toString(json['fld_advertisement_title']),
      advertisementType: _toString(json['fld_advertisement_type']),
      advertisementPath: _toString(json['fld_advertisement_path']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_advertisement_title': advertisementTitle,
      'fld_advertisement_type': advertisementType,
      'fld_advertisement_path': advertisementPath,
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
