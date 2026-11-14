import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:solufine/core/theme/app_theme_context.dart';
import 'package:solufine/core/utility/widgets/custom_appbar.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;

  const PdfViewerScreen({super.key, required this.pdfUrl});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  final Dio _client = Dio();
  final CancelToken _cancelToken = CancelToken();
  bool _downloading = false;
  double? _progress;

  Future<void> _downloadPdf() async {
    if (_downloading) return;
    setState(() {
      _downloading = true;
      _progress = null;
    });
    try {
      final response = await _client.get<List<int>>(
        widget.pdfUrl,
        options: Options(responseType: ResponseType.bytes),
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (mounted && total > 0) {
            setState(() => _progress = (received / total).clamp(0.0, 1.0));
          }
        },
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        throw const FormatException('Empty PDF');
      }
      final uri = Uri.parse(widget.pdfUrl);
      var name = uri.pathSegments.isEmpty
          ? 'report.pdf'
          : uri.pathSegments.last;
      name = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      if (name.isEmpty) name = 'report.pdf';
      if (!name.toLowerCase().endsWith('.pdf')) name = '$name.pdf';
      // Use the same persistent storage as the app's other PDF downloads.
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('PDF downloaded and saved in app storage.'),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              final result = await OpenFilex.open(
                file.path,
                type: 'application/pdf',
              );
              if (!mounted || result.type == ResultType.done) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No PDF app available to open this file.'),
                ),
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted || (error is DioException && CancelToken.isCancel(error))) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to download PDF. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  void dispose() {
    _cancelToken.cancel();
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: CustomAppBar(
        showThemeButton: false,
        title: 'Dealer List',
        showBackButton: true,
        onBackTap: () => context.go('/visits'),
        action: _downloading
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    value: _progress,
                    strokeWidth: 2,
                  ),
                ),
              )
            : IconButton(
                tooltip: 'Download PDF',
                onPressed: _downloadPdf,
                icon: const Icon(Icons.download_outlined),
              ),
      ),
      body: SfPdfViewer.network(widget.pdfUrl),
    );
  }
}
