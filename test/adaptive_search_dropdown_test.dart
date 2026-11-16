import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/core/utility/widgets/adaptive_search_dropdown.dart';

void main() {
  testWidgets('moves results above the field when keyboard covers space below', (tester) async {
    tester.view.physicalSize = const Size(800, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(MaterialApp(home: Scaffold(
      resizeToAvoidBottomInset: false,
      body: Padding(
        padding: const EdgeInsets.only(top: 300),
        child: AdaptiveSearchDropdown(
          visible: true,
          field: const SizedBox(key: ValueKey('field'), height: 60, width: 300),
          options: const SizedBox(key: ValueKey('results'), height: 200, child: Text('Results')),
        ),
      ),
    )));
    await tester.pump();
    expect(tester.getTopLeft(find.byKey(const ValueKey('results'))).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(find.byKey(const ValueKey('field'))).dy));
    tester.view.viewInsets = const FakeViewPadding(bottom: 400);
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(find.byKey(const ValueKey('results'))).dy,
        lessThanOrEqualTo(tester.getTopLeft(find.byKey(const ValueKey('field'))).dy));
    expect(tester.takeException(), isNull);
  });
}