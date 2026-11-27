import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;

class GeoImageStampNew {
  static Future<File> addLocation({
    required File imageFile,
    required String latitude,
    required String longitude,
    required String address,
    String? dateTime,
  }) async {
    // ============================================================
    // 1. READ IMAGE
    // ============================================================

    if (!await imageFile.exists()) {
      throw Exception('Source image not found');
    }

    final bytes = await imageFile.readAsBytes();

    final ui.Codec codec =
        await ui.instantiateImageCodec(bytes);

    final ui.FrameInfo frame;

    try {
      frame = await codec.getNextFrame();
    } finally {
      codec.dispose();
    }

    final ui.Image image = frame.image;

    final List<TextPainter> painters = [];

    try {
      final double imageWidth = image.width.toDouble();

      final double imageHeight = image.height.toDouble();

      // ============================================================
      // 2. DYNAMIC FONT AND SPACING SETTINGS
      // ============================================================

      final double fontSize =
          (imageWidth * 0.035)
              .clamp(12.0, 48.0)
              .toDouble();

      final double padding =
          (imageWidth * 0.020)
              .clamp(8.0, 24.0)
              .toDouble();

      final double lineSpacing = fontSize * 0.20;

      final double availableWidth =
          imageWidth - (padding * 2);

      if (availableWidth <= 0) {
        throw Exception('Image too narrow for GPS text');
      }

      final TextStyle textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      );

      // ============================================================
      // 3. PREPARE DATE TIME AND GPS DETAILS
      // ============================================================

      final String capturedDateTime =
          dateTime != null && dateTime.trim().isNotEmpty
              ? dateTime.trim()
              : DateFormat('dd/MM/yyyy hh:mm:ss a')
                  .format(DateTime.now());

      final String dateTimeText =
          'Date & Time: $capturedDateTime';

      // NEW: LATITUDE AND LONGITUDE IN ONE ROW

      final String latLongText =
          'Lat: $latitude    Long: $longitude';

      final String cleanAddress =
          address.trim().isEmpty
              ? 'Not available'
              : address.trim();

      final String addressText =
          'Address: $cleanAddress';

      // ============================================================
      // 4. CREATE TEXT PAINTER
      // ============================================================

      TextPainter createPainter(
        String value, {
        bool singleLine = false,
      }) {
        final painter = TextPainter(
          text: TextSpan(
            text: value,
            style: textStyle,
          ),
          textDirection: ui.TextDirection.ltr,
          textAlign: TextAlign.left,
          maxLines: singleLine ? 1 : null,
        );

        painters.add(painter);

        // Automatically reduce font size to fit one row.
        if (singleLine) {
          painter.layout();

          if (painter.width > availableWidth) {
            final double adjustedFontSize =
                fontSize *
                (availableWidth / painter.width) *
                0.98;

            painter.text = TextSpan(
              text: value,
              style: textStyle.copyWith(
                fontSize: adjustedFontSize,
              ),
            );
          }
        }

        painter.layout(
          minWidth: 0,
          maxWidth: availableWidth,
        );

        return painter;
      }

      // ============================================================
      // 5. CREATE THREE TEXT PAINTERS
      // ============================================================

      // ROW 1: DATE AND TIME

      final TextPainter dateTimePainter =
          createPainter(
        dateTimeText,
        singleLine: true,
      );

      // ROW 2: LATITUDE AND LONGITUDE

      final TextPainter latLongPainter =
          createPainter(
        latLongText,
        singleLine: true,
      );

      // ROW 3: FULL ADDRESS

      final TextPainter addressPainter =
          createPainter(addressText);

      // ============================================================
      // 6. CALCULATE DYNAMIC GPS PANEL HEIGHT
      // ============================================================

      final double textHeight =
          dateTimePainter.height +
          latLongPainter.height +
          addressPainter.height +
          (lineSpacing * 2);

      final double panelHeight =
          (textHeight + (padding * 2)).ceilToDouble();

      final int outputWidth = image.width;

      final int outputHeight =
          image.height + panelHeight.ceil();

      // ============================================================
      // 7. CREATE CANVAS
      // ============================================================

      final ui.PictureRecorder recorder =
          ui.PictureRecorder();

      final Canvas canvas = Canvas(recorder);

      // Draw original photo without additional resizing.

      canvas.drawImage(
        image,
        Offset.zero,
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high,
      );

      // ============================================================
      // 8. DRAW BLACK GPS PANEL BELOW PHOTO
      // ============================================================

      canvas.drawRect(
        Rect.fromLTWH(
          0,
          imageHeight,
          imageWidth,
          panelHeight,
        ),
        Paint()
          ..color = const Color(0xFF17191B),
      );

      // ============================================================
      // 9. DRAW DATE AND TIME
      // ============================================================

      double currentY = imageHeight + padding;

      dateTimePainter.paint(
        canvas,
        Offset(padding, currentY),
      );

      currentY +=
          dateTimePainter.height + lineSpacing;

      // ============================================================
      // 10. DRAW LATITUDE AND LONGITUDE IN SAME ROW
      // ============================================================

      latLongPainter.paint(
        canvas,
        Offset(padding, currentY),
      );

      currentY +=
          latLongPainter.height + lineSpacing;

      // ============================================================
      // 11. DRAW COMPLETE ADDRESS
      // ============================================================

      addressPainter.paint(
        canvas,
        Offset(padding, currentY),
      );

      // ============================================================
      // 12. GENERATE FINAL STAMPED IMAGE
      // ============================================================

      final ui.Picture picture =
          recorder.endRecording();

      final ui.Image stampedImage;

      try {
        stampedImage = await picture.toImage(
          outputWidth,
          outputHeight,
        );
      } finally {
        picture.dispose();
      }

      try {
        final byteData =
            await stampedImage.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData == null) {
          throw Exception(
            'Failed to encode GPS image',
          );
        }

        // ========================================================
        // 13. SAVE IMAGE IN NEW FILE
        // ========================================================

        final String outputPath =
            '${imageFile.parent.path}'
            '${Platform.pathSeparator}'
            'gps_${DateTime.now().microsecondsSinceEpoch}.png';

        final File outputFile = File(outputPath);

        await outputFile.writeAsBytes(
          byteData.buffer.asUint8List(
            byteData.offsetInBytes,
            byteData.lengthInBytes,
          ),
          flush: true,
        );

        // ========================================================
        // 14. DEBUG LOGS
        // ========================================================

        debugPrint('========== GPS IMAGE STAMP ==========');

        debugPrint('Original Image: ${imageFile.path}');
        debugPrint('Stamped Image: ${outputFile.path}');

        debugPrint('Original Width: $imageWidth');
        debugPrint('Original Height: $imageHeight');

        debugPrint('Output Width: $outputWidth');
        debugPrint('Output Height: $outputHeight');

        debugPrint('GPS Panel Height: $panelHeight');
        debugPrint('Font Size: $fontSize');

        debugPrint('Date Time: $capturedDateTime');
        debugPrint('Latitude: $latitude');
        debugPrint('Longitude: $longitude');
        debugPrint('Address: $cleanAddress');

        debugPrint(
          'File size: '
          '${(await outputFile.length() / 1024).toStringAsFixed(2)} KB',
        );

        debugPrint('====================================');

        return outputFile;

      } finally {
        stampedImage.dispose();
      }

    } finally {
      for (final painter in painters) {
        painter.dispose();
      }

      image.dispose();
    }
  }
}