
import 'package:equatable/equatable.dart';

class SubcategoryListEntity extends Equatable {
  final bool status;
  final String message;
  final List<SubcategoryItemEntity> result;

  const SubcategoryListEntity({
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

class SubcategoryItemEntity extends Equatable {
  final String productId;
  final String productName;
  final String categoryId;
  final String subcategoryId;

  const SubcategoryItemEntity({
    required this.productId,
    required this.productName,
    required this.categoryId,
    required this.subcategoryId,
  });

  @override
  List<Object?> get props => [
        productId,
        productName,
        categoryId,
        subcategoryId,
      ];
}
