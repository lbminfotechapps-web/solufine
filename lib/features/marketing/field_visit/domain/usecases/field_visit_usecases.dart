import 'dart:io';

import '../entities/field_visit_entity.dart';
import '../repositories/field_visit_repository.dart';

class SearchFieldVisitFarmers {
  final FieldVisitRepository repository;

  const SearchFieldVisitFarmers(this.repository);

  Future<List<FieldVisitFarmer>> call({
    required String userId,
    required String searchText,
  }) {
    return repository.searchFarmers(userId: userId, searchText: searchText);
  }
}

class GetFieldVisitCrops {
  final FieldVisitRepository repository;

  const GetFieldVisitCrops(this.repository);

  Future<List<FieldVisitCrop>> call() {
    return repository.getCropsAndVarieties();
  }
}

class SubmitFieldVisit {
  final FieldVisitRepository repository;

  const SubmitFieldVisit(this.repository);

  Future<String> call(FieldVisitEntity entity) async {
    if (entity.userId.trim().isEmpty) {
      throw StateError('Please log in again.');
    }

    if (entity.visitWith.trim().isEmpty) {
      throw StateError('Please enter Visit With.');
    }

    if (entity.farmerId.trim().isEmpty) {
      throw StateError('Please select a farmer.');
    }

    if (entity.cropIds.isEmpty) {
      throw StateError('Please select crops.');
    }

    final packets = int.tryParse(entity.packetSown);

    if (packets == null || packets <= 0) {
      throw StateError('Enter valid packets sown.');
    }

    if (entity.sownDate.trim().isEmpty) {
      throw StateError('Select sowing date.');
    }

    if (entity.plotStatus.trim().isEmpty) {
      throw StateError('Enter plot status.');
    }

    if (!FieldVisitActivities.values.contains(entity.activity)) {
      throw StateError('Select visit activity.');
    }

    if (!entity.latitude.isFinite ||
        !entity.longitude.isFinite ||
        entity.latitude < -90 ||
        entity.latitude > 90 ||
        entity.longitude < -180 ||
        entity.longitude > 180 ||
        (entity.latitude == 0 && entity.longitude == 0)) {
      throw StateError('Valid GPS location required.');
    }

    for (final path in [entity.plotImagePath, entity.visitorImagePath]) {
      if (path.trim().isEmpty || !await File(path).exists()) {
        throw StateError('Plot and visitor photos are required.');
      }
    }

    return repository.submitVisit(entity);
  }
}
