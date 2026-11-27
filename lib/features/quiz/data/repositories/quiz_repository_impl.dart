import '../../domain/entities/quiz_response_entity.dart';
import '../../domain/repository/quiz_repository.dart';
import '../datasource/quiz_remote_datasource.dart';

class QuizRepositoryImpl implements QuizRepository {

  final QuizRemoteDataSource remoteDataSource;

  QuizRepositoryImpl(this.remoteDataSource);

  @override
  Future<QuizResponseEntity> getQuizQuestions(
    String articleId,
  ) {
    return remoteDataSource.getQuizQuestions(
      articleId,
    );
  }
}