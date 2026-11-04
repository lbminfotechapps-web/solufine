import 'package:solufine/features/marketing/complaint_form/complaint_debug.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/subcategory_list_model.dart';
import 'package:solufine/features/marketing/complaint_form/data/model/varienty_model.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/variety_entity.dart';

import '../entity/crop_category.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/outlet_list_entity.dart';
import 'package:solufine/features/marketing/complaint_form/domain/repository/complaint_form_repo.dart';

class ComplainFormUsecase {
  final ComplaintFormRepo _complaintFormRepo;

  ComplainFormUsecase(this._complaintFormRepo);

  Future<CropCategoryListEntity> getCategoryList() =>
      _complaintFormRepo.getCategoryList();

  Future<Map<String, dynamic>> submitComplaintForm(
    Map<String, dynamic> jsonData,
  ) async {
    ComplaintDebug.log('UseCase', 'Calling repository', jsonData);
    try {
      final response = await _complaintFormRepo.submitComplaintForm(jsonData);
      ComplaintDebug.log('UseCase', 'Completed', response);
      return response;
    } catch (e, stack) {
      ComplaintDebug.error('UseCase', e, stack);
      rethrow;
    }
  }

  Future<OutletListEntity> getOutletList(
    String userId,
    String dealerType,
    String dealerName,
  ) async {
    return await _complaintFormRepo.getOutletList(
      userId,
      dealerType,
      dealerName,
    );
  }

  Future<SubCategoryListModel> getSubCategoryList(String categoryId) async {
    return await _complaintFormRepo.getSubCategoryList(categoryId);
  }

  Future<VarietyEntity> getVarietyList(String categoryId) async {
    return await _complaintFormRepo.getVarietyList(categoryId);
  }
}
