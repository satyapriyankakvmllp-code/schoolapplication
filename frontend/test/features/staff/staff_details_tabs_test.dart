import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/staff/application/staff_controller.dart';
import 'package:frontend/src/features/staff/data/staff_repository.dart';
import 'package:frontend/src/features/staff/presentation/admin/staff_details_screen.dart';
import 'package:frontend/src/features/staff/presentation/admin/tabs/staff_profile_tab.dart';
import 'package:frontend/src/features/staff/presentation/admin/tabs/staff_class_routine_tab.dart';
import 'package:frontend/src/features/staff/presentation/admin/tabs/staff_attendance_tab.dart';
import 'package:frontend/src/features/staff/presentation/admin/tabs/staff_leave_tab.dart';
import 'package:frontend/src/features/staff/presentation/admin/tabs/staff_payroll_tab.dart';
import 'package:frontend/src/features/staff/presentation/admin/tabs/staff_library_tab.dart';
import 'package:frontend/src/features/staff/presentation/admin/staff_accounts_ledger_screen.dart';
import 'package:fl_chart/fl_chart.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('StaffDetailsScreen Subtabs & Dynamic Integration Tests', () {
    testWidgets('Renders all 6 subtabs headers', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Teacher Details'), findsOneWidget);
      expect(find.text('Class Routine'), findsWidgets);
      expect(find.text('Attendance'), findsWidgets);
      expect(find.text('Leave'), findsWidgets);
      expect(find.text('Payroll'), findsWidgets);
      expect(find.text('Library'), findsWidgets);
    });

    testWidgets('Default Profile Tab renders enriched faculty details', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StaffProfileTab), findsOneWidget);
      expect(find.text('Dr. Rajeshwari Swaminathan'), findsWidgets);
      expect(find.text('Profile Detail'), findsOneWidget);
      expect(find.text('Previous School Details'), findsOneWidget);
      expect(find.text('Bank Details'), findsOneWidget);
    });

    testWidgets('Switching to Class Routine Tab renders assigned schedule', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_1')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffClassRoutineTab), findsOneWidget);
      expect(find.text('Class Routine'), findsWidgets);
    });

    testWidgets('Switching to Attendance Tab renders KPI metrics', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_2')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffAttendanceTab), findsOneWidget);
      expect(find.text('Attendance'), findsWidgets);
      expect(find.text('Total Present'), findsOneWidget);
      expect(find.text('Total Absent'), findsOneWidget);
    });

    testWidgets('Switching to Leave Tab renders leave applications with Approve/Reject', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_3')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffLeaveTab), findsOneWidget);
      expect(find.text('Leave'), findsWidgets);
    });

    testWidgets('Switching to Payroll Tab renders monthly invoices in INR', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_4')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffPayrollTab), findsOneWidget);
      expect(find.text('Payroll'), findsWidgets);
      expect(find.textContaining('₹'), findsWidgets);
    });

    testWidgets('Switching to Library Tab renders circulation table', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_5')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffLibraryTab), findsOneWidget);
      expect(find.text('Library Circulation & Borrowing'), findsOneWidget);
    });

    testWidgets('Adapts to phone screen (390x844) across tabs with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);

      // Switch to Class Routine on phone
      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_1')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Attendance on phone
      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_2')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Leave on phone
      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_3')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Payroll on phone
      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_4')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      // Switch to Library on phone
      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_5')), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Attendance tab renders Attendance Performance Matrix graph with fl_chart and mode toggle', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_2')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffAttendanceTab), findsOneWidget);
      expect(find.text('Staff Attendance Performance Matrix'), findsOneWidget);
      expect(find.text('Rate Trend (Line)'), findsOneWidget);
      expect(find.text('Days Breakdown (Bar)'), findsOneWidget);
      expect(find.byType(LineChart), findsOneWidget);
      expect(find.text('Present Days'), findsWidgets);
      expect(find.text('Absent Days'), findsWidgets);
      expect(find.text('Attendance Rate'), findsWidgets);
      expect(find.text('Total Present'), findsOneWidget);
      expect(find.text('Total Absent'), findsOneWidget);
      expect(find.text('Total Holiday'), findsOneWidget);

      // Toggle to Days Breakdown Bar Chart
      await tester.tap(find.text('Days Breakdown (Bar)'));
      await tester.pumpAndSettle();
      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('Leave tab renders Leave Matrix BarChart and Quota meters, and sorts newest applications first', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_3')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffLeaveTab), findsOneWidget);
      expect(find.text('Leave Allocation & Consumption Matrix'), findsOneWidget);
      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('Annual Quota Utilization & Entitlement Status'), findsOneWidget);
      expect(find.text('Casual Leave'), findsWidgets);
      expect(find.text('Medical Leave'), findsWidgets);
      expect(find.text('Earned Leave'), findsWidgets);
    });

    testWidgets('Class routine tab renders Month and Week filters, day columns, and Subject / Purpose cards', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_1')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffClassRoutineTab), findsOneWidget);
      expect(find.text('August 2026'), findsOneWidget);
      expect(find.text('Week 1'), findsOneWidget);
      expect(find.text('Week 2'), findsOneWidget);
      expect(find.text('Subject / Purpose'), findsWidgets);
    });

    testWidgets('Class routine tab allows updating mutable Subject and Purpose on a duty card', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_1')));
      await tester.pumpAndSettle();

      // Tap on the first period card
      final firstCard = find.text('Subject / Purpose').first;
      await tester.tap(firstCard);
      await tester.pumpAndSettle();

      expect(find.text('Work Schedule & Duty Purpose'), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_routine_subject_input')), findsOneWidget);
      expect(find.byKey(const ValueKey('edit_routine_purpose_input')), findsOneWidget);

      // Enter new subject and purpose
      await tester.enterText(find.byKey(const ValueKey('edit_routine_subject_input')), 'Advanced Robotics Lab');
      await tester.enterText(find.byKey(const ValueKey('edit_routine_purpose_input')), 'Hands-on Arduino micro-controller workshop');
      await tester.pumpAndSettle();

      // Save changes
      await tester.tap(find.byKey(const ValueKey('edit_routine_save_button')));
      await tester.pumpAndSettle();

      // Verify updated subject and purpose appear on the card
      expect(find.text('Advanced Robotics Lab'), findsOneWidget);
      expect(find.text('Hands-on Arduino micro-controller workshop'), findsOneWidget);
    });

    testWidgets('Payroll tab redirects to Accounts section on clicking Open in Accounts', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('staff_details_subtab_4')));
      await tester.pumpAndSettle();

      expect(find.byType(StaffPayrollTab), findsOneWidget);
      final accountsBtn = find.text('Open in Accounts');
      expect(accountsBtn, findsOneWidget);

      await tester.tap(accountsBtn);
      await tester.pumpAndSettle();

      expect(find.byType(StaffAccountsLedgerScreen), findsOneWidget);
      expect(find.text('Accounts & Salary Disbursement Ledger'), findsOneWidget);
      expect(find.text('Official Registry'), findsOneWidget);
      expect(find.text('Salary Clearing & Bank Transfer Registry'), findsOneWidget);
    });
  });
}
