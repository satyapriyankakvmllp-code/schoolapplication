import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/staff/presentation/staff/common/my_attendance_screen.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/staff/application/staff_controller.dart';
import 'package:frontend/src/features/staff/domain/staff_member_model.dart';
import 'package:frontend/src/features/staff/domain/staff_compensation_model.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/staff/data/staff_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  StaffMemberModel createSampleStaff({String role = 'teacher'}) {
    return StaffMemberModel(
      id: 'STF-2026-0101',
      fullName: 'Dr. Rajeshwari Panda',
      category: StaffCategory.teaching,
      designation: 'Senior Faculty',
      department: 'Mathematics',
      qualification: 'Ph.D., M.Sc.',
      phone: '+91 98765 43210',
      email: 'rajeshwari@edupulse.edu',
      currentAddress: 'Bhubaneswar, Odisha',
      permanentAddress: 'Bhubaneswar, Odisha',
      joiningDate: DateTime(2020, 6, 1),
      employmentType: EmploymentType.permanent,
      experienceYears: 10,
      assignedClasses: const [],
      compensation: const StaffCompensationModel(
        basicSalary: 65000,
        bankName: 'SBI',
        accountNumber: '1234567890',
        ifscCode: 'SBIN0001',
        panNumber: 'ABCDE1234F',
      ),
    );
  }

  Widget createTestWidget({required Widget child, StaffMemberModel? staff, Size physicalSize = const Size(1280, 800)}) {
    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
        if (staff != null) currentLoggedInStaffProvider.overrideWithValue(staff),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('MyAttendanceScreen Tests', () {
    testWidgets('Renders all attendance sections properly on desktop viewport', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyAttendanceScreen(), staff: staff));
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('My Attendance Ledger'), findsOneWidget);
      expect(find.text('Export Slip'), findsOneWidget);
      expect(find.text('Request Regularization'), findsWidgets);

      // Today's Live Status
      expect(find.text('TODAY’S SHIFT STATUS: 22 OCT 2026'), findsOneWidget);
      expect(find.text('PUNCH-IN VERIFIED'), findsOneWidget);

      // KPIs
      expect(find.text('Total Working Days'), findsOneWidget);
      expect(find.text('Present Days'), findsOneWidget);
      expect(find.text('Net Payable Days'), findsOneWidget);

      // Late penalty banner
      expect(find.text('Institutional Punctuality Rule Alert'), findsOneWidget);

      // Calendar Matrix
      expect(find.text('October 2026 Daily Log Matrix'), findsOneWidget);
    });

    testWidgets('Adapts to Phone physical viewport (390x844) with zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyAttendanceScreen(), staff: staff));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('My Attendance Ledger'), findsOneWidget);
      expect(find.text('TODAY’S SHIFT STATUS: 22 OCT 2026'), findsOneWidget);
    });

    testWidgets('Clicking on a calendar day opens details bottom sheet with Day details', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyAttendanceScreen(), staff: staff));
      await tester.pumpAndSettle();

      // Tap on day 1
      final day1 = find.text('1').first;
      await tester.tap(day1);
      await tester.pumpAndSettle();

      expect(find.textContaining('1 Oct 2026'), findsOneWidget);
      expect(find.text('Check-In Time'), findsOneWidget);
      expect(find.text('Check-Out Time'), findsOneWidget);
    });

    testWidgets('Submitting regularization request adds new request to state', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyAttendanceScreen(), staff: staff));
      await tester.pumpAndSettle();

      // Tap 'Request Regularization' in the header
      final regBtn = find.text('Request Regularization').first;
      expect(regBtn, findsOneWidget);
      await tester.tap(regBtn);
      await tester.pumpAndSettle();

      expect(find.text('Regularization / Missed Punch'), findsOneWidget);

      // Enter remarks
      await tester.enterText(find.byType(TextFormField).last, 'Official outdoor exam meeting at Directorate');
      await tester.pumpAndSettle();

      // Submit
      await tester.tap(find.text('Submit Request'));
      await tester.pumpAndSettle();

      expect(find.textContaining('request submitted for Principal/Admin approval'), findsOneWidget);
    });

    testWidgets('Header has no fingerprint icon and changing month dynamically updates all data', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyAttendanceScreen(), staff: staff));
      await tester.pumpAndSettle();

      // 1. Verify foot/fingerprint icon is removed from top header
      expect(find.byIcon(Icons.fingerprint_rounded), findsNothing);

      // Verify October default data
      expect(find.text('October 2026 Daily Log Matrix'), findsOneWidget);
      expect(find.text('TODAY’S SHIFT STATUS: 22 OCT 2026'), findsOneWidget);
      expect(find.text('25 / 26'), findsOneWidget); // Net payable in Oct (26 working days - 1 absent)

      // 2. Switch month to 'September 2026'
      await tester.tap(find.text('October 2026'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('September 2026').last);
      await tester.pumpAndSettle();

      // Verify dynamic updates
      expect(find.text('September 2026 Daily Log Matrix'), findsOneWidget);
      expect(find.text('ARCHIVED LEDGER: September 2026'), findsOneWidget);
      expect(find.text('AUDITED & CLOSED'), findsOneWidget);
      expect(find.text('Perfect Punctuality Record'), findsOneWidget);
      expect(find.textContaining('Zero late arrivals recorded for September 2026'), findsOneWidget);
      expect(find.text('25 / 25'), findsOneWidget); // Net payable in Sep (25 / 25 full attendance)
    });
  });
}
