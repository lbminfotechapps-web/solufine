import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/secure_storage/secure_storage.dart';
import 'package:solufine/core/utility/voice_remark_field.dart';

/// Use NextScreen inside a MaterialApp route.
/// If wrapping MaterialApp for app-wide screenshots, call toolbarButton
/// from a context inside the Navigator so the dialog can open.
class NextScreen extends StatefulWidget {
  final Widget? child;

  const NextScreen({
    super.key,
    this.child,
  });

  static Future<void> captureFromContext(
    BuildContext context,
  ) async {
    final state =
        context.findAncestorStateOfType<_NextScreenState>();

    if (state == null) {
      debugPrint(
        'SCREENSHOT ERROR: NextScreen ancestor not found',
      );
      return;
    }

    await state.captureScreenshot(context);
  }

  static Widget toolbarButton(BuildContext context) {
    return IconButton(
      tooltip: 'Take Screenshot',
      icon: const Icon(Icons.screenshot_rounded),
      onPressed: () => captureFromContext(context),
    );
  }

  @override
  State<NextScreen> createState() => _NextScreenState();
}

class _NextScreenState extends State<NextScreen> {
  // Create the key ONCE, never inside build().
  final GlobalKey _screenshotKey = GlobalKey();
  bool isCapturing = false;

  Future<void> captureScreenshot([BuildContext? sourceContext]) async {
    if (isCapturing || !mounted) return;

    // The wrapper's own context may be ABOVE MaterialApp/Navigator.
    // Prefer the triggering button context (which lives inside a route).
    final navigator = Navigator.maybeOf(sourceContext ?? context) ??
        Navigator.maybeOf(context);
    if (navigator == null) {
      debugPrint('SCREENSHOT ERROR: No Navigator found. Pass a button '
          'context inside MaterialApp, or place NextScreen inside a route.');
      return;
    }

    isCapturing = true;

    try {
      // Wait until layout and paint have finished before reading the boundary.
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;

      final renderObject =
          _screenshotKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary || !renderObject.attached) {
        throw StateError('Screenshot boundary is not ready');
      }

      if (renderObject.debugNeedsPaint) {
        await WidgetsBinding.instance.endOfFrame;
        if (!mounted) return;
      }

      final currentObject =
          _screenshotKey.currentContext?.findRenderObject();
      if (currentObject is! RenderRepaintBoundary ||
          !currentObject.attached ||
          currentObject.debugNeedsPaint) {
        throw StateError('Screenshot is still being painted. Try again.');
      }

      final ui.Image image = await currentObject.toImage(pixelRatio: 2.0);
      Uint8List bytes;
      try {
        final ByteData? data =
            await image.toByteData(format: ui.ImageByteFormat.png);
        if (data == null) throw StateError('Could not encode screenshot');
        bytes = data.buffer.asUint8List();
      } finally {
        image.dispose();
      }

      if (!mounted || !navigator.mounted) return;

      // Navigator context is guaranteed to be within the Navigator's tree.
      await showDialog<void>(
        context: navigator.context,
        barrierDismissible: false,
        builder: (_) => _ScreenshotDialog(
          screenshotBytes: bytes,
          upload: uploadScreenshot,
        ),
      );
    } catch (e, stack) {
      debugPrint('SCREENSHOT ERROR: $e\n$stack');
      if (mounted && navigator.mounted) {
        ScaffoldMessenger.maybeOf(navigator.context)?.showSnackBar(
          SnackBar(content: Text('Screenshot failed: $e')),
        );
      }
    } finally {
      isCapturing = false;
    }
  }

  // Preserved for existing callers that invoke this method directly.
  Future<void> showScreenshotDialog(
    Uint8List screenshotBytes,
    BuildContext sourceContext,
  ) async {
    if (!mounted) return;
    final navigator = Navigator.maybeOf(sourceContext) ?? Navigator.maybeOf(context);
    if (navigator == null || !navigator.mounted) {
      debugPrint('Cannot show screenshot dialog: Navigator not found');
      return;
    }
    await showDialog<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => _ScreenshotDialog(
        screenshotBytes: screenshotBytes,
        upload: uploadScreenshot,
      ),
    );
  }

  Future<bool> uploadScreenshot({
    required String remark,
    required String userId,
    required Uint8List screenshotBytes,
    String? voiceRemarkPath,
  }) async {
    // Keep your current development endpoint. Switch to HTTPS public endpoint
    // for production and verify backend support for the voice_remark field.
    const apiUrl =
        ApiClient.baseUrl;

    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );

    try {
      if (userId.trim().isEmpty) {
        debugPrint('UPLOAD: userId missing');
        return false;
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final screenshotFileName = 'screenshot_$now.png';
      final values = <String, dynamic>{
        'remark': remark,
        'userId': userId,
        'screenshot_photo': MultipartFile.fromBytes(
          screenshotBytes,
          filename: screenshotFileName,
          contentType: DioMediaType('image', 'png'),
        ),
      };

      if (voiceRemarkPath != null && voiceRemarkPath.trim().isNotEmpty) {
        final audioFile = File(voiceRemarkPath);
        if (!await audioFile.exists() || await audioFile.length() == 0) {
          debugPrint('UPLOAD: missing or empty audio: $voiceRemarkPath');
          return false;
        }
        values['voice_remark'] = await MultipartFile.fromFile(
          voiceRemarkPath,
          filename: 'voice_remark_$now.m4a',
          contentType: DioMediaType('audio', 'mp4'),
        );
      }

      debugPrint('==== ADD SCREENSHOT REQUEST ====');
      debugPrint('remark: $remark');
      debugPrint('userId: $userId');
      debugPrint('screenshot_photo: $screenshotFileName');
      debugPrint('screenshotBytes: ${screenshotBytes.length}');
      debugPrint('voice_remark: ${voiceRemarkPath ?? 'none'}');

      final response = await dio.post(
        apiUrl+"/add_screenshot",
        data: FormData.fromMap(values),
        options: Options(
          contentType: Headers.multipartFormDataContentType,
          responseType: ResponseType.json,
        ),
      );

      debugPrint('==== ADD SCREENSHOT RESPONSE ====');
      debugPrint('HTTP: ${response.statusCode}');
      debugPrint('Response: ${response.data}');

      dynamic body = response.data;
      if (body is String) body = jsonDecode(body);
      if (body is! Map) return false;
      final status = body['status'];
      debugPrint('API message: ${body['message']}');
      return status == true ||
          status == 1 ||
          status.toString().toLowerCase() == 'true' ||
          status.toString() == '1';
    } on DioException catch (e) {
      debugPrint('Dio error: ${e.message}');
      debugPrint('HTTP status: ${e.response?.statusCode}');
      debugPrint('Error response: ${e.response?.data}');
      return false;
    } catch (e, stack) {
      debugPrint('Upload error: $e\n$stack');
      return false;
    } finally {
      dio.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Keep the boundary mounted and keyed across captures/dialog changes.
    // Important: widget.child must be a normal screen/subtree, NOT MaterialApp.
    return RepaintBoundary(
      key: _screenshotKey,
      child: widget.child ??
          Scaffold(
            backgroundColor: const Color(0xFFF5F7FB),
            appBar: AppBar(
              title: const Text('Next Screen'),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  tooltip: 'Take Screenshot',
                  onPressed: isCapturing ? null : () => captureScreenshot(context),
                  icon: const Icon(Icons.camera_alt_outlined),
                ),
              ],
            ),
            body: const Center(
              child: Text('Welcome to Next Screen'),
            ),
          ),
    );
  }
}

