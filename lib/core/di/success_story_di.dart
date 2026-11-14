import 'package:solufine/features/schedule/data/datasources/farmer_schedule_remote_data_source.dart';

import 'package:get_it/get_it.dart';

import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/success_story/data/datasources/success_story_datasource.dart';
import 'package:solufine/features/marketing/success_story/data/repositories/success_story_repository_impl.dart';
import 'package:solufine/features/marketing/success_story/domain/repositories/success_story_repository.dart';
import 'package:solufine/features/marketing/success_story/domain/usecases/success_story_usecases.dart';
import 'package:solufine/features/marketing/success_story/presentation/bloc/success_story_bloc.dart';

final sl = GetIt.instance;

Future<void> initSuccessStoryDi() async {
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(() => DioClient());
  }

  if (!sl.isRegistered<SuccessStoryDataSource>()) {
    sl.registerLazySingleton<SuccessStoryDataSource>(
      () => SuccessStoryDataSource(
        sl<DioClient>(),
        farmerSearch: sl<FarmerScheduleRemoteDataSource>(),
      ),
    );
  }

  if (!sl.isRegistered<SuccessStoryRepository>()) {
    sl.registerLazySingleton<SuccessStoryRepository>(
      () => SuccessStoryRepositoryImpl(sl<SuccessStoryDataSource>()),
    );
  }

  if (!sl.isRegistered<SearchSuccessStoryFarmers>()) {
    sl.registerLazySingleton<SearchSuccessStoryFarmers>(
      () => SearchSuccessStoryFarmers(sl<SuccessStoryRepository>()),
    );
  }

  if (!sl.isRegistered<GetSuccessStoryCrops>()) {
    sl.registerLazySingleton<GetSuccessStoryCrops>(
      () => GetSuccessStoryCrops(sl<SuccessStoryRepository>()),
    );
  }

  if (!sl.isRegistered<SubmitSuccessStory>()) {
    sl.registerLazySingleton<SubmitSuccessStory>(
      () => SubmitSuccessStory(sl<SuccessStoryRepository>()),
    );
  }

  if (!sl.isRegistered<SuccessStoryBloc>()) {
    sl.registerFactory<SuccessStoryBloc>(
      () => SuccessStoryBloc(
        searchFarmers: sl<SearchSuccessStoryFarmers>(),
        getCrops: sl<GetSuccessStoryCrops>(),
        submitStory: sl<SubmitSuccessStory>(),
      ),
    );
  }
}
