
import '../entities/farmer_coupon_entity.dart';

abstract class FarmerCouponRepository {
  Future<List<CouponFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  });

  Future<List<CouponProduct>> getProducts();

  Future<String> submitCoupon(
    FarmerCouponEntity coupon,
  );
}
