
import 'dart:async';
import 'dart:io';

import 'package:compress_video/compress_video.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

class ProcessedVideo {
  final String path;
  final int originalBytes;
  final int outputBytes;
  final Duration duration;

  const ProcessedVideo({
    required this.path,
    required this.originalBytes,
    required this.outputBytes,
    required this.duration,
  });

  double get originalMB => originalBytes / (1024 * 1024);
  double get outputMB => outputBytes / (1024 * 1024);

  double get savedPercent => originalBytes == 0
      ? 0
      : (1 - outputBytes / originalBytes) * 100;
}

class VideoTrimCompressUtility {
  VideoTrimCompressUtility._();

  static final CompressVideo _compressor = CompressVideo();
  static CompressJob? _activeJob;

  static bool get isProcessing => _activeJob != null;

  // =====================================================
  // READ VIDEO DURATION
  // =====================================================

  static Future<Duration> getDuration(
    String path,
  ) async {
    final controller = VideoPlayerController.file(
      File(path),
    );

    try {
      await controller.initialize();
      return controller.value.duration;
    } finally {
      await controller.dispose();
    }
  }

  // =====================================================
  // TRIM + COMPRESS
  //
  // Pass start and end time in milliseconds.
  // Maximum exported duration: 30 seconds.
  // =====================================================

  static Future<ProcessedVideo> trimAndCompress({
    required String inputPath,
    required int startMs,
    required int endMs,
    void Function(double progress)? onProgress,
    CompressPreset preset = CompressPreset.p720,
  }) async {
    if (isProcessing) {
      throw StateError(
        'Another video is being processed.',
      );
    }

    final inputFile = File(inputPath);

    if (!await inputFile.exists()) {
      throw StateError('Video file not found.');
    }

    if (startMs < 0 ||
        endMs <= startMs ||
        endMs - startMs > 30000) {
      throw StateError(
        'Select a valid clip up to 30 seconds.',
      );
    }

    final inputDuration = await getDuration(inputPath);

    if (endMs > inputDuration.inMilliseconds) {
      throw StateError(
        'Selected end time exceeds video duration.',
      );
    }

    final originalBytes = await inputFile.length();

    final job = _compressor.compress(
      inputPath,
      options: CompressOptions(
        preset: preset,
        trimStartMs: startMs,
        trimEndMs: endMs,
      ),
    );

    _activeJob = job;

    final subscription = job.progress.listen(
      (progress) {
        onProgress?.call(
          progress.clamp(0.0, 100.0).toDouble(),
        );
      },
    );

    String? outputPath;

    try {
      final result = await job.result;
      outputPath = result.outputPath;

      final outputFile = File(outputPath);

      if (!await outputFile.exists() ||
          await outputFile.length() == 0) {
        throw StateError('Exported video is invalid.');
      }

      final outputDuration = await getDuration(outputPath);

      if (outputDuration <= Duration.zero ||
          outputDuration >
              const Duration(seconds: 30)) {
        throw StateError(
          'Exported video exceeds 30 seconds.',
        );
      }

      final outputBytes = await outputFile.length();

      debugPrint(
        'Video processed: '
        '${(originalBytes / 1048576).toStringAsFixed(2)} MB → '
        '${(outputBytes / 1048576).toStringAsFixed(2)} MB',
      );

      return ProcessedVideo(
        path: outputPath,
        originalBytes: originalBytes,
        outputBytes: outputBytes,
        duration: outputDuration,
      );
    } catch (_) {
      if (outputPath != null && outputPath != inputPath) {
        await deleteTemporaryFile(outputPath);
      }
      rethrow;
    } finally {
      await subscription.cancel();

      if (identical(_activeJob, job)) {
        _activeJob = null;
      }
    }
  }

  // =====================================================
  // COMPRESS WHOLE VIDEO WITHOUT TRIMMING
  // =====================================================

  static Future<ProcessedVideo> compressOnly({
    required String inputPath,
    void Function(double progress)? onProgress,
  }) async {
    final duration = await getDuration(inputPath);

    if (duration <= Duration.zero ||
        duration > const Duration(seconds: 30)) {
      throw StateError(
        'Video must be 30 seconds or less.',
      );
    }

    return trimAndCompress(
      inputPath: inputPath,
      startMs: 0,
      endMs: duration.inMilliseconds,
      onProgress: onProgress,
    );
  }

  // =====================================================
  // MULTIPART FOR DIO
  // =====================================================

  static Future<MultipartFile> toMultipart(
    String videoPath,
  ) async {
    final file = File(videoPath);

    if (!await file.exists()) {
      throw StateError('Video file not found.');
    }

    return MultipartFile.fromFile(
      videoPath,
      filename:
          'Video_${DateTime.now().millisecondsSinceEpoch}.mp4',
      contentType: DioMediaType('video', 'mp4'),
    );
  }

  // =====================================================
  // CANCEL PROCESSING
  // =====================================================

  static void cancel() {
    _activeJob?.cancel();
  }

  // =====================================================
  // DELETE TEMPORARY OUTPUT AFTER UPLOAD
  // =====================================================

  static Future<void> deleteTemporaryFile(
    String? path,
  ) async {
    if (path == null || path.isEmpty) return;

    try {
      final file = File(path);

      if (await file.exists()) {
        await file.delete();
      }
    } catch (error) {
      debugPrint('Video cleanup error: $error');
    }
  }
}
