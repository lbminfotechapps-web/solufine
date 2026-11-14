import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/field_visit/data/datasources/field_visit_datasource.dart';
import 'package:solufine/features/marketing/field_visit/data/models/field_visit_model.dart';
import 'package:solufine/features/marketing/field_visit/domain/entities/field_visit_entity.dart';

void main() {
  test(
    'loads crops from the success story endpoint and cropDetailsData',
    () async {
      final client = DioClient();
      final interceptor = InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.path, ApiClient.successStoryCrops);
          expect(options.data, isA<FormData>());
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: jsonEncode({
                'cropDetailsData': [
                  {'fld_crop_id': '7', 'fld_crop_name': 'Cotton'},
                  {'fld_crop_id': '9', 'fld_crop_name': 'Wheat'},
                ],
              }),
            ),
          );
        },
      );
      client.client.interceptors.add(interceptor);
      addTearDown(() => client.client.interceptors.remove(interceptor));
      final source = FieldVisitDataSource(
        client,
        farmerEndpoint: ApiClient.getScheduleFarmerList,
        cropVarietyEndpoint: ApiClient.successStoryCrops,
      );
      final crops = await source.getCropsAndVarieties();
      expect(crops.map((crop) => crop.id), ['7', '9']);
      expect(crops.map((crop) => crop.name), ['Cotton', 'Wheat']);
    },
  );

  for (final asText in [false, true]) {
    test(
      'searches schedule farmers and maps selected ID (${asText ? 'text' : 'map'})',
      () async {
        final client = DioClient();
        final interceptor = InterceptorsWrapper(
          onRequest: (options, handler) {
            expect(options.path, ApiClient.getScheduleFarmerList);
            expect(options.contentType, Headers.formUrlEncodedContentType);
            expect(options.data, {'farmerName': 'Prasanna'});
            final body = {
              'status': true,
              'result': [
                {
                  'fld_farmer_id': '42',
                  'fld_farmer_name': 'Prasanna',
                  'fld_mobile_no': '1234567890',
                },
              ],
            };
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: asText ? jsonEncode(body) : body,
              ),
            );
          },
        );
        client.client.interceptors.add(interceptor);
        addTearDown(() => client.client.interceptors.remove(interceptor));
        final source = FieldVisitDataSource(
          client,
          farmerEndpoint: ApiClient.getScheduleFarmerList,
          cropVarietyEndpoint: 'getCropsAndVariety',
        );
        final farmers = await source.searchFarmers(
          userId: '4',
          searchText: ' Prasanna ',
        );
        final selected = farmers.single;
        expect(selected.name, 'Prasanna');
        expect(selected.mobile, '1234567890');
        final fields = FieldVisitRequestModel.toFields(
          FieldVisitEntity(
            userId: '4',
            reportingPersonId: '',
            visitWith: 'Team',
            farmerId: selected.id,
            packetSown: '2',
            sownDate: '31-10-2026',
            plotStatus: 'Good',
            activity: 'Visit',
            suggestion: '',
            cropIds: ['7', '9'],
            varietyIds: ['2'],
            latitude: 18,
            longitude: 73,
            geoAddress: '',
            plotImagePath: 'plot.jpg',
            visitorImagePath: 'visitor.jpg',
          ),
        );
        expect(fields['farmerId'], '42');
        expect(fields['cropIds'], '7,9');
      },
    );
  }
}
