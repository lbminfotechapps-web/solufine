class FarmerOption {
  final String id;
  final String name;
  final String mobileNo;
  final String talukaName;
  const FarmerOption(
    this.id,
    this.name, {
    this.mobileNo = '',
    this.talukaName = '',
  });
}

class FieldDayEntry {
  final String userId,
      farmerId,
      activityName,
      farmerParticipants,
      dealerParticipants,

      meetingPlace,
      meetingObjective,
      attendedStaff,
      officerName,
      farmerOpinion,
      packetBookedCount,
      vehicleCharges,
      snacks,
      tentCharges,
      hotelAmount,
      miscAmount,
      totalAmount,
      kmReading,
      manualDistance,
      expectedOutcome;
  final Map<String, String> expenseImages;
  final List<String> pictures;
  const FieldDayEntry({
    required this.userId,
    required this.farmerId,
    required this.activityName,
    required this.farmerParticipants,
    required this.dealerParticipants,

    required this.meetingPlace,
    required this.meetingObjective,
    required this.attendedStaff,
    required this.officerName,
    required this.farmerOpinion,
    required this.packetBookedCount,
    required this.vehicleCharges,
    required this.snacks,
    required this.tentCharges,
    required this.hotelAmount,
    required this.miscAmount,
    required this.totalAmount,
    required this.kmReading,
    required this.manualDistance,
    required this.expectedOutcome,
    required this.expenseImages,
    required this.pictures,
  });
}
