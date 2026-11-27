import '../../domain/entities/quiz_question_entity.dart';
import 'quiz_answer_model.dart';

class QuizQuestionModel extends QuizQuestionEntity {

  const QuizQuestionModel({
    required super.questionId,
    required super.batchNo,
    required super.articleId,
    required super.questionName,
    required super.answers,
  });

  factory QuizQuestionModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return QuizQuestionModel(

      questionId:
          json['fld_quiz_question_id']?.toString() ?? '',

      batchNo:
          json['fld_batch_no']?.toString() ?? '',

      articleId:
          json['fld_article_id']?.toString() ?? '',

      questionName:
          json['fld_question_name']?.toString() ?? '',

      answers: (json['answers'] as List? ?? [])
          .map(
            (e) => QuizAnswerModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}