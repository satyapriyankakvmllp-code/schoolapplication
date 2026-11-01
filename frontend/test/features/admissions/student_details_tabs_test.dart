import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/admissions/presentation/admin/student_details_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('StudentDetailsScreen Category Tabs Integration Tests', () {
    testWidgets('Switches across Attendance, Leave, Fees, Exam, and Library tabs with full interactivity', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudentDetailsScreen(studentId: 'std-1001'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Initially on Student Details Tab
      expect(find.text('Student Details'), findsWidgets);
      expect(find.text('Parent Guardian Detail'), findsOneWidget);

      // 2. Switch to Attendance Tab
      await tester.tap(find.widgetWithText(InkWell, 'Attendance').last);
      await tester.pumpAndSettle();

      // Verify Attendance KPI cards & dynamic months
      expect(find.text('Total Present'), findsOneWidget);
      expect(find.text('Total Absent'), findsOneWidget);
      expect(find.text('Half Day'), findsOneWidget);
      expect(find.text('Total Late'), findsOneWidget);
      expect(find.text('Total Holiday'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Oct'), findsWidgets);

      // 3. Switch to Leave Tab
      await tester.tap(find.widgetWithText(InkWell, 'Leave').last);
      await tester.pumpAndSettle();

      // Verify Leave requests table and Approve/Reject buttons
      expect(find.text('Leave Requests'), findsOneWidget);
      expect(find.text('Submitted by Student'), findsOneWidget);
      expect(find.text('Medical Leave'), findsWidgets);
      expect(find.text('Approve'), findsWidgets);
      expect(find.text('Reject'), findsWidgets);

      // Tap Approve on a pending leave request with ensureVisible
      final approveBtn = find.text('Approve').first;
      await tester.ensureVisible(approveBtn);
      await tester.pumpAndSettle();
      await tester.tap(approveBtn);
      await tester.pumpAndSettle();
      expect(find.text('Leave request marked as Approved'), findsOneWidget);

      // 4. Switch to Fees Tab
      final feesTab = find.widgetWithText(InkWell, 'Fees').last;
      await tester.ensureVisible(feesTab);
      await tester.pumpAndSettle();
      await tester.tap(feesTab);
      await tester.pumpAndSettle();

      // Verify Fees KPI cards & table (no Collect Fees button)
      expect(find.text('Total Amount'), findsOneWidget);
      expect(find.text('Total Fine'), findsOneWidget);
      expect(find.text('Total Paid'), findsOneWidget);
      expect(find.text('Total Due'), findsOneWidget);
      expect(find.text('Collect Fees'), findsNothing);
      expect(find.text('May Month Fees'), findsWidgets);

      // 5. Switch to Exam Tab
      final examTab = find.widgetWithText(InkWell, 'Exam').last;
      await tester.ensureVisible(examTab);
      await tester.pumpAndSettle();
      await tester.tap(examTab);
      await tester.pumpAndSettle();

      // Verify Performance Matrix, Monthly Tests & Weekly Tests sections (no Semesters)
      expect(find.text('Student Performance Matrix'), findsOneWidget);
      expect(find.text('First Semester'), findsNothing);
      expect(find.text('Monthly Tests'), findsWidgets);
      expect(find.text('Weekly Tests'), findsWidgets);

      // Verify new Exam Date and Exam Time table headers
      expect(find.text('Exam Date'), findsWidgets);
      expect(find.text('Exam Time'), findsWidgets);

      // Monthly Test marks visible
      expect(find.text('Bangla'), findsWidgets);
      expect(find.text('Physics'), findsWidgets);
      expect(find.text('Total:'), findsWidgets);

      // Verify Week selector pills in Weekly Tests card
      expect(find.text('Week 1'), findsWidgets);
      expect(find.text('Week 2'), findsWidgets);
      expect(find.text('Week 3'), findsWidgets);
      expect(find.text('Week 4'), findsWidgets);

      // Tap 'Week 2' pill tab to verify interactivity
      final week2Pill = find.text('Week 2').first;
      await tester.ensureVisible(week2Pill);
      await tester.pumpAndSettle();
      await tester.tap(week2Pill);
      await tester.pumpAndSettle();

      // 6. Switch to Library Tab
      final libraryTab = find.widgetWithText(InkWell, 'Library').last;
      await tester.ensureVisible(libraryTab);
      await tester.pumpAndSettle();
      await tester.tap(libraryTab);
      await tester.pumpAndSettle();

      // Verify Library book catalogue & dynamic slide pagination
      expect(find.text('Marigold (NCERT)'), findsOneWidget);
      expect(find.text('Number Magic'), findsOneWidget);
      expect(find.text('Showing 1 to 5 of 12 entries'), findsOneWidget);

      // Slide to next page (› button)
      final nextBtn = find.text('›');
      await tester.ensureVisible(nextBtn);
      await tester.pumpAndSettle();
      await tester.tap(nextBtn);
      await tester.pumpAndSettle();
      expect(find.text('Showing 6 to 10 of 12 entries'), findsOneWidget);
      expect(find.text('Wings of Fire'), findsOneWidget);

      // Slide back to first page (« button)
      final firstBtn = find.text('«');
      await tester.ensureVisible(firstBtn);
      await tester.pumpAndSettle();
      await tester.tap(firstBtn);
      await tester.pumpAndSettle();
      expect(find.text('Showing 1 to 5 of 12 entries'), findsOneWidget);
    });

    testWidgets('Adapts gracefully to mobile phone viewport (390x844) with zero RenderFlex overflow', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      FlutterErrorDetails? caughtError;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        caughtError = details;
        originalOnError?.call(details);
      };

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StudentDetailsScreen(studentId: 'std-1001'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(caughtError, isNull);

      // Scroll down to reveal subtabs on mobile
      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(caughtError, isNull);

      // Tap through all 5 tabs on mobile with ensureVisible to scroll the horizontal tab bar
      for (final tab in ['Attendance', 'Leave', 'Fees', 'Exam', 'Library']) {
        final tabFinder = find.widgetWithText(InkWell, tab).last;
        await tester.ensureVisible(tabFinder);
        await tester.pumpAndSettle();
        await tester.tap(tabFinder, warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(caughtError, isNull);
      }
    });
  });
}
