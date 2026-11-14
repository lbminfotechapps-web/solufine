
class CouponFarmer {
  final String id;
  final String name;

  const CouponFarmer({
    required this.id,
    required this.name,
  });
}

class CouponProduct {
  final String id;
  final String name;

  const CouponProduct({
    required this.id,
    required this.name,
  });
}

class FarmerCouponEntity {
  final String userId;
  final String farmerId;
  final String couponDetails;
  final List<String> productIds;
  final String couponNumber;
  final String giftGiven;
  final String bookingAmount;
  final String noOfCouponBook;
  final String imagePath;

  const FarmerCouponEntity({
    required this.userId,
    required this.farmerId,
    required this.couponDetails,
    required this.productIds,
    required this.couponNumber,
    required this.giftGiven,
    required this.bookingAmount,
    required this.noOfCouponBook,
    required this.imagePath,
  });

  double get totalAmount {
    final amount = double.tryParse(bookingAmount) ?? 0;
    final quantity = int.tryParse(noOfCouponBook) ?? 0;
    return amount * quantity;
  }

  String get selectedProductId =>
      productIds.join(',');
}
