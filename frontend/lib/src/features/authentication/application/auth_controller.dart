import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/user_model.dart';

class RoleMetadata {
  final UserRole role;
  final String title;
  final String shortLabel;
  final String designation;
  final String description;
  final IconData icon;
  final Color primaryColor;
  final Color lightBackgroundColor;
  final Color darkBackgroundColor;
  final String demoEmail;
  final List<String> keyFeatures;

  const RoleMetadata({
    required this.role,
    required this.title,
    required this.shortLabel,
    required this.designation,
    required this.description,
    required this.icon,
    required this.primaryColor,
    required this.lightBackgroundColor,
    required this.darkBackgroundColor,
    required this.demoEmail,
    required this.keyFeatures,
  });
}

class RoleDirectory {
  static final Map<UserRole, RoleMetadata> registry = {
    UserRole.parent: const RoleMetadata(
      role: UserRole.parent,
      title: 'Parent & Guardian Portal',
      shortLabel: 'Parent Portal',
      designation: 'Family & Guardian Hub',
      description:
          'Manage child profiles, submit digital intakes, review reports & toggle emergency contacts.',
      icon: Icons.family_restroom,
      primaryColor: Color(0xFF10B981), // Emerald
      lightBackgroundColor: Color(0xFFECFDF5),
      darkBackgroundColor: Color(0xFF064E3B),
      demoEmail: 'parent.rajesh@gmail.com',
      keyFeatures: [
        'Sibling / Child Context Switcher',
        'Direct Online Child Intake Form',
        'Emergency Contact & Alerts Toggle',
        'Live Application Status Tracker',
      ],
    ),
    UserRole.admissions: const RoleMetadata(
      role: UserRole.admissions,
      title: 'Admissions & Front-Desk Officer',
      shortLabel: 'Front-Desk Desk',
      designation: 'Intake & Verification Officer',
      description:
          'Log walk-in inquiries, screen applicant documents, schedule interviews & print ID badges.',
      icon: Icons.badge_outlined,
      primaryColor: Color(0xFFF59E0B), // Amber
      lightBackgroundColor: Color(0xFFFFFBEB),
      darkBackgroundColor: Color(0xFF78350F),
      demoEmail: 'admissions@edupulse.edu',
      keyFeatures: [
        'Inquiry Desk & Walk-In Intake Studio',
        'Certificate Screening & Verification',
        'Interview Panel Calendar Scheduler',
        'Barcode ID Card Studio & Print',
      ],
    ),
    UserRole.admin: const RoleMetadata(
      role: UserRole.admin,
      title: 'School Administrator',
      shortLabel: 'Admin Console',
      designation: 'Superintendent & Executive',
      description:
          'Executive board intake approvals, class grade & section assignments, roll sequencing & audits.',
      icon: Icons.admin_panel_settings_outlined,
      primaryColor: Color(0xFF6366F1), // Indigo
      lightBackgroundColor: Color(0xFFEEF2FF),
      darkBackgroundColor: Color(0xFF312E81),
      demoEmail: 'admin@edupulse.edu',
      keyFeatures: [
        'Executive Admissions Sign-Off Board',
        'Roll Number Auto-Sequencer',
        'Student Enrollment Status Overrides',
        'Comprehensive Audit & Access Trail',
      ],
    ),
    UserRole.teacher: const RoleMetadata(
      role: UserRole.teacher,
      title: 'Teacher & Class In-Charge',
      shortLabel: 'Teacher Roster',
      designation: 'Class 10-A In-Charge',
      description:
          'Active classroom rosters, emergency contact dials, student blood group safety cards & behavioral tags.',
      icon: Icons.assignment_ind_outlined,
      primaryColor: Color(0xFF3B82F6), // Blue
      lightBackgroundColor: Color(0xFFEFF6FF),
      darkBackgroundColor: Color(0xFF1E3A8A),
      demoEmail: 'teacher.anita@edupulse.edu',
      keyFeatures: [
        'Active Section Class Roster',
        '1-Tap Emergency Contact Card',
        'Blood Group & Medical Alert Tags',
        'Private Classroom Behavioral Notes',
      ],
    ),
    UserRole.student: const RoleMetadata(
      role: UserRole.student,
      title: 'Student Self-Service Hub',
      shortLabel: 'Student Hub',
      designation: 'Grade 10-A Enrolled Scholar',
      description:
          'Digital ID badge, enrollment confirmation, enrolled subject timetable & personal info update requests.',
      icon: Icons.school_outlined,
      primaryColor: Color(0xFF06B6D4), // Cyan
      lightBackgroundColor: Color(0xFFECFEFF),
      darkBackgroundColor: Color(0xFF164E63),
      demoEmail: 'aarav.sharma@student.edupulse.edu',
      keyFeatures: [
        'Digital Student ID Card Preview',
        'Academic Enrollment Record',
        'Correction Request Dispatch Ticket',
        'Subject Catalog & Schedule',
      ],
    ),
    UserRole.finance: const RoleMetadata(
      role: UserRole.finance,
      title: 'Finance & Accounts Officer',
      shortLabel: 'Finance Ledger',
      designation: 'Bursar & Accounts Comptroller',
      description:
          'Issue admission fee receipts, manage installment payment schedules & grant admission clearance tokens.',
      icon: Icons.account_balance_wallet_outlined,
      primaryColor: Color(0xFFEC4899), // Pink
      lightBackgroundColor: Color(0xFFFDF2F8),
      darkBackgroundColor: Color(0xFF831843),
      demoEmail: 'finance@edupulse.edu',
      keyFeatures: [
        'Admission Fee Clearance Bridge',
        'Fee Structure & Term Schedules',
        'Digital Fee Receipt Generator',
        'Financial Clearance Lock / Unlock',
      ],
    ),
  };

