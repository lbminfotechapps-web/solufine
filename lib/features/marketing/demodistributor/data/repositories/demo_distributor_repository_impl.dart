import '../../domain/entities/demo_distributor_entry.dart';
import '../../domain/repositories/demo_distributor_repository.dart';
import '../datasources/demo_distributor_remote_data_source.dart';

class DemoDistributorRepositoryImpl implements DemoDistributorRepository {
  final DemoDistributorRemoteDataSource remote;
  const DemoDistributorRepositoryImpl(this.remote);
  @override
  bool get canSubmit => remote.submitAdapter != null;
  @override
  Future<List<DemoOption>> lookup(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
  }) => remote.lookup(kind, userId: userId, parentId: parentId);
  @override
  Future<String> submit(DemoDistributorEntry entry) => remote.submit(entry);
}
