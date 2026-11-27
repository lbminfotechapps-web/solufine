import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/features/quiz/data/datasource/quiz_remote_datasource.dart';
import 'package:solufine/features/quiz/data/repositories/quiz_repository_impl.dart';
import 'package:solufine/features/quiz/domain/repository/quiz_repository.dart';
import 'package:solufine/features/quiz/domain/usecases/get_quiz_questions_usecase.dart';
import 'package:solufine/features/quiz/presentation/bloc/quiz_bloc.dart';

void initQuizDI() {
  final sl = GetIt.instance;

  // 1. DataSource
  sl.registerLazySingleton<QuizRemoteDataSource>(
    () => QuizRemoteDataSource(
      Dio(
        BaseOptions(
          baseUrl: ApiClient.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
          contentType: Headers.formUrlEncodedContentType,
        ),
      ),
    ),
  );

  // 2. Repository
  sl.registerLazySingleton<QuizRepository>(
    () => QuizRepositoryImpl(
      sl<QuizRemoteDataSource>(),
    ),
  );

  // 3. UseCase
  sl.registerLazySingleton<GetQuizQuestionsUseCase>(
    () => GetQuizQuestionsUseCase(
      sl<QuizRepository>(),
    ),
  );

  // 4. BLoC
  sl.registerFactory<QuizBloc>(
    () => QuizBloc(
      getQuizQuestionsUseCase:
          sl<GetQuizQuestionsUseCase>(),
    ),
  );

  print('QUIZ DI REGISTERED: ${sl.isRegistered<QuizBloc>()}');
}