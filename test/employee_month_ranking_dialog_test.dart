import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/core/api_constant/api_client.dart';
import 'package:solufine/features/home/data/home_model/monthly_performance_detail_model.dart';
import 'package:solufine/features/home/presentation/widgets/employee_month_ranking_dialog.dart';

void main() {
  for (final image in [
    '1793867683_5517.png',
    'https://example.com/employee.png',
    '',
    null,
  ]) {
    testWidgets('resolves API employee image $image', (tester) async {
      final data = MonthlyPerformanceDetailModel.fromJson({
        'status': true,
        'message': 'RECORD FOUND',
        'result': [
          {
            'monthly_performance_id': '2',
            'month_year': 'November - 2026',
            'ranks': [
              {'rank': '1', 'emp_name': 'LBM Manoj Medhe', 'emp_img': image},
            ],
          },
        ],
      });
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: EmployeeMonthRankingDialog(data: data)),
        ),
      );
      if (image == null || image.isEmpty) {
        expect(find.byType(Image), findsNothing);
        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      } else {
        final photo = tester.widget<Image>(find.byType(Image));
        expect(
          (photo.image as NetworkImage).url,
          image.startsWith('https://')
              ? image
              : '${ApiClient.employeeImageBaseUrl}$image',
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
