import '../../domain/entities/demo_distributor_entry.dart';

/// Local draft representation. These keys are NOT a confirmed API contract.
class DemoDistributorModel {
  final DemoDistributorEntry entry;
  const DemoDistributorModel(this.entry);
  Map<String, dynamic> toDraftJson() => {
    'userId': entry.userId,
    'customerType': entry.customerType,
    'stateId': entry.stateId,
    'districtId': entry.districtId,
    'blockId': entry.blockId,
    'village': entry.village,
    'cropId': entry.cropId,
    'subcategoryId': entry.subcategoryId,
    'varietyId': entry.varietyId,
    'quantity': entry.quantity,
    'showingDate': _date(entry.showingDate),
    'tpDate': _date(entry.tpDate),
    'previousProduct': entry.previousProduct,
    'irrigationId': entry.irrigationId,
    'ck': entry.ck,
    'fieldDay': entry.fieldDay,
  };
  String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';
}
