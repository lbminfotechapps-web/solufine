import 'package:equatable/equatable.dart';
import '../../domain/entities/quiz_response_entity.dart';

enum QuizStatus {
  initial,
  loading,
  success,
  failure,
}

class QuizState extends Equatable {

  final QuizStatus status;
  final QuizResponseEntity? quizResponse;
  final String errorMessage;

  const QuizState({
    this.status = QuizStatus.initial,
    this.quizResponse,
    this.errorMessage = '',
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizResponseEntity? quizResponse,
    String? errorMessage,
  }) {
    return QuizState(
      status: status ?? this.status,
      quizResponse: quizResponse ?? this.quizResponse,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status,
    quizResponse,
    errorMessage,
  ];
}