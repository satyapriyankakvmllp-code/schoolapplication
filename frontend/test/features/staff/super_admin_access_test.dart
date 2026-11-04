import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/staff/data/leave_repository.dart';
import 'package:frontend/src/features/staff/domain/staff_compensation_model.dart';
import 'package:frontend/src/features/staff/domain/staff_leave_model.dart';
import 'package:frontend/src/features/staff/domain/staff_menu_item.dart';

void main() {
  group('Super Admin Full Universal Access Tests', () {
    test('isSuperAdmin helper identifies admin and administrator roles', () {
      expect(isSuperAdmin('admin'), isTrue);
      expect(isSuperAdmin('administrator'), isTrue);
      expect(isSuperAdmin('ADMIN'), isTrue);
      expect(isSuperAdmin('principal'), isFalse);
      expect(isSuperAdmin('teacher'), isFalse);
      expect(isSuperAdmin('accountant'), isFalse);
      expect(isSuperAdmin(null), isFalse);
    });

    test('Admin login authenticates STF-2026-0001 with systemRole admin', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      final staff = await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      expect(staff, isNotNull);
      expect(staff!.id, equals('STF-2026-0001'));
      expect(staff.effectiveRole, equals('admin'));
      expect(staff.isSuperAdmin, isTrue);

      final currentStaff = container.read(currentLoggedInStaffProvider);
      expect(currentStaff, isNotNull);
      expect(currentStaff!.id, equals('STF-2026-0001'));
    });

    test('Super Admin sees all 16 staff items + 4 admin CRUD items (20 total)', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      final menuItems = container.read(filteredMenuProvider);
      expect(menuItems.length, equals(allStaffMenuItems.length + adminStaffMenuItems.length));
      expect(menuItems.length, equals(20));

      final routes = menuItems.map((m) => m.routeName).toList();
      // Verifying staff menu items are present
      expect(routes, contains('/staff/dashboard'));
      expect(routes, contains('/staff/my-profile'));
      expect(routes, contains('/staff/my-attendance'));
      expect(routes, contains('/staff/my-leave'));
      expect(routes, contains('/staff/my-payroll'));
      expect(routes, contains('/staff/my-library'));
      expect(routes, contains('/staff/announcements'));
      expect(routes, contains('/staff/section-attendance'));
      expect(routes, contains('/staff/my-classes'));
      expect(routes, contains('/staff/marks-entry'));
      expect(routes, contains('/staff/homework'));
      expect(routes, contains('/staff/fee-collection'));
      expect(routes, contains('/staff/payroll-desk'));
      expect(routes, contains('/staff/library-desk'));
      expect(routes, contains('/staff/fleet-routes'));
      expect(routes, contains('/staff/visitor-log'));

      // Verifying admin CRUD menu items are present
      expect(routes, contains('/admin/staff'));
      expect(routes, contains('/admin/add-staff'));
      expect(routes, contains('/admin/staff-departments'));
      expect(routes, contains('/admin/accounts'));
    });

    test('Compensation masking rule: unmasked details returned when admin is logged in', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      const comp = StaffCompensationModel(
        basicSalary: 85000,
        bankName: 'HDFC Bank',
        accountNumber: '50100492819201',
        ifscCode: 'HDFC0001234',
        panNumber: 'ABCDE1234F',
      );

      // Initially non-admin session: should be masked
      StaffCompensationModel.isAdminSession = false;
      expect(comp.maskedAccountNumber, contains('••••'));
      expect(comp.maskedPanNumber, contains('••••••'));

      // Now log in as admin
      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      // Trigger read so session flag updates
      container.read(currentLoggedInStaffProvider);
      expect(StaffCompensationModel.isAdminSession, isTrue);

      // When admin session is active, getters return raw unmasked values
      expect(comp.maskedAccountNumber, equals('50100492819201'));
      expect(comp.maskedPanNumber, equals('ABCDE1234F'));

      // Logout restores masking
      await authController.logout();
      container.read(currentLoggedInStaffProvider);
      expect(StaffCompensationModel.isAdminSession, isFalse);
      expect(comp.maskedAccountNumber, contains('••••'));
    });

    test('Shared leave workflow: Teacher applies leave -> Admin approves -> Status reflects in repository', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final leaveNotifier = container.read(leaveListProvider.notifier);
      await leaveNotifier.refresh();

      final newLeave = StaffLeaveModel(
        id: 'lv-test-0101',
        staffId: 'STF-2026-0101',
        staffName: 'Dr. Rajeshwari Swaminathan',
        leaveType: 'Medical Leave',
        dateRange: '25 Oct 2026 - 26 Oct 2026',
        fromDate: DateTime(2026, 10, 25),
        toDate: DateTime(2026, 10, 26),
        durationDays: 2,
        applyDate: '21 Oct 2026',
        status: 'Pending',
        reason: 'Root canal treatment and dental recovery',
      );

      // 1. Teacher applies leave
      await leaveNotifier.applyLeave(newLeave);

      final leavesAfterApply = container.read(leaveListProvider).valueOrNull ?? [];
      final applied = leavesAfterApply.firstWhere((l) => l.id == 'lv-test-0101');
      expect(applied.status, equals('Pending'));

      // 2. Admin approves leave
      final approved = await leaveNotifier.approveLeave('lv-test-0101', remarks: 'Approved by Super Admin');
      expect(approved, isTrue);

      // 3. Verify status updated to Approved across shared provider
      final leavesAfterApprove = container.read(leaveListProvider).valueOrNull ?? [];
      final approvedRecord = leavesAfterApprove.firstWhere((l) => l.id == 'lv-test-0101');
      expect(approvedRecord.status, equals('Approved'));
      expect(approvedRecord.adminRemarks, equals('Approved by Super Admin'));
    });
  });
}
