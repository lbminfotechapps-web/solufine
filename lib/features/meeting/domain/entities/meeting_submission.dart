import 'dart:typed_data';

/// A confirmed legacy API payload. Values must be backend IDs, not UI labels.
class MeetingSubmission {
  MeetingSubmission({
    required Map<String, String> fields,
    List<MeetingAttachment> pictures = const [],
    this.kmReadingImage,
  }) : fields = Map.unmodifiable(fields),
       pictures = List.unmodifiable(pictures);

  final Map<String, String> fields;
  final List<MeetingAttachment> pictures;
  final MeetingAttachment? kmReadingImage;
}

class MeetingAttachment {
  MeetingAttachment({required this.filename, required List<int> bytes})
    : bytes = Uint8List.fromList(bytes).asUnmodifiableView();

  final String filename;
  final Uint8List bytes;
}

class MeetingSubmissionResult {
  const MeetingSubmissionResult({required this.message});
  final String message;
}

class MeetingSubmissionException implements Exception {
  const MeetingSubmissionException(this.message);
  final String message;

  @override
  String toString() => message;
}
