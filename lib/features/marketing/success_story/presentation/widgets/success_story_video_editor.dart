import 'package:solufine/core/theme/app_theme_context.dart';
import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:compress_video/compress_video.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

class SuccessStoryVideoEditor extends StatefulWidget {
  final ValueChanged<String?> onExportChanged;
  final ValueChanged<bool>? onBusyChanged;
  final bool uploadInProgress;

  const SuccessStoryVideoEditor({
    super.key,
    required this.onExportChanged,
    this.onBusyChanged,
    this.uploadInProgress = false,
  });

  @override
  State<SuccessStoryVideoEditor> createState() =>
      _SuccessStoryVideoEditorState();
}

class _SuccessStoryVideoEditorState extends State<SuccessStoryVideoEditor> {
  static const maxClipMs = 30000;

  final _picker = ImagePicker();
  final _compressor = CompressVideo();

  VideoPlayerController? _player;
  CompressJob? _job;

  String? _originalPath;
  String? _exportPath;

  int _durationMs = 0;
  int _startMs = 0;
  int _endMs = 0;
  int _originalSize = 0;
  int _exportSize = 0;

  bool _busy = false;
  bool _compressing = false;
  bool _previewExport = false;
  bool _disposed = false;

  double _progress = 0;
  int _generation = 0;

  final List<Uint8List?> _frames = [];
  Timer? _previewMonitor;
  double _dragX = 0;
  int _dragStart = 0;
  int _dragDuration = 0;

  int get _clipDurationMs => _endMs - _startMs;

  bool get _validClip => _clipDurationMs > 0 && _clipDurationMs <= maxClipMs;

