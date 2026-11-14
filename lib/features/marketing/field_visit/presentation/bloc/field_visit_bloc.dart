
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/field_visit_entity.dart';
import '../../domain/usecases/field_visit_usecases.dart';

// =====================================================
// EVENTS
// =====================================================

abstract class FieldVisitEvent {
  const FieldVisitEvent();
}

class LoadFieldVisitCrops extends FieldVisitEvent {
  const LoadFieldVisitCrops();
}

class SearchFieldVisitFarmer extends FieldVisitEvent {
  final String userId;
  final String searchText;

  const SearchFieldVisitFarmer({
    required this.userId,
    required this.searchText,
  });
}

class ClearFieldVisitFarmers extends FieldVisitEvent {
  const ClearFieldVisitFarmers();
}

class SubmitFieldVisitEvent extends FieldVisitEvent {
  final FieldVisitEntity entity;

  const SubmitFieldVisitEvent(this.entity);
}

class ClearFieldVisitMessage extends FieldVisitEvent {
  const ClearFieldVisitMessage();
}

// =====================================================
// STATE
// =====================================================

class FieldVisitState {
  final bool loadingCrops;
  final bool searchingFarmers;
  final bool submitting;

  final List<FieldVisitFarmer> farmers;
  final List<FieldVisitCrop> crops;

  final String? error;
  final String? success;

  const FieldVisitState({
    this.loadingCrops = false,
    this.searchingFarmers = false,
    this.submitting = false,
    this.farmers = const [],
    this.crops = const [],
    this.error,
    this.success,
  });

  FieldVisitState copyWith({
    bool? loadingCrops,
    bool? searchingFarmers,
    bool? submitting,
    List<FieldVisitFarmer>? farmers,
    List<FieldVisitCrop>? crops,
    String? error,
    String? success,
    bool clearMessages = false,
  }) {
    return FieldVisitState(
      loadingCrops: loadingCrops ?? this.loadingCrops,
      searchingFarmers:
          searchingFarmers ?? this.searchingFarmers,
      submitting: submitting ?? this.submitting,
      farmers: farmers ?? this.farmers,
      crops: crops ?? this.crops,
      error: clearMessages ? null : (error ?? this.error),
      success:
          clearMessages ? null : (success ?? this.success),
    );
  }
}

// =====================================================
// BLOC
// =====================================================

class FieldVisitBloc
    extends Bloc<FieldVisitEvent, FieldVisitState> {
  final GetFieldVisitCrops getCrops;
  final SearchFieldVisitFarmers searchFarmers;
  final SubmitFieldVisit submitVisit;

  int _searchVersion = 0;

  FieldVisitBloc({
    required this.getCrops,
    required this.searchFarmers,
    required this.submitVisit,
  }) : super(const FieldVisitState()) {
    on<LoadFieldVisitCrops>(_loadCrops);
    on<SearchFieldVisitFarmer>(_searchFarmer);
    on<ClearFieldVisitFarmers>(_clearFarmers);
    on<SubmitFieldVisitEvent>(_submit);
    on<ClearFieldVisitMessage>((event, emit) {
      emit(state.copyWith(clearMessages: true));
    });
  }

  Future<void> _loadCrops(
    LoadFieldVisitCrops event,
    Emitter<FieldVisitState> emit,
  ) async {
    emit(state.copyWith(
      loadingCrops: true,
      clearMessages: true,
    ));

    try {
      final crops = await getCrops();

      emit(state.copyWith(
        loadingCrops: false,
        crops: crops,
      ));
    } catch (e) {
      emit(state.copyWith(
        loadingCrops: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> _searchFarmer(
    SearchFieldVisitFarmer event,
    Emitter<FieldVisitState> emit,
  ) async {
    final version = ++_searchVersion;

    emit(state.copyWith(
      searchingFarmers: true,
      farmers: [],
    ));

    try {
      final farmers = await searchFarmers(
        userId: event.userId,
        searchText: event.searchText,
      );

      if (version != _searchVersion) return;

      emit(state.copyWith(
        searchingFarmers: false,
        farmers: farmers,
      ));
    } catch (e) {
      if (version != _searchVersion) return;

      emit(state.copyWith(
        searchingFarmers: false,
        farmers: [],
        error: e.toString(),
      ));
    }
  }

  void _clearFarmers(
    ClearFieldVisitFarmers event,
    Emitter<FieldVisitState> emit,
  ) {
    ++_searchVersion;

    emit(state.copyWith(
      searchingFarmers: false,
      farmers: [],
    ));
  }

  Future<void> _submit(
    SubmitFieldVisitEvent event,
    Emitter<FieldVisitState> emit,
  ) async {
    if (state.submitting) return;

    emit(state.copyWith(
      submitting: true,
      clearMessages: true,
    ));

    try {
      final message = await submitVisit(event.entity);

      emit(state.copyWith(
        submitting: false,
        success: message,
      ));
    } catch (e) {
      emit(state.copyWith(
        submitting: false,
        error: e.toString(),
      ));
    }
  }
}
