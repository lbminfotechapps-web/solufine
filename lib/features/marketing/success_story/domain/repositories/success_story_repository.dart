import '../entities/success_story_entity.dart';

abstract class SuccessStoryRepository {
  Future<List<SuccessStoryFarmer>> searchFarmers({
    required String userId,
    required String searchText,
  });

  Future<List<SuccessStoryCrop>> getCrops();

  Future<String> submitStory(
    SuccessStoryEntity story,
  );
}