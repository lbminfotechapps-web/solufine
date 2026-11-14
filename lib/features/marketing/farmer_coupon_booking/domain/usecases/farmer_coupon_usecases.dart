import 'dart:io';

import '../entities/farmer_coupon_entity.dart';
import '../repositories/farmer_coupon_repository.dart';

class SearchCouponFarmers {
  final FarmerCouponRepository repository;

  const SearchCouponFarmers(this.repository);

  Future<List<CouponFarmer>> call({
    required String userId,
    required String searchText,
  }) {
    return repository.searchFarmers(
      userId: userId,
      searchText: searchText.trim(),
    );
  }
}

class GetCouponProducts {
  final FarmerCouponRepository repository;

  const GetCouponProducts(this.repository);

  Future<List<CouponProduct>> call() {
    return repository.getProducts();
  }
}

class SubmitFarmerCoupon {
  final FarmerCouponRepository repository;

  const SubmitFarmerCoupon(this.repository);

  Future<String> call(FarmerCouponEntity coupon) async {
    if (coupon.userId.trim().isEmpty || coupon.userId == '0') {
      throw StateError('Please log in again.');
    }

    if (coupon.farmerId.trim().isEmpty) {
      throw StateError('Please select farmer name.');
    }

    if (coupon.productIds.isEmpty) {
      throw StateError('Please select products.');
    }

    if (coupon.imagePath.isEmpty || !await File(coupon.imagePath).exists()) {
      throw StateError('Please select coupon image.');
    }

    if (coupon.couponNumber.trim().isEmpty) {
      throw StateError('Please enter coupon number.');
    }

    if (coupon.giftGiven.trim().isEmpty) {
      throw StateError('Please enter gift given.');
    }

    final bookingAmount = double.tryParse(coupon.bookingAmount);

    if (bookingAmount == null || bookingAmount <= 0) {
      throw StateError('Please enter a valid booking amount.');
    }

    final quantity = int.tryParse(coupon.noOfCouponBook);

    if (quantity == null || quantity <= 0) {
      throw StateError('Please enter a valid coupon quantity.');
    }

    return repository.submitCoupon(coupon);
  }
}
