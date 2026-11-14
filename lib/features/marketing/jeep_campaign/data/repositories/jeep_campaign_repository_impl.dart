
import '../../domain/entities/jeep_campaign.dart';
import '../../domain/repositories/jeep_campaign_repository.dart';
import '../datasources/jeep_campaign_datasource.dart';

class JeepCampaignRepositoryImpl
    implements JeepCampaignRepository {
  final JeepCampaignDataSource datasource;

  const JeepCampaignRepositoryImpl(this.datasource);

  @override
  Future<List<JeepOption>> getSeasons() {
    return datasource.getSeasons();
  }

  @override
  Future<List<JeepOption>> searchProducts({
    required String seasonId,
    required String searchName,
  }) {
    return datasource.searchProducts(
      seasonId: seasonId,
      searchName: searchName,
    );
  }

  @override
  Future<String> submitCampaign(JeepCampaign campaign) {
    return datasource.submitCampaign(campaign);
  }
}
