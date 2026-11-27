import '../../domain/entities/quiz_response_entity.dart';
import 'quiz_question_model.dart';

class QuizResponseModel extends QuizResponseEntity {

  const QuizResponseModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory QuizResponseModel.fromJson(
    Map<String, dynamic> json,
  ) {
    return QuizResponseModel(

      status: json['status'] == true,

      message: json['message']?.toString() ?? '',

      result: (json['result'] as List? ?? [])
          .map(
            (e) => QuizQuestionModel.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          )
          .toList(),
    );
  }
}