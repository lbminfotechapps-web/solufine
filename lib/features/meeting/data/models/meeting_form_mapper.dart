import 'package:intl/intl.dart';
import '../../domain/entities/meeting_customer.dart';
import '../../domain/entities/meeting_submission.dart';
import 'meeting_customer_model.dart';

/// Converts form values into the field names used by the legacy meeting API.
class MeetingFormMapper {
  static MeetingSubmission build({
    required String userId,
    required String customerType,
    required List<MeetingCustomer> customers,
    required DateTime date,
    required Map<String, String> values,
    required String stateId,
    required String districtId,
    required String blockId,
    required String approverId,
    required String cropId,
    required List<String> classIds,
    required List<String> productIds,
    required String seasonId,
    required String budgetType,
    required String farmerType,
    required String costPerHead,
    required double latitude,
    required double longitude,
    required String address,
    List<MeetingAttachment> pictures = const [],
  }) {
    final type = switch (customerType) {
      'Farmer' => MeetingCustomerType.farmer,
      'Distributor' || 'Dealer' => MeetingCustomerType.dealer,
      'Retailer' => MeetingCustomerType.retailer,
      _ => throw const MeetingSubmissionException('Invalid customer type'),
    };
    if (customers.isEmpty ||
        customers.any((customer) => customer.type != type)) {
      throw const MeetingSubmissionException(
        'Please select valid customer details',
      );
    }
    final requiredIds = {
      'Logged-in user': userId,
      'State': stateId,
      'District': districtId,
      'Budget approver': approverId,
      'Crop': cropId,
      'Season': seasonId,
    };
    final missing = requiredIds.entries
        .where(
          (entry) => entry.value.trim().isEmpty || entry.value.trim() == '0',
        )
        .map((entry) => entry.key)
        .toList();
    if (missing.isNotEmpty) {
      throw MeetingSubmissionException(
        'Please select ${missing.join(', ')} from the results',
      );
    }
    if (productIds.isEmpty) {
      throw const MeetingSubmissionException(
        'Please select at least one product',
      );
    }
    final dataKey = switch (type) {
      MeetingCustomerType.farmer => 'farmerData',
      MeetingCustomerType.dealer => 'dealerData',
      MeetingCustomerType.retailer => 'retailerData',
    };
    String value(String key) => values[key]?.trim() ?? '';
    return MeetingSubmission(
      fields: {
        'userId': userId,
        'meetingPlace': value('Place of meeting'),
        'meetingObjective': value('Objective of meeting'),
        'objectionHandle': ' ',
        'expectedOutcome': ' ',
        'kmReading': ' ',
        'KmDistance': ' ',
        'dealerId': '',
        'dealerCount': ' ',
        'farmerCount': ' ',
        'totalMemberAttend': value('Total members attending'),
        'meetingDate': DateFormat('dd-MM-yyyy').format(date),
        'farmerState': stateId,
        'farmerDistrict': districtId,
        'farmerBlock': blockId,
        'farmerMeetingBudgetApprovalReceive': approverId,
        'farmerCrop': cropId,
        'farmerClass': classIds.where((id) => id.isNotEmpty).toSet().join(','),
        'farmerVeriety': productIds.toSet().join(','),
        'farmerseason': seasonId,
        'farmerBudgetType': budgetType,
        'farmerFutureSaleQty': value('Future sale plan quantity'),
        'farmerMeetingExpense': value('Total meeting expenses'),
        'farmerCostPerHead': costPerHead,
        'farmerBudgetSectionPerHead': value('Budget Sanction per head Rs.'),
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'geoAddress': address,
        'activityId': '12',
        'meetingType': customerType,
        'farmerType': type == MeetingCustomerType.farmer ? farmerType : '',
        dataKey: MeetingCustomerModel.encodeList(customers),
      },
      pictures: pictures,
    );
  }
}
