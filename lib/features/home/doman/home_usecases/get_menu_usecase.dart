import '../home_entity/monthly_performance_entity.dart';
import 'package:solufine/features/home/doman/home_entity/homevisit_entity.dart';
import 'package:solufine/features/home/doman/home_entity/menu_entity.dart';
import 'package:solufine/features/home/doman/home_repository/home_repo.dart';

class GetMenuUsecase {
  final HomeRepo homeRepo;

  Future<MonthlyPerformanceEntity> getMonthlyPerformanceList() =>
      homeRepo.getMonthlyPerformanceList();

  GetMenuUsecase(this.homeRepo);

  Future<List<MenuEntity>> getMenus(int userId, String menuName) async {
    try {
      return await homeRepo.getMenus(userId, menuName);
    } catch (e) {
      throw Exception('Failed to fetch home menu: $e');
    }
  }

  Future<Map<String, dynamic>> getVisitCountGraph(
    int userId,
    String searchFromDate,
    String searchToDate,
  ) async {
    try {
      return await homeRepo.getVisitCountGraph(
        userId,
        searchFromDate,
        searchToDate,
      );
    } catch (e) {
      throw Exception('Failed to fetch visit count graph: $e');
    }
  }

  Future<HomeVisitEntity> getHomeVisitCount({required String userId}) async {
    return await homeRepo.getHomeVisitCount(userId: userId);
  }
}
