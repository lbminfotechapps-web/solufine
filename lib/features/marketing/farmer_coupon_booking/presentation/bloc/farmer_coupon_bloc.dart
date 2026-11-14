
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/farmer_coupon_entity.dart';
import '../../domain/usecases/farmer_coupon_usecases.dart';

// ======================================================
// EVENTS
// ======================================================

abstract class FarmerCouponEvent {
  const FarmerCouponEvent();
}

class LoadCouponProducts extends FarmerCouponEvent {
  const LoadCouponProducts();
}

class SearchCouponFarmer extends FarmerCouponEvent {
  final String userId;
  final String searchText;

  const SearchCouponFarmer({
    required this.userId,
    required this.searchText,
  });
}

class ClearCouponFarmers extends FarmerCouponEvent {
  const ClearCouponFarmers();
}

class SubmitCouponBooking extends FarmerCouponEvent {
  final FarmerCouponEntity coupon;

  const SubmitCouponBooking(this.coupon);
}

// ======================================================
// STATE
// ======================================================

class FarmerCouponState {
  final bool loadingProducts;
  final bool searchingFarmers;
  final bool submitting;

  final List<CouponFarmer> farmers;
  final List<CouponProduct> products;

  final String? error;
  final String? success;

  const FarmerCouponState({
    this.loadingProducts = false,
    this.searchingFarmers = false,
    this.submitting = false,
    this.farmers = const [],
    this.products = const [],
    this.error,
    this.success,
  });

  FarmerCouponState copyWith({
    bool? loadingProducts,
    bool? searchingFarmers,
    bool? submitting,
    List<CouponFarmer>? farmers,
    List<CouponProduct>? products,
    String? error,
    String? success,
    bool clearMessages = false,
  }) {
    return FarmerCouponState(
      loadingProducts:
          loadingProducts ?? this.loadingProducts,
      searchingFarmers:
          searchingFarmers ?? this.searchingFarmers,
      submitting: submitting ?? this.submitting,
      farmers: farmers ?? this.farmers,
      products: products ?? this.products,
      error: clearMessages ? null : (error ?? this.error),
      success: clearMessages
          ? null
          : (success ?? this.success),
    );
  }
}

// ======================================================
// BLOC
// ======================================================

class FarmerCouponBloc
    extends Bloc<FarmerCouponEvent, FarmerCouponState> {
  final SearchCouponFarmers searchCouponFarmers;
  final GetCouponProducts getCouponProducts;
  final SubmitFarmerCoupon submitFarmerCoupon;

  int _searchVersion = 0;

  FarmerCouponBloc({
    required this.searchCouponFarmers,
    required this.getCouponProducts,
    required this.submitFarmerCoupon,
  }) : super(const FarmerCouponState()) {
    on<LoadCouponProducts>(_loadProducts);
    on<SearchCouponFarmer>(_searchFarmer);
    on<ClearCouponFarmers>(_clearFarmers);
    on<SubmitCouponBooking>(_submitCoupon);
  }

  Future<void> _loadProducts(
    LoadCouponProducts event,
    Emitter<FarmerCouponState> emit,
  ) async {
    emit(
      state.copyWith(
        loadingProducts: true,
        clearMessages: true,
      ),
    );

    try {
      final products = await getCouponProducts();

      emit(
        state.copyWith(
          loadingProducts: false,
          products: products,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingProducts: false,
          error: error.toString(),
        ),
      );
    }
  }

  void _clearFarmers(
    ClearCouponFarmers event,
    Emitter<FarmerCouponState> emit,
  ) {
    _searchVersion++;

    emit(
      state.copyWith(
        searchingFarmers: false,
        farmers: [],
      ),
    );
  }

  Future<void> _searchFarmer(
    SearchCouponFarmer event,
    Emitter<FarmerCouponState> emit,
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
      final farmers = await searchCouponFarmers(
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
    } catch (error) {
      if (version != _searchVersion) return;

      emit(
        state.copyWith(
          searchingFarmers: false,
          error: error.toString(),
        ),
      );
    }
  }

  Future<void> _submitCoupon(
    SubmitCouponBooking event,
    Emitter<FarmerCouponState> emit,
  ) async {
    if (state.submitting) return;

    emit(
      state.copyWith(
        submitting: true,
        clearMessages: true,
      ),
    );

    try {
      final message = await submitFarmerCoupon(
        event.coupon,
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
