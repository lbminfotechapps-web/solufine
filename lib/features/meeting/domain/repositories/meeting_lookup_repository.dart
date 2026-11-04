import '../entities/meeting_option.dart';

abstract class MeetingLookupRepository {
  Future<List<MeetingOption>> getSeasons();
  Future<List<MeetingOption>> getBudgetApprovers(String query);
}
