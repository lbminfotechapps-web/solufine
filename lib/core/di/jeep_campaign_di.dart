import 'package:solufine/core/api_constant/api_client.dart';

import 'package:get_it/get_it.dart';

import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/jeep_campaign/data/datasources/jeep_campaign_datasource.dart';
import 'package:solufine/features/marketing/jeep_campaign/data/repositories/jeep_campaign_repository_impl.dart';
import 'package:solufine/features/marketing/jeep_campaign/domain/repositories/jeep_campaign_repository.dart';
import 'package:solufine/features/marketing/jeep_campaign/domain/usecases/jeep_campaign_usecases.dart';
import 'package:solufine/features/marketing/jeep_campaign/presentation/bloc/jeep_campaign_bloc.dart';

final sl = GetIt.instance;

Future<void> initJeepCampaignDi() async {
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(() => DioClient());
  }

  if (!sl.isRegistered<JeepCampaignDataSource>()) {
    sl.registerLazySingleton<JeepCampaignDataSource>(
      () => JeepCampaignDataSource(
        sl<DioClient>(),

        // Set exact paths from Java Retrofit interface.
        seasonEndpoint: ApiClient.getSeason,
        productEndpoint: ApiClient.getProductListForSchedule,
      ),
    );
  }

  if (!sl.isRegistered<JeepCampaignRepository>()) {
    sl.registerLazySingleton<JeepCampaignRepository>(
      () => JeepCampaignRepositoryImpl(sl<JeepCampaignDataSource>()),
    );
  }

  if (!sl.isRegistered<GetJeepSeasons>()) {
    sl.registerLazySingleton<GetJeepSeasons>(
      () => GetJeepSeasons(sl<JeepCampaignRepository>()),
    );
  }

  if (!sl.isRegistered<SearchJeepProducts>()) {
    sl.registerLazySingleton<SearchJeepProducts>(
      () => SearchJeepProducts(sl<JeepCampaignRepository>()),
    );
  }

  if (!sl.isRegistered<SubmitJeepCampaign>()) {
    sl.registerLazySingleton<SubmitJeepCampaign>(
      () => SubmitJeepCampaign(sl<JeepCampaignRepository>()),
    );
  }

  if (!sl.isRegistered<JeepCampaignBloc>()) {
    sl.registerFactory<JeepCampaignBloc>(
      () => JeepCampaignBloc(
        getSeasons: sl<GetJeepSeasons>(),
        searchProducts: sl<SearchJeepProducts>(),
        submitCampaign: sl<SubmitJeepCampaign>(),
      ),
    );
  }
}
