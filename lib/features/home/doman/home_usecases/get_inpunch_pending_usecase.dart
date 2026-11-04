import 'package:solufine/features/home/doman/home_entity/inpunch_pending_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_detail_entity.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_entity.dart';
import 'package:solufine/features/home/doman/home_repository/home_repo.dart';

class GetInpunchPendingUseCase {
  final HomeRepo repository;

  GetInpunchPendingUseCase({required this.repository});

  Future<InpunchPendingResponseEntity> getInpunchPending(String userId) async {
    return await repository.getInpunchPending(userId);
  }

  Future<MonthlyPerformanceEntity> getMonthlyPerformanceList() async {
    return await repository.getMonthlyPerformanceList();
  }

  Future<MonthlyPerformanceDetailEntity>
  getMonthlyPerformanceDetailList() async {
    return await repository.getMonthlyPerformanceDetailList();
  }
}
