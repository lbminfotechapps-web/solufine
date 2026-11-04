
import 'package:solufine/features/home/doman/home_entity/advertisement_entity.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';

import 'package:solufine/features/home/doman/home_entity/vehicle_type_entity.dart';

abstract class QickAccessRepo {
  Future<PunchStatEntity> getPunchStatus(int userId);
  Future<List<VehicleTypeEntity>> getVehicleType(int userId, String lastDate);
  Future<Map<String, dynamic>> savePunchDetails(Map<String, dynamic> jsonData);
  Future<Map<String, dynamic>> storeLocationData(Map<String, dynamic> jsonData);

  Future<AdvertisementEntity> getAdvertisement(
    String searchType,
    String searchtitle,
  );
}
