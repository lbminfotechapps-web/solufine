import '../entities/demo_distributor_entry.dart';
import '../repositories/demo_distributor_repository.dart';

class GetDemoDistributorOptions {
  final DemoDistributorRepository repository;
  const GetDemoDistributorOptions(this.repository);
  Future<List<DemoOption>> call(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
  }) {
    if (userId.trim().isEmpty || userId == '0') {
      throw StateError('Please log in again.');
    }
    if ({
          DemoLookup.district,
          DemoLookup.block,
          DemoLookup.subcategory,
          DemoLookup.variety,
        }.contains(kind) &&
        parentId.isEmpty) {
      throw StateError('Select the parent field first.');
    }
    return repository.lookup(kind, userId: userId, parentId: parentId);
  }
}

class SubmitDemoDistributor {
  final DemoDistributorRepository repository;
  const SubmitDemoDistributor(this.repository);
  bool get available => repository.canSubmit;

  Future<String> call(DemoDistributorEntry entry) {
    final requiredValues = [
      entry.userId,
      entry.customerType,
      entry.stateId,
      entry.districtId,
      entry.blockId,
      entry.village,
      entry.cropId,
      entry.subcategoryId,
      entry.varietyId,
      entry.ck,
      entry.fieldDay,
    ];
    if (entry.userId == '0' ||
        requiredValues.any((value) => value.trim().isEmpty)) {
      throw StateError('Please complete all required fields.');
    }
    if (!entry.quantity.isFinite || entry.quantity <= 0) {
      throw StateError('Quantity must be greater than zero.');
    }
    return repository.submit(entry);
  }
}
