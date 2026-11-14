import '../../domain/entities/meeting_option.dart';
import '../../domain/repositories/meeting_lookup_repository.dart';
import '../../domain/entities/meeting_submission.dart';
import '../../domain/repositories/meeting_repository.dart';
import '../datasources/meeting_remote_datasource.dart';

class MeetingRepositoryImpl
    implements MeetingRepository, MeetingLookupRepository {
  const MeetingRepositoryImpl(this.remote);
  final MeetingRemoteDataSource remote;
  @override
  Future<List<MeetingOption>> getSeasons() => remote.getSeasons();
  @override
  Future<List<MeetingOption>> getBudgetApprovers(String query) =>
      remote.getBudgetApprovers(query);

  @override
  Future<MeetingSubmissionResult> submit(MeetingSubmission submission) =>
      remote.submit(submission);
}
