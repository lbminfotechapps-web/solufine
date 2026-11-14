
class JeepOption {
  final String id;
  final String name;

  const JeepOption({
    required this.id,
    required this.name,
  });
}

class JeepCampaign {
  final String userId;
  final String seasonId;
  final String productId;
  final String promotionArea;
  final String vehicleType;
  final String rentPerDay;
  final String workingDays;

  final List<String> attachmentA;
  final List<String> attachmentB;
  final List<String> attachmentC1;
  final List<String> attachmentC2;

  const JeepCampaign({
    required this.userId,
    required this.seasonId,
    required this.productId,
    required this.promotionArea,
    required this.vehicleType,
    required this.rentPerDay,
    required this.workingDays,
    required this.attachmentA,
    required this.attachmentB,
    required this.attachmentC1,
    required this.attachmentC2,
  });

  double get totalBillAmount =>
      (double.tryParse(rentPerDay) ?? 0) *
      (int.tryParse(workingDays) ?? 0);
}
