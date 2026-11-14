import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:solufine/features/marketing/demodistributor/domain/entities/demo_distributor_entry.dart';
import 'package:solufine/features/marketing/demodistributor/presentation/widgets/demo_location_search.dart';

void main() {
  testWidgets('search is inline, debounced, and selects an API result', (
    tester,
  ) async {
    final controller = TextEditingController();
    final queries = <String>[];
    DemoOption? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => DemoLocationSearch(
              label: 'State',
              controller: controller,
              selected: selected,
              load: (query) async {
                queries.add(query);
                return const [DemoOption('1', 'Maharashtra')];
              },
              onEdited: () => setState(() => selected = null),
              onSelected: (option) => setState(() => selected = option),
            ),
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'Maha');
    await tester.pump(const Duration(milliseconds: 999));
    expect(queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();
    expect(queries, ['Maha']);
    expect(find.byType(AlertDialog), findsNothing);
    await tester.tap(find.text('Maharashtra'));
    await tester.pump();
    expect(selected?.id, '1');
    expect(controller.text, 'Maharashtra');
    await tester.enterText(find.byType(TextFormField), 'Other');
    expect(selected, isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('older responses cannot replace a newer query', (tester) async {
    final controller = TextEditingController();
    final first = Completer<List<DemoOption>>();
    final second = Completer<List<DemoOption>>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DemoLocationSearch(
            label: 'State',
            controller: controller,
            selected: null,
            onEdited: () {},
            onSelected: (_) {},
            load: (query) => query == 'old' ? first.future : second.future,
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'old');
    await tester.pump(const Duration(seconds: 1));
    await tester.enterText(find.byType(TextFormField), 'new');
    await tester.pump(const Duration(seconds: 1));
    second.complete(const [DemoOption('2', 'New result')]);
    await tester.pump();
    first.complete(const [DemoOption('1', 'Old result')]);
    await tester.pump();
    expect(find.text('New result'), findsOneWidget);
    expect(find.text('Old result'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('changing parent invalidates in-flight child results', (
    tester,
  ) async {
    final controller = TextEditingController();
    final response = Completer<List<DemoOption>>();
    String parent = 'state1';
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return DemoLocationSearch(
                label: 'District',
                controller: controller,
                selected: null,
                parentId: parent,
                onEdited: () {},
                onSelected: (_) {},
                load: (_) => response.future,
              );
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextFormField), 'district');
    await tester.pump(const Duration(seconds: 1));
    rebuild(() => parent = 'state2');
    await tester.pump();
    response.complete(const [DemoOption('1', 'Stale district')]);
    await tester.pump();
    expect(find.text('Stale district'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}
