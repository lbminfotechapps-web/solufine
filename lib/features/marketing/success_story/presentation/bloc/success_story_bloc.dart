
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/success_story_entity.dart';
import '../../domain/usecases/success_story_usecases.dart';

// ====================================================
// EVENTS
// ====================================================

abstract class SuccessStoryEvent {
  const SuccessStoryEvent();
}

class LoadSuccessStoryCrops extends SuccessStoryEvent {
  const LoadSuccessStoryCrops();
}

class SearchSuccessStoryFarmer extends SuccessStoryEvent {
  final String userId;
  final String searchText;

  const SearchSuccessStoryFarmer({
    required this.userId,
    required this.searchText,
  });
}

class ClearSuccessStoryFarmers extends SuccessStoryEvent {
  const ClearSuccessStoryFarmers();
}

class SubmitSuccessStoryEvent extends SuccessStoryEvent {
  final SuccessStoryEntity story;

  const SubmitSuccessStoryEvent(this.story);
}

// ====================================================
// STATE
// ====================================================

class SuccessStoryState {
  final bool loadingCrops;
  final bool searchingFarmers;
  final bool submitting;

  final List<SuccessStoryCrop> crops;
  final List<SuccessStoryFarmer> farmers;

  final String? success;
  final String? error;

  const SuccessStoryState({
    this.loadingCrops = false,
    this.searchingFarmers = false,
    this.submitting = false,
    this.crops = const [],
    this.farmers = const [],
    this.success,
    this.error,
  });

  SuccessStoryState copyWith({
    bool? loadingCrops,
    bool? searchingFarmers,
    bool? submitting,
    List<SuccessStoryCrop>? crops,
    List<SuccessStoryFarmer>? farmers,
    String? success,
    String? error,
    bool clearMessages = false,
  }) {
    return SuccessStoryState(
      loadingCrops: loadingCrops ?? this.loadingCrops,
      searchingFarmers:
          searchingFarmers ?? this.searchingFarmers,
      submitting: submitting ?? this.submitting,
      crops: crops ?? this.crops,
      farmers: farmers ?? this.farmers,
      success: clearMessages
          ? null
          : (success ?? this.success),
      error: clearMessages
          ? null
          : (error ?? this.error),
    );
  }
}

// ====================================================
// BLOC
// ====================================================

class SuccessStoryBloc
    extends Bloc<SuccessStoryEvent, SuccessStoryState> {
  final SearchSuccessStoryFarmers searchFarmers;
  final GetSuccessStoryCrops getCrops;
  final SubmitSuccessStory submitStory;

  int _searchVersion = 0;

  SuccessStoryBloc({
    required this.searchFarmers,
    required this.getCrops,
    required this.submitStory,
  }) : super(const SuccessStoryState()) {
    on<LoadSuccessStoryCrops>(_loadCrops);
    on<SearchSuccessStoryFarmer>(_searchFarmers);
    on<ClearSuccessStoryFarmers>(_clearFarmers);
    on<SubmitSuccessStoryEvent>(_submit);
  }

  Future<void> _loadCrops(
    LoadSuccessStoryCrops event,
    Emitter<SuccessStoryState> emit,
  ) async {
    emit(
      state.copyWith(
        loadingCrops: true,
        clearMessages: true,
      ),
    );

    try {
      final crops = await getCrops();

      emit(
        state.copyWith(
          loadingCrops: false,
          crops: crops,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          loadingCrops: false,
          error: e.toString(),
        ),
      );
    }
  }

  void _clearFarmers(
    ClearSuccessStoryFarmers event,
    Emitter<SuccessStoryState> emit,
  ) {
    _searchVersion++;

    emit(
      state.copyWith(
        searchingFarmers: false,
        farmers: [],
      ),
    );
  }

  Future<void> _searchFarmers(
    SearchSuccessStoryFarmer event,
    Emitter<SuccessStoryState> emit,
  ) async {
    final version = ++_searchVersion;

    emit(
      state.copyWith(
        searchingFarmers: true,
        farmers: [],
        clearMessages: true,
      ),
    );

    try {
      final farmers = await searchFarmers(
        userId: event.userId,
        searchText: event.searchText,
      );

      if (version != _searchVersion) return;

      emit(
        state.copyWith(
          searchingFarmers: false,
          farmers: farmers,
        ),
      );
    } catch (e) {
      if (version != _searchVersion) return;

      emit(
        state.copyWith(
          searchingFarmers: false,
          error: e.toString(),
        ),
      );
    }
  }

  Future<void> _submit(
    SubmitSuccessStoryEvent event,
    Emitter<SuccessStoryState> emit,
  ) async {
    if (state.submitting) return;

    emit(
      state.copyWith(
        submitting: true,
        clearMessages: true,
      ),
    );

    try {
      final message = await submitStory(event.story);

      emit(
        state.copyWith(
          submitting: false,
          success: message,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          submitting: false,
          error: e.toString(),
        ),
      );
    }
  }
}
