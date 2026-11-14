import '../../domain/entities/field_visit_entity.dart';
import '../../domain/repositories/field_visit_repository.dart';
import '../datasources/field_visit_datasource.dart';

class FieldVisitRepositoryImpl
    implements FieldVisitRepository {
  final FieldVisitDataSource datasource;

  const FieldVisitRepositoryImpl(this.datasource);

  @override
  Future<List<FieldVisitFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  }) {
    return datasource.searchFarmers(
      userId: userId,
      searchText: searchText,
    );
  }

  @override
  Future<List<FieldVisitCrop>> getCropsAndVarieties() {
    return datasource.getCropsAndVarieties();
  }

  @override
  Future<String> submitVisit(
    FieldVisitEntity entity,
  ) {
    return datasource.submitFieldVisit(entity);
  }
}