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
  final String customerType;
  final String stateId, districtId, blockId, village;
  final String cropId, subcategoryId, varietyId;
  final double quantity;
  final DateTime showingDate, tpDate;
  final String previousProduct, irrigationId, ck, fieldDay;

  const DemoDistributorEntry({
    required this.userId,
    required this.customerType,
    required this.stateId,
    required this.districtId,
    required this.blockId,
    required this.village,
    required this.cropId,
    required this.subcategoryId,
    required this.varietyId,
    required this.quantity,
    required this.showingDate,
    required this.tpDate,
    required this.previousProduct,
    required this.irrigationId,
    required this.ck,
    required this.fieldDay,
  });
}
