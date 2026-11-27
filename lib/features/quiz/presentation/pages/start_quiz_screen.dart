import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';

import 'package:solufine/core/utility/widgets/custom_appbar.dart';

import '../../domain/entities/quiz_question_entity.dart';

import '../bloc/quiz_bloc.dart';
import '../bloc/quiz_event.dart';
import '../bloc/quiz_state.dart';

class StartQuizScreen extends StatelessWidget {
  final String articleId;
  final String articleTitle;

  const StartQuizScreen({
    super.key,
    required this.articleId,
    required this.articleTitle,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<QuizBloc>(),
      child: _QuizView(
        articleId: articleId,
        articleTitle: articleTitle,
      ),
    );
  }
}

class _QuizView extends StatefulWidget {
  final String articleId;
  final String articleTitle;

  const _QuizView({
    required this.articleId,
    required this.articleTitle,
  });

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {

  // Store question ID and selected answer ID
  final Map<String, String> selectedAnswers = {};

  @override
  void initState() {
    super.initState();
    _getQuizQuestions();
  }

  // GET QUIZ QUESTIONS API
  void _getQuizQuestions() {
    context.read<QuizBloc>().add(
      GetQuizQuestionsEvent(
        articleId: widget.articleId,
      ),
    );
  }

  // SELECT ANSWER
  void _selectAnswer(
    String questionId,
    String answerId,
  ) {
    setState(() {
      selectedAnswers[questionId] = answerId;
    });

    debugPrint('QUESTION ID: $questionId');
    debugPrint('ANSWER ID: $answerId');
    debugPrint('SELECTED ANSWERS: $selectedAnswers');
  }

  // SUBMIT QUIZ
  void _submitQuiz(List<QuizQuestionEntity> questions) {

    // Validate all questions are answered
    final allAnswered = questions.every(
      (question) => question.answers.any(
        (answer) =>
            answer.answerId ==
            selectedAnswers[question.questionId],
      ),
    );

    if (!allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please answer all questions'),
        ),
      );
      return;
    }

    // Prepare selected answers
    final List<Map<String, String>> answerList =
        questions.map((question) {
      return {
        'question_id': question.questionId,
        'answer_id':
            selectedAnswers[question.questionId]!,
      };
    }).toList();
    

    // Prepare final request
    final Map<String, dynamic> requestData = {
      'article_id': widget.articleId,
      'answers': answerList,
    };

    // Convert into JSON
    final String jsonData = jsonEncode(requestData);

    debugPrint('================================');
    debugPrint('QUIZ SUBMIT DATA');
    debugPrint('ARTICLE ID: ${widget.articleId}');
    debugPrint('SELECTED ANSWERS: $answerList');
    debugPrint('FINAL JSON: $jsonData');
    debugPrint('================================');

    // Future submit API event will be called here

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All answers collected successfully'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: const CustomAppBar(
        title: 'Quiz',
        showBackButton: true,
      ),

      body: BlocBuilder<QuizBloc, QuizState>(
        builder: (context, state) {

          // INITIAL OR LOADING
          if (state.status == QuizStatus.loading ||
              state.status == QuizStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // FAILURE
          if (state.status == QuizStatus.failure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(state.errorMessage),

                  ElevatedButton(
                    onPressed: _getQuizQuestions,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // SUCCESS
          final questions =
              state.quizResponse?.result ?? [];

          if (questions.isEmpty) {
            return const Center(
              child: Text('No questions available'),
            );
          }

          final answeredCount = questions.where(
            (question) => question.answers.any(
              (answer) =>
                  answer.answerId ==
                  selectedAnswers[question.questionId],
            ),
          ).length;

          return Column(
            children: [

              // QUIZ HEADER
              _buildQuizHeader(
                context,
                questions.length,
                answeredCount,
              ),

              // QUESTION LIST
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    12, 4, 12, 12,
                  ),
                  itemCount: questions.length,

                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),

                  itemBuilder: (context, index) {
                    final question = questions[index];

                    return _buildQuestionCard(
                      context,
                      question,
                      index,
                    );
                  },
                ),
              ),

              // SUBMIT BUTTON
              _buildSubmitButton(
                context,
                questions,
                answeredCount,
              ),
            ],
          );
        },
      ),
    );
  }

  // =================================================
  // QUIZ HEADER
  // =================================================

  Widget _buildQuizHeader(
    BuildContext context,
    int totalQuestions,
    int answeredQuestions,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.articleTitle,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Text(
                'Total Questions: $totalQuestions',
                style: const TextStyle(fontSize: 12),
              ),

              const Spacer(),

              Text(
                '$answeredQuestions/$totalQuestions Answered',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: totalQuestions == 0
                  ? 0.0
                  : answeredQuestions / totalQuestions,
              minHeight: 5,
              backgroundColor:
                  colors.primary.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                colors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =================================================
  // QUESTION CARD
  // =================================================

  Widget _buildQuestionCard(
    BuildContext context,
    QuizQuestionEntity question,
    int index,
  ) {
    final colors = Theme.of(context).colorScheme;

    final isAnswered =
        selectedAnswers.containsKey(question.questionId);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // QUESTION NUMBER
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(
                  'Question ${index + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ),

              const Spacer(),

              if (isAnswered)
                Icon(
                  Icons.check_circle_rounded,
                  color: colors.primary,
                  size: 19,
                ),
            ],
          ),

          const SizedBox(height: 9),

          // QUESTION NAME
          Text(
            question.questionName,
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),

          const SizedBox(height: 10),

          // ANSWER OPTIONS
          ...question.answers.map((answer) {

            final isSelected =
                selectedAnswers[question.questionId] ==
                    answer.answerId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 7),

              child: Material(
                color: isSelected
                    ? colors.primary.withOpacity(0.07)
                    : colors.surface,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: isSelected
                        ? colors.primary
                        : colors.outlineVariant,
                    width: isSelected ? 1.2 : 0.8,
                  ),
                ),

                child: InkWell(
                  borderRadius: BorderRadius.circular(8),

                  onTap: () {
                    _selectAnswer(
                      question.questionId,
                      answer.answerId,
                    );
                  },

                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 11,
                    ),

                    child: Row(
                      children: [

                        // RADIO BUTTON ICON
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          size: 20,
                          color: isSelected
                              ? colors.primary
                              : colors.onSurfaceVariant,
                        ),

                        const SizedBox(width: 10),

                        // ANSWER TEXT
                        Expanded(
                          child: Text(
                            answer.answer,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.3,
                              color: isSelected
                                  ? colors.primary
                                  : colors.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // =================================================
  // SUBMIT QUIZ BUTTON
  // =================================================

  Widget _buildSubmitButton(
    BuildContext context,
    List<QuizQuestionEntity> questions,
    int answeredCount,
  ) {
    final colors = Theme.of(context).colorScheme;

    final bool allAnswered =
        answeredCount == questions.length;

    return SafeArea(
      top: false,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          12, 10, 12, 10,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(
            top: BorderSide(
              color: colors.outlineVariant,
              width: 0.8,
            ),
          ),
        ),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            if (!allAnswered) ...[
              Text(
                '${questions.length - answeredCount} '
                'questions remaining',
                style: TextStyle(
                  fontSize: 11,
                  color: colors.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 7),
            ],

            SizedBox(
              width: double.infinity,
              height: 44,

              child: ElevatedButton.icon(
                onPressed: allAnswered
                    ? () => _submitQuiz(questions)
                    : null,

                icon: const Icon(
                  Icons.check_circle_outline,
                  size: 19,
                ),

                label: const Text(
                  'Submit Quiz',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}