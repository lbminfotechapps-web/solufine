import 'package:equatable/equatable.dart';

abstract class DealerEevent extends Equatable {
  const DealerEevent();

  @override
  List<Object?> get props => [];
}

class DealerListEvent extends DealerEevent {
  final String user_id;
  final String latitude;
  final String longitude;
  final String searchText;
  final String type;

  // CHANGE THIS
  final int startLimit;

  const DealerListEvent({
    required this.user_id,
    required this.latitude,
    required this.longitude,
    required this.searchText,
    required this.type,
    required this.startLimit,
  });

  @override
  List<Object> get props => [
    user_id,
    latitude,
    longitude,
    searchText,
    type,
    startLimit,
  ];
}

class AddDealerLocation extends DealerEevent {
  final String dealerId;
  final String userId;
  final String locationHistoryString;

  final String latitude;
  final String longitude;

  final String networkLatitude;
  final String networkLongitude;

  final String gpsLatitude;
  final String gpsLongitude;

  final String geoAddress;

  final String mobileInfo;
  final String mobileImei;

  final String networkInfo;
  final String batteryInfo;

  const AddDealerLocation({
    required this.dealerId,
    required this.userId,
    required this.locationHistoryString,
    required this.latitude,
    required this.longitude,
    required this.networkLatitude,
    required this.networkLongitude,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.geoAddress,
    this.mobileInfo = '',
    this.mobileImei = '',
    required this.networkInfo,
    required this.batteryInfo,
  });

  @override
  List<Object?> get props => [
    dealerId,
    userId,
    locationHistoryString,
    latitude,
    longitude,
    networkLatitude,
    networkLongitude,
    gpsLatitude,
    gpsLongitude,
    geoAddress,
    mobileInfo,
    mobileImei,
    networkInfo,
    batteryInfo,
  ];
}

class DealerProductListEvent extends DealerEevent {
  final String dealerId;

  const DealerProductListEvent({required this.dealerId});

  @override
  List<Object> get props => [dealerId];
}

class AddDealerStock extends DealerEevent {
  final String dealerId;
  final String userId;
  final String geoAddress;

  /// Local dealer image file path.
  final String dealerImage;

  final String jsonData;

  /// Local signature PNG file path.
  final String digitalSignature;

  const AddDealerStock({
    required this.dealerId,
    required this.userId,
    required this.geoAddress,
    required this.dealerImage,
    required this.jsonData,
    required this.digitalSignature,
  });

  @override
  List<Object?> get props => [
    dealerId,
    userId,
    geoAddress,
    dealerImage,
    jsonData,
    digitalSignature,
  ];
}

class GetTallyCompanyListEvent extends DealerEevent {}

class GetTallyPdfEvent extends DealerEevent {
  final String type;
  final String dealerId;
  final String fromDate;

  final String toDate;

  final String tallyCompanyId;

  const GetTallyPdfEvent(
    this.type,
    this.dealerId,
    this.fromDate,
    this.toDate,
    this.tallyCompanyId,
  );
}
