import '../entities/quiz_response_entity.dart';
import '../repository/quiz_repository.dart';

class GetQuizQuestionsUseCase {

  final QuizRepository repository;

  GetQuizQuestionsUseCase(this.repository);

  Future<QuizResponseEntity> call(
    String articleId,
  ) {
    return repository.getQuizQuestions(
      articleId,
    );
  }
}