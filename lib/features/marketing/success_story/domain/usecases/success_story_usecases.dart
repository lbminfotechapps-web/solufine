
import 'dart:io';

import '../entities/success_story_entity.dart';
import '../repositories/success_story_repository.dart';

class SearchSuccessStoryFarmers {
  final SuccessStoryRepository repository;

  const SearchSuccessStoryFarmers(this.repository);

  Future<List<SuccessStoryFarmer>> call({
    required String userId,
    required String searchText,
  }) {
    if (searchText.trim().length < 3) {
      return Future.value([]);
    }

    return repository.searchFarmers(
      userId: userId,
      searchText: searchText.trim(),
    );
  }
}

class GetSuccessStoryCrops {
  final SuccessStoryRepository repository;

  const GetSuccessStoryCrops(this.repository);

  Future<List<SuccessStoryCrop>> call() {
    return repository.getCrops();
  }
}

class SubmitSuccessStory {
  final SuccessStoryRepository repository;

  const SubmitSuccessStory(this.repository);

  Future<String> call(SuccessStoryEntity story) async {
    if (story.userId.trim().isEmpty ||
        story.userId == '0') {
      throw StateError('Please log in again.');
    }

    if (story.farmerId.trim().isEmpty) {
      throw StateError('Please select farmer.');
    }

    if (!RegExp(r'^[1-9][0-9]{9}$')
        .hasMatch(story.mobileNo.trim())) {
      throw StateError(
        'Enter a valid 10-digit mobile number.',
      );
    }

    if (story.address.trim().isEmpty) {
      throw StateError('Please enter address.');
    }

    if (story.cropIds.isEmpty) {
      throw StateError('Please select crop.');
    }

    final acreage =
        double.tryParse(story.cropAcrage.trim());

    if (acreage == null ||
        !acreage.isFinite ||
        acreage <= 0) {
      throw StateError('Enter valid crop acreage.');
    }

    if (story.usedProduct.trim().isEmpty) {
      throw StateError('Please enter used product.');
    }

    if (story.cropStage.trim().isEmpty) {
      throw StateError('Please enter crop stage.');
    }

    if (story.employeeNameHq.trim().isEmpty) {
      throw StateError('Please enter Employee/HQ name.');
    }

    if (story.alternateMobileNo.trim().isNotEmpty &&
        !RegExp(r'^[1-9][0-9]{9}$')
            .hasMatch(story.alternateMobileNo.trim())) {
      throw StateError('Enter valid alternate mobile.');
    }

    if (story.videoPath != null &&
        story.videoPath!.isNotEmpty &&
        !await File(story.videoPath!).exists()) {
      throw StateError('Selected video was not found.');
    }

    return repository.submitStory(story);
  }
}
