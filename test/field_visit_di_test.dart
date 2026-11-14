import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:solufine/core/di/field_visit_di.dart';
import 'package:solufine/features/marketing/field_visit/presentation/bloc/field_visit_bloc.dart';

void main() {
  test(
    'field visit DI resolves fresh blocs and tolerates repeated registration',
    () async {
      final sl = GetIt.instance;
      await sl.reset();
      addTearDown(() => sl.reset());

      await initFieldVisitDi();
      await initFieldVisitDi();

      final first = sl<FieldVisitBloc>();
      final second = sl<FieldVisitBloc>();
      addTearDown(first.close);
      addTearDown(second.close);
      expect(identical(first, second), isFalse);
      expect(first.state.loadingCrops, isFalse);
    },
  );
}