  String _formatTime(int ms) {
    final duration = Duration(milliseconds: ms);
    final m = duration.inMinutes.toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatSize(int bytes) => '${(bytes / 1048576).toStringAsFixed(2)} MB';

  void _notify(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _setBusy(bool busy) {
    if (!mounted) return;
    setState(() => _busy = busy);
    widget.onBusyChanged?.call(busy);
  }

  Future<void> _deleteOutput(String? path) async {
    if (path == null || path == _originalPath) return;
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (e) {
      debugPrint('Video cleanup: $e');
    }
  }

  Future<ImageSource?> _chooseSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.cardBackgroundColor,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Choose Success Story Video',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
            ListTile(
              leading: Icon(Icons.videocam, color: context.primaryColor),
              title: const Text('Record Video'),
              onTap: () => Navigator.pop(sheet, ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.video_library, color: context.primaryColor),
              title: const Text('Select from Gallery'),
              onTap: () => Navigator.pop(sheet, ImageSource.gallery),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _selectVideo() async {
    if (_busy || widget.uploadInProgress) return;

    final source = await _chooseSource();
    if (source == null || !mounted) return;

    final generation = ++_generation;
    _stopPreviewMonitor();
    _setBusy(true);

    VideoPlayerController? candidate;

    try {
      // Gallery videos can be longer than 30 seconds.
      final picked = await _picker.pickVideo(source: source);

      if (picked == null || !mounted || generation != _generation) {
        return;
      }

      candidate = VideoPlayerController.file(File(picked.path));

      await candidate.initialize();

      if (!mounted || generation != _generation) return;

      final duration = candidate.value.duration.inMilliseconds;

      if (duration <= 0) {
        throw Exception('Video duration is invalid.');
      }

      final size = await File(picked.path).length();

      final oldPlayer = _player;
      final oldOutput = _exportPath;

      final newPlayer = candidate;
      candidate = null;

      setState(() {
        _player = newPlayer;
        _originalPath = picked.path;
        _exportPath = null;
        _previewExport = false;

        _durationMs = duration;
        _startMs = 0;
        _endMs = duration < maxClipMs ? duration : maxClipMs;
        _originalSize = size;
        _exportSize = 0;
        _progress = 0;

        _frames.clear();
      });

      widget.onExportChanged(null);

      await oldPlayer?.dispose();
      await _deleteOutput(oldOutput);

      unawaited(_generateThumbnails(picked.path, generation));
    } catch (e) {
      _notify('Unable to select video: $e');
    } finally {
      await candidate?.dispose();

      if (mounted && generation == _generation) {
        _setBusy(false);
      }
    }
  }

  // ============================================================
  // GENERATE REAL VIDEO-FRAME THUMBNAILS
  // ============================================================

  Future<void> _generateThumbnails(String videoPath, int generation) async {
    const count = 12;

    for (int i = 0; i < count; i++) {
      if (!mounted || generation != _generation) return;

      try {
        final timeMs = (_durationMs * (i + .5) / count).round();

        final bytes = await _compressor.getThumbnail(
          videoPath,
          positionMs: timeMs,
          maxDimensionPx: 170,
          quality: 55,
        );

        if (!mounted || generation != _generation) return;

        setState(() {
          // Preserve timeline order despite async generation.
          while (_frames.length < count) {
            _frames.add(null);
          }
          _frames[i] = bytes;
        });
      } catch (e) {
        debugPrint('Thumbnail $i failed: $e');
      }
    }
  }

  // ============================================================
  // TRIM RANGE
  // ============================================================

  Future<void> _updateRange(RangeValues values) async {
    if (_busy || widget.uploadInProgress || _previewExport) {
      return;
    }

    final start = values.start.round();
    final end = values.end.round();

    if (end <= start || end - start > maxClipMs) return;

    _stopPreviewMonitor();

    final oldOutput = _exportPath;

    setState(() {
      _startMs = start;
      _endMs = end;
      _exportPath = null;
      _exportSize = 0;
    });

    widget.onExportChanged(null);

    await _player?.pause();
    await _player?.seekTo(Duration(milliseconds: start));

    if (oldOutput != null) {
      await _deleteOutput(oldOutput);
    }
  }

  void _stopPreviewMonitor() {
    _previewMonitor?.cancel();
    _previewMonitor = null;
  }

  Future<void> _togglePlay() async {
    final player = _player;

    if (player == null || !player.value.isInitialized) {
      return;
    }

    if (player.value.isPlaying) {
      _stopPreviewMonitor();
      await player.pause();
      if (mounted) setState(() {});
      return;
    }

    if (!_previewExport) {
      await player.seekTo(Duration(milliseconds: _startMs));
    } else if (player.value.position >= player.value.duration) {
      await player.seekTo(Duration.zero);
    }

    await player.play();

    if (mounted) setState(() {});

    if (!_previewExport) {
      _previewMonitor = Timer.periodic(const Duration(milliseconds: 80), (
        timer,
      ) {
        if (!mounted || !identical(_player, player)) {
          timer.cancel();
          return;
        }

        if (!player.value.isPlaying) {
          timer.cancel();
          return;
        }

        if (player.value.position.inMilliseconds >= _endMs) {
          timer.cancel();
          unawaited(player.pause());
          unawaited(player.seekTo(Duration(milliseconds: _startMs)));
          if (mounted) setState(() {});
        }
      });
    }
  }

  // ============================================================
  // TRIM + COMPRESS VIDEO TO MP4
  // ============================================================

  Future<CompressResult> _compressClip(CompressOptions options) async {
    final job = _compressor.compress(_originalPath!, options: options);
    _job = job;
    final subscription = job.progress.listen((value) {
      if (mounted) {
        setState(() => _progress = value.clamp(0.0, 100.0));
      }
    });
    try {
      return await job.result;
    } finally {
      await subscription.cancel();
      if (identical(_job, job)) _job = null;
    }
  }

  Future<void> _export() async {
    if (_busy ||
        widget.uploadInProgress ||
        _originalPath == null ||
        !_validClip) {
      return;
    }

    _stopPreviewMonitor();
    _setBusy(true);

    setState(() {
      _compressing = true;
      _progress = 0;
    });

    String? pendingOutput;

    try {
      // Release the preview decoder before requesting export codec resources.
      final previewPlayer = _player;
      setState(() => _player = null);
      await previewPlayer?.dispose();
      if (!mounted) return;

      late CompressResult result;
      try {
        result = await _compressClip(
          CompressOptions(
            preset: CompressPreset.p720,
            trimStartMs: _startMs,
            trimEndMs: _endMs,
          ),
        );
      } on CompressVideoException catch (e) {
        if (e.reason != CompressVideoErrorReason.encoderUnavailable ||
            !mounted) {
          rethrow;
        }
        debugPrint('Retrying video export with a smaller H.264 format: $e');
        _notify(
          'Retrying with a smaller video format supported by this device.',
        );
        setState(() => _progress = 0);
        result = await _compressClip(
          CompressOptions(
            preset: CompressPreset.p360,
            videoBitrateBps: 600000,
            maxFps: 15,
            trimStartMs: _startMs,
            trimEndMs: _endMs,
          ),
        );
      }
      pendingOutput = result.outputPath;

      final outputFile = File(pendingOutput);

      if (!await outputFile.exists() || await outputFile.length() == 0) {
        throw Exception('Exported video is invalid.');
      }

      // Verify the export with the video player.
      final verified = VideoPlayerController.file(outputFile);
      await verified.initialize();

      if (!mounted) {
        await verified.dispose();
        return;
      }

      final actualDuration = verified.value.duration.inMilliseconds;

      if (actualDuration <= 0 || actualDuration > maxClipMs) {
        await verified.dispose();
        throw Exception(
          'Exported video exceeds 30 seconds. '
          'Try a slightly shorter clip.',
        );
      }

      final previousPlayer = _player;
      final previousOutput = _exportPath;
      final outputSize = await outputFile.length();

      setState(() {
        _player = verified;
        _previewExport = true;
        _exportPath = pendingOutput;
        _exportSize = outputSize;
        _progress = 100;
      });

      pendingOutput = null;

      widget.onExportChanged(_exportPath);

      await previousPlayer?.dispose();
      await _deleteOutput(previousOutput);

      _notify('Video trimmed and compressed successfully.');
    } on CompressVideoException catch (e, stackTrace) {
      debugPrint('Video export failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (e.reason == CompressVideoErrorReason.cancelled) {
        _notify('Video processing cancelled.');
      } else {
        _notify('Video processing failed: ${e.message}');
      }
    } catch (e, stackTrace) {
      debugPrint('Video export or preview verification failed: $e');
      debugPrintStack(stackTrace: stackTrace);
      _notify('Video processing failed: $e');
    } finally {
      await _deleteOutput(pendingOutput);
      _job = null;

      if (mounted) {
        setState(() => _compressing = false);
        _setBusy(false);
        if (_player == null) {
          await _switchPreview(_previewExport);
        }
      }
    }
  }

  // ============================================================
  // SWITCH ORIGINAL / EXPORTED PREVIEW
  // ============================================================

  Future<void> _switchPreview(bool showExport) async {
    if (_busy || widget.uploadInProgress) return;

    final path = showExport ? _exportPath : _originalPath;

    if (path == null) return;

    _stopPreviewMonitor();
    _setBusy(true);

    VideoPlayerController? candidate;

    try {
      candidate = VideoPlayerController.file(File(path));
      await candidate.initialize();

      if (!mounted) return;

      final old = _player;
      final next = candidate;
      candidate = null;

      setState(() {
        _player = next;
        _previewExport = showExport;
      });

      await old?.dispose();

      if (!showExport) {
        await next.seekTo(Duration(milliseconds: _startMs));
      }
    } catch (e) {
      _notify('Preview failed: $e');
    } finally {
      await candidate?.dispose();
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _removeVideo() async {
    if (_busy || widget.uploadInProgress) return;

    ++_generation;
    _stopPreviewMonitor();

    final oldPlayer = _player;
    final oldOutput = _exportPath;

    setState(() {
      _player = null;
      _originalPath = null;
      _exportPath = null;
      _durationMs = 0;
      _startMs = 0;
      _endMs = 0;
      _originalSize = 0;
      _exportSize = 0;
      _previewExport = false;
      _frames.clear();
    });

    widget.onExportChanged(null);

    await oldPlayer?.dispose();
    await _deleteOutput(oldOutput);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _stopPreviewMonitor();
    _job?.cancel();
    _player?.dispose();

    // Do not delete the exported file here: the
    // parent may still be uploading it.
    super.dispose();
  }

  // ============================================================
  // THUMBNAIL TIMELINE, LIKE YOUR SCREENSHOT
  // ============================================================

  Widget _timeline() {
    final total = _durationMs.toDouble();

    if (total <= 0) {
      return const SizedBox.shrink();
    }

    final range = RangeValues(_startMs.toDouble(), _endMs.toDouble());

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _timeLabel('START', _startMs, CrossAxisAlignment.start),
            _timeLabel('END', _endMs, CrossAxisAlignment.end),
          ],
        ),

        const SizedBox(height: 10),

        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final left = width * _startMs / total;
            final right = width * _endMs / total;

            return SizedBox(
              height: 89,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Row(
                      children: List.generate(12, (i) {
                        final frame = i < _frames.length ? _frames[i] : null;

                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 1.5,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                color:
                                    context.appColors.surfaceContainerHighest,
                                child: frame == null
                                    ? Icon(
                                        Icons.play_arrow,
                                        color: context.secondaryTextColor,
                                        size: 16,
                                      )
                                    : Image.memory(frame, fit: BoxFit.cover),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),

                  // Dark overlay outside selected range.
                  Positioned(
                    left: 0,
                    width: left,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        color: context.appColors.scrim.withValues(alpha: 0.54),
                      ),
                    ),
                  ),
                  Positioned(
                    left: right,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: Container(
                        color: context.appColors.scrim.withValues(alpha: 0.54),
                      ),
                    ),
                  ),

                  // Green highlighted selected clip.
                  Positioned(
                    left: left,
                    width: (right - left).clamp(0, width),
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragStart:
                          _busy || widget.uploadInProgress || _previewExport
                          ? null
                          : (details) {
                              _dragX = details.globalPosition.dx;
                              _dragStart = _startMs;
                              _dragDuration = _clipDurationMs;
                            },
                      onHorizontalDragUpdate:
                          _busy || widget.uploadInProgress || _previewExport
                          ? null
                          : (details) {
                              if (width <= 0) return;
                              final delta =
                                  ((details.globalPosition.dx - _dragX) /
                                          width *
                                          total)
                                      .round();
                              final start = (_dragStart + delta).clamp(
                                0,
                                _durationMs - _dragDuration,
                              );
                              if (start == _startMs) return;
                              unawaited(
                                _updateRange(
                                  RangeValues(
                                    start.toDouble(),
                                    (start + _dragDuration).toDouble(),
                                  ),
                                ),
                              );
                            },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: context.primaryColor,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 9),

        Text(
          'Drag the highlighted clip to move it; use the handles to trim.',
          style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
        ),

        // Interactive start/end handles.
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: context.primaryColor,
            inactiveTrackColor: context.borderColor,
            thumbColor: context.primaryColor,
            overlayColor: context.primaryColor.withValues(alpha: .20),
            trackHeight: 4,
          ),
          child: RangeSlider(
            min: 0,
            max: total,
            values: range,
            onChanged: _busy || widget.uploadInProgress || _previewExport
                ? null
                : (values) {
                    final start = values.start;
                    final end = values.end;

                    if (end - start > maxClipMs || end <= start) {
                      return;
                    }

                    unawaited(_updateRange(values));
                  },
          ),
        ),

        Row(
          children: [
            Text(
              '${(_clipDurationMs / 1000).toStringAsFixed(1)} '
              'seconds selected',
              style: TextStyle(fontSize: 12, color: context.primaryColor),
            ),
            const Spacer(),
            Text(
              'Max 30 seconds',
              style: TextStyle(fontSize: 11, color: context.secondaryTextColor),
            ),
          ],
        ),
      ],
    );
  }

  Widget _timeLabel(
    String label,
    int milliseconds,
    CrossAxisAlignment alignment,
  ) {
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          label,
          style: TextStyle(color: context.secondaryTextColor, fontSize: 9),
        ),
        const SizedBox(height: 3),
        Text(
          _formatTime(milliseconds),
          style: TextStyle(
            color: context.primaryTextColor,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // WIDGET DESIGN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final player = _player;
    final ready = player != null && player.value.isInitialized;

    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: context.cardBackgroundColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Success Story Video',
                  style: TextStyle(
                    color: context.primaryTextColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                'Max 30 sec export',
                style: TextStyle(
                  color: context.secondaryTextColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // VIDEO PREVIEW
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: GestureDetector(
              onTap: _busy ? null : _selectVideo,
              child: Container(
                height: 185,
                width: double.infinity,
                color: context.appColors.surfaceContainerHighest,
                child: ready
                    ? Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: AspectRatio(
                              aspectRatio: player.value.aspectRatio > 0
                                  ? player.value.aspectRatio
                                  : 16 / 9,
                              child: VideoPlayer(player),
                            ),
                          ),
                          IconButton.filled(
                            onPressed: _busy || widget.uploadInProgress
                                ? null
                                : _togglePlay,
                            icon: Icon(
                              player.value.isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: context.cardBackgroundColor,
                              foregroundColor: context.primaryColor,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.play_circle_fill,
                            color: context.primaryTextColor,
                            size: 38,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Selected Clip Preview',
                            style: TextStyle(
                              color: context.primaryTextColor,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          if (_originalPath == null)
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _busy ? null : _selectVideo,
                icon: const Icon(Icons.video_library_outlined),
                label: const Text('Record / Select Video'),
                style: FilledButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: context.onPrimaryColor,
                ),
              ),
            ),

          if (_originalPath != null) ...[
            Row(
              children: [
                Text(
                  'Original: ${_formatTime(_durationMs)}',
                  style: TextStyle(
                    color: context.secondaryTextColor,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                Text(
                  'Selected: ${_formatTime(_clipDurationMs)}',
                  style: TextStyle(
                    color: context.primaryColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            if (_exportPath == null) _timeline(),

            // if (_previewExport)
            //   Padding(
            //     padding: const EdgeInsets.symmetric(vertical: 14),
            //     child: Text(
            //       'Compressed video ready • ${_formatSize(_exportSize)}',
            //       style: TextStyle(
            //         color: context.primaryColor,
            //         fontWeight: FontWeight.w700,
            //       ),
            //     ),
            //   ),
            // const SizedBox(height: 12),
            if (_exportPath == null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy || widget.uploadInProgress || !_validClip
                      ? null
                      : _export,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: context.onPrimaryColor,
                  ),
                  icon: const Icon(Icons.content_cut),
                  label: const Text('Save Trim & Compress'),
                ),
              ),

            if (_compressing) ...[
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: _progress / 100,
                minHeight: 7,
                color: context.primaryColor,
              ),
              const SizedBox(height: 5),
              Text(
                'Processing ${_progress.toStringAsFixed(0)}%',
                style: TextStyle(color: context.secondaryTextColor),
              ),
              TextButton(
                onPressed: () => _job?.cancel(),
                child: const Text('Cancel'),
              ),
            ],

            if (_exportPath != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.check_circle, color: context.primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_formatSize(_originalSize)} → '
                      '${_formatSize(_exportSize)}',
                      style: TextStyle(
                        color: context.primaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _busy || widget.uploadInProgress
                        ? null
                        : _selectVideo,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Change Video'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.primaryTextColor,
                      side: BorderSide(color: context.borderColor),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _busy || widget.uploadInProgress
                      ? null
                      : _removeVideo,
                  icon: Icon(
                    Icons.delete_outline,
                    color: context.appColors.error,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
