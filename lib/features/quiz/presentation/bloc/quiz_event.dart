import 'package:equatable/equatable.dart';

abstract class QuizEvent extends Equatable {

  const QuizEvent();

  @override
  List<Object?> get props => [];
}

class GetQuizQuestionsEvent extends QuizEvent {

  final String articleId;

  const GetQuizQuestionsEvent({
    required this.articleId,
  });

  @override
  List<Object?> get props => [articleId];
}