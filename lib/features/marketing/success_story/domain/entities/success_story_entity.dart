
class SuccessStoryFarmer {
  final String id;
  final String name;
  final String mobile;
  final String address;

  const SuccessStoryFarmer({
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
  });
}

class SuccessStoryCrop {
  final String id;
  final String name;

  const SuccessStoryCrop({
    required this.id,
    required this.name,
  });
}

class SuccessStoryEntity {
  final String userId;
  final String farmerId;
  final String mobileNo;
  final String address;
  final List<String> cropIds;
  final String cropAcrage;
  final String usedProduct;
  final String cropStage;
  final String alternateMobileNo;
  final String employeeNameHq;
  final String? videoPath;

  const SuccessStoryEntity({
    required this.userId,
    required this.farmerId,
    required this.mobileNo,
    required this.address,
    required this.cropIds,
    required this.cropAcrage,
    required this.usedProduct,
    required this.cropStage,
    required this.alternateMobileNo,
    required this.employeeNameHq,
    this.videoPath,
  });

  String get selectedCropIds => cropIds.join(',');
}
