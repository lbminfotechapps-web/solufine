import 'package:equatable/equatable.dart';

class CropCategoryListEntity extends Equatable {
  final bool status;
  final String message;
  final List<CropCategoryItemEntity> result;

  const CropCategoryListEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [status, message, result];
}

class CropCategoryItemEntity extends Equatable {
  final String categoryId;
  final String categoryName;

  const CropCategoryItemEntity({
    required this.categoryId,
    required this.categoryName,
  });

  @override
  List<Object?> get props => [categoryId, categoryName];
}
