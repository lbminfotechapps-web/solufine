import 'package:get_it/get_it.dart';
import 'package:solufine/core/api_constant/api_client.dart';

import 'package:solufine/core/api_constant/dio_client.dart';

import 'package:solufine/features/marketing/field_visit/data/datasources/field_visit_datasource.dart';
import 'package:solufine/features/marketing/field_visit/data/repositories/field_visit_repository_impl.dart';
import 'package:solufine/features/marketing/field_visit/domain/repositories/field_visit_repository.dart';
import 'package:solufine/features/marketing/field_visit/domain/usecases/field_visit_usecases.dart';
import 'package:solufine/features/marketing/field_visit/presentation/bloc/field_visit_bloc.dart';

Future<void> initFieldVisitDi() async {
  final sl = GetIt.instance;

  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(() => DioClient());
  }

  if (!sl.isRegistered<FieldVisitDataSource>()) {
    sl.registerLazySingleton<FieldVisitDataSource>(
      () => FieldVisitDataSource(
        sl<DioClient>(),

        farmerEndpoint: ApiClient.getScheduleFarmerList,
        cropVarietyEndpoint: ApiClient.successStoryCrops,
      ),
    );
  }

  if (!sl.isRegistered<FieldVisitRepository>()) {
    sl.registerLazySingleton<FieldVisitRepository>(
      () => FieldVisitRepositoryImpl(sl<FieldVisitDataSource>()),
    );
  }

  if (!sl.isRegistered<SearchFieldVisitFarmers>()) {
    sl.registerLazySingleton<SearchFieldVisitFarmers>(
      () => SearchFieldVisitFarmers(sl<FieldVisitRepository>()),
    );
  }

  if (!sl.isRegistered<GetFieldVisitCrops>()) {
    sl.registerLazySingleton<GetFieldVisitCrops>(
      () => GetFieldVisitCrops(sl<FieldVisitRepository>()),
    );
  }

  if (!sl.isRegistered<SubmitFieldVisit>()) {
    sl.registerLazySingleton<SubmitFieldVisit>(
      () => SubmitFieldVisit(sl<FieldVisitRepository>()),
    );
  }

  if (!sl.isRegistered<FieldVisitBloc>()) {
    sl.registerFactory<FieldVisitBloc>(
      () => FieldVisitBloc(
        getCrops: sl<GetFieldVisitCrops>(),
        searchFarmers: sl<SearchFieldVisitFarmers>(),
        submitVisit: sl<SubmitFieldVisit>(),
      ),
    );
  }
}
