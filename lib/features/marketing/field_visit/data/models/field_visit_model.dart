
import '../../domain/entities/field_visit_entity.dart';

class FieldVisitRequestModel {
  static Map<String, String> toFields(
    FieldVisitEntity entity,
  ) {
    return {
      'reportingPersonId': entity.reportingPersonId,
      'userId': entity.userId,
      'visitWith': entity.visitWith,
      'farmerId': entity.farmerId,
      'packetSown': entity.packetSown,
      'sownDate': entity.sownDate,
      'plotStatus': entity.plotStatus,
      'KmReading': entity.kmReading,
      'suggestion': entity.suggestion,
      'KmManualDistance': entity.kmManualDistance,
      'varietyIds': entity.varietyIds.join(','),
      'cropIds': entity.cropIds.join(','),
      'activity': entity.activity,
      'activityId': '10',
      'latitude': entity.latitude.toString(),
      'longitude': entity.longitude.toString(),
      'geoAddress': entity.geoAddress,
    };
  }
}

class FieldVisitFarmerModel extends FieldVisitFarmer {
  const FieldVisitFarmerModel({
    required super.id,
    required super.name,
    super.mobile,
  });

  factory FieldVisitFarmerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return FieldVisitFarmerModel(
      id: _field(json, [
        'fld_farmer_id',
        'farmerId',
        'strFarmerId',
        'fld_id',
      ]),
      name: _field(json, [
        'fld_farmer_name',
        'farmerName',
        'strFarmerName',
        'fld_name',
      ]),
      mobile: _field(json, [
        'fld_mobile_no',
        'mobileNo',
        'mobile',
      ]),
    );
  }
}

class FieldVisitCropModel extends FieldVisitCrop {
  const FieldVisitCropModel({
    required super.id,
    required super.name,
    required super.varieties,
  });

  factory FieldVisitCropModel.fromJson(
    Map<String, dynamic> json,
  ) {
    // Field names are provisional pending a real
    // getCropsAndVariety response example.
    final rawVarieties = json['varietyList'] ??
        json['varieties'] ??
        json['variety_details'] ??
        json['fld_variety_list'];

    final varieties = rawVarieties is List
        ? rawVarieties.whereType<Map>().map((raw) {
            final value = Map<String, dynamic>.from(raw);

            return FieldVisitVariety(
              id: _field(value, [
                'fld_variety_id',
                'varietyId',
                'strVarietyId',
                'fld_id',
              ]),
              name: _field(value, [
                'fld_variety_name',
                'varietyName',
                'strVarietyName',
                'fld_name',
              ]),
            );
          }).where((item) => item.id.isNotEmpty).toList()
        : <FieldVisitVariety>[];

    return FieldVisitCropModel(
      id: _field(json, [
        'fld_crop_id',
        'cropId',
        'strCropId',
        'fld_id',
      ]),
      name: _field(json, [
        'fld_crop_name',
        'cropName',
        'strCropName',
        'fld_name',
      ]),
      varieties: varieties,
    );
  }
}

String _field(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final value = json[key];

    if (value != null &&
        value.toString().trim().isNotEmpty &&
        value.toString() != 'null') {
      return value.toString();
    }
  }

  return '';
}