  static final Map<UserRole, UserModel> mockUsers = {
    UserRole.parent: UserModel(
      id: 'usr-2001',
      email: 'rajesh.sharma@example.com',
      phoneNumber: '+91 98765 43210',
      userRole: UserRole.parent,
      firstName: 'Rajesh',
      lastName: 'Sharma',
      gender: Gender.male,
      status: AccountStatus.active,
      createdAt: DateTime(2025, 1, 10),
      updatedAt: DateTime(2026, 2, 1),
    ),
    UserRole.admissions: UserModel(
      id: 'USR-ADM-01',
      email: 'admissions@edupulse.edu',
      phoneNumber: '+91 98111 22334',
      userRole: UserRole.admissions,
      firstName: 'Priya',
      lastName: 'Verma',
      gender: Gender.female,
      status: AccountStatus.active,
      createdAt: DateTime(2024, 6, 1),
      updatedAt: DateTime(2026, 1, 15),
    ),
    UserRole.admin: UserModel(
      id: 'USR-ADMIN-01',
      email: 'admin@edupulse.edu',
      phoneNumber: '+91 99000 11223',
      userRole: UserRole.admin,
      firstName: 'Dr. Sarah',
      lastName: 'Jenkins',
      gender: Gender.female,
      status: AccountStatus.active,
      createdAt: DateTime(2023, 4, 1),
      updatedAt: DateTime(2026, 3, 1),
    ),
    UserRole.teacher: UserModel(
      id: 'USR-TEACH-01',
      email: 'teacher.anita@edupulse.edu',
      phoneNumber: '+91 97788 99001',
      userRole: UserRole.teacher,
      firstName: 'Anita',
      lastName: 'Desai',
      gender: Gender.female,
      status: AccountStatus.active,
      createdAt: DateTime(2024, 8, 12),
      updatedAt: DateTime(2026, 2, 20),
    ),
    UserRole.student: UserModel(
      id: 'usr-1001',
      email: 'aarav.sharma@example.com',
      phoneNumber: '+91 98765 43210',
      userRole: UserRole.student,
      firstName: 'Aarav',
      lastName: 'Sharma',
      gender: Gender.male,
      status: AccountStatus.active,
      createdAt: DateTime(2025, 4, 1),
      updatedAt: DateTime(2026, 3, 5),
    ),
    UserRole.finance: UserModel(
      id: 'USR-FIN-01',
      email: 'finance@edupulse.edu',
      phoneNumber: '+91 96655 44332',
      userRole: UserRole.finance,
      firstName: 'Vikram',
      lastName: 'Mehta',
      gender: Gender.male,
      status: AccountStatus.active,
      createdAt: DateTime(2024, 1, 5),
      updatedAt: DateTime(2026, 2, 10),
    ),
  };
}

/// The currently active role. If `null`, the app renders the Portal Gateway / Login screen.
final activeUserRoleProvider = StateProvider<UserRole?>((ref) => null);

/// The active user model based on the active role.
final currentUserProfileProvider = Provider<UserModel?>((ref) {
  final role = ref.watch(activeUserRoleProvider);
  if (role == null) return null;
  return RoleDirectory.mockUsers[role];
});

/// Contextual provider for parent portal active child ID
final parentActiveChildIdProvider = StateProvider<String>((ref) => 'std-1001');
