import 'package:equatable/equatable.dart';

import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';
import 'package:solufine/features/home/doman/home_entity/inpunch_pending_entity.dart';
import 'package:solufine/features/home/doman/home_entity/menu_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_detail_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_entity.dart';

enum HomeStatus { initial, loading, success, failure,mothlyPerformanceDetailSuccess,monthlyPerformanceDetailFailure,monthlyPerformanceDetailLoading }

class HomeState extends Equatable {
  final MonthlyPerformanceDetailEntity? monthlyPerformanceDetailData;
  final HomeStatus status;

  final List<MenuEntity> menus;

  final String? errorMessage;

  // Existing old graph totals
  final String? totalDealerCount;
  final String? totalFarmerCount;

  // IMPORTANT:
  // Home page is reading graph + home summary from this object
  final HomeVisitEntity? homedata;
  final MonthlyPerformanceEntity? monthlyPerformanceData;
  final InpunchPendingResponseEntity? data;
  
  const HomeState({
    this.status = HomeStatus.initial,
    this.menus = const [],
    this.errorMessage,
    this.totalDealerCount,
    this.totalFarmerCount,
    this.homedata,
    this.monthlyPerformanceData,
    this.data,
    this.monthlyPerformanceDetailData,
  });

  HomeState copyWith({
    HomeStatus? status,
    List<MenuEntity>? menus,
    String? errorMessage,
    String? totalDealerCount,
    String? totalFarmerCount,
    HomeVisitEntity? homedata,
    MonthlyPerformanceEntity? monthlyPerformanceData,
    InpunchPendingResponseEntity? data,
    MonthlyPerformanceDetailEntity? monthlyPerformanceDetailData,
  }) {
    return HomeState(
      status: status ?? this.status,

      menus: menus ?? this.menus,

      errorMessage: errorMessage ?? this.errorMessage,

      totalDealerCount: totalDealerCount ?? this.totalDealerCount,

      totalFarmerCount: totalFarmerCount ?? this.totalFarmerCount,

      homedata: homedata ?? this.homedata,

      data: data ?? this.data,
      monthlyPerformanceData:
          monthlyPerformanceData ?? this.monthlyPerformanceData,
      monthlyPerformanceDetailData:
          monthlyPerformanceDetailData ?? this.monthlyPerformanceDetailData,
    );
  }

  @override
  List<Object?> get props => [
    status,
    menus,
    errorMessage,
    totalDealerCount,
    totalFarmerCount,
    homedata,
    data,
    monthlyPerformanceData,
    monthlyPerformanceDetailData,
  ];
}
