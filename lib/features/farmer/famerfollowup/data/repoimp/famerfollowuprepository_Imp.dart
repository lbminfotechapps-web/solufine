import 'package:solufine/features/farmer/famerfollowup/data/datasource/famerfollowup_datasource.dart';
import 'package:solufine/features/farmer/famerfollowup/data/model/followuplist_model.dart';
import 'package:solufine/features/farmer/famerfollowup/data/model/submitFollowup_mode.dart';
import 'package:solufine/features/farmer/famerfollowup/domain/repository/famerfollowup_repository.dart';

class FamerfollowupRepositoryImpl implements FamerfollowupRepository {
  final FamerfollowupDatasource datasource;

  FamerfollowupRepositoryImpl(this.datasource);

  @override
  Future<SubmitFollowupModel> submitFollowup({
    required String farmerId,
    required String userId,
    required String followUpDate,
    required String followUpType,
    required String remark,
    required double latitude,
    required double longitude,
    required double networkLatitude,
    required double networkLongitude,
    required double gpsLatitude,
    required double gpsLongitude,
    required String geoAddress,
    required String networkInfo,
    required String batteryInfo,
    required String differenceByAndroid,
    required String statusOfFarmer,
    required String activityId,
    required String cropDetails,
    String? imagePath,
  }) async {
    final response = await datasource.submitFollowup(
      farmerId: farmerId,
      userId: userId,
      followUpDate: followUpDate,
      followUpType: followUpType,
      remark: remark,
      latitude: latitude,
      longitude: longitude,
      networkLatitude: networkLatitude,
      networkLongitude: networkLongitude,
      gpsLatitude: gpsLatitude,
      gpsLongitude: gpsLongitude,
      geoAddress: geoAddress,
      networkInfo: networkInfo,
      batteryInfo: batteryInfo,
      differenceByAndroid: differenceByAndroid,
      statusOfFarmer: statusOfFarmer,
      activityId: activityId,
      cropDetails: cropDetails,
      imagePath: imagePath,
    );

    return SubmitFollowupModel(status: response.status);
  }

  @override
  Future<List<RemarkListModel>> getRemarkHistory({
    required String farmerId,
  }) async {
    return await datasource.getRemarkHistory(farmerId: farmerId);
  }
}
