enum DemoLookup {
  state,
  district,
  block,
  crop,
  subcategory,
  variety,
  irrigation,
}

class DemoOption {
  final String id;
  final String name;
  final String parentId;
  const DemoOption(this.id, this.name, {this.parentId = ''});
}


class DemoDistributorEntry {
  final String userId;
  final String farmerId;
  final String cropId;

  final String noOfPkt;
  final String pktWt;
  final DateTime sowingDate;
  final String kmReading;
  final String activityId;

  final String customerType;
  final String customerTypeId;
  final String customerId;

  final String stateId;
  final String districtId;
  final String blockId;
  final String village;

  final String demoCropId;
  final String demoProductId;
  final DateTime tpDate;
  final String previousYear;
  final String irrigationId;
  final String ck;
  final String fieldDay;

  const DemoDistributorEntry({
    required this.userId,
    required this.farmerId,
    required this.cropId,
    required this.noOfPkt,
    required this.pktWt,
    required this.sowingDate,
    required this.kmReading,
    required this.activityId,
    required this.customerType,
    required this.customerTypeId,
    required this.customerId,
    required this.stateId,
    required this.districtId,
    required this.blockId,
    required this.village,
    required this.demoCropId,
    this.demoProductId = '',
    required this.tpDate,
    required this.previousYear,
    required this.irrigationId,
    required this.ck,
    required this.fieldDay,
  });
}
