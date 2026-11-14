import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/home/doman/home_entity/monthly_performance_entity.dart';
import 'package:solufine/features/home/presentation/widgets/employee_month_marquee.dart';

void main() {
  testWidgets('shows a compact horizontal name row and animates overflow', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 150,
            child: EmployeeMonthMarquee(
              entries: [
                MonthlyPerformanceItemEntity(
                  monthlyPerformanceId: '1',
                  monthYear: 'November 2026',
                  employeeNames: ['Asha Sharma', 'Ravi Kumar', 'Meera Patel'],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Employee of the Month'), findsNothing);
    expect(find.text('November 2026'), findsNothing);
    expect(find.byType(Icon), findsNothing);
    expect(
      tester.getSize(find.byType(EmployeeMonthMarquee)).height,
      lessThan(50),
    );
    final label = find.text(' Asha Sharma').first;
    final before = tester.getTopLeft(label);
    await tester.pump(const Duration(seconds: 1));
    final after = tester.getTopLeft(label);
    expect(after.dx, lessThan(before.dx));
    expect(after.dy, before.dy);
    await tester.pumpWidget(const SizedBox.shrink());
    expect(tester.takeException(), isNull);
  });
  testWidgets('hides when no names are available', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: EmployeeMonthMarquee(entries: [])),
    );
    expect(find.byType(DecoratedBox), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
