import 'package:solufine/features/dealer/data/models/DealerListModel.dart';
import 'package:solufine/features/dealer/data/models/dealer_products.dart';
import 'package:solufine/features/dealer/data/models/tally_company_list_model.dart';

enum DealerListStatus {
  initial,
  loading,
  success,
  failure,
  addDealerloading,
  addDealerLocationSuccess,
  addDealerStockSuccess,
}

class DealerListState {
  final DealerListStatus status;
  final List<DealerListModel> dealerList;
  final String? errorMessage;
  final bool isLoadingMore;
  final bool hasMore;
  final int nextStartLimit;
  final String searchText;
  final String? loadMoreError;
  final List<DealerStockProductModel> productList;

  final TallyCompanyListModel? tallyCompanyListModel;

  final String? tallyPdfUrl;
  final String? tallyPdfError;

  const DealerListState({
    this.status = DealerListStatus.initial,
    this.dealerList = const [],
    this.productList = const [],
    this.errorMessage,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.nextStartLimit = 0,
    this.searchText = '',
    this.loadMoreError,
    this.tallyCompanyListModel,
    this.tallyPdfUrl,
    this.tallyPdfError,
  });

  DealerListState copyWith({
    DealerListStatus? status,
    List<DealerListModel>? dealerList,
    List<DealerStockProductModel>? productList,
    String? errorMessage,
    bool? isLoadingMore,
    bool? hasMore,
    int? nextStartLimit,
    String? searchText,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    TallyCompanyListModel? tallyCompanyListModel,
    String? tallyPdfUrl,
    String? tallyPdfError,
  }) {
    return DealerListState(
      status: status ?? this.status,
      dealerList: dealerList ?? this.dealerList,
      productList: productList ?? this.productList,
      errorMessage: errorMessage ?? this.errorMessage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      nextStartLimit: nextStartLimit ?? this.nextStartLimit,
      searchText: searchText ?? this.searchText,
      loadMoreError: clearLoadMoreError
          ? null
          : loadMoreError ?? this.loadMoreError,
      tallyCompanyListModel:
          tallyCompanyListModel ?? this.tallyCompanyListModel,
      tallyPdfUrl: tallyPdfUrl ?? this.tallyPdfUrl,
      tallyPdfError: tallyPdfError ?? this.tallyPdfError,
    );
  }
}
