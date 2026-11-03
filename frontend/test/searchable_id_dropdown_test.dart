import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/classes/presentation/widgets/classes_ui.dart';

void main() {
  testWidgets('search suggestions appear below the field as text is entered', (
    tester,
  ) async {
    String? selectedId;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: SearchableIdDropdown(
                label: 'Room Number',
                value: selectedId,
                options: const {
                  'room-101': 'Room 101',
                  'room-102': 'Room 102',
                  'room-103': 'Room 103',
                },
                disabled: const {'room-102': 'Assigned to 2nd Class'},
                onChanged: (value) => selectedId = value,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'ROOM 10');
    await tester.pumpAndSettle();

    expect(find.text('Room 101'), findsOneWidget);
    expect(find.text('Room 102'), findsOneWidget);
    expect(find.text('Assigned to 2nd Class'), findsOneWidget);
    expect(find.text('Room 103'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'room 103');
    await tester.pumpAndSettle();
    expect(find.text('Room 101'), findsNothing);
    expect(find.text('Room 102'), findsNothing);
    expect(find.text('Room 103'), findsOneWidget);

    await tester.tap(find.text('Room 103'));
    await tester.pumpAndSettle();
    expect(selectedId, 'room-103');
    expect(find.text('Room 103'), findsOneWidget);
  });

  testWidgets('selected value persists across parent rebuilds', (tester) async {
    String? selectedId;
    var unrelatedParentState = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) => Scaffold(
            body: Column(
              children: [
                Text('$unrelatedParentState'),
                SearchableIdDropdown(
                  label: 'Subject',
                  value: selectedId,
                  options: {'math': 'Maths', 'science': 'Science'},
                  onChanged: (value) => setState(() => selectedId = value),
                ),
                TextButton(
                  onPressed: () => setState(() => unrelatedParentState += 1),
                  child: const Text('Rebuild parent'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'science');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Science'));
    await tester.pumpAndSettle();
    expect(selectedId, 'science');
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Science',
    );

    await tester.tap(find.text('Rebuild parent'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Science',
    );
  });
}
