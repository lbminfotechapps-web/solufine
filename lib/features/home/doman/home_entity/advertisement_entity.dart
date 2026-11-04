
import 'package:equatable/equatable.dart';

class AdvertisementEntity extends Equatable {
  final bool status;
  final String message;
  final List<AdvertisementItemEntity> result;

  const AdvertisementEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [
        status,
        message,
        result,
      ];
}

class AdvertisementItemEntity extends Equatable {
  final String advertisementTitle;
  final String advertisementType;
  final String advertisementPath;

  const AdvertisementItemEntity({
    required this.advertisementTitle,
    required this.advertisementType,
    required this.advertisementPath,
  });

  bool get isVideo =>
      advertisementType.trim().toLowerCase() == 'video';

  bool get isNews =>
      advertisementType.trim().toLowerCase() == 'news';

  bool get hasMedia => advertisementPath.trim().isNotEmpty;

  @override
  List<Object?> get props => [
        advertisementTitle,
        advertisementType,
        advertisementPath,
      ];
}
