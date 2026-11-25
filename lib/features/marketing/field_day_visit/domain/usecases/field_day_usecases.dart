import '../entities/field_day_entry.dart';
import '../repositories/field_day_repository.dart';

class SubmitFieldDay {
  final FieldDayRepository repository;
  const SubmitFieldDay(this.repository);
  Future<String> call(FieldDayEntry e) {
    if (e.userId.isEmpty || e.userId == '0')
      throw StateError('Please log in again');
    if (e.activityName.trim().isEmpty) throw StateError('Enter activity done');
    if (e.farmerId.isEmpty)
      throw StateError('Select a farmer from suggestions');
    for (final item in {
      'Farmer participants': e.farmerParticipants,
      'Dealer participants': e.dealerParticipants,
    }.entries) {
      if (int.tryParse(item.value) == null || int.parse(item.value) < 0) {
        throw StateError('Enter valid ${item.key}');
      }
    }
    if (e.meetingPlace.trim().isEmpty) throw StateError('Enter meeting place');
    if (e.meetingObjective.trim().isEmpty)
      throw StateError('Enter meeting objective');
    if (e.officerName.trim().isEmpty) throw StateError('Enter officer name');
    if (e.packetBookedCount.trim().isEmpty)
      throw StateError('Enter packet booking count');
    if (int.tryParse(e.packetBookedCount) == null)
      throw StateError('Enter valid packet booking count');
    for (final item in {
      'Vehicle charges': e.vehicleCharges,
      'Snacks': e.snacks,
      'Tent charges': e.tentCharges,
      'Hotel amount': e.hotelAmount,
      'Miscellaneous amount': e.miscAmount,
    }.entries) {
      final s = item.value.trim();
      if (s.isNotEmpty && (double.tryParse(s) == null || double.parse(s) < 0)) {
        throw StateError('Enter valid ${item.key}');
      }
    }
    return repository.submit(e);
  }
}

class SearchFieldDayFarmers {
  final FieldDayRepository repository;
  const SearchFieldDayFarmers(this.repository);
  Future<List<FarmerOption>> call(String userId, String query) {
    if (query.trim().length < 3) return Future.value([]);
    return repository.searchFarmers(userId, query);
  }
}
