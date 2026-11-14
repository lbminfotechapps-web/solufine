
class TallyCompanyListModel {
  final bool status;
  final String message;
  final List<TallyCompanyItemModel> result;

  const TallyCompanyListModel({
    required this.status,
    required this.message,
    required this.result,
  });

  factory TallyCompanyListModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TallyCompanyListModel(
      status: _toBool(json['status']),
      message: _toString(json['message']),
      result: json['result'] is List
          ? (json['result'] as List)
              .whereType<Map>()
              .map(
                (item) => TallyCompanyItemModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
          : <TallyCompanyItemModel>[],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'result': result.map((item) => item.toJson()).toList(),
    };
  }
}

// ==========================================
// TALLY COMPANY ITEM MODEL
// ==========================================

class TallyCompanyItemModel {
  final String tallyCompanyId;
  final String tallyCompanyName;

  const TallyCompanyItemModel({
    required this.tallyCompanyId,
    required this.tallyCompanyName,
  });

  factory TallyCompanyItemModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return TallyCompanyItemModel(
      tallyCompanyId: _toString(json['fld_tally_company_id']),
      tallyCompanyName: _toString(json['fld_tally_company_name']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_tally_company_id': tallyCompanyId,
      'fld_tally_company_name': tallyCompanyName,
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
