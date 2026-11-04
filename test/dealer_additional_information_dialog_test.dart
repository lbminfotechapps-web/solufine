import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/dealer_visit/presentation/pages/dealer_additional_information_dialog.dart';
import 'package:solufine/features/products/domain/entity/product_name.dart';

void main() {
  testWidgets(
    'saves classification and preserves product amounts across search',
    (tester) async {
      DealerAdditionalInformation? saved;
      final queries = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  saved = await showDialog<DealerAdditionalInformation>(
                    context: context,
                    builder: (_) => DealerAdditionalInformationDialog(
                      initialValue: DealerAdditionalInformation(
                        classification: 'B',
                        salesPotential: [],
                      ),
                      loadProducts: (query) async {
                        queries.add(query);
                        return const ProductResponseEntity(
                          status: true,
                          message: '',
                          products: [
                            ProductEntityy(
                              productId: '1',
                              productName: 'Product One',
                              productPath: '',
                              productContents: '',
                              productDosage: '',
                            ),
                            ProductEntityy(
                              productId: '2',
                              productName: 'Product Two',
                              productPath: '',
                              productContents: '',
                              productDosage: '',
                            ),
                          ],
                        );
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(queries, isEmpty);
      expect(find.byKey(const ValueKey('1')), findsNothing);
      await tester.enterText(find.byType(TextField).first, 'One');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(queries, ['One']);
      await tester.enterText(find.byKey(const ValueKey('1')), '120.50');
      await tester.enterText(find.byType(TextField).first, 'Tw');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField).first, 'Two');
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(queries, ['One', 'Two']);
      await tester.enterText(find.byKey(const ValueKey('2')), '80');
      await tester.pump();
      expect(find.text('Grand Total'), findsOneWidget);
      expect(find.text('200.50'), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('2')), '');
      await tester.pump();
      expect(find.text('120.50'), findsWidgets);
      await tester.enterText(find.byKey(const ValueKey('2')), '80');
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(saved!.classification, 'B');
      expect(saved!.salesPotential.map((item) => item.productId), ['1', '2']);
      expect(saved!.salesPotential.map((item) => item.amount), [
        '120.50',
        '80',
      ]);
    },
  );
}
