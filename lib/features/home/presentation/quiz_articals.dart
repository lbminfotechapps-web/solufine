import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:html/parser.dart' as html;
import 'package:solufine/features/quiz/presentation/pages/start_quiz_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/home/doman/home_entity/article_entity.dart';

import 'quick_aceess_bloc/quick_acess_bloc.dart';
import 'quick_aceess_bloc/quick_access_event.dart';
import 'quick_aceess_bloc/quick_access_state.dart';

class QuizArticals extends StatelessWidget {
  const QuizArticals({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.instance<QuickAcessBloc>(),
      child: const _ArticlesView(),
    );
  }
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
    _getArticles();
  }

  void _getArticles() {
    context.read<QuickAcessBloc>().add(GetArticleEvent());
  }

  Future<void> _refreshArticles() async {
    final bloc = context.read<QuickAcessBloc>();

    final completion = bloc.stream.firstWhere(
      (state) =>
          state.quickAccessStatus == QuickAccessStatus.success ||
          state.quickAccessStatus == QuickAccessStatus.failure,
    );

    bloc.add(GetArticleEvent());
    await completion;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,

      appBar: const CustomAppBar(
        title: 'Articles',
        showBackButton: true,
      ),

      body: BlocBuilder<QuickAcessBloc, QuickAccessState>(
        builder: (context, state) {
          if (state.quickAccessStatus ==
                  QuickAccessStatus.loading ||
              state.quickAccessStatus ==
                  QuickAccessStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (state.quickAccessStatus ==
                  QuickAccessStatus.failure ||
              state.articleResponseEntity?.status == false) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 46,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(height: 10),
                  const Text('Unable to load articles.'),
                  TextButton.icon(
                    onPressed: _getArticles,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final articles =
              state.articleResponseEntity?.result ?? [];

          if (articles.isEmpty) {
            return const Center(
              child: Text('No articles available.'),
            );
          }

          return RefreshIndicator(
            onRefresh: _refreshArticles,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
              itemCount: articles.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ArticleCard(
                  article: articles[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// =====================================================
// ARTICLE CARD
// =====================================================

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({
    required this.article,
  });

  final ArticleEntity article;

  String get articleType =>
      article.articleType.trim().toLowerCase();

  String get articleUrl {
    final path = article.articlePath.trim();

    if (path.isEmpty) return '';

    final uri = Uri.tryParse(path);

    if (uri != null && uri.hasScheme) {
      return uri.toString();
    }

    final baseUrl = ApiClient.imageBaseUrl.endsWith('/')
        ? ApiClient.imageBaseUrl
        : '${ApiClient.imageBaseUrl}/';

    return Uri.parse('${baseUrl}article/')
        .resolve(path)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outlineVariant.withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image, Video, PDF or URL
          _buildMedia(context),

          const SizedBox(height: 8),

          // Article Details
          _buildArticleDetails(context),
        ],
      ),
    );
  }

  // =====================================================
  // MEDIA BASED ON ARTICLE TYPE
  // =====================================================

  Widget _buildMedia(BuildContext context) {
    if (articleUrl.isEmpty) {
      return _buildUnavailable(context);
    }

    switch (articleType) {
      case 'image':
        return _buildImage(context);

      case 'video':
        return ArticleVideoPlayer(
          key: ValueKey(articleUrl),
          videoUrl: articleUrl,
        );

      case 'document':
      case 'pdf':
        return _buildDocument(context);

      case 'link':
      case 'url':
        return _buildLink(context);

      default:
        return _buildUnavailable(context);
    }
  }

  // =====================================================
  // IMAGE PREVIEW
  // =====================================================

  Widget _buildImage(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ArticleFullImageScreen(
              imageUrl: articleUrl,
              title: article.articleTitle,
            ),
          ),
        );
      },

      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: colors.surfaceContainerHighest,
                child: Image.network(
                  articleUrl,
                  width: double.infinity,
                  fit: BoxFit.contain,

                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;

                    return const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    );
                  },

                  errorBuilder: (_, __, ___) {
                    return const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 42,
                      ),
                    );
                  },
                ),
              ),
            ),

            // Full-screen icon
            Positioned(
              bottom: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Icon(
                  Icons.fullscreen_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =====================================================
  // PDF / DOCUMENT
  // =====================================================

  Widget _buildDocument(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primary.withOpacity(0.05),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),

        onTap: () {
          final path = Uri.tryParse(articleUrl)?.path ?? '';

          if (path.toLowerCase().endsWith('.pdf') ||
              articleType == 'pdf') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArticlePdfScreen(
                  pdfUrl: articleUrl,
                  title: article.articleTitle,
                ),
              ),
            );
          } else {
            _openUrl(context, articleUrl);
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                height: 58,
                width: 58,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  articleUrl.toLowerCase().contains('.pdf')
                      ? Icons.picture_as_pdf_rounded
                      : Icons.description_rounded,
                  size: 32,
                  color: Colors.red.shade700,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.articleTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      articleUrl.toLowerCase().contains('.pdf')
                          ? 'Tap to view PDF'
                          : 'Tap to view document',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // WEBSITE LINK
  // =====================================================

  Widget _buildLink(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Material(
      color: colors.primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openUrl(context, articleUrl),

        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.language_rounded,
                  size: 30,
                  color: colors.primary,
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      article.articleTitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      articleUrl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Icon(
                Icons.open_in_new_rounded,
                size: 20,
                color: colors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // ARTICLE DETAILS
  // =====================================================

 Widget _buildArticleDetails(BuildContext context) {
  final colors = Theme.of(context).colorScheme;

  final description = html
          .parse(article.articleDescription)
          .body
          ?.text
          .trim() ??
      '';

  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: colors.primary.withOpacity(0.025),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: colors.primary.withOpacity(0.12),
        width: 0.8,
      ),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getTypeIcon(),
              size: 19,
              color: colors.primary,
            ),
            const SizedBox(width: 7),
            Text(
              '${article.articleType} Details',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        Divider(
          height: 1,
          color: colors.outlineVariant.withOpacity(0.6),
        ),

        const SizedBox(height: 8),

        // Article Title
        _detailRow(
          context,
          'Title',
          Text(
            article.articleTitle,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        // Article URL
        if (articleType == 'link' ||
            articleType == 'url') ...[
          const SizedBox(height: 6),
          _detailRow(
            context,
            'Link',
            GestureDetector(
              onTap: () => _openUrl(context, articleUrl),
              child: Text(
                articleUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],

        // Article Description
        if (description.isNotEmpty) ...[
          const SizedBox(height: 6),
          _detailRow(
            context,
            'Description',
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                color: colors.onSurface,
              ),
            ),
          ),
        ],

        const SizedBox(height: 10),

        // Start Quiz Button
        Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            height: 34,
            child: ElevatedButton(
              onPressed: () {
                _startQuiz(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                ),
                minimumSize: Size.zero,
                tapTargetSize:
                    MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.quiz_outlined,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Start Quiz',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
  Widget _detailRow(
    BuildContext context,
    String label,
    Widget value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant,
            ),
          ),
        ),

        const Text(
          ' : ',
          style: TextStyle(fontSize: 12),
        ),

        const SizedBox(width: 4),

        Expanded(child: value),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (articleType) {
      case 'image':
        return Icons.image_outlined;

      case 'video':
        return Icons.videocam_rounded;

      case 'document':
      case 'pdf':
        return Icons.picture_as_pdf_outlined;

      case 'link':
      case 'url':
        return Icons.link_rounded;

      default:
        return Icons.article_outlined;
    }
  }

  Widget _buildUnavailable(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 30),
          SizedBox(height: 6),
          Text(
            'Preview unavailable',
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // OPEN EXTERNAL URL
  // =====================================================
void _startQuiz(BuildContext context) {

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => StartQuizScreen(
        articleId: article.articleId,
        articleTitle: article.articleTitle,
      ),
    ),
  );
}
  Future<void> _openUrl(
    BuildContext context,
    String url,
  ) async {
    try {
      final uri = Uri.tryParse(url);

      if (uri == null ||
          !['http', 'https'].contains(uri.scheme)) {
        throw Exception('Invalid URL');
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        throw Exception('Unable to open URL');
      }
    } catch (e) {
      debugPrint('URL_ERROR: $e');

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to open link.'),
        ),
      );
    }
  }
  
}
class ArticleVideoPlayer extends StatefulWidget {
  const ArticleVideoPlayer({
    super.key,
    required this.videoUrl,
  });

  final String videoUrl;

  @override
  State<ArticleVideoPlayer> createState() =>
      _ArticleVideoPlayerState();
}

class _ArticleVideoPlayerState
    extends State<ArticleVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _isLoading = false;
  bool _hasError = false;

  Future<void> _initializeVideo() async {
    if (_isLoading || _chewieController != null) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      _videoController = controller;

      await controller.initialize();

      if (!mounted) return;

      _chewieController = ChewieController(
        videoPlayerController: controller,
        aspectRatio: controller.value.aspectRatio > 0
            ? controller.value.aspectRatio
            : 16 / 9,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        showControls: true,

        materialProgressColors: ChewieProgressColors(
          playedColor: Theme.of(context).colorScheme.primary,
          handleColor: Colors.white,
          bufferedColor: Colors.white54,
          backgroundColor: Colors.white24,
        ),
      );

      setState(() {
        _isLoading = false;
      });

    } catch (e) {
      debugPrint('VIDEO_ERROR: $e');

      if (!mounted) return;

      final failedController = _videoController;
      _videoController = null;

      await failedController?.dispose();

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ColoredBox(
          color: Colors.black,
          child: _chewieController != null
              ? Chewie(controller: _chewieController!)
              : _buildPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white,
          strokeWidth: 2,
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white70,
              size: 32,
            ),
            const SizedBox(height: 8),
            const Text(
              'Unable to load video',
              style: TextStyle(color: Colors.white),
            ),
            TextButton.icon(
              onPressed: _initializeVideo,
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              label: const Text(
                'Retry',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _initializeVideo,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF243447),
                  Color(0xFF101820),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 58,
                  width: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.15),
                    border: Border.all(
                      color: Colors.white,
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to play video',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 7,
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '0:00',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: 0,
                      minHeight: 2,
                      backgroundColor: Colors.white38,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class ArticleFullImageScreen extends StatelessWidget {
  const ArticleFullImageScreen({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  final String imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          title,
          style: const TextStyle(fontSize: 16),
        ),
      ),

      body: SizedBox.expand(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 5,
          child: Center(
            child: Image.network(
              imageUrl,
              width: double.infinity,
              fit: BoxFit.contain,

              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                  ),
                );
              },

              errorBuilder: (_, __, ___) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 45,
                        color: Colors.white70,
                      ),

                      SizedBox(height: 10),

                      Text(
                        'Unable to load image',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
class ArticlePdfScreen extends StatefulWidget {
  const ArticlePdfScreen({
    super.key,
    required this.pdfUrl,
    required this.title,
  });

  final String pdfUrl;
  final String title;

  @override
  State<ArticlePdfScreen> createState() =>
      _ArticlePdfScreenState();
}

class _ArticlePdfScreenState
    extends State<ArticlePdfScreen> {
  final PdfViewerController _pdfController =
      PdfViewerController();

  int _currentPage = 1;
  int _totalPages = 0;

  bool _hasError = false;
  int _retryCount = 0;

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: widget.title,
        showBackButton: true,
      ),

      body: _hasError
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.picture_as_pdf_outlined,
                    size: 48,
                    color: colors.onSurfaceVariant,
                  ),

                  const SizedBox(height: 10),

                  const Text('Unable to load PDF'),

                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _currentPage = 1;
                        _totalPages = 0;
                        _retryCount++;
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SfPdfViewer.network(
                    widget.pdfUrl,
                    key: ValueKey(_retryCount),
                    controller: _pdfController,

                    enableDoubleTapZooming: true,
                    enableTextSelection: true,
                    canShowScrollHead: true,
                    canShowScrollStatus: true,

                    onDocumentLoaded: (details) {
                      if (!mounted) return;

                      setState(() {
                        _totalPages =
                            details.document.pages.count;
                      });
                    },

                    onPageChanged: (details) {
                      if (!mounted) return;

                      setState(() {
                        _currentPage =
                            details.newPageNumber;
                      });
                    },

                    onDocumentLoadFailed: (details) {
                      debugPrint(
                        'PDF_ERROR: ${details.description}',
                      );

                      if (!mounted) return;

                      setState(() {
                        _hasError = true;
                      });
                    },
                  ),
                ),

                if (_totalPages > 0)
                  SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: colors.surface,
                        border: Border(
                          top: BorderSide(
                            color: colors.outlineVariant,
                          ),
                        ),
                      ),

                      child: Row(
                        mainAxisAlignment:
                            MainAxisAlignment.center,
                        children: [
                          IconButton(
                            onPressed: _currentPage > 1
                                ? () {
                                    _pdfController
                                        .previousPage();
                                  }
                                : null,
                            icon: const Icon(
                              Icons.chevron_left_rounded,
                            ),
                          ),

                          Text(
                            'Page $_currentPage of $_totalPages',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          IconButton(
                            onPressed:
                                _currentPage < _totalPages
                                    ? () {
                                        _pdfController
                                            .nextPage();
                                      }
                                    : null,
                            icon: const Icon(
                              Icons.chevron_right_rounded,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}