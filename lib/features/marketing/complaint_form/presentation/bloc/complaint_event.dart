import 'package:equatable/equatable.dart';

abstract class ComplaintFormEvent extends Equatable {
  const ComplaintFormEvent();

  @override
  List<Object?> get props => [];
}

class SubmitComplaintFormEvent extends ComplaintFormEvent {
  final Map<String, dynamic> jsonData;

  const SubmitComplaintFormEvent({required this.jsonData});

  @override
  String toString() =>
      'SubmitComplaintFormEvent(fields: ' + jsonData.keys.join(', ') + ')';

  @override
  List<Object?> get props => [jsonData];
}

class GetOutletListEvent extends ComplaintFormEvent {
  final String userId;
  final String dealerType;
  final String dealerName;
  const GetOutletListEvent({
    required this.userId,
    required this.dealerType,
    required this.dealerName,
  });
  @override
  List<Object?> get props => [userId, dealerType, dealerName];
}

class GetCropCategoryListEvent extends ComplaintFormEvent {
  const GetCropCategoryListEvent();

  @override
  List<Object?> get props => [];
}

class GetSubCategoryListEvent extends ComplaintFormEvent {
  final String categoryId;
  const GetSubCategoryListEvent({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class GetVarietyListEvent extends ComplaintFormEvent {
  final String categoryId;
  const GetVarietyListEvent({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}
