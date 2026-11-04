import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/meeting/data/datasources/meeting_remote_datasource.dart';
import 'package:solufine/features/meeting/data/models/meeting_form_mapper.dart';
import 'package:solufine/features/meeting/domain/entities/meeting_customer.dart';
import 'package:solufine/features/meeting/domain/entities/meeting_submission.dart';

MeetingSubmission build(
  String type, {
  String seasonId = '8',
  String blockId = '3',
}) => MeetingFormMapper.build(
  userId: '7',
  customerType: type,
  customers: [
    MeetingCustomer(
      type: switch (type) {
        'Farmer' => MeetingCustomerType.farmer,
        'Retailer' => MeetingCustomerType.retailer,
        _ => MeetingCustomerType.dealer,
      },
      id: '15',
      name: 'Customer',
      mobile: '123',
      address: 'Village',
    ),
  ],
  date: DateTime(2026, 11, 4),
  values: {
    'Place of meeting': ' Village ',
    'Objective of meeting': 'Discussion',
    'Total members attending': '10',
    'Future sale plan quantity': '25',
    'Total meeting expenses': '100',
    'Budget Sanction per head Rs.': '10',
  },
  stateId: '1',
  districtId: '2',
  blockId: blockId,
  approverId: '4',
  cropId: '5',
  classIds: ['6', '6', '9'],
  productIds: ['11', '12'],
  seasonId: seasonId,
  budgetType: 'Non Budget Meeting',
  farmerType: 'Crop Show',
  costPerHead: '10.00',
  latitude: 20.5,
  longitude: 75.5,
  address: 'Current address',
);

void main() {
  test('optional Block can be empty and is submitted as empty', () {
    expect(build('Farmer', blockId: '').fields['farmerBlock'], '');
  });

  test('missing season error identifies the field', () {
    expect(
      () => build('Farmer', seasonId: ''),
      throwsA(
        isA<MeetingSubmissionException>().having(
          (error) => error.message,
          'message',
          contains('Season'),
        ),
      ),
    );
  });
  for (final entry in {
    'Distributor': 'dealerData',
    'Dealer': 'dealerData',
    'Retailer': 'retailerData',
    'Farmer': 'farmerData',
  }.entries) {
    test('${entry.key} sends matching legacy customer array', () {
      final fields = build(entry.key).fields;
      expect(fields['meetingType'], entry.key);
      expect(fields['meetingDate'], '04-11-2026');
      expect(fields['farmerType'], entry.key == 'Farmer' ? 'Crop Show' : '');
      final customers = jsonDecode(fields[entry.value]!) as List;
      expect(customers.single['fld_name'], 'Customer');
      expect(
        fields.keys.where(
          (key) => ['dealerData', 'retailerData', 'farmerData'].contains(key),
        ),
        [entry.value],
      );
    });
  }

  test(
    'maps selected IDs, product lists, budget, location, and legacy fields',
    () {
      final fields = build('Distributor').fields;
      expect(fields['farmerClass'], '6,9');
      expect(fields['farmerVeriety'], '11,12');
      expect(fields['farmerseason'], '8');
      expect(fields['farmerMeetingBudgetApprovalReceive'], '4');
      expect(fields['meetingPlace'], 'Village');
      expect(fields['farmerBudgetType'], 'Non Budget Meeting');
      expect(fields['farmerCostPerHead'], '10.00');
      expect(fields['latitude'], '20.5');
      expect(fields['geoAddress'], 'Current address');
      expect(fields['activityId'], '12');
    },
  );

  test('blocks missing season ID instead of submitting display text', () {
    expect(
      () => build('Farmer', seasonId: ''),
      throwsA(isA<MeetingSubmissionException>()),
    );
  });

  test('lookups send API fields and discard placeholder IDs', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path == '/getSeason') {
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': true,
                  'result': [
                    {'fld_season_id': '0', 'fld_season': 'Select'},
                    {'fld_season_id': '8', 'fld_season': 'Kharif'},
                  ],
                },
              ),
            );
          } else {
            expect(options.path, '/getMeetingBudgetApprovalReceivedFrom');
            expect(
              Map.fromEntries((options.data as FormData).fields)['searchName'],
              'John',
            );
            handler.resolve(
              Response(
                requestOptions: options,
                data: {
                  'status': true,
                  'result': [
                    {'fld_id': '4', 'fld_adm_name': 'John'},
                  ],
                },
              ),
            );
          }
        },
      ),
    );
    final source = MeetingRemoteDataSource(dio: dio);
    final seasons = await source.getSeasons();
    expect(seasons, hasLength(1));
    expect(seasons.single.id, '8');
    final approvers = await source.getBudgetApprovers('John');
    expect(approvers.single.id, '4');
    expect(approvers.single.name, 'John');
    dio.close();
  });
}
