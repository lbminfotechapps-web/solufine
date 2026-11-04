import 'package:solufine/features/home/doman/home_entity/advertisement_entity.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/doman/home_entity/vehicle_type_entity.dart';
import 'package:solufine/features/home/doman/home_repository/qick_access_repo.dart';

class GetPunchStatusUsecase {
  final QickAccessRepo qickAccessRepo;

  GetPunchStatusUsecase(this.qickAccessRepo);

  Future<PunchStatEntity> getPunchStatus(int userId) async {
    try {
      return await qickAccessRepo.getPunchStatus(userId);
    } catch (e) {
      throw Exception('Failed to fetch punch status: $e');
    }
  }

  Future<List<VehicleTypeEntity>> getVehicleType(
    int userId,
    String lastDate,
  ) async {
    try {
      return await qickAccessRepo.getVehicleType(userId, lastDate);
    } catch (e) {
      throw Exception('Failed to fetch vehicle types: $e');
    }
  }

  Future<Map<String, dynamic>> savePunchDetails(
    Map<String, dynamic> jsonData,
  ) async {
    try {
      return await qickAccessRepo.savePunchDetails(jsonData);
    } catch (e) {
      throw Exception('Failed to save punch details: $e');
    }
  }

  Future<Map<String, dynamic>> storeLocationData(
    Map<String, dynamic> jsonData,
  ) async {
    try {
      return await qickAccessRepo.storeLocationData(jsonData);
    } catch (e) {
      throw Exception('Failed to save track location: $e');
    }
  }



  
  Future<AdvertisementEntity> getAdvertisement(
    String searchType,
    String searchtitle,
  ) async {
    try {
      return await qickAccessRepo.getAdvertisement(searchType, searchtitle);
    } catch (e) {
      throw Exception('Failed to fetch advertisement: $e');
    }
  }
}
