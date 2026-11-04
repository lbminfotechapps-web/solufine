import 'package:equatable/equatable.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/subcategory_list_model.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/crop_category.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/outlet_list_entity.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/variety_entity.dart';

enum ComplaintFormStatus { initial, loading, success, failure }

class ComplaintFormState extends Equatable {
  final ComplaintFormStatus status;
  final ComplaintFormStatus submissionStatus;
  final ComplaintFormStatus cropStatus;
  final ComplaintFormStatus varietyStatus;
  final String varietyErrorMessage;
  final ComplaintFormStatus subcategoryStatus;
  final String subcategoryErrorMessage;
  final String cropErrorMessage;
  final OutletListEntity? outletListEntity;
  final CropCategoryListEntity? cropCategoryListEntity;
  final SubCategoryListModel? subCategoryListEntity;

  final VarietyEntity? varietyListEntity;

  final String? errorMessage;

  const ComplaintFormState({
    this.submissionStatus = ComplaintFormStatus.initial,
    this.status = ComplaintFormStatus.initial,
    this.cropStatus = ComplaintFormStatus.initial,
    this.varietyStatus = ComplaintFormStatus.initial,
    this.varietyErrorMessage = '',
    this.subcategoryStatus = ComplaintFormStatus.initial,
    this.subcategoryErrorMessage = '',
    this.cropErrorMessage = '',
    this.errorMessage,
    this.outletListEntity,
    this.cropCategoryListEntity,
    this.subCategoryListEntity,
    this.varietyListEntity,
  });

  ComplaintFormState copyWith({
    ComplaintFormStatus? status,
    ComplaintFormStatus? submissionStatus,
    ComplaintFormStatus? cropStatus,
    ComplaintFormStatus? varietyStatus,
    String? varietyErrorMessage,
    ComplaintFormStatus? subcategoryStatus,
    String? subcategoryErrorMessage,
    String? cropErrorMessage,
    String? errorMessage,
    OutletListEntity? outletListEntity,
    CropCategoryListEntity? cropCategoryListEntity,
    SubCategoryListModel? subCategoryListEntity,
    VarietyEntity? varietyListEntity,
  }) {
    return ComplaintFormState(
      status: status ?? this.status,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      cropStatus: cropStatus ?? this.cropStatus,
      varietyStatus: varietyStatus ?? this.varietyStatus,
      varietyErrorMessage: varietyErrorMessage ?? this.varietyErrorMessage,
      subcategoryStatus: subcategoryStatus ?? this.subcategoryStatus,
      subcategoryErrorMessage:
          subcategoryErrorMessage ?? this.subcategoryErrorMessage,
      cropErrorMessage: cropErrorMessage ?? this.cropErrorMessage,
      errorMessage: errorMessage ?? this.errorMessage,
      outletListEntity: outletListEntity ?? this.outletListEntity,
      cropCategoryListEntity:
          cropCategoryListEntity ?? this.cropCategoryListEntity,
      subCategoryListEntity:
          subCategoryListEntity ?? this.subCategoryListEntity,
      varietyListEntity: varietyListEntity ?? this.varietyListEntity,
    );
  }

  @override
  List<Object?> get props => [
    status,
    submissionStatus,
    cropStatus,
    varietyStatus,
    varietyErrorMessage,
    subcategoryStatus,
    subcategoryErrorMessage,
    cropErrorMessage,
    errorMessage,
    outletListEntity,
    cropCategoryListEntity,
    subCategoryListEntity,
    varietyListEntity,
  ];
}
