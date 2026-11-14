
import '../../domain/entities/success_story_entity.dart';

class SuccessStoryModel {
  final SuccessStoryEntity story;

  const SuccessStoryModel(this.story);

  Map<String, String> toFields() => {
    'userId': story.userId,
    'activityId': '15',
    'farmerId': story.farmerId,
    'mobileNo': story.mobileNo.trim(),
    'address': story.address.trim(),
    'cropIds': story.selectedCropIds,
    'cropAcrage': story.cropAcrage.trim(),
    'usedProduct': story.usedProduct.trim(),
    'cropStage': story.cropStage.trim(),
    'alternateMobileNo':
        story.alternateMobileNo.trim(),
    'employeeName_hq':
        story.employeeNameHq.trim(),
  };
}
