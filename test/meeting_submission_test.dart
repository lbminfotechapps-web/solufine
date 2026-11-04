import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/meeting/data/datasources/meeting_remote_datasource.dart';
import 'package:solufine/features/meeting/data/models/meeting_submission_model.dart';
import 'package:solufine/features/meeting/data/repositories/meeting_repository_impl.dart';
import 'package:solufine/features/meeting/domain/entities/meeting_submission.dart';
import 'package:solufine/features/meeting/domain/repositories/meeting_repository.dart';
import 'package:solufine/features/meeting/domain/usecases/submit_meeting.dart';
import 'package:solufine/features/meeting/presentation/cubit/meeting_submission_cubit.dart';

MeetingSubmission request() => MeetingSubmission(
  fields: {
    'userId': '7',
    'meetingDate': '04-11-2026',
    'meetingType': 'Farmer',
    'farmerCrop': '3',
    'farmerData': '[{"id":"5"}]',
    'activityId': '12',
  },
  pictures: [
    MeetingAttachment(filename: 'meeting.jpg', bytes: [1, 2, 3]),
  ],
  kmReadingImage: MeetingAttachment(filename: 'km.jpg', bytes: [4, 5]),
);

class PendingMeetingRepository implements MeetingRepository {
  int calls = 0;
  final completer = Completer<MeetingSubmissionResult>();
  @override
  Future<MeetingSubmissionResult> submit(MeetingSubmission submission) {
    calls++;
    return completer.future;
  }
}

void main() {
  test(
    'multipart preserves legacy keys, JSON strings, and attachment bytes',
    () async {
      final model = MeetingSubmissionModel(request());
      final form = model.toFormData();
      expect(Map.fromEntries(form.fields)['farmerData'], '[{"id":"5"}]');
      expect(form.files.map((entry) => entry.key), [
        'kmReadingImage',
        'pictures[]',
      ]);
      expect(
        await form.files.last.value
            .finalize()
            .expand((chunk) => chunk)
            .toList(),
        [1, 2, 3],
      );
      expect(model.toFormData().files.last.value.isFinalized, isFalse);
    },
  );

  test('posts multipart and accepts JSON string response', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.invalid'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          expect(options.method, 'POST');
          expect(options.path, '/confirmed-meeting-endpoint');
          expect(options.data, isA<FormData>());
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: '{"status":true,"message":"Saved"}',
            ),
          );
        },
      ),
    );
    final remote = MeetingRemoteDataSource(
      dio: dio,
      endpoint: '/confirmed-meeting-endpoint',
    );
    final result = await SubmitMeeting(MeetingRepositoryImpl(remote))(
      request(),
    );
    expect(result.message, 'Saved');
    dio.close();
  });

  test('rejects backend failure and malformed responses', () {
    for (final body in [
      <String, Object>{'status': false, 'message': 'Rejected'},
      '<html>Error</html>',
      null,
    ]) {
      expect(
        () => MeetingSubmissionModel.parseResponse(body),
        throwsA(isA<MeetingSubmissionException>()),
      );
    }
  });

  test('does not send when endpoint is missing', () async {
    final dio = Dio();
    var called = false;
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          called = true;
          handler.resolve(
            Response(requestOptions: options, data: {'status': true}),
          );
        },
      ),
    );
    await expectLater(
      MeetingRemoteDataSource(dio: dio, endpoint: '').submit(request()),
      throwsA(isA<MeetingSubmissionException>()),
    );
    expect(called, isFalse);
    dio.close();
  });

  test('Cubit prevents duplicate submissions and reports success', () async {
    final repository = PendingMeetingRepository();
    final cubit = MeetingSubmissionCubit(SubmitMeeting(repository));
    final first = cubit.submit(request());
    await cubit.submit(request());
    expect(repository.calls, 1);
    expect(cubit.state.status, MeetingSubmissionStatus.submitting);
    repository.completer.complete(
      const MeetingSubmissionResult(message: 'Saved'),
    );
    await first;
    expect(cubit.state.status, MeetingSubmissionStatus.success);
    await cubit.close();
  });

  test('Cubit reports validation failure without posting', () async {
    final repository = PendingMeetingRepository();
    final cubit = MeetingSubmissionCubit(SubmitMeeting(repository));
    await cubit.submit(MeetingSubmission(fields: {}));
    expect(repository.calls, 0);
    expect(cubit.state.status, MeetingSubmissionStatus.failure);
    await cubit.close();
  });
}
