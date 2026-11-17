import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/marketing/demodistributor/domain/entities/demo_distributor_entry.dart';
import 'package:solufine/features/marketing/demodistributor/presentation/widgets/demo_irrigation_search.dart';

void main() {
  testWidgets('opens irrigation without typing and selects the API ID', (
    tester,
  ) async {
    String? selected;
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DemoIrrigationSearch(
            load: () async {
              requests++;
              return const [
                DemoOption('0', 'Select Irrigation'),
                DemoOption('1', 'SALO'),
                DemoOption('2', 'BARSHA'),
              ];
            },
            onChanged: (id) => selected = id,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    expect(find.text('SALO'), findsOneWidget);
    expect(find.text('BARSHA'), findsOneWidget);
    expect(find.text('Select Irrigation'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    await tester.tap(find.text('BARSHA'));
    await tester.pumpAndSettle();
    expect(selected, '2');
    expect(requests, 1);
    await tester.tap(find.byType(TextFormField));
    await tester.pumpAndSettle();
    expect(find.text('SALO'), findsOneWidget);
    await tester.tap(find.text('SALO'));
    await tester.pumpAndSettle();
    expect(selected, '1');
    await tester.tap(find.byTooltip('Clear irrigation'));
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(find.byTooltip('Clear irrigation'), findsNothing);
    await tester.tap(find.byTooltip('Select irrigation'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('BARSHA'));
    await tester.pumpAndSettle();
    expect(selected, '2');
    expect(requests, 1);
  });
}
