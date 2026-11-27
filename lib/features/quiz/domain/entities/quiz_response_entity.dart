import 'package:equatable/equatable.dart';
import 'quiz_question_entity.dart';

class QuizResponseEntity extends Equatable {

  final bool status;
  final String message;
  final List<QuizQuestionEntity> result;

  const QuizResponseEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [
    status,
    message,
    result,
  ];
}