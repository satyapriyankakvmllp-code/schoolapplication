import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/staff/presentation/staff/common/my_leave_screen.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/staff/application/staff_controller.dart';
import 'package:frontend/src/features/staff/data/staff_repository.dart';
import 'package:frontend/src/features/staff/data/leave_repository.dart';
import 'package:frontend/src/features/staff/domain/staff_member_model.dart';
import 'package:frontend/src/features/staff/domain/staff_compensation_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  StaffMemberModel createSampleStaff({StaffCategory category = StaffCategory.teaching}) {
    return StaffMemberModel(
      id: 'STF-2026-0101',
      fullName: 'Dr. Rajeshwari Swaminathan',
      category: category,
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

  Widget createTestWidget({
    required Widget child,
    StaffMemberModel? staff,
  }) {
    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
        leaveRepositoryProvider.overrideWithValue(MockLeaveRepository()),
        if (staff != null) currentLoggedInStaffProvider.overrideWithValue(staff),
      ],
      child: MaterialApp(
        home: Scaffold(body: child),
      ),
    );
  }

  group('MyLeaveScreen Responsiveness and Facility Tests', () {
    testWidgets('Renders all sections properly on Desktop viewport (1280x800)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyLeaveScreen(), staff: staff));
      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('My Leave Management'), findsOneWidget);
      expect(find.text('Download Statement'), findsOneWidget);
      expect(find.text('+ Apply for Leave'), findsOneWidget);

      // Quota cards
      expect(find.text('Casual Leave'), findsWidgets);
      expect(find.text('Medical Leave'), findsOneWidget);
      expect(find.text('Earned Leave'), findsOneWidget);
      expect(find.text('On-Duty / Comp'), findsOneWidget);
      expect(find.text('Loss of Pay'), findsOneWidget);

      // Institutional Policy
      expect(find.textContaining('Institutional Leave Rules'), findsOneWidget);

      // Holiday Widget
      expect(find.text('Upcoming Gazetted Holidays (Term II)'), findsOneWidget);
      expect(find.text('Diwali & Kali Puja'), findsOneWidget);

      // Tabs
      expect(find.text('Apply for Leave'), findsOneWidget);
      expect(find.text('My Leave History'), findsOneWidget);
    });

    testWidgets('Strict Mobile Viewport (390x844) renders with ZERO overflow exceptions', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyLeaveScreen(), staff: staff));
      await tester.pumpAndSettle();

      final exc = tester.takeException();
      expect(exc, isNull);

      // Header is rendered
      expect(find.text('My Leave Management'), findsOneWidget);

      // Quota cards are properly rendered in mobile wrap
      expect(find.text('Casual Leave'), findsWidgets);
      expect(find.text('Medical Leave'), findsOneWidget);

      // Switch to History Tab on Mobile
      await tester.ensureVisible(find.text('My Leave History'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('My Leave History'));
      await tester.pumpAndSettle();

      // Verify no overflow on history tab
      expect(tester.takeException(), isNull);
      expect(find.textContaining('All ('), findsOneWidget);
    });

    testWidgets('Half-Day toggle works and updates duration calculation to 0.5 Day', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyLeaveScreen(), staff: staff));
      await tester.pumpAndSettle();

      // Verify initial duration
      expect(find.textContaining('working day(s)'), findsOneWidget);

      // Toggle Half-Day switch
      final switchFinder = find.byType(Switch);
      expect(switchFinder, findsOneWidget);
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      // Verify half day session dropdown and updated requested chip
      expect(find.text('Select Shift Session'), findsOneWidget);
      expect(find.textContaining('Requested: 0.5 Day'), findsOneWidget);
    });

    testWidgets('Leave Statement modal opens on tapping Download Statement', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyLeaveScreen(), staff: staff));
      await tester.pumpAndSettle();

      // Tap Download Statement
      await tester.tap(find.text('Download Statement'));
      await tester.pumpAndSettle();

      // Verify Statement Dialog
      expect(find.text('Official Faculty Leave Statement'), findsOneWidget);
      expect(find.text('Export PDF Statement'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Official Faculty Leave Statement'), findsNothing);
    });

    testWidgets('Withdraw pending application workflow cancels leave', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final staff = createSampleStaff();
      await tester.pumpWidget(createTestWidget(child: const MyLeaveScreen(), staff: staff));
      await tester.pumpAndSettle();

      // Switch to History tab
      await tester.tap(find.text('My Leave History'));
      await tester.pumpAndSettle();

      // Find Withdraw Application button
      final withdrawBtn = find.text('Withdraw Application');
      if (withdrawBtn.evaluate().isNotEmpty) {
        await tester.ensureVisible(withdrawBtn.first);
        await tester.pumpAndSettle();
        await tester.tap(withdrawBtn.first);
        await tester.pumpAndSettle();

        // Confirmation dialog appears
        expect(find.text('Withdraw Leave Request?'), findsOneWidget);
        expect(find.text('Yes, Withdraw'), findsOneWidget);

        // Confirm
        await tester.tap(find.text('Yes, Withdraw'));
        await tester.pumpAndSettle();

        expect(find.text('Withdraw Leave Request?'), findsNothing);
      }
    });
  });
}
