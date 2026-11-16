import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/demodistributor/data/datasources/demo_distributor_remote_data_source.dart';
import 'package:solufine/features/marketing/demodistributor/data/repositories/demo_distributor_repository_impl.dart';
import 'package:solufine/features/marketing/demodistributor/domain/usecases/demo_distributor_usecases.dart';
import 'package:solufine/features/marketing/demodistributor/domain/usecases/get_demo_distributor_options.dart';
import 'package:solufine/features/marketing/demodistributor/presentation/bloc/demo_distributor_cubit.dart';


DemoDistributorCubit createDemoDistributorCubit(
  DioClient client,
) {
  final remoteDataSource = DemoDistributorRemoteDataSource(
    client,
  );

  final repository = DemoDistributorRepositoryImpl(
    remoteDataSource,
  );

  return DemoDistributorCubit(
    GetDemoDistributorOptions(repository),
    SubmitDemoDistributor(repository),
  );
}

