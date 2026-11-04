import 'dart:convert';
import 'package:dio/dio.dart';
import '../../domain/entities/meeting_submission.dart';

class MeetingSubmissionModel {
  const MeetingSubmissionModel(this.submission);
  final MeetingSubmission submission;

  FormData toFormData() {
    final form = FormData();
    form.fields.addAll(submission.fields.entries);
    void attach(String key, MeetingAttachment attachment) {
      form.files.add(
        MapEntry(
          key,
          MultipartFile.fromBytes(
            attachment.bytes,
            filename: attachment.filename,
          ),
        ),
      );
    }

    final kmImage = submission.kmReadingImage;
    if (kmImage != null) attach('kmReadingImage', kmImage);
    for (final picture in submission.pictures) {
      attach('pictures[]', picture);
    }
    return form;
  }

  static MeetingSubmissionResult parseResponse(Object? body) {
    Object? decoded = body;
    if (body is String) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        throw const MeetingSubmissionException(
          'Invalid meeting server response',
        );
      }
    }
    if (decoded is! Map) {
      throw const MeetingSubmissionException('Invalid meeting server response');
    }
    final status = decoded['status'];
    final success =
        status == true || status == 1 || status == '1' || status == 'true';
    final message = decoded['message']?.toString().trim() ?? '';
    if (!success) {
      throw MeetingSubmissionException(
        message.isEmpty
            ? 'Unable to submit meeting. Please try again.'
            : message,
      );
    }
    return MeetingSubmissionResult(
      message: message.isEmpty ? 'Meeting submitted successfully' : message,
    );
  }
}
