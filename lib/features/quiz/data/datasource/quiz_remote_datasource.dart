import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import '../model/quiz_response_model.dart';

class QuizRemoteDataSource {
  final Dio dio;

  QuizRemoteDataSource(this.dio);

  Future<QuizResponseModel> getQuizQuestions(
    String articleId,
  ) async {
    final url =
        '${ApiClient.baseUrl}${ApiClient.getQuizQuestions}';

    debugPrint('QUIZ API URL: $url');
    debugPrint('QUIZ ARTICLE ID: $articleId');

    final response = await dio.post(
      url,
      data: {
        'article_id': articleId,
      },
      options: Options(
        contentType: Headers.formUrlEncodedContentType,
      ),
    );

    debugPrint('QUIZ STATUS CODE: ${response.statusCode}');
    debugPrint('QUIZ RESPONSE: ${response.data}');

    final data = response.data is String
        ? jsonDecode(response.data)
        : response.data;

    return QuizResponseModel.fromJson(
      Map<String, dynamic>.from(data as Map),
    );
  }
}