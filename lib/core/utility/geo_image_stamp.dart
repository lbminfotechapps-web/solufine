
import 'dart:io';
import 'dart:typed_data' as ui;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class GeoImageStamp {
  static Future<File> addLocation({
    required File imageFile,
    required String latitude,
    required String longitude,
    required String address,
    
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

    final ui.FrameInfo frame =
        await codec.getNextFrame();

    final ui.Image image = frame.image;

    codec.dispose();

    try {
      final double imageWidth =
          image.width.toDouble();

      final double imageHeight =
          image.height.toDouble();

      // ============================================================
      // 2. FONT SETTINGS - FIXED 14 BOLD
      // ============================================================

      const double fontSize = 14.0;
      const double padding = 12.0;
      const double lineSpacing = 6.0;

      final double availableWidth =
          imageWidth - (padding * 2);

      if (availableWidth <= 0) {
        throw Exception('Image too narrow for GPS text');
      }

      const TextStyle textStyle = TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.3,
      );

      // ============================================================
      // 3. PREPARE LATITUDE, LONGITUDE AND ADDRESS
      // ============================================================

      final String latText =
          'Lat: $latitude';

      final String longText =
          'Long: $longitude';

      final String cleanAddress =
          address.trim().isEmpty
              ? 'Not available'
              : address.trim();

      final String addressText =
          'Address: $cleanAddress';

      // ============================================================
      // 4. TEXT PAINTER - NO copyWith ERROR
      // ============================================================

        TextPainter createPainter(String value) {
          final painter = TextPainter(
            text: TextSpan(
              text: value,
              style: textStyle,
            ),
            textDirection: TextDirection.ltr,
            textAlign: TextAlign.left,
          );

          painter.layout(
            minWidth: 0,
            maxWidth: availableWidth,
          );

          return painter;
        }

      final TextPainter latPainter =
          createPainter(latText);

      final TextPainter longPainter =
          createPainter(longText);

      final TextPainter addressPainter =
          createPainter(addressText);

      // ============================================================
      // 5. CALCULATE DYNAMIC PANEL HEIGHT
      // ============================================================

      final double textHeight =
          latPainter.height +
          longPainter.height +
          addressPainter.height +
          (lineSpacing * 2);

      final double panelHeight =
          (textHeight + (padding * 2))
              .ceilToDouble();

      final int outputWidth =
          image.width;

      // NEW: Add extra height for GPS information.
      final int outputHeight =
          image.height + panelHeight.ceil();

      // ============================================================
      // 6. CREATE CANVAS
      // ============================================================

      final ui.PictureRecorder recorder =
          ui.PictureRecorder();

      final Canvas canvas = Canvas(recorder);

      // Draw existing compressed photo.
      canvas.drawImage(
        image,
        Offset.zero,
        Paint(),
      );

      // ============================================================
      // 7. DRAW BLACK GPS PANEL BELOW PHOTO
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
      // 8. PRINT LAT, LONG, AND FULL ADDRESS
      // ============================================================

      double currentY =
          imageHeight + padding;

      latPainter.paint(
        canvas,
        Offset(padding, currentY),
      );

      currentY +=
          latPainter.height + lineSpacing;

      longPainter.paint(
        canvas,
        Offset(padding, currentY),
      );

      currentY +=
          longPainter.height + lineSpacing;

      addressPainter.paint(
        canvas,
        Offset(padding, currentY),
      );

      // ============================================================
      // 9. GENERATE FINAL STAMPED IMAGE
      // ============================================================

      final ui.Picture picture =
          recorder.endRecording();

      final ui.Image stampedImage =
          await picture.toImage(
        outputWidth,
        outputHeight,
      );

      picture.dispose();

      try {
        final ui.ByteData? byteData =
            await stampedImage.toByteData(
          format: ui.ImageByteFormat.png,
        );

        if (byteData == null) {
          throw Exception(
            'Failed to encode GPS image',
          );
        }

        // NEW FILE: avoids stale preview image cache.
        final String outputPath =
            '${imageFile.parent.path}'
            '${Platform.pathSeparator}'
            'gps_${DateTime.now().microsecondsSinceEpoch}.png';

        final File outputFile = File(outputPath);

        await outputFile.writeAsBytes(
          byteData.buffer.asUint8List(),
          flush: true,
        );

        // ========================================================
        // 10. LOGS
        // ========================================================

        debugPrint(
          '========== GPS IMAGE STAMP =========='
        );

        debugPrint('Image: ${outputFile.path}');
        debugPrint('Width: $outputWidth');
        debugPrint('Height: $outputHeight');
        debugPrint('Font: 14 bold');
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
      image.dispose();
    }
  }
}
