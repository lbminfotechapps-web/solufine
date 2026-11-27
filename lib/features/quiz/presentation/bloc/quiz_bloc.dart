import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

import '../../domain/usecases/get_quiz_questions_usecase.dart';
import 'quiz_event.dart';
import 'quiz_state.dart';

class QuizBloc extends Bloc<QuizEvent, QuizState> {

  final GetQuizQuestionsUseCase getQuizQuestionsUseCase;

  QuizBloc({
    required this.getQuizQuestionsUseCase,
  }) : super(const QuizState()) {

    on<GetQuizQuestionsEvent>(_onGetQuizQuestions);
  }

  Future<void> _onGetQuizQuestions(
    GetQuizQuestionsEvent event,
    Emitter<QuizState> emit,
  ) async {

    try {

      // STEP 1: Loading
      emit(
        const QuizState(
          status: QuizStatus.loading,
        ),
      );

      // STEP 2: Call UseCase
      final response = await getQuizQuestionsUseCase(
        event.articleId,
      );

      // STEP 3: Check response
      if (response.status) {

        emit(
          state.copyWith(
            status: QuizStatus.success,
            quizResponse: response,
          ),
        );

      } else {

        emit(
          state.copyWith(
            status: QuizStatus.failure,
            errorMessage: response.message,
          ),
        );
      }

    } catch (e, stackTrace) {

      debugPrint('QUIZ_API_ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      emit(
        state.copyWith(
          status: QuizStatus.failure,
          errorMessage: 'Unable to load quiz questions.',
        ),
      );
    }
  }
}