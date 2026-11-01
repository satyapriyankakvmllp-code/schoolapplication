import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/staff/data/staff_repository.dart';
import 'package:frontend/src/features/staff/domain/class_subject_assignment.dart';
import 'package:frontend/src/features/staff/domain/staff_compensation_model.dart';
import 'package:frontend/src/features/staff/domain/staff_login_account_model.dart';
import 'package:frontend/src/features/staff/domain/staff_member_model.dart';

void main() {
  group('Staff Domain Models Tests', () {
    test('ClassSubjectAssignment serializes and deserializes accurately', () {
      const assignment = ClassSubjectAssignment(
        grade: 'Class 10',
        section: 'A',
        subject: 'Mathematics',
        isClassTeacher: true,
        periodsPerWeek: 6,
      );

      final map = assignment.toMap();
      final restored = ClassSubjectAssignment.fromMap(map);

      expect(restored.grade, 'Class 10');
      expect(restored.section, 'A');
      expect(restored.subject, 'Mathematics');
      expect(restored.isClassTeacher, isTrue);
      expect(restored.periodsPerWeek, 6);
      expect(restored.displayName, 'Class 10-A • Mathematics');
    });

    test('StaffCompensationModel accurately masks sensitive financial data', () {
      const compensation = StaffCompensationModel(
        basicSalary: 85000.0,
        payFrequency: 'Monthly',
        bankName: 'State Bank of India',
        accountNumber: '30192847561',
        ifscCode: 'SBIN0004512',
        panNumber: 'ABCPS1234E',
        epfUan: '100984726152',
      );

      expect(compensation.maskedAccountNumber.endsWith('7561'), isTrue);
      expect(compensation.maskedAccountNumber.contains('••••'), isTrue);
      expect(compensation.maskedPanNumber.startsWith('AB'), isTrue);
      expect(compensation.maskedPanNumber.endsWith('4E'), isTrue);
      expect(compensation.maskedPanNumber.contains('••••••'), isTrue);
    });

    test('StaffMemberModel correctly computes initials and primary teacher assignment', () {
      final staff = StaffMemberModel(
        id: 'STF-2026-0101',
        fullName: 'Dr. Rajeshwari Swaminathan',
        category: StaffCategory.teaching,
        designation: 'HOD Mathematics',
        department: 'Mathematics',
        qualification: 'Ph.D.',
        specialization: 'Calculus',
        phone: '+91 98450 12345',
        email: 'rajeshwari@edupulse.edu.in',
        currentAddress: 'Bengaluru',
        permanentAddress: 'Chennai',
        joiningDate: DateTime(2020, 6, 15),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 10',
            section: 'A',
            subject: 'Mathematics',
            isClassTeacher: true,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 85000,
          bankName: 'SBI',
          accountNumber: '12345678',
          ifscCode: 'SBIN0001',
          panNumber: 'ABCDE1234F',
        ),
        status: StaffStatus.active,
      );

      expect(staff.isClassTeacher, isTrue);
      expect(staff.primaryClassAssignment?.grade, 'Class 10');
      expect(staff.initials, 'RS');
    });
  });

  group('MockStaffRepository Tests', () {
    late MockStaffRepository repository;

    setUp(() {
      repository = MockStaffRepository();
    });

    test('Loads pre-seeded Indian faculty records', () async {
      final list = await repository.getStaffList();
      expect(list.length, greaterThanOrEqualTo(10));

      final rajeshwari = await repository.getStaffById('STF-2026-0101');
      expect(rajeshwari, isNotNull);
      expect(rajeshwari!.fullName, 'Dr. Rajeshwari Swaminathan');
      expect(rajeshwari.category, StaffCategory.teaching);
      expect(rajeshwari.assignedClasses.length, 2);
    });

    test('Generates next sequential Staff ID', () async {
      final nextId = await repository.generateNextStaffId();
      expect(nextId, 'STF-2026-0112');
    });

    test('Saves new staff member and retrieves by ID', () async {
      final nextId = await repository.generateNextStaffId();
      final newStaff = StaffMemberModel(
        id: nextId,
        fullName: 'Arun Kumar',
        category: StaffCategory.teaching,
        designation: 'TGT Chemistry',
        department: 'Science',
        qualification: 'M.Sc. Chemistry, B.Ed.',
        specialization: 'Organic Chemistry',
        phone: '+91 98765 43210',
        email: 'arun.kumar@edupulse.edu.in',
        currentAddress: 'Indiranagar, Bengaluru',
        permanentAddress: 'Mysuru',
        joiningDate: DateTime(2024, 7, 1),
        employmentType: EmploymentType.permanent,
        assignedClasses: const [
          ClassSubjectAssignment(
            grade: 'Class 9',
            section: 'A',
            subject: 'Chemistry',
            isClassTeacher: true,
          ),
        ],
        compensation: const StaffCompensationModel(
          basicSalary: 55000,
          bankName: 'Canara Bank',
          accountNumber: '9876543210',
          ifscCode: 'CNRB0001234',
          panNumber: 'ARNPK1234Z',
        ),
        loginAccount: const StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: 'arun.kumar@edupulse.edu.in',
          systemRole: 'teacher',
        ),
        status: StaffStatus.active,
      );

      final saved = await repository.saveStaff(newStaff);
      expect(saved.id, nextId);

      final retrieved = await repository.getStaffById(nextId);
      expect(retrieved, isNotNull);
      expect(retrieved!.fullName, 'Arun Kumar');

      // Next ID should now be incremented
      final followingId = await repository.generateNextStaffId();
      expect(followingId, 'STF-2026-0113');
    });

    test('Deactivates staff member properly', () async {
      final success = await repository.deleteOrDeactivateStaff('STF-2026-0102');
      expect(success, isTrue);

      final updated = await repository.getStaffById('STF-2026-0102');
      expect(updated, isNotNull);
      expect(updated!.status, StaffStatus.inactive);
    });
  });
}
