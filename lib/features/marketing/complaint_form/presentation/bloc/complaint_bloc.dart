import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:solufine/features/marketing/complaint_form/domain/usecase/complain_form_usecase.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_event.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_state.dart';

class ComplaintBloc extends Bloc<ComplaintFormEvent, ComplaintFormState> {
  int _searchVersion = 0;
  int _varietyVersion = 0;
  int _subcategoryVersion = 0;
  final ComplainFormUsecase complaintFormUsecase;

  ComplaintBloc({required this.complaintFormUsecase})
    : super(const ComplaintFormState()) {
    on<GetCropCategoryListEvent>(_onGetCropCategoryList);
    on<GetOutletListEvent>(_onGetOutletList);
    on<SubmitComplaintFormEvent>(_onSubmitComplaintForm);
    on<GetSubCategoryListEvent>(_onGetSubCategoryList);
    on<GetVarietyListEvent>(_onGetVarietyList);
  }

  Future<void> _onGetCropCategoryList(
    GetCropCategoryListEvent event,
    Emitter<ComplaintFormState> emit,
  ) async {
    if (state.cropStatus == ComplaintFormStatus.loading) return;
    emit(
      state.copyWith(
        cropStatus: ComplaintFormStatus.loading,
        cropErrorMessage: '',
      ),
    );
    try {
      final response = await complaintFormUsecase.getCategoryList();
      emit(
        state.copyWith(
          cropStatus: response.status
              ? ComplaintFormStatus.success
              : ComplaintFormStatus.failure,
          cropCategoryListEntity: response,
          cropErrorMessage: response.status ? '' : response.message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          cropStatus: ComplaintFormStatus.failure,
          cropErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetOutletList(
    GetOutletListEvent event,
    Emitter<ComplaintFormState> emit,
  ) async {
    final version = ++_searchVersion;
    emit(state.copyWith(status: ComplaintFormStatus.loading));
    try {
      final response = await complaintFormUsecase.getOutletList(
        event.userId,
        event.dealerType,
        event.dealerName,
      );
      if (version != _searchVersion) return;
      emit(
        state.copyWith(
          status: response.status
              ? ComplaintFormStatus.success
              : ComplaintFormStatus.failure,
          outletListEntity: response,
          errorMessage: response.status ? '' : response.message,
        ),
      );
    } catch (e) {
      if (version != _searchVersion) return;
      emit(
        state.copyWith(
          status: ComplaintFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onSubmitComplaintForm(
    SubmitComplaintFormEvent event,
    Emitter<ComplaintFormState> emit,
  ) async {
    emit(state.copyWith(status: ComplaintFormStatus.loading));
    try {
      await complaintFormUsecase.submitComplaintForm(event.jsonData);
      emit(state.copyWith(status: ComplaintFormStatus.success));
    } catch (e) {
      emit(
        state.copyWith(
          status: ComplaintFormStatus.failure,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _onGetSubCategoryList(
    GetSubCategoryListEvent event,
    Emitter<ComplaintFormState> emit,
  ) async {
    final version = ++_subcategoryVersion;
    emit(
      state.copyWith(
        subcategoryStatus: ComplaintFormStatus.loading,
        subcategoryErrorMessage: '',
      ),
    );
    try {
      final response = await complaintFormUsecase.getSubCategoryList(
        event.categoryId,
      );
      if (version != _subcategoryVersion) return;
      emit(
        state.copyWith(
          subcategoryStatus: response.status
              ? ComplaintFormStatus.success
              : ComplaintFormStatus.failure,
          subCategoryListEntity: response,
          subcategoryErrorMessage: response.status ? '' : response.message,
        ),
      );
    } catch (e) {
      if (version != _subcategoryVersion) return;
      emit(
        state.copyWith(
          subcategoryStatus: ComplaintFormStatus.failure,
          subcategoryErrorMessage: e.toString(),
        ),
      );
    }
  }

  FutureOr<void> _onGetVarietyList(
    GetVarietyListEvent event,
    Emitter<ComplaintFormState> emit,
  ) async {
    final version = ++_varietyVersion;
    emit(
      state.copyWith(
        varietyStatus: ComplaintFormStatus.loading,
        varietyErrorMessage: '',
      ),
    );
    try {
      final response = await complaintFormUsecase.getVarietyList(
        event.categoryId,
      );
      if (version != _varietyVersion) return;
      emit(
        state.copyWith(
          varietyStatus: response.status
              ? ComplaintFormStatus.success
              : ComplaintFormStatus.failure,
          varietyListEntity: response,
          varietyErrorMessage: response.status ? '' : response.message,
        ),
      );
    } catch (e) {
      if (version != _varietyVersion) return;
      emit(
        state.copyWith(
          varietyStatus: ComplaintFormStatus.failure,
          varietyErrorMessage: e.toString(),
        ),
      );
    }
  }
}
