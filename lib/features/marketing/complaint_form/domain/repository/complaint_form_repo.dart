import 'package:solufine/features/marketing/complaint_form/data/model/varienty_model.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/variety_entity.dart';

import '../../data/model/subcategory_list_model.dart';
import '../entity/crop_category.dart';
import 'package:solufine/features/marketing/complaint_form/domain/entity/outlet_list_entity.dart';

abstract class ComplaintFormRepo {
  Future<SubCategoryListModel> getSubCategoryList(String categoryId);
  Future<CropCategoryListEntity> getCategoryList();
  Future<Map<String, dynamic>> submitComplaintForm(
    Map<String, dynamic> jsonData,
  );

  Future<OutletListEntity> getOutletList(
    String userId,
    String dealerType,
    String dealerName,
  );


  Future<VarietyEntity> getVarietyList(String categoryId);
  
}
