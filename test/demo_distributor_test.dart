import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/marketing/demodistributor/domain/entities/demo_distributor_entry.dart';
import 'package:solufine/features/marketing/demodistributor/domain/repositories/demo_distributor_repository.dart';
import 'package:solufine/features/marketing/demodistributor/domain/usecases/demo_distributor_usecases.dart';
import 'package:solufine/features/marketing/demodistributor/presentation/bloc/demo_distributor_cubit.dart';

class FakeRepository implements DemoDistributorRepository {
  int submissions = 0;
  Completer<String>? pending;
  bool fail = false;
  @override
  bool get canSubmit => true;
  @override
  Future<List<DemoOption>> lookup(
    DemoLookup kind, {
    required String userId,
    String parentId = '',
  }) async => const [
    DemoOption('1', 'Alpha', parentId: 'a'),
    DemoOption('2', 'Beta', parentId: 'b'),
  ];
  @override
  Future<String> submit(DemoDistributorEntry entry) async {
    submissions++;
    if (fail) throw StateError('Server rejected submission');
    return pending == null ? 'Saved' : pending!.future;
  }
}

DemoDistributorEntry entry({double quantity = 1}) => DemoDistributorEntry(
  userId: '4',
  customerType: 'Farmer',
  stateId: '1',
  districtId: '2',
  blockId: '3',
  village: 'Village',
  cropId: '4',
  subcategoryId: 'a',
  varietyId: '1',
  quantity: quantity,
  showingDate: DateTime(2026, 11, 13),
  tpDate: DateTime(2026, 11, 14),
  previousProduct: '',
  irrigationId: '',
  ck: 'CK',
  fieldDay: 'Field day',
);

void main() {
  test('invalid quantities never reach submission API', () async {
    final repository = FakeRepository();
    final submit = SubmitDemoDistributor(repository);
    for (final value in [0.0, -1.0, double.nan, double.infinity]) {
      expect(() => submit(entry(quantity: value)), throwsStateError);
    }
    expect(repository.submissions, 0);
  });

  test('prevents concurrent and post-success duplicate submissions', () async {
    final repository = FakeRepository()..pending = Completer<String>();
    final cubit = DemoDistributorCubit(
      GetDemoDistributorOptions(repository),
      SubmitDemoDistributor(repository),
    );
    final pending = cubit.submit(entry());
    await cubit.submit(entry());
    expect(repository.submissions, 1);
    repository.pending!.complete('Saved');
    await pending;
    await cubit.submit(entry());
    expect(repository.submissions, 1);
    expect(cubit.state.success, 'Saved');
    await cubit.close();
  });

  test('failed submission can be retried', () async {
    final repository = FakeRepository()..fail = true;
    final cubit = DemoDistributorCubit(
      GetDemoDistributorOptions(repository),
      SubmitDemoDistributor(repository),
    );
    await cubit.submit(entry());
    expect(cubit.state.error, isNotNull);
    repository.fail = false;
    await cubit.submit(entry());
    expect(cubit.state.success, 'Saved');
    expect(repository.submissions, 2);
    await cubit.close();
  });

  test('varieties belong to selected subcategory and match search', () async {
    final repository = FakeRepository();
    final cubit = DemoDistributorCubit(
      GetDemoDistributorOptions(repository),
      SubmitDemoDistributor(repository),
    );
    final rows = await cubit.options(
      DemoLookup.variety,
      userId: '4',
      parentId: 'crop',
      subcategoryId: 'b',
      query: ' BETA ',
    );
    expect(rows.map((row) => row.id), ['2']);
    expect(
      () => GetDemoDistributorOptions(repository)(
        DemoLookup.district,
        userId: '4',
      ),
      throwsStateError,
    );
    await cubit.close();
  });
}
