import '../entities/meeting_submission.dart';
import '../repositories/meeting_repository.dart';

class SubmitMeeting {
  const SubmitMeeting(this.repository);
  final MeetingRepository repository;

  Future<MeetingSubmissionResult> call(MeetingSubmission submission) {
    for (final key in ['userId', 'meetingDate', 'meetingType', 'farmerCrop']) {
      if (submission.fields[key]?.trim().isNotEmpty != true) {
        throw MeetingSubmissionException('Missing meeting field: $key');
      }
    }
    return repository.submit(submission);
  }
}
