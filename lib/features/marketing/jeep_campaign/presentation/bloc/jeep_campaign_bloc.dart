
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/jeep_campaign.dart';
import '../../domain/usecases/jeep_campaign_usecases.dart';

// EVENTS

abstract class JeepCampaignEvent {
  const JeepCampaignEvent();
}

class LoadJeepSeasons extends JeepCampaignEvent {
  const LoadJeepSeasons();
}

class SearchJeepProduct extends JeepCampaignEvent {
  final String seasonId;
  final String searchName;

  const SearchJeepProduct({
    required this.seasonId,
    required this.searchName,
  });
}

class ClearJeepProducts extends JeepCampaignEvent {
  const ClearJeepProducts();
}

class SubmitJeepCampaignEvent extends JeepCampaignEvent {
  final JeepCampaign campaign;

  const SubmitJeepCampaignEvent(this.campaign);
}

// STATE

class JeepCampaignState {
  final bool loadingSeasons;
  final bool searchingProducts;
  final bool submitting;

  final List<JeepOption> seasons;
  final List<JeepOption> products;

  final String? error;
  final String? success;

  const JeepCampaignState({
    this.loadingSeasons = false,
    this.searchingProducts = false,
    this.submitting = false,
    this.seasons = const [],
    this.products = const [],
    this.error,
    this.success,
  });

  JeepCampaignState copyWith({
    bool? loadingSeasons,
    bool? searchingProducts,
    bool? submitting,
    List<JeepOption>? seasons,
    List<JeepOption>? products,
    String? error,
    String? success,
    bool clearMessages = false,
  }) {
    return JeepCampaignState(
      loadingSeasons:
          loadingSeasons ?? this.loadingSeasons,
      searchingProducts:
          searchingProducts ?? this.searchingProducts,
      submitting: submitting ?? this.submitting,
      seasons: seasons ?? this.seasons,
      products: products ?? this.products,
      error: clearMessages ? null : (error ?? this.error),
      success: clearMessages
          ? null
          : (success ?? this.success),
    );
  }
}

// BLOC

class JeepCampaignBloc
    extends Bloc<JeepCampaignEvent, JeepCampaignState> {
  final GetJeepSeasons getSeasons;
  final SearchJeepProducts searchProducts;
  final SubmitJeepCampaign submitCampaign;

  int _searchVersion = 0;

  JeepCampaignBloc({
    required this.getSeasons,
    required this.searchProducts,
    required this.submitCampaign,
  }) : super(const JeepCampaignState()) {
    on<LoadJeepSeasons>(_loadSeasons);
    on<SearchJeepProduct>(_searchProducts);
    on<ClearJeepProducts>(_clearProducts);
    on<SubmitJeepCampaignEvent>(_submit);
  }

  Future<void> _loadSeasons(
    LoadJeepSeasons event,
    Emitter<JeepCampaignState> emit,
  ) async {
    emit(
      state.copyWith(
        loadingSeasons: true,
        clearMessages: true,
      ),
    );

    try {
      final seasons = await getSeasons();

      emit(
        state.copyWith(
          loadingSeasons: false,
          seasons: seasons,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingSeasons: false,
          error: error.toString(),
        ),
      );
    }
  }

  void _clearProducts(
    ClearJeepProducts event,
    Emitter<JeepCampaignState> emit,
  ) {
    _searchVersion++;

    emit(
      state.copyWith(
        products: [],
        searchingProducts: false,
      ),
    );
  }

  Future<void> _searchProducts(
    SearchJeepProduct event,
    Emitter<JeepCampaignState> emit,
  ) async {
    final requestVersion = ++_searchVersion;

    emit(
      state.copyWith(
        searchingProducts: true,
        products: [],
        clearMessages: true,
      ),
    );

    try {
      final products = await searchProducts(
        seasonId: event.seasonId,
        searchName: event.searchName,
      );

      if (requestVersion != _searchVersion) return;

      emit(
        state.copyWith(
          searchingProducts: false,
          products: products,
        ),
      );
    } catch (error) {
      if (requestVersion != _searchVersion) return;

      emit(
        state.copyWith(
          searchingProducts: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _submit(
    SubmitJeepCampaignEvent event,
    Emitter<JeepCampaignState> emit,
  ) async {
    if (state.submitting) return;

    emit(
      state.copyWith(
        submitting: true,
        clearMessages: true,
      ),
    );

    try {
      final message = await submitCampaign(
        event.campaign,
      );

      emit(
        state.copyWith(
          submitting: false,
          success: message,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          submitting: false,
          error: error.toString(),
        ),
      );
    }
  }
}
