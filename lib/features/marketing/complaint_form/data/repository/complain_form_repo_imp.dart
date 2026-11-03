import 'package:solufine/features/marketing/complaint_form/data/model/subcategory_list_model.dart';

import '../../domain/entity/crop_category.dart';
import '../../domain/entity/outlet_list_entity.dart';
import 'package:solufine/features/marketing/complaint_form/data/datasource/complain_form_dsource.dart';
import 'package:solufine/features/marketing/complaint_form/domain/repository/complaint_form_repo.dart';

class ComplaintFormRepoImp extends ComplaintFormRepo {
  final ComplainFormDSource datasource;

  ComplaintFormRepoImp({required this.datasource});

  @override
  Future<CropCategoryListEntity> getCategoryList() =>
      datasource.getCategoryList();
  @override
  Future<OutletListEntity> getOutletList(
    String userId,
    String dealerType,
    String dealerName,
  ) => datasource.getOutletList(userId, dealerType, dealerName);

  @override
  Future<Map<String, dynamic>> submitComplaintForm(
    Map<String, dynamic> jsonData,
  ) async {
    try {
      final response = await datasource.submitComplaintForm(jsonData);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<SubCategoryListModel> getSubCategoryList(String categoryId) {
    return datasource.getSubCategoryList(categoryId);
  }

  @override
  getVarietyList(String categoryId) {
return datasource.getVarietyList(categoryId);
  }
}
