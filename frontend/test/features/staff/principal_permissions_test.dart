import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/classes/application/classes_access.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/staff/data/leave_repository.dart';
import 'package:frontend/src/features/staff/domain/staff_compensation_model.dart';
import 'package:frontend/src/features/staff/domain/staff_member_model.dart';
import 'package:frontend/src/features/staff/presentation/admin/tabs/staff_payroll_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';

StaffMemberModel _createMockPrincipal() {
  return StaffMemberModel(
    id: 'STF-2026-0002',
    fullName: 'Dr. Anand Roy',
    category: StaffCategory.administrative,
    designation: 'Principal & Executive Head',
    department: 'Administration',
    qualification: 'Ph.D. in Educational Leadership',
    phone: '+91 98765 43210',
    email: 'principal@school.edu',
    currentAddress: 'Campus Quarters',
    permanentAddress: 'Campus Quarters',
    joiningDate: DateTime(2020, 1, 1),
    employmentType: EmploymentType.permanent,
    assignedClasses: const [],
    compensation: const StaffCompensationModel(
      basicSalary: 85000,
      bankName: 'SBI',
      accountNumber: '1234567890',
      ifscCode: 'SBIN0001234',
      panNumber: 'ABCDE1234F',
    ),
    status: StaffStatus.active,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Principal Role Permissions & Navigation Gating', () {
    test('filteredMenuProvider hides Add Staff and Accounts Ledger from Principal', () {
      final container = ProviderContainer(
        overrides: [
          currentLoggedInStaffProvider.overrideWithValue(_createMockPrincipal()),
        ],
      );
      addTearDown(container.dispose);

      final menu = container.read(filteredMenuProvider);
      final rootIds = menu.map((m) => m.id).toSet();
      final allMenuIds = <String>{
        ...rootIds,
        for (final m in menu) ...m.subItems.map((s) => s.id),
      };

      // Allowed Root Modules for Principal (dummy dashboard removed as requested)
      expect(rootIds.contains('dashboard'), isFalse);
      expect(rootIds.contains('student-admissions'), isTrue);
      expect(rootIds.contains('faculty-staff'), isTrue);
      expect(rootIds.contains('classes-academics'), isTrue);
      expect(rootIds.contains('examinations-grading'), isTrue);
      expect(rootIds.contains('finance-campus'), isTrue);
      expect(rootIds.contains('announcements'), isTrue);
      expect(rootIds.contains('principal-personal'), isTrue);

      // Allowed Sub-items for Principal
      expect(allMenuIds.contains('principal-admissions-pipeline'), isTrue);
      expect(allMenuIds.contains('principal-students'), isTrue);
      expect(allMenuIds.contains('admin-staff-directory'), isTrue);
      expect(allMenuIds.contains('principal-faculty-leaves'), isTrue);
      expect(allMenuIds.contains('principal-classes'), isTrue);
      expect(allMenuIds.contains('principal-teacher-workload'), isTrue);
      expect(allMenuIds.contains('principal-curriculum'), isTrue);
      expect(allMenuIds.contains('principal-timetable'), isTrue);
      expect(allMenuIds.contains('principal-fee-analytics'), isTrue);
      expect(allMenuIds.contains('principal-fee-waivers'), isTrue);
      expect(allMenuIds.contains('my-profile'), isTrue);
      expect(allMenuIds.contains('my-attendance'), isTrue);
      expect(allMenuIds.contains('my-leave'), isTrue);

      // Strictly Restricted from Principal (Super Admin only)
      expect(allMenuIds.contains('admin-add-staff'), isFalse);
      expect(allMenuIds.contains('admin-accounts-ledger'), isFalse);
    });

    test('Leave segregation: Principal cannot see their own leave in approval board', () async {
      final principal = _createMockPrincipal();

      final container = ProviderContainer(
        overrides: [
          currentLoggedInStaffProvider.overrideWithValue(principal),
        ],
      );
      addTearDown(container.dispose);

      await container.read(leaveListProvider.future);

      final leavesForPrincipal = container.read(pendingLeavesForPrincipalProvider);
      // Ensure none of the pending leaves belong to Dr. Anand Roy
      for (final l in leavesForPrincipal) {
        expect(l.staffId, isNot(equals('STF-2026-0002')));
      }

      // Principal's leave MUST appear in admin review provider
      final leavesForAdmin = container.read(pendingPrincipalLeavesForAdminProvider);
      final hasPrincipalLeave = leavesForAdmin.any((l) => l.staffId == 'STF-2026-0002');
      expect(hasPrincipalLeave, isTrue);
    });

    test('Classes Permissions: Principal has full management access to classes & teachers', () {
      final principal = _createMockPrincipal();

      final container = ProviderContainer(
        overrides: [
          currentLoggedInStaffProvider.overrideWithValue(principal),
        ],
      );
      addTearDown(container.dispose);

      final actor = container.read(classesActorProvider);
      expect(actor.permissions.canManageClasses, isTrue);
      expect(actor.permissions.canManageSubjects, isTrue);
      expect(actor.permissions.canManageSections, isTrue);
      expect(actor.permissions.canAssignTeachers, isTrue);
      expect(actor.permissions.canManageTimetable, isTrue);
    });

    testWidgets('Payroll Tab masks financial records when viewed by Principal', (tester) async {
      final targetStaff = StaffMemberModel(
        id: 'STF-2026-0101',
        fullName: 'Dr. Rajeshwari Swaminathan',
        category: StaffCategory.teaching,
        designation: 'Senior PGT Mathematics',
        department: 'Science',
        qualification: 'M.Sc., B.Ed.',
        phone: '+91 94444 11223',
        email: 'rajeshwari.swaminathan@edupulse.org',
        currentAddress: 'Chennai',
        permanentAddress: 'Chennai',
        joiningDate: DateTime(2018, 6, 12),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [],
        compensation: const StaffCompensationModel(
          basicSalary: 62000,
          bankName: 'HDFC Bank',
          accountNumber: '50100432198765',
          ifscCode: 'HDFC0001234',
          panNumber: 'ABCPS1234K',
        ),
        status: StaffStatus.active,
      );

      final principal = _createMockPrincipal();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentLoggedInStaffProvider.overrideWithValue(principal),
            activeUserRoleProvider.overrideWith((ref) => null),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: StaffPayrollTab(
                staff: targetStaff,
                isDark: false,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify that confidential shield card is displayed
      expect(find.text('Confidential Compensation & Payroll Record'), findsOneWidget);
      // Sensitive basic salary amounts should NOT be rendered
      expect(find.text('Total Net Salary'), findsNothing);
    });
  });
}