typedef _ScreenshotUpload = Future<bool> Function({
  required String remark,
  required String userId,
  required Uint8List screenshotBytes,
  String? voiceRemarkPath,
});

class _ScreenshotDialog extends StatefulWidget {
  final Uint8List screenshotBytes;
  final _ScreenshotUpload upload;

  const _ScreenshotDialog({
    required this.screenshotBytes,
    required this.upload,
  });

  @override
  State<_ScreenshotDialog> createState() => _ScreenshotDialogState();
}

class _ScreenshotDialogState extends State<_ScreenshotDialog> {
  final TextEditingController _remarkController = TextEditingController();
  bool _isLoading = false;
  String? _voiceRemarkPath;

  void _showMessage(String message, {bool success = false}) {
    if (!mounted) return;
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _handleScreenshot({required bool shareAfterUpload}) async {
    if (_isLoading) return;
    final remark = _remarkController.text.trim();
    final audioPath = _voiceRemarkPath;

    if (remark.isEmpty && audioPath == null) {
      _showMessage('Please enter remark or record voice');
      return;
    }

    // If recording has started but not stopped, audioPath is still null.
    // The user must stop recording before submitting.
    if (audioPath != null && !await File(audioPath).exists()) {
      _showMessage('Voice recording file not found');
      return;
    }
    if (!mounted) return;

    setState(() => _isLoading = true);
    bool shouldClose = false;
    String? successMessage;

    try {
      final userId = await SecureStorage.instance.getFarmerId();
      if (!mounted) return;
      if (userId.trim().isEmpty) {
        _showMessage('User ID is missing');
        return;
      }

      final uploaded = await widget.upload(
        remark: remark,
        userId: userId,
        screenshotBytes: widget.screenshotBytes,
        voiceRemarkPath: audioPath,
      );
      if (!mounted) return;

      if (!uploaded) {
        _showMessage('Screenshot upload failed. Please try again.');
        return;
      }

      if (shareAfterUpload) {
        final now = DateTime.now().millisecondsSinceEpoch;
        final files = <XFile>[
          XFile.fromData(widget.screenshotBytes, mimeType: 'image/png'),
        ];
        final names = <String>['screenshot_$now.png'];

        if (audioPath != null && await File(audioPath).exists()) {
          files.add(XFile(audioPath, mimeType: 'audio/mp4'));
          names.add('voice_remark_$now.m4a');
        }
        if (!mounted) return;
        await SharePlus.instance.share(
          ShareParams(
            text: remark.isEmpty ? null : remark,
            files: files,
            fileNameOverrides: names,
          ),
        );
        if (!mounted) return;
      } else {
        successMessage = 'Screenshot and remark uploaded successfully';
      }

      shouldClose = true;
    } catch (e, stack) {
      debugPrint('SCREENSHOT / SHARE ERROR: $e\n$stack');
      _showMessage('Something went wrong: $e');
    } finally {
      if (mounted) {
        // One update while mounted; NEVER update State after Navigator.pop.
        setState(() => _isLoading = false);
      }
    }

    if (shouldClose && mounted) {
      final messenger = ScaffoldMessenger.maybeOf(context);
      Navigator.of(context).pop();
      if (successMessage != null) {
        messenger?.showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom - 40;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: availableHeight.clamp(1.0, double.infinity)),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Center(
                child: Text(
                  'Screenshot Preview',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                height: 210,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    widget.screenshotBytes,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Remark',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
              VoiceRemarkField(
                remarkController: _remarkController,
                isLoading: _isLoading,
                onAudioChanged: (path) {
                  if (!mounted) return;
                  setState(() => _voiceRemarkPath = path);
                  debugPrint('Voice remark: ${path ?? 'removed'}');
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading
                          ? null
                          : () => _handleScreenshot(shareAfterUpload: false),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => _handleScreenshot(shareAfterUpload: true),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
