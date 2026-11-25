import 'package:solufine/features/home/doman/home_entity/article_entity.dart';

class ArticleResponseModel extends ArticleResponseEntity {
  const ArticleResponseModel({
    required super.status,
    required super.message,
    required super.result,
  });

  factory ArticleResponseModel.fromJson(Map<String, dynamic> json) {
    return ArticleResponseModel(
      status: json['status'] == true,
      message: json['message']?.toString() ?? '',
      result: (json['result'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map((item) => ArticleModel.fromJson(item))
          .toList(),
    );
  }
}

class ArticleModel extends ArticleEntity {
  const ArticleModel({
    required super.articleId,
    required super.articlePath,
    required super.articleTitle,
    required super.articleType,
    required super.articleDescription,
  });

  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      articleId: json['fld_article_id']?.toString() ?? '',
      articlePath: json['fld_article_path']?.toString() ?? '',
      articleTitle: json['fld_article_title']?.toString() ?? '',
      articleType: json['fld_article_type']?.toString() ?? '',
      articleDescription: json['fld_article_description']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fld_article_id': articleId,
      'fld_article_path': articlePath,
      'fld_article_title': articleTitle,
      'fld_article_type': articleType,
      'fld_article_description': articleDescription,
    };
  }
}
