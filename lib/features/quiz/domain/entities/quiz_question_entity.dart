import 'package:equatable/equatable.dart';
import 'quiz_answer_entity.dart';

class QuizQuestionEntity extends Equatable {

  final String questionId;
  final String batchNo;
  final String articleId;
  final String questionName;
  final List<QuizAnswerEntity> answers;

  const QuizQuestionEntity({
    required this.questionId,
    required this.batchNo,
    required this.articleId,
    required this.questionName,
    required this.answers,
  });

  @override
  List<Object?> get props => [
    questionId,
    batchNo,
    articleId,
    questionName,
    answers,
  ];
}