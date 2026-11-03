
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
  final String subcategoryId;
  final String subcategoryName;

  const SubcategoryItemEntity({
    required this.subcategoryId,
    required this.subcategoryName,
  });

  @override
  List<Object?> get props => [
        subcategoryId,
        subcategoryName,
      ];
}
