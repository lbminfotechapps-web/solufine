import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/core/location_tracking/location_repository.dart';
import 'package:solufine/features/home/doman/home_entity/advertisement_entity.dart';
import 'package:solufine/features/home/doman/home_repository/qick_access_repo.dart';
import 'package:solufine/features/home/doman/home_usecases/get_punch_status_usecase.dart';
import 'package:solufine/features/home/presentation/advertisement.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_acess_bloc.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_event.dart';
import 'package:solufine/features/home/presentation/quick_aceess_bloc/quick_access_state.dart';

class _Repository implements QickAccessRepo {
  final requests =
      <({String type, String title, Completer<AdvertisementEntity> result})>[];
  @override
  Future<AdvertisementEntity> getAdvertisement(String type, String title) {
    final result = Completer<AdvertisementEntity>();
    requests.add((type: type, title: title, result: result));
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _LocationRepository implements LocationRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _success = AdvertisementEntity(
  status: true,
  message: '',
  result: [
    AdvertisementItemEntity(
      advertisementTitle: 'Seed launch',
      advertisementType: 'News',
      advertisementPath: '',
    ),
  ],
);

void main() {
  for (final path in [
    'youtube.com/watch?v=I8GpAR3vBeU',
    'www.youtube.com/shorts/I8GpAR3vBeU',
    '//youtu.be/I8GpAR3vBeU',
    'https://www.youtube.com/watch?v=I8GpAR3vBeU',
  ]) {
    testWidgets('shows YouTube thumbnail for $path', (tester) async {
      final repository = _Repository();
      final bloc = QuickAcessBloc(
        GetPunchStatusUsecase(repository),
        _LocationRepository(),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: bloc, child: const Advertisement()),
        ),
      );
      await tester.pump();
      repository.requests.single.result.complete(
        AdvertisementEntity(
          status: true,
          message: '',
          result: [
            AdvertisementItemEntity(
              advertisementTitle: 'Video preview',
              advertisementType: 'Video',
              advertisementPath: path,
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump();
      final image = tester.widget<Image>(find.byType(Image));
      expect(
        (image.image as NetworkImage).url,
        'https://img.youtube.com/vi/I8GpAR3vBeU/hqdefault.jpg',
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
    'loads event data, searches, retries failures and shows empty results',
    (tester) async {
      final repository = _Repository();
      final bloc = QuickAcessBloc(
        GetPunchStatusUsecase(repository),
        _LocationRepository(),
      );
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(value: bloc, child: const Advertisement()),
        ),
      );
      await tester.pump();
      expect(repository.requests.single.title, '');
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      repository.requests[0].result.complete(_success);
      await tester.pumpAndSettle();
      expect(find.text('Seed launch'), findsOneWidget);
      expect(bloc.state.quickAccessStatus, QuickAccessStatus.initial);
      await tester.enterText(find.byType(TextField), 'wh');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'wheat');
      await tester.pump(const Duration(milliseconds: 399));
      expect(repository.requests.length, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(repository.requests[1].title, 'wheat');
      repository.requests[1].result.completeError(StateError('Offline'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Offline'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump();
      repository.requests[2].result.complete(
        const AdvertisementEntity(status: true, message: '', result: []),
      );
      await tester.pumpAndSettle();
      expect(find.text('No advertisements found'), findsOneWidget);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(repository.requests.length, 4);
      expect(repository.requests.last.title, 'wheat');
      final indicator = tester.state<RefreshIndicatorState>(
        find.byType(RefreshIndicator),
      );
      var finished = false;
      final refreshDone = indicator.show().then((_) => finished = true);
      await tester.pump();
      expect(finished, isFalse);
      repository.requests.last.result.complete(_success);
      await tester.pumpAndSettle();
      await refreshDone;
      expect(finished, isTrue);
      expect(find.text('Seed launch'), findsOneWidget);
    },
  );

  test(
    'newer search results survive an older request completing later',
    () async {
      final repository = _Repository();
      final bloc = QuickAcessBloc(
        GetPunchStatusUsecase(repository),
        _LocationRepository(),
      );
      addTearDown(bloc.close);
      bloc.add(AdvertisementEvent('', 'old'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(AdvertisementEvent('', 'new'));
      await Future<void>.delayed(Duration.zero);
      final loaded = bloc.stream.firstWhere(
        (state) => state.advertisementStatus == QuickAccessStatus.success,
      );
      repository.requests[1].result.complete(_success);
      await loaded;
      repository.requests[0].result.complete(
        const AdvertisementEntity(status: true, message: '', result: []),
      );
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.advertisementData, _success);
    },
  );
}
