import 'package:solufine/features/marketing/demodistributor/domain/repositories/demo_distributor_repository.dart';

import '../entities/demo_distributor_entry.dart';

class SubmitDemoDistributor {
  final DemoDistributorRepository repository;

  const SubmitDemoDistributor(this.repository);

  bool get available => repository.canSubmit;

  Future<String> call(DemoDistributorEntry entry) async {
    final requiredValues = [
      entry.userId,
      entry.customerType,
      entry.stateId,
      entry.districtId,
      entry.blockId,
      entry.village,
      entry.demoCropId,
      entry.noOfPkt,
      entry.ck,
      entry.fieldDay,
    ];

    if (entry.userId.trim() == '0' ||
        requiredValues.any(
          (value) => value.trim().isEmpty,
        )) {
      throw StateError(
        'Please complete all required fields.',
      );
    }

    final packetCount = int.tryParse(entry.noOfPkt.trim());

    if (packetCount == null || packetCount <= 0) {
      throw StateError(
        'Quantity must be a whole number greater than zero.',
      );
    }

    final packetWeight = double.tryParse(entry.pktWt.trim());

    if (entry.pktWt.trim().isNotEmpty && (packetWeight == null ||
        !packetWeight.isFinite ||
        packetWeight <= 0)) {
      throw StateError(
        'Packet weight must be greater than zero.',
      );
    }

    return repository.submit(entry);
  }



  
}
