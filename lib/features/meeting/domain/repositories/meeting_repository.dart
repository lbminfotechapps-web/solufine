import '../entities/meeting_submission.dart';

abstract class MeetingRepository {
  Future<MeetingSubmissionResult> submit(MeetingSubmission submission);
}
