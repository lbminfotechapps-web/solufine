import 'package:equatable/equatable.dart';

class QuizAnswerEntity extends Equatable {

  final String answerId;
  final String questionId;
  final String optionNo;
  final String answer;
  final bool isCorrect;

  const QuizAnswerEntity({
    required this.answerId,
    required this.questionId,
    required this.optionNo,
    required this.answer,
    required this.isCorrect,
  });

  @override
  List<Object?> get props => [
    answerId,
    questionId,
    optionNo,
    answer,
    isCorrect,
  ];
}