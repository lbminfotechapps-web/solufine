
import '../../domain/entities/jeep_campaign.dart';

class JeepCampaignModel {
  final JeepCampaign campaign;
  const JeepCampaignModel(this.campaign);

  Map<String, String> toFields() => {
    'userId': campaign.userId,
    'productId': campaign.productId,
    'promotionArea': campaign.promotionArea.trim(),
    'rentPerDay': campaign.rentPerDay,
    'totNoOfWorkingDays': campaign.workingDays,
    'totBillAmt':
        campaign.totalBillAmount.toStringAsFixed(2),
    'seasonId': campaign.seasonId,
    'vehicleTypeId': campaign.vehicleType,
    'activityId': '16',

    // Legacy empty fields sent by the Java code.
    'hiredVehicleNo': '',
    'driverId': '',
    'driverMobileNo': '',
    'vehicleRentPerDay': '',
    'vehicleUseFor': '',
    'totalRentAmt': '',
    'fuelQty': '',
    'fuelAmt': '',
    'averagePerLtr': '',
    'fuelBill': '',
    'noTemporarryStaff': '',
    'perDayWagesStaff': '',
    'hiredForNoDays': '',
    'totalAmtWages': '',
    'miscCharges': '',
    'totalExpence': '',
  };
}
