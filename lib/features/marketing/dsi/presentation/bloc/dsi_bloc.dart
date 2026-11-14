import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/dsi_entity.dart';
import '../../domain/usecases/dsi_usecases.dart';

// ======================================================
// EVENTS
// ======================================================

abstract class DsiEvent {
  const DsiEvent();
}

class LoadDsiList extends DsiEvent {
  final DsiFilter filter;

  final bool loadMore;

  const LoadDsiList(this.filter, {this.loadMore = false});
}

class SubmitDsiEvent extends DsiEvent {
  final AddDsiEntity entity;

  const SubmitDsiEvent(this.entity);
}

class ClearDsiMessage extends DsiEvent {
  const ClearDsiMessage();
}

// ======================================================
// STATE
// ======================================================

class DsiState {
  final bool loading;
  final bool submitting;
  final bool loadingMore;
  final bool hasMore;
  final List<DsiRecord> records;
  final String? success;
  final String? error;

  const DsiState({
    this.loading = false,
    this.submitting = false,
    this.loadingMore = false,
    this.hasMore = true,
    this.records = const [],
    this.success,
    this.error,
  });

  DsiState copyWith({
    bool? loading,
    bool? submitting,
    bool? loadingMore,
    bool? hasMore,
    List<DsiRecord>? records,
    String? success,
    String? error,
    bool clearMessages = false,
  }) {
    return DsiState(
      loading: loading ?? this.loading,
      submitting: submitting ?? this.submitting,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      records: records ?? this.records,
      success: clearMessages ? null : (success ?? this.success),
      error: clearMessages ? null : (error ?? this.error),
    );
  }
}

// ======================================================
// BLOC
// ======================================================

class DsiBloc extends Bloc<DsiEvent, DsiState> {
  final GetDsiList getDsiList;
  final SubmitDsi submitDsi;

  int _latestListRequest = 0;
  int _nextOffset = 0;
  DsiFilter? _activeFilter;

  DsiBloc({required this.getDsiList, required this.submitDsi})
    : super(const DsiState()) {
    on<LoadDsiList>(_onLoad);
    on<SubmitDsiEvent>(_onSubmit);
    on<ClearDsiMessage>((event, emit) {
      emit(state.copyWith(clearMessages: true));
    });
  }

  Future<void> _onLoad(LoadDsiList event, Emitter<DsiState> emit) async {
    if (event.loadMore &&
        (state.loading ||
            state.loadingMore ||
            !state.hasMore ||
            _activeFilter == null)) {
      return;
    }
    final requestId = ++_latestListRequest;
    if (!event.loadMore) {
      _activeFilter = event.filter;
      _nextOffset = 0;
    }
    final active = _activeFilter!;
    final offset = _nextOffset;
    final filter = DsiFilter(
      userId: active.userId,
      searchText: active.searchText,
      fromDate: active.fromDate,
      toDate: active.toDate,
      startLimit: offset,
    );
    emit(
      state.copyWith(
        loading: !event.loadMore,
        loadingMore: event.loadMore,
        records: event.loadMore ? state.records : [],
        hasMore: event.loadMore ? state.hasMore : true,
        clearMessages: true,
      ),
    );
    try {
      final page = await getDsiList(filter);
      if (requestId != _latestListRequest) return;
      final seen = event.loadMore
          ? state.records.where((r) => r.id.isNotEmpty).map((r) => r.id).toSet()
          : <String>{};
      final additions = page
          .where((r) => r.id.isEmpty || seen.add(r.id))
          .toList();
      _nextOffset = offset + page.length;
      emit(
        state.copyWith(
          loading: false,
          loadingMore: false,
          records: [if (event.loadMore) ...state.records, ...additions],
          // No page size is supplied by the API; stop on an empty or repeated page.
          hasMore: page.isNotEmpty && additions.isNotEmpty,
        ),
      );
    } catch (e) {
      if (requestId != _latestListRequest) return;
      emit(
        state.copyWith(loading: false, loadingMore: false, error: e.toString()),
      );
    }
  }

  Future<void> _onSubmit(SubmitDsiEvent event, Emitter<DsiState> emit) async {
    if (state.submitting) return;

    emit(state.copyWith(submitting: true, clearMessages: true));

    try {
      final message = await submitDsi(event.entity);

      emit(state.copyWith(submitting: false, success: message));
    } catch (e) {
      emit(state.copyWith(submitting: false, error: e.toString()));
    }
  }
}
