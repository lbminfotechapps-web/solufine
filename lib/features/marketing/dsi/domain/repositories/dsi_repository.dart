import '../entities/dsi_entity.dart';

abstract class DsiRepository {
  Future<List<DsiRecord>> fetchDsiList(
    DsiFilter filter,
  );

  Future<String> addDsi(
    AddDsiEntity entity,
  );
}