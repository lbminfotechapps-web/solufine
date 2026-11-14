import '../entities/field_visit_entity.dart';

abstract class FieldVisitRepository {
  Future<List<FieldVisitFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  });

  Future<List<FieldVisitCrop>> getCropsAndVarieties();

  Future<String> submitVisit(FieldVisitEntity entity);
}