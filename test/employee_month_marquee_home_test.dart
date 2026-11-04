import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_entity.dart';
import 'package:solufine/features/home/doman/home_repository/home_repo.dart';
import 'package:solufine/features/home/doman/home_usecases/get_menu_usecase.dart';
import 'package:solufine/features/home/doman/home_usecases/get_inpunch_pending_usecase.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_bloc.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_event.dart';
import 'package:solufine/features/home/presentation/home_bloc/home_state.dart';
import 'package:solufine/features/home/presentation/widgets/employee_month_marquee.dart';

class _Repository implements HomeRepo {
  @override
  Future<MonthlyPerformanceEntity> getMonthlyPerformanceList() async => const MonthlyPerformanceEntity(
    status: true, message: '', result: [MonthlyPerformanceItemEntity(
      monthlyPerformanceId: '1', monthYear: 'Nov 2026', employeeNames: ['Asha Sharma', 'Ravi Kumar'],
    )]);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('marquee appears after list loads inside the dialog tap wrapper', (tester) async {
    final repository = _Repository();
    final bloc = HomeBloc(GetMenuUsecase(repository), GetInpunchPendingUseCase(repository: repository));
    addTearDown(bloc.close);
    var tapped = false;
    await tester.pumpWidget(MaterialApp(home: BlocProvider.value(value: bloc,
      child: Scaffold(body: SingleChildScrollView(child: Column(children: [
        BlocListener<HomeBloc, HomeState>(listener: (_, _) {},
          child: InkWell(onTap: () { tapped = true; },
            child: BlocBuilder<HomeBloc, HomeState>(
              buildWhen: (p, c) => p.monthlyPerformanceData != c.monthlyPerformanceData,
              builder: (_, state) => EmployeeMonthMarquee(entries: state.monthlyPerformanceData?.result ?? const []),
            ),
          ),
        ),
      ]))),
    )));
    bloc.add(GetMonthlyPerformanceEvent());
    await tester.pump();
    await tester.pump();
    expect(find.text(' Asha Sharma'), findsWidgets);
    expect(tester.getSize(find.byType(EmployeeMonthMarquee)).width, greaterThan(0));
    await tester.tap(find.byType(EmployeeMonthMarquee));
    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}