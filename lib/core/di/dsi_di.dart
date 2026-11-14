
import 'package:get_it/get_it.dart';

import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/dsi/data/datasources/dsi_datasource.dart';
import 'package:solufine/features/marketing/dsi/data/repositories/dsi_repository_impl.dart';
import 'package:solufine/features/marketing/dsi/domain/repositories/dsi_repository.dart';
import 'package:solufine/features/marketing/dsi/domain/usecases/dsi_usecases.dart';
import 'package:solufine/features/marketing/dsi/presentation/bloc/dsi_bloc.dart';

Future<void> initDsiDi() async {
  final sl = GetIt.instance;

  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(
      () => DioClient(),
    );
  }

  if (!sl.isRegistered<DsiDataSource>()) {
    sl.registerLazySingleton<DsiDataSource>(
      () => DsiDataSource(sl<DioClient>()),
    );
  }

  if (!sl.isRegistered<DsiRepository>()) {
    sl.registerLazySingleton<DsiRepository>(
      () => DsiRepositoryImpl(
        sl<DsiDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<GetDsiList>()) {
    sl.registerLazySingleton<GetDsiList>(
      () => GetDsiList(
        sl<DsiRepository>(),
      ),
    );
  }

  if (!sl.isRegistered<SubmitDsi>()) {
    sl.registerLazySingleton<SubmitDsi>(
      () => SubmitDsi(
        sl<DsiRepository>(),
      ),
    );
  }

  if (!sl.isRegistered<DsiBloc>()) {
    sl.registerFactory<DsiBloc>(
      () => DsiBloc(
        getDsiList: sl<GetDsiList>(),
        submitDsi: sl<SubmitDsi>(),
      ),
    );
  }
}
