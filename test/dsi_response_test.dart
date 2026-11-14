import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/core/api_constant/dio_client.dart';
import 'package:solufine/features/marketing/dsi/data/datasources/dsi_datasource.dart';
import 'package:solufine/features/marketing/dsi/domain/entities/dsi_entity.dart';

void main() {
  final client = DioClient();
  final source = DsiDataSource(client);
  const entity = AddDsiEntity(
    userId: '4',
    date: '31/10/2026',
    effectiveness: 'Skill Develop',
    description: 'test drive activity',
    saveTime: '85',
    saveMoney: '6300',
  );

  void respondWith(dynamic body) {
    final interceptor = InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(requestOptions: options, statusCode: 200, data: body),
        );
      },
    );
    client.client.interceptors.add(interceptor);
    addTearDown(() => client.client.interceptors.remove(interceptor));
  }

  const success = {
    'result': 'success',
    'status': true,
    'message': 'Record Inserted Successfully..!',
  };

  for (final asText in [false, true]) {
    test(
      'accepts successful DSI insert as ${asText ? 'JSON text' : 'map'}',
      () async {
        respondWith(asText ? ' \n${jsonEncode(success)}\n ' : success);
        expect(await source.addDsi(entity), success['message']);
      },
    );
  }

  test('preserves server failure message from JSON text', () async {
    respondWith(jsonEncode({'status': false, 'message': 'Unable to insert'}));
    await expectLater(
      source.addDsi(entity),
      throwsA(
        isA<Exception>().having(
          (error) => error.toString(),
          'message',
          contains('Unable to insert'),
        ),
      ),
    );
  });

  for (final body in ['<html>Server error</html>', '[]', 'null', '{invalid']) {
    test('rejects invalid response: $body', () async {
      respondWith(body);
      await expectLater(source.addDsi(entity), throwsFormatException);
    });
  }

  test('accepts DSI list returned as JSON text', () async {
    respondWith(jsonEncode({'status': true, 'result': []}));
    expect(await source.getDsiList(const DsiFilter(userId: '4')), isEmpty);
  });
}
