import 'package:equatable/equatable.dart';

class ArticleResponseEntity extends Equatable {
  final bool status;
  final String message;
  final List<ArticleEntity> result;

  const ArticleResponseEntity({
    required this.status,
    required this.message,
    required this.result,
  });

  @override
  List<Object?> get props => [status, message, result];
}

class ArticleEntity extends Equatable {
  final String articleId;
  final String articlePath;
  final String articleTitle;
  final String articleType;
  final String articleDescription;

  const ArticleEntity({
    required this.articleId,
    required this.articlePath,
    required this.articleTitle,
    required this.articleType,
    required this.articleDescription,
  });

  bool get isImage => articleType.toLowerCase() == 'image';

  bool get isLink => articleType.toLowerCase() == 'link';

  @override
  List<Object?> get props => [
    articleId,
    articlePath,
    articleTitle,
    articleType,
    articleDescription,
  ];
}
