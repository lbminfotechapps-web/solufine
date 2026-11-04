import 'package:solufine/features/home/data/home_datasource/home_datasource.dart';
import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';
import 'package:solufine/features/home/doman/home_entity/inpunch_pending_entity.dart';
import 'package:solufine/features/home/doman/home_entity/menu_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_detail_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_entity.dart';
import 'package:solufine/features/home/doman/home_repository/home_repo.dart';

class HomeRepoImp implements HomeRepo {
  final HomeDatasource homeDatasource;

  HomeRepoImp(this.homeDatasource);

  @override
  Future<List<MenuEntity>> getMenus(int userID, String menuName) async {
    final menus = await homeDatasource.fetchHomeMenu(userID, menuName);
    return menus;
  }

  @override
  Future<Map<String, dynamic>> getVisitCountGraph(
    int userId,
    String searchFromDate,
    String searchToDate,
  ) {
    return homeDatasource.fetchVisitCountGraph(
      userId,
      searchFromDate,
      searchToDate,
    );
  }

  @override
  Future<HomeVisitEntity> getHomeVisitCount({required String userId}) async {
    return await homeDatasource.getHomeVisitCount(userId: userId);
  }

  @override
  Future<InpunchPendingResponseEntity> getInpunchPending(String userId) async {
    return await homeDatasource.getInpunchPending(userId);
  }

  @override
  Future<MonthlyPerformanceEntity> getMonthlyPerformanceList() async {
    return await homeDatasource.getMonthlyPerformanceList();
  }

  @override
  Future<MonthlyPerformanceDetailEntity> getMonthlyPerformanceDetailList() {
    return homeDatasource.getMonthlyPerformanceDetailList();
  }
}
