import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/admissions/presentation/admin/tabs/student_exam_tab.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Load and parse examinations.json', () async {
    final jsonString = await rootBundle.loadString('assets/data/examinations/examinations.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    expect(data.containsKey('exam_schedules'), isTrue);
    expect(data.containsKey('exam_papers'), isTrue);

    final schedules = data['exam_schedules'] as List;
    final papers = data['exam_papers'] as List;

    print('Loaded schedules: ${schedules.length}');
    print('Loaded papers: ${papers.length}');

    final monthly = schedules.where((s) => s['test_type'] == 'MONTHLY').toList();
    final weekly = schedules.where((s) => s['test_type'] == 'WEEKLY').toList();

    print('Monthly schedules count: ${monthly.length}');
    print('Weekly schedules count: ${weekly.length}');

    final monthlyMonths = monthly.map((s) => s['month']).toSet().toList();
    final weeklyMonths = weekly.map((s) => s['month']).toSet().toList();

    print('Monthly months: $monthlyMonths');
    print('Weekly months: $weeklyMonths');
  });

  testWidgets('StudentExamTab renders all 5 months and allows switching months and weeks', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StudentExamTab(isDark: false),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dropdown exists
    final dropdownFinders = find.byType(DropdownButton<String>);
    print('Found DropdownButton count: ${dropdownFinders.evaluate().length}');
    expect(dropdownFinders, findsWidgets);

    // Verify Dropdown items
    final monthlyDropdown = dropdownFinders.first;
    final dropdownWidget = tester.widget<DropdownButton<String>>(monthlyDropdown);
    print('Monthly Dropdown items count: ${dropdownWidget.items?.length}');
    for (final item in dropdownWidget.items ?? <DropdownMenuItem<String>>[]) {
      print('Dropdown item: ${item.value}');
    }

    // Tap the dropdown to open it
    await tester.tap(monthlyDropdown);
    await tester.pumpAndSettle();

    // Look for other months in the opened menu
    expect(find.text('July 2025'), findsWidgets);
    expect(find.text('June 2025'), findsWidgets);
    expect(find.text('May 2025'), findsWidgets);
    expect(find.text('April 2025'), findsWidgets);

    // Select 'July 2025' from the dropdown menu
    await tester.tap(find.text('July 2025').last);
    await tester.pumpAndSettle();

    print('Selected July 2025 successfully!');

    // Verify Weekly Test table is not empty
    expect(find.text('No Weekly Test record found'), findsNothing);

    // Test weekly dropdown
    final weeklyDropdown = dropdownFinders.at(1);
    await tester.tap(weeklyDropdown);
    await tester.pumpAndSettle();

    // Select 'June 2025' on weekly dropdown
    expect(find.text('June 2025'), findsWidgets);
    await tester.tap(find.text('June 2025').last);
    await tester.pumpAndSettle();

    // Verify Weekly Test table is not empty for June
    expect(find.text('No Weekly Test record found'), findsNothing);

    // Test tapping all 4 weeks for June
    for (int w = 1; w <= 4; w++) {
      final pill = find.widgetWithText(InkWell, 'Week $w');
      await tester.ensureVisible(pill.first);
      await tester.tap(pill.first);
      await tester.pumpAndSettle();
      expect(find.text('No Weekly Test record found'), findsNothing);
    }

    // Now test May 2025
    await tester.tap(weeklyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('May 2025').last);
    await tester.pumpAndSettle();
    expect(find.text('No Weekly Test record found'), findsNothing);

    for (int w = 1; w <= 4; w++) {
      final pill = find.widgetWithText(InkWell, 'Week $w');
      await tester.ensureVisible(pill.first);
      await tester.tap(pill.first);
      await tester.pumpAndSettle();
      expect(find.text('No Weekly Test record found'), findsNothing);
    }

    // Now test April 2025
    await tester.tap(weeklyDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text('April 2025').last);
    await tester.pumpAndSettle();
    expect(find.text('No Weekly Test record found'), findsNothing);

    for (int w = 1; w <= 4; w++) {
      final pill = find.widgetWithText(InkWell, 'Week $w');
      await tester.ensureVisible(pill.first);
      await tester.tap(pill.first);
      await tester.pumpAndSettle();
      expect(find.text('No Weekly Test record found'), findsNothing);
    }
  });
}
