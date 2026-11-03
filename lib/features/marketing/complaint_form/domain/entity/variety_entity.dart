import 'package:equatable/equatable.dart';

class VarietyEntity extends Equatable {
  final bool status;
  final String message;
  final List<VarientyItemEntity> result;

  const VarietyEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [status, message, result];
}

class VarientyItemEntity extends Equatable {
  final String productId;
  final String categoryId;
  final String productName;
  final String subCategoryId;

  const VarientyItemEntity({
    required this.productId,
    required this.categoryId,
    required this.productName,
    required this.subCategoryId,
  });

  @override
  List<Object?> get props => [
    productId,
    categoryId,
    productName,
    subCategoryId,
  ];
}
