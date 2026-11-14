import '../entities/demo_distributor_entry.dart';

abstract class DemoDistributorRepository {
  Future<List<DemoOption>> lookup(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
  });
  bool get canSubmit;
  Future<String> submit(DemoDistributorEntry entry);
}
