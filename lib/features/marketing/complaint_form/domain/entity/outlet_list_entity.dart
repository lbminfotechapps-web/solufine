import 'package:equatable/equatable.dart';

class OutletListEntity extends Equatable {
  final bool status;
  final String message;
  final List<OutletItemEntity> result;

  const OutletListEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [status, message, result];
}

class OutletItemEntity extends Equatable {
  final String outletId;
  final String outletName;
  final String outletAddress;
  final String talukaName;
  final String outletPersonMobile;
  final String districtName;
  final String stateName;
  final String village;
  final String outletType;

  const OutletItemEntity({
    required this.outletId,
    required this.outletName,
    required this.outletAddress,
    required this.talukaName,
    required this.outletPersonMobile,
    required this.districtName,
    required this.stateName,
    required this.village,
    required this.outletType,
  });

  @override
  List<Object?> get props => [
    outletId,
    outletName,
    outletAddress,
    talukaName,
    outletPersonMobile,
    districtName,
    stateName,
    village,
    outletType,
  ];
}
