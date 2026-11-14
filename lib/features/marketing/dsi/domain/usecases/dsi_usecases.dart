
import 'dart:io';

import '../entities/dsi_entity.dart';
import '../repositories/dsi_repository.dart';

class GetDsiList {
  final DsiRepository repository;

  const GetDsiList(this.repository);

  Future<List<DsiRecord>> call(
    DsiFilter filter,
  ) async {
    if (filter.userId.trim().isEmpty) {
      throw StateError('Please log in again.');
    }

    return repository.fetchDsiList(filter);
  }
}

class SubmitDsi {
  final DsiRepository repository;

  const SubmitDsi(this.repository);

  Future<String> call(AddDsiEntity entity) async {
    if (entity.userId.isEmpty || entity.userId == '0') {
      throw StateError('Please log in again.');
    }

    if (entity.date.trim().isEmpty) {
      throw StateError('Please select DSI date.');
    }

    if (!DsiEffectiveness.addOptions
        .contains(entity.effectiveness)) {
      throw StateError('Please select effectiveness.');
    }

    if (entity.description.trim().isEmpty) {
      throw StateError('Please enter DSI description.');
    }

    for (final entry in {
      'Save Time': entity.saveTime,
      'Save Money': entity.saveMoney,
    }.entries) {
      if (entry.value.trim().isEmpty) continue;

      final amount = int.tryParse(entry.value.trim());

      if (amount == null || amount < 0) {
        throw StateError('Enter valid ${entry.key}.');
      }
    }

    if (entity.photoPath != null &&
        entity.photoPath!.isNotEmpty &&
        !await File(entity.photoPath!).exists()) {
      throw StateError('Selected photo not found.');
    }

    return repository.addDsi(entity);
  }
}
