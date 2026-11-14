import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';
import 'package:solufine/features/home/doman/home_usecases/get_inpunch_pending_usecase.dart';
import 'package:solufine/features/home/doman/home_usecases/get_menu_usecase.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_event.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final GetMenuUsecase getMenuUsecase;
  final GetInpunchPendingUseCase getInpunchPendingUseCase;

  HomeBloc(this.getMenuUsecase, this.getInpunchPendingUseCase)
    : super(const HomeState()) {
    on<GetMonthlyPerformanceEvent>(_onGetMonthlyPerformance);
    on<GetMenuEvent>(_onGetMenus);

    on<VisitGraphCountEvent>(_onGetGraphCount);

    on<GetHomeVisitEvent>(_onGetHomeVisitCount);

    on<GetInpunchPendingEvent>(_getInpunchPending);
    on<GetMonthlyPerformanceDetailEvent>(_onGetMonthlyPerformanceDetail);
  }

  // ============================================================
  // MENU
  // ============================================================

  Future<void> _onGetMenus(GetMenuEvent event, Emitter<HomeState> emit) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final menus = await getMenuUsecase.getMenus(event.userId, event.menuType);

      print('bloc response$menus');

      emit(state.copyWith(status: HomeStatus.success, menus: menus));
    } catch (error) {
      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  // ============================================================
  // GRAPH API
  //
  // API:
  // getEmployeevisitcount
  //
  // RETURNS:
  // tot_dealer_cnt
  // tot_farmer_cnt
  // day_wise
  // ============================================================

  FutureOr<void> _onGetGraphCount(
    VisitGraphCountEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final graphcount = await getMenuUsecase.getVisitCountGraph(
        event.userId,
        event.searchFromDate,
        event.searchToDate,
      );

      debugPrint('========================================');

      debugPrint('GRAPH API RESPONSE: $graphcount');

      // ==========================================================
      // TOTAL DEALER
      // ==========================================================

      final String dealerCount =
          graphcount['tot_dealer_cnt']?.toString() ?? '0';

      // ==========================================================
      // TOTAL FARMER
      // ==========================================================

      final String farmerCount =
          graphcount['tot_farmer_cnt']?.toString() ?? '0';

      // ==========================================================
      // DAY WISE
      // ==========================================================

      final List<DayWiseVisitEntity> dayWiseList = [];

      final dynamic dayWiseData = graphcount['day_wise'];

      if (dayWiseData is List) {
        for (final item in dayWiseData) {
          if (item is Map) {
            dayWiseList.add(
              DayWiseVisitEntity(
                date: item['date']?.toString() ?? '',

                dealerCount: item['tot_dealer_cnt']?.toString() ?? '0',

                farmerCount: item['tot_farmer_cnt']?.toString() ?? '0',
              ),
            );
          }
        }
      }

      // ==========================================================
      // IMPORTANT
      //
      // KEEP EXISTING HOME SUMMARY DATA
      // AND ONLY UPDATE GRAPH DATA
      // ==========================================================

      final HomeVisitEntity? oldHomeData = state.homedata;

      final HomeVisitEntity updatedHomeData = HomeVisitEntity(
        currentMonth: oldHomeData?.currentMonth ?? '',

        // --------------------------------------------------------
        // EXISTING HOME API DATA
        // --------------------------------------------------------
        status: oldHomeData?.status ?? false,

        message: oldHomeData?.message ?? '',

        todayTotalVisit: oldHomeData?.todayTotalVisit ?? '0',

        todayDealerCnt: oldHomeData?.todayDealerCnt ?? '0',

        todayFarmerCnt: oldHomeData?.todayFarmerCnt ?? '0',

        monthlyTotalVisit: oldHomeData?.monthlyTotalVisit ?? '0',

        monthlyDealerCnt: oldHomeData?.monthlyDealerCnt ?? '0',

        monthlyFarmerCnt: oldHomeData?.monthlyFarmerCnt ?? '0',

        monthlyUniqueDealerCnt: oldHomeData?.monthlyUniqueDealerCnt ?? '0',

        monthlyUniqueFarmerCnt: oldHomeData?.monthlyUniqueFarmerCnt ?? '0',

        lastThirNotVisitDealer: oldHomeData?.lastThirNotVisitDealer ?? '0',

        lastThirNotVisitFarmer: oldHomeData?.lastThirNotVisitFarmer ?? '0',

        // --------------------------------------------------------
        // NEW GRAPH DATA
        // --------------------------------------------------------
        totalDealerCount: dealerCount,

        totalFarmerCount: farmerCount,

        dayWise: dayWiseList,
      );

      // ==========================================================
      // DEBUG
      // ==========================================================

      debugPrint(
        'GRAPH TOTAL DEALER: '
        '$dealerCount',
      );

      debugPrint(
        'GRAPH TOTAL FARMER: '
        '$farmerCount',
      );

      debugPrint(
        'GRAPH DAY WISE COUNT: '
        '${dayWiseList.length}',
      );

      for (final item in dayWiseList) {
        debugPrint(
          '${item.date} => '
          'Dealer: '
          '${item.dealerCount} | '
          'Farmer: '
          '${item.farmerCount}',
        );
      }

      debugPrint('========================================');

      // ==========================================================
      // UPDATE STATE
      // ==========================================================

      emit(
        state.copyWith(
          status: HomeStatus.success,

          // Keep these because your previous code uses them
          totalDealerCount: dealerCount,

          totalFarmerCount: farmerCount,

          // IMPORTANT FOR CURRENT HOME.DART
          homedata: updatedHomeData,
        ),
      );
    } catch (error) {
      debugPrint(
        'GRAPH API ERROR: '
        '$error',
      );

      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  // ============================================================
  // HOME VISIT API
  //
  // IMPORTANT:
  // When this API returns, KEEP graph data already stored
  // inside state.homedata.
  // ============================================================

  FutureOr<void> _onGetHomeVisitCount(
    GetHomeVisitEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final response = await getMenuUsecase.getHomeVisitCount(
        userId: event.userId,
      );

      print(
        'Block Data ++++++> : '
        '$response',
      );

      // ==========================================================
      // CURRENT GRAPH DATA
      //
      // It may already have been loaded by graph API.
      // ==========================================================

      final HomeVisitEntity? currentData = state.homedata;

      // ==========================================================
      // MERGE
      //
      // HOME API DATA
      // +
      // EXISTING GRAPH DATA
      // ==========================================================

      final HomeVisitEntity mergedData = HomeVisitEntity(
        currentMonth: response.currentMonth,

        // --------------------------------------------------------
        // DATA FROM HOME VISIT API
        // --------------------------------------------------------
        status: response.status,

        message: response.message,

        todayTotalVisit: response.todayTotalVisit,

        todayDealerCnt: response.todayDealerCnt,

        todayFarmerCnt: response.todayFarmerCnt,

        monthlyTotalVisit: response.monthlyTotalVisit,

        monthlyDealerCnt: response.monthlyDealerCnt,

        monthlyFarmerCnt: response.monthlyFarmerCnt,

        monthlyUniqueDealerCnt: response.monthlyUniqueDealerCnt,

        monthlyUniqueFarmerCnt: response.monthlyUniqueFarmerCnt,

        lastThirNotVisitDealer: response.lastThirNotVisitDealer,

        lastThirNotVisitFarmer: response.lastThirNotVisitFarmer,

        // --------------------------------------------------------
        // KEEP GRAPH DATA
        // --------------------------------------------------------
        totalDealerCount:
            currentData?.totalDealerCount ?? response.totalDealerCount,

        totalFarmerCount:
            currentData?.totalFarmerCount ?? response.totalFarmerCount,

        dayWise: currentData?.dayWise.isNotEmpty == true
            ? currentData!.dayWise
            : response.dayWise,
      );

      debugPrint('========================================');

      debugPrint('HOME DATA MERGED');

      debugPrint(
        'TODAY TOTAL: '
        '${mergedData.todayTotalVisit}',
      );

      debugPrint(
        'GRAPH DEALER: '
        '${mergedData.totalDealerCount}',
      );

      debugPrint(
        'GRAPH FARMER: '
        '${mergedData.totalFarmerCount}',
      );

      debugPrint(
        'GRAPH DAY WISE: '
        '${mergedData.dayWise.length}',
      );

      debugPrint('========================================');

      emit(state.copyWith(status: HomeStatus.success, homedata: mergedData));
    } catch (error) {
      debugPrint(
        'HOME VISIT API ERROR: '
        '$error',
      );

      emit(
        state.copyWith(
          status: HomeStatus.failure,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  // ============================================================
  // INPUNCH PENDING
  // PREVIOUS CODE KEPT
  // ============================================================

  FutureOr<void> _getInpunchPending(
    GetInpunchPendingEvent event,
    Emitter<HomeState> emit,
  ) async {
    emit(state.copyWith(status: HomeStatus.loading));

    try {
      final result = await getInpunchPendingUseCase.getInpunchPending(
        event.userId,
      );

      print('========================================');

      print('INPUNCH PENDING RESPONSE');

      print('Status: ${result.status}');

      print('Message: ${result.message}');

      print(
        'Total Recursive Employee: '
        '${result.totalRecursiveEmployee}',
      );

      print(
        'Pending Inpunch Count: '
        '${result.pendingInpunchCount}',
      );

      print(
        'Inpunch Time: '
        '${result.inpunchTime}',
      );

      print('Address: ${result.address}');

      print(
        'Result List Size: '
        '${result.result.length}',
      );

      print('========================================');

      emit(state.copyWith(status: HomeStatus.success, data: result));
    } catch (e) {
      debugPrint(
        'INPUNCH PENDING API ERROR: '
        '$e',
      );

      emit(
        state.copyWith(status: HomeStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  Future<void> _onGetMonthlyPerformance(
    GetMonthlyPerformanceEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      final response = await getInpunchPendingUseCase
          .getMonthlyPerformanceList();
      if (response.status == true) {
        emit(state.copyWith(monthlyPerformanceData: response));
      } else {
        debugPrint('EMPLOYEE OF THE MONTH: ${response.message}');
      }
    } catch (error) {
      debugPrint('EMPLOYEE OF THE MONTH: $error');
    }
  }

  FutureOr<void> _onGetMonthlyPerformanceDetail(
    GetMonthlyPerformanceDetailEvent event,
    Emitter<HomeState> emit,
  ) async {
    try {
      emit(state.copyWith(status: HomeStatus.monthlyPerformanceDetailLoading));

      final response = await getInpunchPendingUseCase
          .getMonthlyPerformanceDetailList();
      if (response.status == true) {
        emit(
          state.copyWith(
            status: HomeStatus.mothlyPerformanceDetailSuccess,
            monthlyPerformanceDetailData: response,
          ),
        );
      } else {
        debugPrint('EMPLOYEE OF THE MONTH DETAIL: ${response.message}');
        emit(
          state.copyWith(
            status: HomeStatus.monthlyPerformanceDetailFailure,
            errorMessage: response.message,
          ),
        );
      }
    } catch (error) {
      debugPrint('EMPLOYEE OF THE MONTH DETAIL: $error');
      emit(
        state.copyWith(
          status: HomeStatus.monthlyPerformanceDetailFailure,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
