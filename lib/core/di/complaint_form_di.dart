import 'package:get_it/get_it.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/complaint_form/data/datasource/complain_form_dsource.dart';
import 'package:solufine/features/marketing/complaint_form/data/repository/complain_form_repo_imp.dart';
import 'package:solufine/features/marketing/complaint_form/domain/repository/complaint_form_repo.dart';
import 'package:solufine/features/marketing/complaint_form/domain/usecase/complain_form_usecase.dart';
import 'package:solufine/features/marketing/complaint_form/presentation/bloc/complaint_bloc.dart';

Future<void> initComplaintFormDi() async {
  final sl = GetIt.instance;
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(() => DioClient());
  }
  if (!sl.isRegistered<ComplainFormDSource>()) {
    sl.registerLazySingleton<ComplainFormDSource>(
      () => ComplainFormDSource(sl<DioClient>()),
    );
  }
  if (!sl.isRegistered<ComplaintFormRepo>()) {
    sl.registerLazySingleton<ComplaintFormRepo>(
      () => ComplaintFormRepoImp(datasource: sl<ComplainFormDSource>()),
    );
  }
  if (!sl.isRegistered<ComplainFormUsecase>()) {
    sl.registerLazySingleton<ComplainFormUsecase>(
      () => ComplainFormUsecase(sl<ComplaintFormRepo>()),
    );
  }
  if (!sl.isRegistered<ComplaintBloc>()) {
    sl.registerFactory<ComplaintBloc>(
      () => ComplaintBloc(complaintFormUsecase: sl<ComplainFormUsecase>()),
    );
  }
}
