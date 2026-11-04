import '../../doman/home_entity/advertisement_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:solufine/features/home/doman/home_entity/punch_stat_entity.dart';
import 'package:solufine/features/home/doman/home_entity/vehicle_type_entity.dart';

enum QuickAccessStatus {
  initial,
  loading,
  success,
  failure,
  punchStatusSuccess,
  locationAddedSucces,
  locationHistoryUploaded,
  locationTrackingSucess,
}

class QuickAccessState extends Equatable {
  final QuickAccessStatus quickAccessStatus;
  final QuickAccessStatus advertisementStatus;
  final AdvertisementEntity? advertisementData;
  final String advertisementError;
  final PunchStatEntity? punchStat;
  final String? errorMessage;
  final List<VehicleTypeEntity> vehicleList;
  final VehicleTypeEntity? selectedVehicle;
  final String? punchStatus;
  final String? dailyTranId;

  const QuickAccessState({
    this.advertisementStatus = QuickAccessStatus.initial,
    this.advertisementData,
    this.advertisementError = '',
    this.quickAccessStatus = QuickAccessStatus.initial,
    this.punchStat,
    this.errorMessage,
    this.vehicleList = const [],
    this.selectedVehicle,
    this.punchStatus,
    this.dailyTranId,
  });

  QuickAccessState copyWith({
    QuickAccessStatus? quickAccessStatus,
    QuickAccessStatus? advertisementStatus,
    AdvertisementEntity? advertisementData,
    String? advertisementError,
    PunchStatEntity? punchStat,
    String? errorMessage,
    List<VehicleTypeEntity>? vehicleList,
    VehicleTypeEntity? selectedVehicle,
    String? punchStatus,
    String? dailyTranId,
  }) {
    return QuickAccessState(
      quickAccessStatus: quickAccessStatus ?? this.quickAccessStatus,
      advertisementStatus: advertisementStatus ?? this.advertisementStatus,
      advertisementData: advertisementData ?? this.advertisementData,
      advertisementError: advertisementError ?? this.advertisementError,
      punchStat: punchStat ?? this.punchStat,
      errorMessage: errorMessage ?? this.errorMessage,
      vehicleList: vehicleList ?? this.vehicleList,
      selectedVehicle: selectedVehicle ?? this.selectedVehicle,
      punchStatus: punchStatus ?? this.punchStatus,
      dailyTranId: dailyTranId ?? this.dailyTranId,
    );
  }

  @override
  List<Object?> get props => [
    quickAccessStatus,
    advertisementStatus,
    advertisementData,
    advertisementError,
    punchStat,
    errorMessage,
    vehicleList,
    selectedVehicle,
    dailyTranId,
  ];
}
