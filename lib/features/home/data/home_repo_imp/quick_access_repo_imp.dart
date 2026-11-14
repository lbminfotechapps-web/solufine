import 'package:solufine/features/home/data/home_datasource/quick_access_datasource.dart';
import 'package:solufine/features/home/data/home_model/advertisement_model.dart';
import 'package:solufine/features/home/doman/home_entity/advertisement_entity.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/doman/home_entity/vehicle_type_entity.dart';
import 'package:solufine/features/home/doman/home_repository/qick_access_repo.dart';

class QuickAccessRepoImp implements QickAccessRepo {
  final QuickAccessDatasource quickAccessDatasource;

  QuickAccessRepoImp(this.quickAccessDatasource);

  @override
  Future<PunchStatEntity> getPunchStatus(int userId) {
    return quickAccessDatasource.getPunchStatus(userId);
  }

  @override
  Future<List<VehicleTypeEntity>> getVehicleType(int userId, String lastDate) {
    return quickAccessDatasource.getVehicleType(userId, lastDate);
  }

  @override
  Future<Map<String, dynamic>> savePunchDetails(Map<String, dynamic> jsonData) {
    return quickAccessDatasource.savePunchDetails(jsonData);
  }

  @override
  Future<Map<String, dynamic>> storeLocationData(
    Map<String, dynamic> jsonData,
  ) {
    return quickAccessDatasource.storeLocationData(jsonData);
  }

  @override
  Future<AdvertisementEntity> getAdvertisement(
    String searchType,
    String searchtitle,
  ) {
    return quickAccessDatasource.getAdvertisement(searchType, searchtitle);
  }
}
