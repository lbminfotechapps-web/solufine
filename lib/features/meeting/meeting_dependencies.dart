import 'package:dio/dio.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'data/datasources/meeting_remote_datasource.dart';
import 'data/repositories/meeting_repository_impl.dart';
import 'domain/usecases/get_meeting_options.dart';
import 'domain/usecases/submit_meeting.dart';
import 'presentation/cubit/meeting_submission_cubit.dart';

class MeetingDependencies {
  MeetingDependencies({Dio? dio}) {
    final repository = MeetingRepositoryImpl(
      MeetingRemoteDataSource(dio: dio ?? DioClient().client),
    );
    options = GetMeetingOptions(repository);
    submission = MeetingSubmissionCubit(SubmitMeeting(repository));
  }
  late final GetMeetingOptions options;
  late final MeetingSubmissionCubit submission;
}
