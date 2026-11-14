
import '../../domain/entities/farmer_coupon_entity.dart';
import '../../domain/repositories/farmer_coupon_repository.dart';
import '../datasources/farmer_coupon_datasource.dart';

class FarmerCouponRepositoryImpl
    implements FarmerCouponRepository {
  final FarmerCouponDataSource datasource;

  const FarmerCouponRepositoryImpl(
    this.datasource,
  );

  @override
  Future<List<CouponFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  }) {
    return datasource.searchFarmers(
      userId: userId,
      searchText: searchText,
    );
  }

  @override
  Future<List<CouponProduct>> getProducts() {
    return datasource.getProducts();
  }

  @override
  Future<String> submitCoupon(
    FarmerCouponEntity coupon,
  ) {
    return datasource.submitCoupon(coupon);
  }
}
