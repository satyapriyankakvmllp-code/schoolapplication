import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/staff/domain/staff_member_model.dart';
import 'package:frontend/src/features/staff/domain/class_subject_assignment.dart';
import 'package:frontend/src/features/staff/domain/staff_compensation_model.dart';
import 'package:frontend/src/features/staff/domain/staff_login_account_model.dart';
import 'package:frontend/src/features/staff/presentation/staff/common/my_profile_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  StaffMemberModel createTeacherStaff() {
    return StaffMemberModel(
      id: 'STF-2026-0001',
      fullName: 'Anita Sharma',
      category: StaffCategory.teaching,
      designation: 'Senior Teacher',
      department: 'Mathematics',
      qualification: 'M.Sc., B.Ed.',
      specialization: 'Pure Mathematics & Calculus',
      phone: '+91 98765 43210',
      email: 'anita.sharma@school.edu',
      currentAddress: 'Flat 402, Rose Enclave, Bhubaneswar',
      permanentAddress: 'Plot 12, Nayapalli, Bhubaneswar',
      joiningDate: DateTime(2021, 6, 15),
      employmentType: EmploymentType.permanent,
      experienceYears: 6,
      assignedClasses: const [
        ClassSubjectAssignment(
          grade: 'Class 10',
          section: 'A',
          subject: 'Mathematics',
          periodsPerWeek: 6,
          isClassTeacher: true,
        ),
      ],
      compensation: const StaffCompensationModel(
        basicSalary: 52000,
        bankName: 'State Bank of India',
        accountNumber: '987654321098',
        ifscCode: 'SBIN0001234',
        panNumber: 'ABCDE1234F',
      ),
      loginAccount: const StaffLoginAccountModel(
        institutionalEmail: 'anita.sharma@school.edu',
        systemRole: 'teacher',
      ),
    );
  }

  StaffMemberModel createAdminStaff() {
    return StaffMemberModel(
      id: 'STF-2026-0002',
      fullName: 'Dr. Debabrata Jena',
      category: StaffCategory.administrative,
      designation: 'Principal & Academic Director',
      department: 'Administration',
      qualification: 'Ph.D., M.Ed.',
      phone: '+91 98111 22233',
      email: 'principal@school.edu',
      currentAddress: 'Campus Official Bungalow, Bhubaneswar',
      permanentAddress: 'Campus Official Bungalow, Bhubaneswar',
      joiningDate: DateTime(2018, 4, 1),
      employmentType: EmploymentType.permanent,
      experienceYears: 18,
      assignedClasses: const [],
      compensation: const StaffCompensationModel(
        basicSalary: 95000,
        bankName: 'HDFC Bank',
        accountNumber: '50100456789012',
        ifscCode: 'HDFC0000456',
        panNumber: 'PQRST5678G',
      ),
      loginAccount: const StaffLoginAccountModel(
        institutionalEmail: 'principal@school.edu',
        systemRole: 'principal',
      ),
    );
  }

  Widget buildTestableProfileWidget(StaffMemberModel staff, {Size physicalSize = const Size(1280, 800)}) {
    return ProviderScope(
      overrides: [
        currentLoggedInStaffProvider.overrideWithValue(staff),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: MyProfileScreen(),
        ),
      ),
    );
  }

  group('Universal MyProfileScreen Responsive & Role Adaptation Tests', () {
    testWidgets('Renders Teacher profile with teaching assignment matrix on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final teacher = createTeacherStaff();
      await tester.pumpWidget(buildTestableProfileWidget(teacher));
      await tester.pumpAndSettle();

      // Check Header Details
      expect(find.text('Anita Sharma'), findsOneWidget);
      expect(find.textContaining('Senior Teacher • Mathematics'), findsOneWidget);
      expect(find.text('Teaching Faculty'), findsWidgets);
      expect(find.text('STF-2026-0001'), findsOneWidget);

      // Check Micro-KPIs
      expect(find.text('6+ Years'), findsOneWidget);
      expect(find.text('Full-Time Permanent'), findsOneWidget);

      // Check Tabs
      expect(find.text('Overview & Bio'), findsOneWidget);
      expect(find.text('Work & Duties'), findsOneWidget);
      expect(find.text('Payroll & Statutory'), findsOneWidget);
      expect(find.text('Document Vault'), findsOneWidget);

      // Switch to Work & Duties Tab
      await tester.tap(find.text('Work & Duties'));
      await tester.pumpAndSettle();

      // Verify Teaching assignment matrix is displayed
      expect(find.text('Assigned Classes & Subjects Matrix'), findsOneWidget);
      expect(find.text('Class 10 - A'), findsOneWidget);
      expect(find.text('Mathematics'), findsWidgets);
      expect(find.text('Class Teacher'), findsWidgets);
    });

    testWidgets('Renders Administrative Non-Teaching profile (Principal) with operational responsibilities', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final principal = createAdminStaff();
      await tester.pumpWidget(buildTestableProfileWidget(principal));
      await tester.pumpAndSettle();

      // Check Header Details
      expect(find.text('Dr. Debabrata Jena'), findsOneWidget);
      expect(find.textContaining('Principal & Academic Director'), findsOneWidget);
      expect(find.text('Administrative Staff'), findsWidgets);

      // Switch to Work & Duties Tab
      await tester.tap(find.text('Work & Duties'));
      await tester.pumpAndSettle();

      // Verify Operational portfolio is displayed instead of teaching matrix
      expect(find.text('Operational Portfolio & Key Responsibilities'), findsOneWidget);
      expect(find.text('Assigned Classes & Subjects Matrix'), findsNothing);
      expect(find.text('Administrative Reporting Hierarchy'), findsOneWidget);
    });

    testWidgets('Adapts to Phone physical viewport (390x844) with zero RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      FlutterErrorDetails? caughtDetails;
      final oldOnError = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        caughtDetails = details;
        oldOnError?.call(details);
      };

      final teacher = createTeacherStaff();
      await tester.pumpWidget(buildTestableProfileWidget(teacher));
      await tester.pumpAndSettle();

      FlutterError.onError = oldOnError;
      if (caughtDetails != null) {
        debugPrint('CAUGHT DETAILS: ${caughtDetails!.summary}');
        debugPrint('CAUGHT CONTEXT: ${caughtDetails!.context}');
        debugPrint('CAUGHT INFORMATION: ${caughtDetails!.informationCollector?.call().map((d) => d.toString()).join('\n')}');
      }
      expect(caughtDetails, isNull);
      expect(find.text('Anita Sharma'), findsOneWidget);

      // Test mobile tab navigation
      await tester.tap(find.text('Work & Duties'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Payroll & Statutory'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Document Vault'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('Opens Digital ID Badge and Change Password modals correctly', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final teacher = createTeacherStaff();
      await tester.pumpWidget(buildTestableProfileWidget(teacher));
      await tester.pumpAndSettle();

      // Click Digital ID Badge button
      await tester.tap(find.text('Digital ID Badge'));
      await tester.pumpAndSettle();

      expect(find.text('Institutional Digital ID Badge'), findsOneWidget);
      expect(find.text('Print / Dispatch ID Card'), findsOneWidget);

      // Close modal
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      // Click Change Password button
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('Change Portal Password'), findsOneWidget);
      expect(find.text('Current Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
    });
  });
}
