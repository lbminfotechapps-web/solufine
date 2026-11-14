import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/marketing/dsi/domain/entities/dsi_entity.dart';
import 'package:solufine/features/marketing/dsi/domain/repositories/dsi_repository.dart';
import 'package:solufine/features/marketing/dsi/domain/usecases/dsi_usecases.dart';
import 'package:solufine/features/marketing/dsi/data/models/dsi_model.dart';
import 'package:solufine/features/marketing/dsi/presentation/bloc/dsi_bloc.dart';

class FakeRepository implements DsiRepository {
  final requests = <DsiFilter>[];
  final pending = <Completer<List<DsiRecord>>>[];
  @override
  Future<List<DsiRecord>> fetchDsiList(DsiFilter filter) {
    requests.add(filter);
    final result = Completer<List<DsiRecord>>();
    pending.add(result);
    return result.future;
  }

  @override
  Future<String> addDsi(AddDsiEntity entity) async => 'Saved';
}

DsiRecord record(String id) => DsiRecordModel.fromJson({'fld_dsi_id': id});
Future<void> tick() => Future<void>.delayed(Duration.zero);

void main() {
  test('serializes the startLimit offset', () {
    expect(
      DsiRequestModel.listFields(const DsiFilter(userId: '4'))['startLimit'],
      '0',
    );
    expect(
      DsiRequestModel.listFields(
        const DsiFilter(userId: '4', startLimit: 12),
      )['startLimit'],
      '12',
    );
  });

  late FakeRepository repository;
  late DsiBloc bloc;
  const filter = DsiFilter(
    userId: '4',
    searchText: 'Money',
    fromDate: '1-10-2026',
    toDate: '31-10-2026',
  );
  setUp(() {
    repository = FakeRepository();
    bloc = DsiBloc(
      getDsiList: GetDsiList(repository),
      submitDsi: SubmitDsi(repository),
    );
  });
  tearDown(() async {
    await bloc.close();
  });

  test(
    'appends pages, preserves filters, suppresses concurrent loads and stops on empty page',
    () async {
      bloc.add(const LoadDsiList(filter));
      await tick();
      repository.pending[0].complete([record('1'), record('2')]);
      await tick();
      bloc.add(const LoadDsiList(filter, loadMore: true));
      bloc.add(const LoadDsiList(filter, loadMore: true));
      await tick();
      expect(repository.requests.length, 2);
      expect(repository.requests[1].startLimit, 2);
      expect(repository.requests[1].searchText, 'Money');
      expect(repository.requests[1].fromDate, filter.fromDate);
      expect(repository.requests[1].toDate, filter.toDate);
      repository.pending[1].complete([record('3')]);
      await tick();
      expect(bloc.state.records.map((r) => r.id), ['1', '2', '3']);
      bloc.add(const LoadDsiList(filter, loadMore: true));
      await tick();
      expect(repository.requests[2].startLimit, 3);
      repository.pending[2].complete([]);
      await tick();
      expect(bloc.state.hasMore, isFalse);
      expect(bloc.state.records.length, 3);
    },
  );

  test(
    'pagination failure preserves rows and retries the same offset',
    () async {
      bloc.add(const LoadDsiList(filter));
      await tick();
      repository.pending[0].complete([record('1')]);
      await tick();
      bloc.add(const LoadDsiList(filter, loadMore: true));
      await tick();
      repository.pending[1].completeError(Exception('Offline'));
      await tick();
      expect(bloc.state.records.single.id, '1');
      expect(bloc.state.loadingMore, isFalse);
      bloc.add(const LoadDsiList(filter, loadMore: true));
      await tick();
      expect(repository.requests[2].startLimit, 1);
      repository.pending[2].complete([record('2')]);
      await tick();
    },
  );

  test('filter reset ignores an older in-flight page', () async {
    bloc.add(const LoadDsiList(filter));
    await tick();
    repository.pending[0].complete([record('1')]);
    await tick();
    bloc.add(const LoadDsiList(filter, loadMore: true));
    await tick();
    bloc.add(const LoadDsiList(DsiFilter(userId: '4', searchText: 'Other')));
    await tick();
    expect(repository.requests[2].startLimit, 0);
    repository.pending[2].complete([record('9')]);
    await tick();
    repository.pending[1].complete([record('2')]);
    await tick();
    expect(bloc.state.records.single.id, '9');
  });

  test(
    'repeated pages do not duplicate rows or keep pagination running',
    () async {
      bloc.add(const LoadDsiList(filter));
      await tick();
      repository.pending[0].complete([record('1')]);
      await tick();
      bloc.add(const LoadDsiList(filter, loadMore: true));
      await tick();
      repository.pending[1].complete([record('1')]);
      await tick();
      expect(bloc.state.records.length, 1);
      expect(bloc.state.hasMore, isFalse);
    },
  );
}
