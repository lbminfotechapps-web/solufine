import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/meeting/data/models/meeting_customer_model.dart';
import 'package:solufine/features/meeting/domain/entities/meeting_customer.dart';
import 'package:solufine/features/meeting/presentation/pages/meeting_distributor_dialog.dart';

void main() {
  for (final entry in {
    MeetingCustomerType.farmer: 'fld_farmer_id',
    MeetingCustomerType.dealer: 'fld_dealer_id',
    MeetingCustomerType.retailer: 'fld_retailer_id',
  }.entries) {
    test('serializes ${entry.key.name} with legacy Gson keys', () {
      final encoded = MeetingCustomerModel.encodeList([
        MeetingCustomer(
          type: entry.key,
          id: '7',
          name: 'Test',
          mobile: '123',
          address: 'Village',
          talukaName: 'Taluka',
        ),
      ]);
      expect(jsonDecode(encoded), [
        {
          entry.value: '7',
          'fld_name': 'Test',
          'fld_mobileno': '123',
          'fld_Address': 'Village',
          'fld_taluka_name': 'Taluka',
        },
      ]);
    });
  }

  test(
    'only selected customers enter the payload; manual ID 0 is retained',
    () {
      const selection = MeetingDistributorSelection(
        [
          MeetingDistributor(
            id: '0',
            name: 'Manual',
            mobile: '111',
            address: 'A',
          ),
          MeetingDistributor(
            id: '2',
            name: 'Other',
            mobile: '222',
            address: 'B',
          ),
        ],
        {'111'},
      );
      final customers = selection.toCustomers(MeetingCustomerType.farmer);
      expect(customers, hasLength(1));
      expect(customers.single.id, '0');
      expect(customers.single.name, 'Manual');
    },
  );
}
