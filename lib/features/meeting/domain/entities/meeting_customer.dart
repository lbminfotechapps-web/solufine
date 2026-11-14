enum MeetingCustomerType { farmer, dealer, retailer }

class MeetingCustomer {
  const MeetingCustomer({
    required this.type,
    required this.id,
    required this.name,
    required this.mobile,
    required this.address,
    this.talukaName = '',
  });

  final MeetingCustomerType type;
  final String id;
  final String name;
  final String mobile;
  final String address;
  final String talukaName;
}
