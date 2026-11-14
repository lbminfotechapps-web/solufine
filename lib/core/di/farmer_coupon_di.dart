import 'package:get_it/get_it.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/farmer_coupon_booking/data/datasources/farmer_coupon_datasource.dart';
import 'package:solufine/features/marketing/farmer_coupon_booking/data/repositories/farmer_coupon_repository_impl.dart';
import 'package:solufine/features/marketing/farmer_coupon_booking/domain/repositories/farmer_coupon_repository.dart';
import 'package:solufine/features/marketing/farmer_coupon_booking/domain/usecases/farmer_coupon_usecases.dart';
import 'package:solufine/features/marketing/farmer_coupon_booking/presentation/bloc/farmer_coupon_bloc.dart';

final sl = GetIt.instance;

Future<void> initFarmerCouponDi() async {
  // 1. DIO
  if (!sl.isRegistered<DioClient>()) {
    sl.registerLazySingleton<DioClient>(() => DioClient());
  }

  // 2. DATASOURCE
  if (!sl.isRegistered<FarmerCouponDataSource>()) {
    sl.registerLazySingleton<FarmerCouponDataSource>(
      () => FarmerCouponDataSource(
        sl<DioClient>(),

        // Share the farmer endpoint used by FarmerSchedulePage.
        farmerEndpoint: ApiClient.getScheduleFarmerList,

        // Share the product endpoint used by FarmerSchedulePage.
        productEndpoint: ApiClient.getProductListForSchedule,
      ),
    );
  }

  // 3. REPOSITORY
  if (!sl.isRegistered<FarmerCouponRepository>()) {
    sl.registerLazySingleton<FarmerCouponRepository>(
      () => FarmerCouponRepositoryImpl(sl<FarmerCouponDataSource>()),
    );
  }

  // 4. USE CASES
  if (!sl.isRegistered<SearchCouponFarmers>()) {
    sl.registerLazySingleton<SearchCouponFarmers>(
      () => SearchCouponFarmers(sl<FarmerCouponRepository>()),
    );
  }

  if (!sl.isRegistered<GetCouponProducts>()) {
    sl.registerLazySingleton<GetCouponProducts>(
      () => GetCouponProducts(sl<FarmerCouponRepository>()),
    );
  }

  if (!sl.isRegistered<SubmitFarmerCoupon>()) {
    sl.registerLazySingleton<SubmitFarmerCoupon>(
      () => SubmitFarmerCoupon(sl<FarmerCouponRepository>()),
    );
  }

  // 5. BLOC
  if (!sl.isRegistered<FarmerCouponBloc>()) {
    sl.registerFactory<FarmerCouponBloc>(
      () => FarmerCouponBloc(
        searchCouponFarmers: sl<SearchCouponFarmers>(),
        getCouponProducts: sl<GetCouponProducts>(),
        submitFarmerCoupon: sl<SubmitFarmerCoupon>(),
      ),
    );
  }
}
