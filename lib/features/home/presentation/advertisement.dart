import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:compress_video/compress_video.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:solufine/core/router/app_router.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/theme/app_dynamic_colors.dart';
import '../doman/home_entity/advertisement_entity.dart';
import 'quick_aceess_bloc/quick_acess_bloc.dart';
import 'quick_aceess_bloc/quick_access_event.dart';
import 'quick_aceess_bloc/quick_access_state.dart';

class Advertisement extends StatefulWidget {
  const Advertisement({super.key});

  @override
  State<Advertisement> createState() => _AdvertisementState();
}

class _AdvertisementState extends State<Advertisement> {
  final _search = TextEditingController();
  Timer? _searchDebounce;
  AdvertisementItemEntity? _sharingItem;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _searchDebounce?.cancel();
    context.read<QuickAcessBloc>().add(
      AdvertisementEvent('', _search.text.trim()),
    );
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _load();
    });
  }

  Future<void> _refresh() async {
    final bloc = context.read<QuickAcessBloc>();
    final completed = bloc.stream.firstWhere(
      (state) =>
          state.advertisementStatus == QuickAccessStatus.success ||
          state.advertisementStatus == QuickAccessStatus.failure,
      orElse: () => bloc.state,
    );
    _load();
    await completed;
  }

  Widget _scrollableStatus(Widget child) => CustomScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    slivers: [
      SliverFillRemaining(hasScrollBody: false, child: Center(child: child)),
    ],
  );

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  Uri? _mediaUri(String path) {
    var value = path.trim();
    if (value.startsWith('//')) {
      value = 'https:$value';
    } else if (RegExp(
      r'^(www\.|(?:m\.|music\.)?youtube\.com/|youtu\.be/|(?:www\.)?youtube-nocookie\.com/)',
      caseSensitive: false,
    ).hasMatch(value)) {
      value = 'https://$value';
    }
    if (value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null) return null;
    if (uri.hasScheme) {
      return ['http', 'https'].contains(uri.scheme) ? uri : null;
    }
    final uploads = Uri.parse(ApiClient.advertisementImageBaseUrl);
    if (value.startsWith('/')) return uploads.resolve(value);
    if (value.startsWith('uploads/')) {
      return Uri.parse(ApiClient.imageBaseUrl).resolve('../$value');
    }
    if (value.startsWith('advertisement/')) {
      return Uri.parse(ApiClient.imageBaseUrl).resolve(value);
    }
    return uploads.resolve(value);
  }

  Future<void> _shareAdvertisement(
    AdvertisementItemEntity item,
    Uri? uri,
    BuildContext buttonContext,
  ) async {
    if (_sharingItem != null) return;
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box != null && box.hasSize
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    final title = item.advertisementTitle.trim().isEmpty
        ? 'Advertisement'
        : item.advertisementTitle.trim();
    setState(() => _sharingItem = item);
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    Directory? directory;
    bool sharedFile = false;
    try {
      XFile? attachment;
      final host = uri?.host.toLowerCase() ?? '';
      final isVideoPage =
          host == 'youtu.be' ||
          host == 'youtube.com' ||
          host.endsWith('.youtube.com') ||
          host == 'youtube-nocookie.com' ||
          host.endsWith('.youtube-nocookie.com');
      if (uri != null && !isVideoPage) {
        final cache = await getTemporaryDirectory();
        directory = await cache.createTemp('advertisement_share_');
        final name = uri.pathSegments.isEmpty
            ? 'advertisement'
            : uri.pathSegments.last;
        final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
        final filePath =
            '${directory.path}/${safeName.isEmpty ? 'advertisement' : safeName}';
        final response = await client.download(uri.toString(), filePath);
        final mimeType = response.headers
            .value('content-type')
            ?.split(';')
            .first
            .trim()
            .toLowerCase();
        // Web pages (including YouTube) are shared as links, not HTML attachments.
        if (mimeType != 'text/html' && mimeType != 'application/xhtml+xml') {
          if (await File(filePath).length() == 0) {
            throw StateError('The advertisement file is empty.');
          }
          attachment = XFile(filePath, mimeType: mimeType);
        }
      }
      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          subject: title,
          text: attachment != null || uri == null ? title : '$title\n$uri',
          files: attachment == null ? null : [attachment],
          sharePositionOrigin: origin,
        ),
      );
      // Receiving apps may read the file after the share sheet has closed.
      sharedFile = attachment != null;
    } catch (error) {
      debugPrint('Unable to share advertisement: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to share advertisement. Please try again.'),
          ),
        );
      }
    } finally {
      client.close(force: true);
      if (!sharedFile && directory != null) {
        try {
          await directory.delete(recursive: true);
        } catch (error) {
          debugPrint('Unable to clean advertisement share cache: $error');
        }
      }
      if (mounted) setState(() => _sharingItem = null);
    }
  }

  Future<void> _open(Uri uri) async {
    try {
      if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {
      /* Show the same feedback when launching fails. */
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Unable to open advertisement')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: CustomAppBar(
        title: 'Advertisements',

        showBackButton: true,

        onBackTap: () {
          context.go(AppRouter.home);
        },
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: 'Search advertisements',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              textInputAction: TextInputAction.search,
              onChanged: _onSearchChanged,
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              child: BlocBuilder<QuickAcessBloc, QuickAccessState>(
                buildWhen: (p, c) =>
                    p.advertisementStatus != c.advertisementStatus ||
                    p.advertisementData != c.advertisementData ||
                    p.advertisementError != c.advertisementError,
                builder: (context, state) {
                  if (state.advertisementStatus == QuickAccessStatus.initial ||
                      state.advertisementStatus == QuickAccessStatus.loading) {
                    return _scrollableStatus(const CircularProgressIndicator());
                  }
                  if (state.advertisementStatus == QuickAccessStatus.failure) {
                    return _scrollableStatus(
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              state.advertisementError.isEmpty
                                  ? 'Unable to load advertisements'
                                  : state.advertisementError,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  final items =
                      state.advertisementData?.result ??
                      const <AdvertisementItemEntity>[];
                  if (items.isEmpty)
                    return _scrollableStatus(
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('No advertisements found'),
                          TextButton(
                            onPressed: _load,
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    );
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _advertisementCard(items[index]),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _advertisementCard(AdvertisementItemEntity item) {
    final uri = _mediaUri(item.advertisementPath);

    debugPrint('Advertisement media: $uri');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (uri != null)
            InkWell(
              onTap: () => _open(uri),
              child: _AdvertisementMediaPreview(
                key: ValueKey(uri),
                uri: uri,
                isVideo: item.isVideo,
              ),
            ),
          ListTile(
            leading: Icon(
              item.isVideo
                  ? Icons.play_circle_outline
                  : item.isNews
                  ? Icons.newspaper
                  : Icons.campaign_outlined,
            ),
            title: Text(
              item.advertisementTitle.isEmpty
                  ? 'Advertisement'
                  : item.advertisementTitle,
            ),
            subtitle: item.advertisementType.isEmpty
                ? null
                : Text(item.advertisementType),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (uri != null) const Icon(Icons.open_in_new),
                Builder(
                  builder: (buttonContext) => IconButton(
                    tooltip: 'Share advertisement',
                    onPressed: _sharingItem != null
                        ? null
                        : () => _shareAdvertisement(item, uri, buttonContext),
                    icon: _sharingItem == item
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.share_outlined),
                  ),
                ),
              ],
            ),
            onTap: uri == null ? null : () => _open(uri),
          ),
        ],
      ),
    );
  }
}

class _AdvertisementMediaPreview extends StatefulWidget {
  const _AdvertisementMediaPreview({
    super.key,
    required this.uri,
    required this.isVideo,
  });

  final Uri uri;
  final bool isVideo;

  @override
  State<_AdvertisementMediaPreview> createState() =>
      _AdvertisementMediaPreviewState();
}

class _AdvertisementMediaPreviewState
    extends State<_AdvertisementMediaPreview> {
  static final _thumbnailCache = <Uri, Future<Uint8List>>{};
  Future<Uint8List>? _thumbnail;

  String? get _youtubeId {
    final uri = widget.uri;
    final host = uri.host.toLowerCase();
    String? id;
    if (host == 'youtu.be') {
      id = uri.pathSegments.firstOrNull;
    } else if (host == 'youtube.com' ||
        host.endsWith('.youtube.com') ||
        host == 'youtube-nocookie.com' ||
        host.endsWith('.youtube-nocookie.com')) {
      id = uri.queryParameters['v'];
      if (id == null &&
          uri.pathSegments.length >= 2 &&
          const ['embed', 'shorts', 'live'].contains(uri.pathSegments.first)) {
        id = uri.pathSegments[1];
      }
    }
    return id != null && RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)
        ? id
        : null;
  }

  bool get _isVideo =>
      widget.isVideo ||
      _youtubeId != null ||
      RegExp(
        r'\.(mp4|mov|m4v|webm|avi|m3u8)$',
        caseSensitive: false,
      ).hasMatch(widget.uri.path);

  @override
  void initState() {
    super.initState();
    _loadThumbnail();
  }

  @override
  void didUpdateWidget(covariant _AdvertisementMediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uri != widget.uri || oldWidget.isVideo != widget.isVideo) {
      _loadThumbnail();
    }
  }

  void _loadThumbnail() {
    _thumbnail = null;
    if (!_isVideo || _youtubeId != null) return;
    final uri = widget.uri;
    if (_thumbnailCache.length >= 20 && !_thumbnailCache.containsKey(uri)) {
      _thumbnailCache.remove(_thumbnailCache.keys.first);
    }
    _thumbnail = _thumbnailCache.putIfAbsent(uri, () => _extractThumbnail(uri));
  }

  static Future<Uint8List> _extractThumbnail(Uri uri) async {
    Directory? temporaryDirectory;
    final client = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    try {
      final cache = await getTemporaryDirectory();
      temporaryDirectory = await cache.createTemp('advertisement_preview_');
      final videoPath = '${temporaryDirectory.path}/video.mp4';
      await client.download(uri.toString(), videoPath);
      // Extract only a video frame; never initialize the clip's audio decoder.
      return await CompressVideo().getThumbnail(
        videoPath,
        positionMs: 0,
        quality: 80,
        maxDimensionPx: 640,
      );
    } catch (error) {
      _thumbnailCache.remove(uri);
      debugPrint('Advertisement thumbnail extraction failed: $error');
      rethrow;
    } finally {
      client.close(force: true);
      if (temporaryDirectory != null) {
        try {
          await temporaryDirectory.delete(recursive: true);
        } catch (error) {
          debugPrint('Unable to clean advertisement preview cache: $error');
        }
      }
    }
  }

  Widget _fallback() => const Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.broken_image_outlined, size: 32),
        SizedBox(height: 8),
        Text('Preview unavailable • Tap to open'),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final youtubeId = _youtubeId;

    final Widget content;
    if (_isVideo && youtubeId == null) {
      content = FutureBuilder<Uint8List>(
        future: _thumbnail,
        builder: (context, snapshot) {
          if (snapshot.hasError) return _fallback();
          final bytes = snapshot.data;
          if (bytes == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return Image.memory(
            bytes,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => _fallback(),
          );
        },
      );
    } else {
      content = Image.network(
        youtubeId == null
            ? widget.uri.toString()
            : 'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg',
        width: double.infinity,
        height: 180,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, progress) => progress == null
            ? child
            : const Center(child: CircularProgressIndicator()),
        errorBuilder: (_, _, _) => _fallback(),
      );
    }
    return SizedBox(
      height: 180,
      child: Stack(
        fit: StackFit.expand,
        children: [
          content,
          if (_isVideo)
            const Center(
              child: Icon(
                Icons.play_circle_fill,
                size: 48,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
