import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/theme/typography/app_text_styles.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:solufine/features/quickchartreport/presentation/bloc/gallerybloc.dart';
import 'package:solufine/features/quickchartreport/presentation/bloc/galleryevent.dart';
import 'package:solufine/features/quickchartreport/presentation/bloc/gallerystate.dart';

class QuickReferencePage extends StatefulWidget {
  const QuickReferencePage({super.key});

  @override
  State<QuickReferencePage> createState() => _QuickReferencePageState();
}

class _QuickReferencePageState extends State<QuickReferencePage> {
  static const String baseFileUrl = ApiClient.imageGalleryUrl;

  @override
  void initState() {
    super.initState();
print("Helooooo");
    context.read<GalleryBloc>().add(const GetGalleryEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        title: 'Quick Reference Chart Report',

        showBackButton: true,
        onBackTap: () {
          context.go(AppRouter.home);
        },
      ),

      body: BlocBuilder<GalleryBloc, GalleryState>(
        builder: (context, state) {
          if (state.status == GalleryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == GalleryStatus.failure) {
            return _buildError(state.message);
          }

          if (state.galleryList.isEmpty) {
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<GalleryBloc>().add(const GetGalleryEvent());
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.galleryList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final gallery = state.galleryList[index];

                return _QuickReferenceCard(
                  title: gallery.title,
                  // date: gallery.date,
                  files: gallery.data,
                  baseFileUrl: baseFileUrl,
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 70,
            color: context.secondaryTextColor,
          ),
          SizedBox(height: 12),
          Text(
            'No quick reference found',
            style: AppTextStyles.body.copyWith(
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 60,
              color: context.appColors.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                context.read<GalleryBloc>().add(const GetGalleryEvent());
              },
              icon: const Icon(Icons.refresh),
              label: Text('Retry', style: AppTextStyles.button),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickReferenceCard extends StatelessWidget {
  final String title;
  // final String date;
  final List files;
  final String baseFileUrl;

  const _QuickReferenceCard({
    required this.title,
    // required this.date,
    required this.files,
    required this.baseFileUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
        boxShadow: [
          BoxShadow(
            color: context.appColors.shadow.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: context.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.cardTitle.copyWith(
                          height: 1.3,
                          color: context.primaryTextColor,
                        ),
                      ),
                      // const SizedBox(height: 6),
                      // Row(
                      //   children: [
                      //     Icon(
                      //       Icons.calendar_today_outlined,
                      //       size: 14,
                      //       color: context.secondaryTextColor,
                      //     ),
                      //     // const SizedBox(width: 5),
                      //     // Text(
                      //     //   date,
                      //     //   style: AppTextStyles.bodySmall.copyWith(
                      //     //     color: context.secondaryTextColor,
                      //     //   ),
                      //     // ),
                      //   ],
                      // ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            Divider(height: 1, color: context.borderColor),

            const SizedBox(height: 14),

            Text(
              files.length > 1 ? 'Available References' : 'Available Reference',
              style: AppTextStyles.label.copyWith(
                color: context.secondaryTextColor,
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: files.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final file = files[index];
                  final fileUrl = '$baseFileUrl${file.file}';
                  return SizedBox(
                    width: 250,
                    child: _ReferenceFileTile(
                      language: file.language,
                      fileUrl: fileUrl,
                      referenceFiles: files,
                      referenceTitle: title,
                      baseFileUrl: baseFileUrl,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReferenceFileTile extends StatelessWidget {
  final String language;
  final String fileUrl;

  final List referenceFiles;
  final String referenceTitle;
  final String baseFileUrl;

  const _ReferenceFileTile({
    required this.language,
    required this.fileUrl,
    required this.referenceFiles,
    required this.referenceTitle,
    required this.baseFileUrl,
  });

  bool get isPdf => fileUrl.toLowerCase().endsWith('.pdf');

  bool get isImage {
    final value = fileUrl.toLowerCase();

    return value.endsWith('.png') ||
        value.endsWith('.jpg') ||
        value.endsWith('.jpeg') ||
        value.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (isImage) {
          final images = <String>[];
          final titles = <String>[];
          for (final file in referenceFiles) {
            final url = '$baseFileUrl${file.file}';
            if (_isImageUrl(url)) {
              images.add(url);
              titles.add('$referenceTitle (${file.language})');
            }
          }
          final index = images.indexOf(fileUrl);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => QuickReferenceImagePage(
                imageUrl: fileUrl,
                title: language,
                imageUrls: images,
                titles: titles,
                initialIndex: index < 0 ? 0 : index,
              ),
            ),
          );
        }

        if (isPdf) {
          // Open PDF page here.
        }
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: context.appTheme.inputBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.borderColor),
        ),
        child: Row(
          children: [
            _buildPreview(context),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: context.primaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isPdf
                        ? 'PDF Document'
                        : isImage
                        ? 'Image Reference'
                        : 'Reference File',
                    style: AppTextStyles.caption.copyWith(
                      color: context.secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.visibility_outlined,
                size: 19,
                color: context.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(BuildContext context) {
    if (isImage) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          fileUrl,
          width: 58,
          height: 58,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildIconBox(context, Icons.broken_image_outlined);
          },
        ),
      );
    }

    if (isPdf) {
      return _buildIconBox(context, Icons.picture_as_pdf_outlined);
    }

    return _buildIconBox(context, Icons.insert_drive_file_outlined);
  }

  Widget _buildIconBox(BuildContext context, IconData icon) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        color: context.appTheme.inputBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 28, color: context.secondaryTextColor),
    );
  }
}

bool _isImageUrl(String url) {
  final path = Uri.parse(url).path.toLowerCase();
  return ['.png', '.jpg', '.jpeg', '.webp'].any(path.endsWith);
}

class QuickReferenceImagePage extends StatefulWidget {
  final String imageUrl;
  final String title;
  final List<String> imageUrls;
  final List<String> titles;
  final int initialIndex;

  const QuickReferenceImagePage({
    super.key,
    required this.imageUrl,
    required this.title,
    this.imageUrls = const [],
    this.titles = const [],
    this.initialIndex = 0,
  });

  @override
  State<QuickReferenceImagePage> createState() =>
      _QuickReferenceImagePageState();
}

class _QuickReferenceImagePageState extends State<QuickReferenceImagePage> {
  late final List<String> _images;
  late final PageController _pageController;
  late int _index;
  bool _sharing = false;
  bool _zoomed = false;
  final Set<int> _activePointers = {};
  Offset? _swipeStart;
  bool _canSwipe = false;
  late final List<TransformationController> _transforms = _createTransforms();

  @override
  void initState() {
    super.initState();
    _images = widget.imageUrls.isEmpty ? [widget.imageUrl] : widget.imageUrls;
    _index = widget.initialIndex.clamp(0, _images.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  List<TransformationController> _createTransforms() {
    return List.generate(_images.length, (_) {
      final controller = TransformationController();
      controller.addListener(_updateZoomState);
      return controller;
    });
  }

  String get _title =>
      _index < widget.titles.length ? widget.titles[_index] : widget.title;

  void _updateZoomState() {
    final zoomed = _transforms[_index].value.getMaxScaleOnAxis() > 1.01;
    if (mounted && zoomed != _zoomed) setState(() => _zoomed = zoomed);
  }

  void _setZoom(double scale, Size viewport) {
    final controller = _transforms[_index];
    final target = scale.clamp(1.0, 8.0).toDouble();
    final center = Offset(viewport.width / 2, viewport.height / 2);
    final scene = controller.toScene(center);
    controller.value = Matrix4.identity()
      ..setEntry(0, 0, target)
      ..setEntry(1, 1, target)
      ..setEntry(0, 3, center.dx - scene.dx * target)
      ..setEntry(1, 3, center.dy - scene.dy * target);
    if (target == 1) controller.value = Matrix4.identity();
  }

  void _pointerDown(PointerDownEvent event) {
    _activePointers.add(event.pointer);
    if (_activePointers.length == 1) {
      _swipeStart = event.position;
      _canSwipe = !_zoomed;
    } else {
      _canSwipe = false;
    }
  }

  void _pointerUp(PointerUpEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.isNotEmpty) return;
    final start = _swipeStart;
    _swipeStart = null;
    if (!_canSwipe || _zoomed || start == null) return;
    final delta = event.position - start;
    if (delta.dx.abs() > 60 && delta.dx.abs() > delta.dy.abs() * 1.5) {
      _changeSlide(_index + (delta.dx < 0 ? 1 : -1));
    }
  }

  void _changeSlide(int index) {
    if (index < 0 || index >= _images.length) return;
    _transforms[_index].value = Matrix4.identity();
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _shareImage(BuildContext buttonContext) async {
    if (_sharing) return;
    final uri = Uri.parse(_images[_index]);
    final title = _title;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;
    setState(() => _sharing = true);
    try {
      final response = await http.get(uri).timeout(const Duration(seconds: 30));
      final mimeType = response.headers['content-type']
          ?.split(';')
          .first
          .trim();
      if (response.statusCode != 200 ||
          response.bodyBytes.isEmpty ||
          (mimeType != null && !mimeType.startsWith('image/'))) {
        throw Exception('Image download failed');
      }
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          text: title,
          files: [XFile.fromData(response.bodyBytes, mimeType: mimeType)],
          fileNameOverrides: [uri.pathSegments.last],
          sharePositionOrigin: origin,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to share image. Please try again.',
              style: AppTextStyles.body,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _transforms) {
      controller.removeListener(_updateZoomState);
      controller.dispose();
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,

      appBar: CustomAppBar(
        title: _title,

        showBackButton: true,
        showThemeButton: false,
        action: Builder(
          builder: (buttonContext) => IconButton(
            tooltip: 'Share image',
            onPressed: _sharing ? null : () => _shareImage(buttonContext),
            icon: _sharing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(Icons.share_outlined),
          ),
        ),
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(
            constraints.maxWidth,
            constraints.maxHeight - 64,
          );
          return Column(
            children: [
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _images.length,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    _transforms[_index].value = Matrix4.identity();
                    setState(() {
                      _index = index;
                      _zoomed = false;
                    });
                  },
                  itemBuilder: (context, index) => Listener(
                    onPointerDown: _pointerDown,
                    onPointerUp: _pointerUp,
                    onPointerCancel: (event) {
                      _activePointers.remove(event.pointer);
                      _canSwipe = false;
                    },
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onDoubleTap: () => _setZoom(_zoomed ? 1 : 3, viewport),
                      child: InteractiveViewer(
                        transformationController: _transforms[index],
                        panEnabled: true,
                        scaleEnabled: true,
                        trackpadScrollCausesScale: true,
                        onInteractionEnd: (_) {
                          if (_transforms[index].value.getMaxScaleOnAxis() <=
                              1.01) {
                            _transforms[index].value = Matrix4.identity();
                          }
                        },
                        minScale: 1,
                        maxScale: 8,
                        boundaryMargin: EdgeInsets.zero,
                        child: Center(
                          child: Image.network(
                            _images[index],
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, progress) =>
                                progress == null
                                ? child
                                : Center(
                                    child: CircularProgressIndicator(
                                      color: context.primaryColor,
                                    ),
                                  ),
                            errorBuilder: (context, error, stackTrace) =>
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.broken_image_outlined,
                                      size: 60,
                                      color: context.secondaryTextColor,
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Unable to load image',
                                      style: AppTextStyles.body.copyWith(
                                        color: context.secondaryTextColor,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Previous image',
                      onPressed: _index > 0
                          ? () => _changeSlide(_index - 1)
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text(
                      '${_index + 1} / ${_images.length}',
                      style: AppTextStyles.body,
                    ),
                    IconButton(
                      tooltip: 'Next image',
                      onPressed: _index < _images.length - 1
                          ? () => _changeSlide(_index + 1)
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                    IconButton(
                      tooltip: 'Zoom out',
                      onPressed: () => _setZoom(
                        _transforms[_index].value.getMaxScaleOnAxis() / 1.5,
                        viewport,
                      ),
                      icon: const Icon(Icons.zoom_out),
                    ),
                    IconButton(
                      tooltip: 'Reset zoom',
                      onPressed: () => _setZoom(1, viewport),
                      icon: const Icon(Icons.fit_screen),
                    ),
                    IconButton(
                      tooltip: 'Zoom in',
                      onPressed: () => _setZoom(
                        _transforms[_index].value.getMaxScaleOnAxis() * 1.5,
                        viewport,
                      ),
                      icon: const Icon(Icons.zoom_in),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
