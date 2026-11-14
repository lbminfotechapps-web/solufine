import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';
import 'package:solufine/features/home/doman/home_entity/inpunch_pending_entity.dart';
import 'package:solufine/features/home/doman/home_entity/menu_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_detail_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_entity.dart';

abstract class HomeRepo {
  Future<List<MenuEntity>> getMenus(int userID, String menuName);
  Future<Map<String, dynamic>> getVisitCountGraph(
    int userId,
    String searchFromDate,
    String searchToDate,
  );

  Future<HomeVisitEntity> getHomeVisitCount({required String userId});

  Future<InpunchPendingResponseEntity> getInpunchPending(String userId);
  Future<MonthlyPerformanceEntity> getMonthlyPerformanceList();

  Future<MonthlyPerformanceDetailEntity> getMonthlyPerformanceDetailList();
}
