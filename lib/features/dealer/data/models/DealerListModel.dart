class DealerListModel {
  const DealerListModel({
    required this.outletId,
    required this.outletName,
    required this.outletPerson,
    required this.outletAddress,
    this.fertilizerLicence,
    this.outletPersonMobile,
    this.outletMobile,
    this.outletPersonEmail,
    this.pesticidesLicence,
    this.outletState,
    this.outletDistrict,
    this.outletTaluka,
    this.outletCity,
    this.remark,
    this.latitude,
    this.longitude,
    this.gstNo,
    this.dob,
    this.anniversaryDate,
    this.companyDetails,
    this.turnOver,
    this.establishedYear,
    this.firmType,
    this.accountantName,
    this.accountantEmail,
    this.distName,
    this.code,
    this.name,
    this.definedRadius,
    this.outstandingAmt,
    this.overDueAmt,
    this.outletType,
    this.followupType,
    this.outletDistance,
    this.lastDateTime,
    this.lastVisitDateTime,
    this.lastOrderDateTime,
  });

  final String outletId;
  final String outletName;
  final String outletPerson;
  final String outletAddress;

  final String? fertilizerLicence;
  final String? outletPersonMobile;
  final String? outletMobile;
  final String? outletPersonEmail;
  final String? pesticidesLicence;
  final String? outletState;
  final String? outletDistrict;
  final String? outletTaluka;
  final String? outletCity;
  final String? remark;
  final String? latitude;
  final String? longitude;
  final String? gstNo;
  final String? dob;
  final String? anniversaryDate;
  final String? companyDetails;
  final String? turnOver;
  final String? establishedYear;
  final String? firmType;
  final String? accountantName;
  final String? accountantEmail;
  final String? distName;
  final String? code;
  final String? name;
  final String? definedRadius;
  final String? outstandingAmt;
  final String? overDueAmt;
  final String? outletType;
  final String? followupType;
  final String? outletDistance;
  final String? lastDateTime;
  final String? lastVisitDateTime;
  final String? lastOrderDateTime;

  factory DealerListModel.fromJson(Map<String, dynamic> json) {
    print('--------------------------------');
    print('PARSING DEALER JSON');
    print('Dealer JSON: $json');

    final dealer = DealerListModel(
      outletId: _stringValue(json['fld_outlet_id']),
      outletName: _stringValue(json['fld_outlet_name']),
      outletPerson: _stringValue(json['fld_outlet_person']),
      outletAddress: _stringValue(json['fld_outlet_address']),

      fertilizerLicence: _nullableString(json['fld_fertilizer_licence']),

      outletPersonMobile: _nullableString(json['fld_outletper_mobile']),

      outletMobile: _nullableString(json['fld_outlet_mobile']),

      outletPersonEmail: _nullableString(json['fld_outletper_email']),

      pesticidesLicence: _nullableString(json['fld_pesticides_licence']),

      outletState: _nullableString(json['fld_outlet_state']),

      outletDistrict: _nullableString(json['fld_outlet_district']),

      outletTaluka: _nullableString(json['fld_outlet_taluka']),

      outletCity: _nullableString(json['fld_outlet_city']),

      remark: _nullableString(json['fld_remark']),

      latitude: _nullableString(json['fld_latitude']),

      longitude: _nullableString(json['fld_longitude']),

      gstNo: _nullableString(json['fld_gst_no']),

      dob: _nullableString(json['fld_dob']),

      anniversaryDate: _nullableString(json['fld_anniversary_date']),

      companyDetails: _nullableString(json['fld_company_details']),

      turnOver: _nullableString(json['fld_turn_over']),

      establishedYear: _nullableString(json['fld_established_year']),

      firmType: _nullableString(json['fld_firm_type']),

      accountantName: _nullableString(json['fld_accountant_name']),

      accountantEmail: _nullableString(json['fld_accountant_email']),

      distName: _nullableString(json['fld_dist_name']),

      code: _nullableString(json['fld_code']),

      name: _nullableString(json['fld_name']),

      definedRadius: _nullableString(json['definedRadius']),

      outstandingAmt: _nullableString(json['fld_outstanding_amt']),

      overDueAmt: _nullableString(json['fld_over_due_amt']),

      outletType: _nullableString(json['fld_outlet_type']),

      followupType: _nullableString(json['fld_followup_type']),

      outletDistance: _nullableString(json['outletDistance']),

      lastDateTime: _nullableString(json['last_date_time']),

      lastVisitDateTime: _nullableString(json['last_visit_date_time']),

      lastOrderDateTime: _nullableString(json['last_order_date_time']),
    );

    print('MODEL CREATED');
    print('Outlet ID: ${dealer.outletId}');
    print('Outlet Name: ${dealer.outletName}');
    print('Outlet Person: ${dealer.outletPerson}');
    print('Outlet Person Mobile: ${dealer.outletPersonMobile}');
    print('Outlet Address: ${dealer.outletAddress}');
    print('Latitude: ${dealer.latitude}');
    print('Longitude: ${dealer.longitude}');
    print('Distance: ${dealer.outletDistance}');

    return dealer;
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_outlet_id': outletId,
      'fld_outlet_name': outletName,
      'fld_outlet_person': outletPerson,
      'fld_fertilizer_licence': fertilizerLicence,
      'fld_outletper_mobile': outletPersonMobile,
      'fld_outlet_mobile': outletMobile,
      'fld_outletper_email': outletPersonEmail,
      'fld_pesticides_licence': pesticidesLicence,
      'fld_outlet_address': outletAddress,
      'fld_outlet_state': outletState,
      'fld_outlet_district': outletDistrict,
      'fld_outlet_taluka': outletTaluka,
      'fld_outlet_city': outletCity,
      'fld_remark': remark,
      'fld_latitude': latitude,
      'fld_longitude': longitude,
      'fld_gst_no': gstNo,
      'fld_dob': dob,
      'fld_anniversary_date': anniversaryDate,
      'fld_company_details': companyDetails,
      'fld_turn_over': turnOver,
      'fld_established_year': establishedYear,
      'fld_firm_type': firmType,
      'fld_accountant_name': accountantName,
      'fld_accountant_email': accountantEmail,
      'fld_dist_name': distName,
      'fld_code': code,
      'fld_name': name,
      'definedRadius': definedRadius,
      'fld_outstanding_amt': outstandingAmt,
      'fld_over_due_amt': overDueAmt,
      'fld_outlet_type': outletType,
      'fld_followup_type': followupType,
      'outletDistance': outletDistance,
      'last_date_time': lastDateTime,
      'last_visit_date_time': lastVisitDateTime,
      'last_order_date_time': lastOrderDateTime,
    };
  }

  static String _stringValue(Object? value) {
    return value?.toString() ?? '';
  }

  static String? _nullableString(Object? value) {
    return value?.toString();
  }
}
