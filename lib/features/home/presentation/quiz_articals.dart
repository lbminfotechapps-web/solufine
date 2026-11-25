import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/parser.dart' as html;
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/home/doman/home_entity/article_entity.dart';
import 'quick_aceess_bloc/quick_acess_bloc.dart';
import 'quick_aceess_bloc/quick_access_event.dart';
import 'quick_aceess_bloc/quick_access_state.dart';

class QuizArticals extends StatelessWidget {
  const QuizArticals({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => GetIt.instance<QuickAcessBloc>(),
    child: const _ArticlesView(),
  );
}

class _ArticlesView extends StatefulWidget {
  const _ArticlesView();
  @override
  State<_ArticlesView> createState() => _QuizArticalsState();
}

class _QuizArticalsState extends State<_ArticlesView> {
  @override
  void initState() {
    super.initState();
    context.read<QuickAcessBloc>().add(GetArticleEvent());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const CustomAppBar(title: 'Articles', showBackButton: true),
    body: BlocBuilder<QuickAcessBloc, QuickAccessState>(
      builder: (context, state) {
        if (state.quickAccessStatus == QuickAccessStatus.loading || state.quickAccessStatus == QuickAccessStatus.initial) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.quickAccessStatus == QuickAccessStatus.failure || state.articleResponseEntity?.status == false) {
          return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Unable to load articles.'),
            TextButton(onPressed: () => context.read<QuickAcessBloc>().add(GetArticleEvent()), child: const Text('Retry')),
          ]));
        }
        final articles = state.articleResponseEntity?.result ?? [];
        if (articles.isEmpty) return const Center(child: Text('No articles available.'));
        return ListView.separated(
          padding: const EdgeInsets.all(16), itemCount: articles.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _ArticleCard(article: articles[index]),
        );
      },
    ),
  );
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article});
  final ArticleEntity article;
  @override
  Widget build(BuildContext context) {
    final description = html.parse(article.articleDescription).body?.text.trim() ?? '';
    final path = article.articlePath.trim();
    final uri = Uri.tryParse(path);
    final imageUrl = uri != null && uri.hasScheme ? uri.toString() : Uri.parse('${ApiClient.imageBaseUrl}article/').resolve(path).toString();
    final colors = Theme.of(context).colorScheme;
    return Card(clipBehavior: Clip.antiAlias, child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 90, height: 90,
          child: article.isImage && path.isNotEmpty
            ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder(colors))
            : _placeholder(colors))),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(article.articleTitle, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(article.articleType, style: Theme.of(context).textTheme.labelMedium),
          if (description.isNotEmpty) ...[const SizedBox(height: 6), Text(description, maxLines: 3, overflow: TextOverflow.ellipsis)],
        ])),
      ]),
    ));
  }
  Widget _placeholder(ColorScheme colors) => ColoredBox(
    color: colors.surfaceContainerHighest,
    child: Icon(article.isLink ? Icons.link : article.isImage ? Icons.image_outlined : Icons.play_circle_outline, color: colors.onSurfaceVariant, size: 36),
  );
}
