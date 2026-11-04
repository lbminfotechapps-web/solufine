import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/meeting_submission.dart';
import '../../domain/usecases/submit_meeting.dart';

enum MeetingSubmissionStatus { initial, submitting, success, failure }

class MeetingSubmissionState {
  const MeetingSubmissionState(this.status, {this.message = ''});
  final MeetingSubmissionStatus status;
  final String message;
}

class MeetingSubmissionCubit extends Cubit<MeetingSubmissionState> {
  MeetingSubmissionCubit(this._submit)
    : super(const MeetingSubmissionState(MeetingSubmissionStatus.initial));
  final SubmitMeeting _submit;

  Future<void> submit(MeetingSubmission submission) async {
    if (isClosed || state.status == MeetingSubmissionStatus.submitting) return;
    emit(const MeetingSubmissionState(MeetingSubmissionStatus.submitting));
    try {
      final result = await _submit(submission);
      if (!isClosed) {
        emit(
          MeetingSubmissionState(
            MeetingSubmissionStatus.success,
            message: result.message,
          ),
        );
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('MEETING SUBMISSION ERROR: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      if (!isClosed) {
        emit(
          MeetingSubmissionState(
            MeetingSubmissionStatus.failure,
            message: error is MeetingSubmissionException
                ? error.message
                : 'Unable to submit meeting. Please try again.',
          ),
        );
      }
    }
  }
}
