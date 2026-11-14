
class FieldVisitFarmer {
  final String id;
  final String name;
  final String mobile;

  const FieldVisitFarmer({
    required this.id,
    required this.name,
    this.mobile = '',
  });
}

class FieldVisitVariety {
  final String id;
  final String name;

  const FieldVisitVariety({
    required this.id,
    required this.name,
  });
}

class FieldVisitCrop {
  final String id;
  final String name;
  final List<FieldVisitVariety> varieties;

  const FieldVisitCrop({
    required this.id,
    required this.name,
    this.varieties = const [],
  });
}

class FieldVisitEntity {
  final String userId;
  final String reportingPersonId;
  final String visitWith;
  final String farmerId;
  final String packetSown;
  final String sownDate;
  final String plotStatus;
  final String activity;
  final String suggestion;
  final String kmReading;
  final String kmManualDistance;
  final List<String> cropIds;
  final List<String> varietyIds;
  final double latitude;
  final double longitude;
  final String geoAddress;

  final String plotImagePath;
  final String visitorImagePath;
  final String? kmReadingImagePath;

  const FieldVisitEntity({
    required this.userId,
    required this.reportingPersonId,
    required this.visitWith,
    required this.farmerId,
    required this.packetSown,
    required this.sownDate,
    required this.plotStatus,
    required this.activity,
    required this.suggestion,
    required this.cropIds,
    required this.varietyIds,
    required this.latitude,
    required this.longitude,
    required this.geoAddress,
    required this.plotImagePath,
    required this.visitorImagePath,
    this.kmReading = '',
    this.kmManualDistance = '',
    this.kmReadingImagePath,
  });
}

class FieldVisitActivities {
  static const values = [
    'Visit',
    'Field Day',
    'Field Trip',
    'Dealer Visit',
    'Demo Board',
  ];
}
