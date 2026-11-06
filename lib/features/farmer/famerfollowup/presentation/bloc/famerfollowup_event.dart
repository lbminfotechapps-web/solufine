abstract class FamerfollowupEvent {}

class SubmitFollowupEvent extends FamerfollowupEvent {
  final String farmerId;
  final String userId;
  final String followUpDate;
  final String followUpType;
  final String remark;
  final double latitude;
  final double longitude;
  final double networkLatitude;
  final double networkLongitude;
  final double gpsLatitude;
  final double gpsLongitude;
  final String geoAddress;
  final String networkInfo;
  final String batteryInfo;
  final String differenceByAndroid;
  final String statusOfFarmer;
  final String activityId;
  final String cropDetails;
  final String? imagePath;

  SubmitFollowupEvent({
    required this.farmerId,
    required this.userId,
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
    required this.networkInfo,
    required this.batteryInfo,
    required this.differenceByAndroid,
    required this.statusOfFarmer,
    required this.activityId,
    required this.cropDetails,
    this.imagePath,
  });
}

class GetRemarkHistoryEvent extends FamerfollowupEvent {
  final String farmerId;

  GetRemarkHistoryEvent({required this.farmerId});
}
