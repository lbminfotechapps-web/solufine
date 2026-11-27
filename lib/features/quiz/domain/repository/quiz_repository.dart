import '../entities/quiz_response_entity.dart';

abstract class QuizRepository {

  Future<QuizResponseEntity> getQuizQuestions(
    String articleId,
  );
}