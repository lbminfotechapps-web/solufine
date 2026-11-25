import '../../domain/entities/field_day_entry.dart';

class FieldDayModel {
  static Map<String, String> toFields(FieldDayEntry e) => {
    'userId': e.userId,
    'farmerId': e.farmerId,
    'activityName': e.activityName,
    'farmerParticipants': e.farmerParticipants,
    'dealerParticipants': e.dealerParticipants,
    'meetingPlace': e.meetingPlace,
    'meetingObjective': e.meetingObjective,
    'attendedStaff': e.attendedStaff,
    'officerName': e.officerName,
    'farmerOpinion': e.farmerOpinion,
    'packetBookedCount': e.packetBookedCount,
    'vehicleCharges': e.vehicleCharges,
    'snacks': e.snacks,
    'tentCharges': e.tentCharges,
    'hotelAmount': e.hotelAmount,
    'miscAmount': e.miscAmount,
    'totalAmount': e.totalAmount,
    'kmReading': e.kmReading,
    'manualDistance': e.manualDistance,
    'expectedOutcome': e.expectedOutcome,
    'activityId': '11',
  };
}
