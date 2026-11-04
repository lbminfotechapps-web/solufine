import '../entities/meeting_option.dart';
import '../repositories/meeting_lookup_repository.dart';

class GetMeetingOptions {
  const GetMeetingOptions(this.repository);
  final MeetingLookupRepository repository;
  Future<List<MeetingOption>> seasons() => repository.getSeasons();
  Future<List<MeetingOption>> budgetApprovers(String query) =>
      repository.getBudgetApprovers(query);
}
