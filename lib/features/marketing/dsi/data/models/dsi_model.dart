import '../../domain/entities/dsi_entity.dart';

class DsiRequestModel {
  static Map<String, String> listFields(DsiFilter filter) {
    return {
      'login_user_id': filter.userId,
      'searchText': filter.searchText,
      'from_date': filter.fromDate,
      'to_date': filter.toDate,
      'startLimit': filter.startLimit.toString(),
    };
  }

  static Map<String, String> addFields(AddDsiEntity entity) {
    return {
      'login_user_id': entity.userId,
      'date': entity.date,
      // Spelling from the original Java API.
      'effectivness': entity.effectiveness,
      'description': entity.description.trim(),
      'saveTime': entity.saveTime.trim(),
      'saveMoney': entity.saveMoney.trim(),
    };
  }
}

class DsiRecordModel extends DsiRecord {
  const DsiRecordModel({
    required super.id,
    required super.date,
    required super.effectiveness,
    required super.description,
    required super.saveTime,
    required super.saveMoney,
    required super.imageUrl,
    required super.employeeName,
  });

  static String _read(Map<String, dynamic> json, List<String> keys) {
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

  factory DsiRecordModel.fromJson(Map<String, dynamic> json) {
    return DsiRecordModel(
      id: _read(json, ['fld_dsi_id', 'fld_id', 'dsi_id', 'id']),
      date: _read(json, ['fld_created_date', 'fld_date', 'date', 'dsi_date']),
      effectiveness: _read(json, [
        'fld_effectiveness',
        'fld_effectivness',
        'effectivness',
        'effectiveness',
      ]),
      description: _read(json, ['fld_description', 'description']),
      saveTime: _read(json, ['fld_save_time', 'saveTime', 'save_time']),
      saveMoney: _read(json, ['fld_save_money', 'saveMoney', 'save_money']),
      imageUrl: _read(json, [
        'fld_image',
        'fld_dsi_photo',
        'dsi_photo',
        'photo',
        'image_url',
      ]),
      employeeName: _read(json, [
        'fld_adm_name',
        'fld_employee_name',
        'employeeName',
        'emp_name',
      ]),
    );
  }
}
