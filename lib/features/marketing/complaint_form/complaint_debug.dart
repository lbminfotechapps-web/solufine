import 'dart:io';
import 'package:flutter/foundation.dart';

/// Console tracing for the complaint submission flow in debug builds.
class ComplaintDebug {
  ComplaintDebug._();

  static void log(String stage, String message, [Object? data]) {
    if (!kDebugMode) return;
    debugPrint('[SubmitComplaintFormEvent][$stage] $message');
    if (data is Map) {
      for (final entry in data.entries) {
        debugPrint('  ${entry.key}: ${_describe(entry.value)}');
      }
    } else if (data != null) {
      debugPrint('  ${_describe(data)}');
    }
  }

  static Object? _describe(Object? value) {
    if (value is Uint8List) return '${value.length} bytes';
    if (value is File) return 'File(${value.uri.pathSegments.last})';
    if (value is List) return value.map(_describe).toList();
    return value;
  }

  static void error(String stage, Object error, StackTrace stack) {
    if (!kDebugMode) return;
    log(stage, 'FAILED', error);
    debugPrint(stack.toString());
  }
}
