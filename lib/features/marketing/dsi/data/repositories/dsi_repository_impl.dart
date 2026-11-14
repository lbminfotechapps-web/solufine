import '../../domain/entities/dsi_entity.dart';
import '../../domain/repositories/dsi_repository.dart';
import '../datasources/dsi_datasource.dart';

class DsiRepositoryImpl implements DsiRepository {
  final DsiDataSource dataSource;

  const DsiRepositoryImpl(this.dataSource);

  @override
  Future<List<DsiRecord>> fetchDsiList(
    DsiFilter filter,
  ) {
    return dataSource.getDsiList(filter);
  }

  @override
  Future<String> addDsi(
    AddDsiEntity entity,
  ) {
    return dataSource.addDsi(entity);
  }
}