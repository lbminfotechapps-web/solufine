
import 'dart:io';

import '../entities/jeep_campaign.dart';
import '../repositories/jeep_campaign_repository.dart';

class GetJeepSeasons {
  final JeepCampaignRepository repository;
  const GetJeepSeasons(this.repository);

  Future<List<JeepOption>> call() =>
      repository.getSeasons();
}

class SearchJeepProducts {
  final JeepCampaignRepository repository;
  const SearchJeepProducts(this.repository);

  Future<List<JeepOption>> call({
    required String seasonId,
    required String searchName,
  }) {
    return repository.searchProducts(
      seasonId: seasonId,
      searchName: searchName,
    );
  }
}

class SubmitJeepCampaign {
  final JeepCampaignRepository repository;
  const SubmitJeepCampaign(this.repository);

  Future<String> call(JeepCampaign campaign) async {
    if (campaign.userId.isEmpty ||
        campaign.userId == '0') {
      throw StateError('Please log in again.');
    }

    if (campaign.seasonId.isEmpty ||
        campaign.seasonId == '0') {
      throw StateError('Please select season.');
    }

    if (campaign.productId.isEmpty) {
      throw StateError('Please select product.');
    }

    if (campaign.promotionArea.trim().isEmpty) {
      throw StateError('Please enter promotion area.');
    }

    if (!['TOTO', 'AUTO', 'CAR']
        .contains(campaign.vehicleType)) {
      throw StateError('Please select vehicle type.');
    }

    final rent = double.tryParse(campaign.rentPerDay);
    final days = int.tryParse(campaign.workingDays);

    if (rent == null || rent <= 0) {
      throw StateError('Enter a valid rent per day.');
    }

    if (days == null || days <= 0) {
      throw StateError('Enter valid working days.');
    }

    final groups = [
      campaign.attachmentA,
      campaign.attachmentB,
      campaign.attachmentC1,
      campaign.attachmentC2,
    ];

    for (final group in groups) {
      if (group.length > 2) {
        throw StateError(
          'Maximum 2 images per attachment.',
        );
      }

      for (final path in group) {
        if (!await File(path).exists()) {
          throw StateError('Attachment file not found.');
        }
      }
    }

    return repository.submitCampaign(campaign);
  }
}
