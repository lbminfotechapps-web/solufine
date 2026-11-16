
import 'package:solufine/features/marketing/demodistributor/domain/entities/demo_distributor_entry.dart';
import 'package:solufine/features/marketing/demodistributor/domain/repositories/demo_distributor_repository.dart';

class GetDemoDistributorOptions {
  final DemoDistributorRepository repository;

  const GetDemoDistributorOptions(this.repository);

  Future<List<DemoOption>> call(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
  }) {
    if (userId.trim().isEmpty || userId.trim() == '0') {
      throw StateError('Please log in again.');
    }

    if ({
          DemoLookup.district,
          DemoLookup.block,
          DemoLookup.subcategory,
          DemoLookup.variety,
        }.contains(kind) &&
        parentId.trim().isEmpty) {
      throw StateError(
        'Select the parent field first.',
      );
    }

    return repository.lookup(
      kind,
      userId: userId,
      parentId: parentId,
    );
  }
}
