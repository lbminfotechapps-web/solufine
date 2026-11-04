import 'package:solufine/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/home/presentation/widgets/visit_overview.dart';

void main() {
  testWidgets(
    'opens and closes chart, keeps totals and survives parent rebuild',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Widget page(String count, {bool isOpen = false}) => ScreenUtilPlusInit(
        designSize: const Size(390, 844),
        builder: (_, _) => MaterialApp(
          theme: AppColor.getLightTheme(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: VisitOverviewCard(
                dealerCount: count,
                farmerCount: '8',
                dayWise: const [],
                isOpen: isOpen,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(page('5'));
      expect(find.text('Visit Trend'), findsNothing);
      expect(find.text('Dealer Visits'), findsOneWidget);
      await tester.tap(find.byTooltip('Expand visit chart'));
      await tester.pumpAndSettle();
      expect(find.text('Visit Trend'), findsOneWidget);
      await tester.pumpWidget(page('6'));
      await tester.pumpAndSettle();
      expect(find.text('Visit Trend'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);
      await tester.tap(find.byTooltip('Collapse visit chart'));
      await tester.pumpAndSettle();
      expect(find.text('Visit Trend'), findsNothing);
      expect(find.text('Farmer Visits'), findsOneWidget);
      await tester.pumpWidget(page('6', isOpen: true));
      await tester.pumpAndSettle();
      expect(find.text('Visit Trend'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
