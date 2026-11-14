
import '../entities/jeep_campaign.dart';

abstract class JeepCampaignRepository {
  Future<List<JeepOption>> getSeasons();

  Future<List<JeepOption>> searchProducts({
    required String seasonId,
    required String searchName,
  });

  Future<String> submitCampaign(JeepCampaign campaign);
}
