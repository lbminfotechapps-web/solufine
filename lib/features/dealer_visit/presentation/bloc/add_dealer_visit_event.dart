import 'package:equatable/equatable.dart';

abstract class AddDealerRemarkEvent extends Equatable {
  const AddDealerRemarkEvent();

  @override
  List<Object?> get props => [];
}

class AddDealerRemarkSubmitEvent extends AddDealerRemarkEvent {
  final String userId;
  final String outletId;
  final String purposeId;
  final String amount;
  final String followUpDate;
  final String followUpType;
  final String remark;
  final String latitude;
  final String longitude;
  final String networkLatitude;
  final String networkLongitude;
  final String gpsLatitude;
  final String gpsLongitude;
  final String geoAddress;
  final String strNetworkInfo;
  final String strBatteryInfo;
  final String activityId;
  final String? imagePath;

  const AddDealerRemarkSubmitEvent({
    required this.userId,
    required this.outletId,
    required this.purposeId,
    required this.amount,
    required this.followUpDate,
    required this.followUpType,
    required this.remark,
    required this.latitude,
    required this.longitude,
    required this.networkLatitude,
    required this.networkLongitude,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.geoAddress,
    required this.strNetworkInfo,
    required this.strBatteryInfo,
    required this.activityId,
    this.imagePath,
  });
}

class ClearLeaveMessageEvent extends AddDealerRemarkEvent {
  const ClearLeaveMessageEvent();
}

class GetPurposeEvent extends AddDealerRemarkEvent {
  final String userId;

  const GetPurposeEvent(this.userId);
}

class StateListEvent extends AddDealerRemarkEvent {
  final String userId;
  const StateListEvent({required this.userId});
}

class DistrictEvent extends AddDealerRemarkEvent {
  final String userId;
  final String stateId;

  const DistrictEvent({required this.stateId, required this.userId});
}

class AddDealerFollowUpEvent extends AddDealerRemarkEvent {
  final String userId;
  final String type;
  final String outletName;
  final String contactPerson;
  final String gstNo;
  final String mobileNo;
  final String mobileNo2;
  final String emailId;
  final String address;
  final String state;
  final String district;
  final String taluka;
  final String remark;
  final String city;
  final String latitude;
  final String longitude;
  final String networkLatitude;
  final String networkLongitude;
  final String gpsLatitude;
  final String gpsLongitude;
  final String geoAddress;
  final String differenceByAndroid;
  final String mobileInfo;
  final String mobileImei;
  final String followUpDate;
  final String followUpType;
  final String strNetworkInfo;
  final String strBatteryInfo;
  final String registrationType;
  final String flag;
  final String dealerCode;
  final String dealerCategory;
  final String dealerAdditionalJson;
  final String activityId;
  final String selfieCaptureImage;

  const AddDealerFollowUpEvent({
    required this.userId,
    required this.type,
    required this.outletName,
    required this.contactPerson,
    required this.gstNo,
    required this.mobileNo,
    required this.mobileNo2,
    required this.emailId,
    required this.address,
    required this.state,
    required this.district,
    required this.taluka,
    required this.remark,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.networkLatitude,
    required this.networkLongitude,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.geoAddress,
    required this.differenceByAndroid,
    required this.mobileInfo,
    required this.mobileImei,
    required this.followUpDate,
    required this.followUpType,
    required this.strNetworkInfo,
    required this.strBatteryInfo,
    required this.registrationType,
    required this.flag,
    required this.dealerCode,
    required this.dealerCategory,
    required this.dealerAdditionalJson,
    required this.activityId,
    required this.selfieCaptureImage,
  });

  @override
  List<Object?> get props => [
    userId,
    type,
    outletName,
    contactPerson,
    gstNo,
    mobileNo,
    mobileNo2,
    emailId,
    address,
    state,
    district,
    taluka,
    remark,
    city,
    latitude,
    longitude,
    networkLatitude,
    networkLongitude,
    gpsLatitude,
    gpsLongitude,
    geoAddress,
    differenceByAndroid,
    mobileInfo,
    mobileImei,
    followUpDate,
    followUpType,
    strNetworkInfo,
    strBatteryInfo,
    registrationType,
    flag,
    dealerCode,
    dealerCategory,
    dealerAdditionalJson,
    activityId,
    selfieCaptureImage,
  ];
}

class UpdateDealerEvent extends AddDealerRemarkEvent {
  final String outletId;

  final String userId;
  final String type;
  final String outletName;
  final String contactPerson;
  final String gstNo;
  final String mobileNo;
  final String mobileNo2;
  final String emailId;
  final String address;
  final String state;
  final String district;
  final String taluka;
  final String remark;
  final String city;

  final String latitude;
  final String longitude;

  final String dealerCode;
  final String activityId;
  final String followUpType;
  final String registrationType;

  const UpdateDealerEvent({
    required this.outletId,
    required this.userId,
    required this.type,
    required this.outletName,
    required this.contactPerson,
    required this.gstNo,
    required this.mobileNo,
    required this.mobileNo2,
    required this.emailId,
    required this.address,
    required this.state,
    required this.district,
    required this.taluka,
    required this.remark,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.dealerCode,
    required this.activityId,
    required this.followUpType,
    required this.registrationType,
  });

  @override
  List<Object?> get props => [
    outletId,
    userId,
    type,
    outletName,
    contactPerson,
    gstNo,
    mobileNo,
    mobileNo2,
    emailId,
    address,
    state,
    district,
    taluka,
    remark,
    city,
    latitude,
    longitude,
    dealerCode,
    activityId,
    followUpType,
    registrationType,
  ];
}

class GetFollowupEvent extends AddDealerRemarkEvent {
  final String outlet_id;

  const GetFollowupEvent(this.outlet_id);
}
