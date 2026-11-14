
import '../../domain/entities/farmer_coupon_entity.dart';

class FarmerCouponModel {
  final FarmerCouponEntity entity;

  const FarmerCouponModel(this.entity);

  Map<String, String> toFields() {
    return {
      'userId': entity.userId,
      'farmerId': entity.farmerId,
      'couponDetails': entity.couponDetails,
      'selectedProductId': entity.selectedProductId,
      'couponNumber': entity.couponNumber.trim(),
      'giftGiven': entity.giftGiven.trim(),
      'bookingAmount': entity.bookingAmount.trim(),
      'noOfCouponBook': entity.noOfCouponBook.trim(),
      'totalAmount': entity.totalAmount.toStringAsFixed(2),
      'activityId': '17',
    };
  }
}
