import '../../domain/entities/demo_distributor_entry.dart';

/// Local draft representation. These keys are NOT a confirmed API contract.

class DemoDistributorModel {
  final DemoDistributorEntry entry;

  const DemoDistributorModel(this.entry);

  Map<String, dynamic> toJson() {
    return {
      'userId': entry.userId,
      'farmerId': entry.farmerId,
      'cropId': entry.cropId,
      'noOfPkt': entry.noOfPkt,
      'pktWt': entry.pktWt,
      'sowingDate': _date(entry.sowingDate),
      'kmReading': entry.kmReading,
      'activityId': entry.activityId,
      'customerType': entry.customerType,
      'customerTypeId': entry.customerTypeId,
      'customerId': entry.customerId,
      'demoStateId': entry.stateId,
      'demoDistrictId': entry.districtId,
      'demoBlockId': entry.blockId,
      'demoVillage': entry.village,
      'demoCropId': entry.demoCropId,
      'demoTPDate': _date(entry.tpDate),
      'demoPreviousYear': entry.previousYear,
      'demoIrrigationId': entry.irrigationId,
      'demoCK': entry.ck,
      'demoFieldDay': entry.fieldDay,
    };
  }

  Map<String, dynamic> toDraftJson() => toJson();

  String _date(DateTime value) {
    return '${value.year.toString().padLeft(4, '0')}-'
        '${value.month.toString().padLeft(2, '0')}-'
        '${value.day.toString().padLeft(2, '0')}';
  }
}

