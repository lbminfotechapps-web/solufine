import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class QuickAccessEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class PunchStatEvent extends QuickAccessEvent {
  final int userId;

  PunchStatEvent(this.userId);

  @override
  List<Object?> get props => [userId];
}

class VehicleTypeEvent extends QuickAccessEvent {
  final int userId;
  final String lastDate;

  VehicleTypeEvent(this.userId, this.lastDate);

  @override
  List<Object?> get props => [userId, lastDate];
}

class PunchInOutDetailsAddEvent extends QuickAccessEvent {
  final int userId;
  final String inOutStatus;
  final String differenceByAndroid;
  final String locationHistoryString;
  final String batteryInfo;
  final String networkInfo;
  final String pinRemark;
  final String startingClosingKmAmount;
  final String vehicleTypeId;
  final String route;
  final String latitude;
  final String longitude;
  final String networkLatitude;
  final String networkLongitude;
  final String gpsLatitude;
  final String gpsLongitude;
  final String geoAddress;

  // Optional
  final String? startingKmImage;
  final String? closingKmImage;

  final String activityId;

  // Optional
  final String? date;
  final String? newTime;

  final bool? isForceOutPunch;

  PunchInOutDetailsAddEvent({
    required this.userId,
    required this.inOutStatus,
    this.differenceByAndroid = '0.0',
    this.locationHistoryString = '',
    required this.batteryInfo,
    required this.networkInfo,
    required this.pinRemark,
    required this.startingClosingKmAmount,
    required this.vehicleTypeId,
    required this.route,
    required this.latitude,
    required this.longitude,
    required this.networkLatitude,
    required this.networkLongitude,
    required this.gpsLatitude,
    required this.gpsLongitude,
    required this.geoAddress,

    // No required
    this.startingKmImage,
    this.closingKmImage,

    required this.activityId,

    // No default value
    this.date,
    this.newTime,

    this.isForceOutPunch,
  });

  @override
  List<Object?> get props => [
    userId,
    inOutStatus,
    differenceByAndroid,
    locationHistoryString,
    batteryInfo,
    networkInfo,
    pinRemark,
    startingClosingKmAmount,
    vehicleTypeId,
    route,
    latitude,
    longitude,
    networkLatitude,
    networkLongitude,
    gpsLatitude,
    gpsLongitude,
    geoAddress,
    startingKmImage,
    closingKmImage,
    activityId,
    date,
    newTime,
    isForceOutPunch,
  ];
}

class SavePunchInLocationEvent extends QuickAccessEvent {
  final int userId;
  final String latitude;
  final String longitude;
  final String geoAddress;
  final int capturedAt;
  final double accuracy;
  final String provider;

  SavePunchInLocationEvent({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.geoAddress,
    required this.capturedAt,
    required this.accuracy,
    required this.provider,
  });

  @override
  List<Object?> get props => [
    userId,
    latitude,
    longitude,
    geoAddress,
    capturedAt,
    accuracy,
    provider,
  ];
}

class SaveNextLocationEvent extends QuickAccessEvent {
  final int userId;
  final String latitude;
  final String longitude;
  final String geoAddress;
  final int capturedAt;
  final double accuracy;
  final String provider;

  SaveNextLocationEvent({
    required this.userId,
    required this.latitude,
    required this.longitude,
    required this.geoAddress,
    required this.capturedAt,
    required this.accuracy,
    required this.provider,
  });

  @override
  List<Object?> get props => [
    userId,
    latitude,
    longitude,
    geoAddress,
    capturedAt,
    accuracy,
    provider,
  ];
}

class StoreTrackLocation extends QuickAccessEvent {
  final String userId;
  final String dailyTranId;
  final String strAllLocations;

  StoreTrackLocation(this.userId, this.dailyTranId, this.strAllLocations);
}

class ShareLocationEvent extends QuickAccessEvent {
  final int userId;

  final String inOutStatus;
  final String differenceByAndroid;
  final String locationHistoryString;

  final String batteryInfo;
  final String networkInfo;
  final String pinRemark;

  final String startingClosingKmAmount;
  final String vehicleTypeId;
  final String route;

  final String latitude;
  final String longitude;

  final String networkLatitude;
  final String networkLongitude;

  final String gpsLatitude;
  final String gpsLongitude;

  final String geoAddress;

  final String? startingKmImage;
  final String? closingKmImage;

  final String activityId;

  ShareLocationEvent({
    required this.userId,
    required this.inOutStatus,

    this.differenceByAndroid = '0.0',
    this.locationHistoryString = '',

    required this.batteryInfo,
    required this.networkInfo,
    required this.pinRemark,

    this.startingClosingKmAmount = '',
    this.vehicleTypeId = '',
    this.route = '',

    required this.latitude,
    required this.longitude,

    required this.networkLatitude,
    required this.networkLongitude,

    required this.gpsLatitude,
    required this.gpsLongitude,

    required this.geoAddress,

    this.startingKmImage,
    this.closingKmImage,

    required this.activityId,
  });

  @override
  List<Object?> get props => [
    userId,
    inOutStatus,
    differenceByAndroid,
    locationHistoryString,
    batteryInfo,
    networkInfo,
    pinRemark,
    startingClosingKmAmount,
    vehicleTypeId,
    route,
    latitude,
    longitude,
    networkLatitude,
    networkLongitude,
    gpsLatitude,
    gpsLongitude,
    geoAddress,
    startingKmImage,
    closingKmImage,
    activityId,
  ];
}

class AdvertisementEvent extends QuickAccessEvent {
  final String searchtype;
  final String searchtitle;

  AdvertisementEvent(this.searchtype, this.searchtitle);

  @override
  List<Object?> get props => [searchtype, searchtitle];
}
