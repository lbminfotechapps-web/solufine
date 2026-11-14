
import '../../domain/entities/success_story_entity.dart';
import '../../domain/repositories/success_story_repository.dart';
import '../datasources/success_story_datasource.dart';

class SuccessStoryRepositoryImpl
    implements SuccessStoryRepository {
  final SuccessStoryDataSource dataSource;

  const SuccessStoryRepositoryImpl(
    this.dataSource,
  );

  @override
  Future<List<SuccessStoryFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  }) {
    return dataSource.searchFarmers(
      userId: userId,
      searchText: searchText,
    );
  }

  @override
  Future<List<SuccessStoryCrop>> getCrops() {
    return dataSource.getCrops();
  }

  @override
  Future<String> submitStory(
    SuccessStoryEntity story,
  ) {
    return dataSource.submitStory(story);
  }
}
