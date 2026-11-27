import '../../domain/entities/quiz_answer_entity.dart';

class QuizAnswerModel extends QuizAnswerEntity {

  const QuizAnswerModel({
    required super.answerId,
    required super.questionId,
    required super.optionNo,
    required super.answer,
    required super.isCorrect,
  });

  factory QuizAnswerModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return QuizAnswerModel(

      answerId:
          json['fld_quiz_answer_id']?.toString() ?? '',

      questionId:
          json['fld_quiz_question_id']?.toString() ?? '',

      optionNo:
          json['fld_option_no']?.toString() ?? '',

      answer:
          json['fld_answer']?.toString() ?? '',

      isCorrect:
          json['fld_is_correct']?.toString() == '1',
    );
  }
}