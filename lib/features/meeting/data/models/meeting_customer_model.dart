import 'dart:convert';
import '../../domain/entities/meeting_customer.dart';

/// Matches Gson's MultipleAddFarmer field names and omits unused null IDs.
class MeetingCustomerModel {
  const MeetingCustomerModel(this.customer);
  final MeetingCustomer customer;

  Map<String, String> toJson() => {
    switch (customer.type) {
      MeetingCustomerType.farmer => 'fld_farmer_id',
      MeetingCustomerType.dealer => 'fld_dealer_id',
      MeetingCustomerType.retailer => 'fld_retailer_id',
    }: customer.id,
    'fld_name': customer.name,
    'fld_mobileno': customer.mobile,
    'fld_Address': customer.address,
    'fld_taluka_name': customer.talukaName,
  };

  static String encodeList(Iterable<MeetingCustomer> customers) => jsonEncode(
    customers.map((item) => MeetingCustomerModel(item).toJson()).toList(),
  );
}
