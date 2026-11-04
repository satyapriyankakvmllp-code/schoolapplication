import 'package:flutter/material.dart';
import '../../../routing/route_names.dart';

class StaffMenuItem {
  final String id;
  final String label;
  final IconData iconData;
  final String routeName;
  final List<String> allowedRoles;
  final bool requiresClassTeacher;
  final String? badgeText;
  final List<StaffMenuItem> subItems;

  const StaffMenuItem({
    required this.id,
    required this.label,
    required this.iconData,
    required this.routeName,
    required this.allowedRoles,
    this.requiresClassTeacher = false,
    this.badgeText,
    this.subItems = const [],
  });
}

/// Master list of all possible Staff End navigation items.
const List<StaffMenuItem> allStaffMenuItems = [
  // --- COMMON (7) ---
  StaffMenuItem(
    id: 'dashboard',
    label: 'Dashboard',
    iconData: Icons.dashboard_outlined,
    routeName: '/staff/dashboard',
    allowedRoles: [
      'principal',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'receptionist',
    ],
  ),
  StaffMenuItem(
    id: 'my-profile',
    label: 'My Profile',
    iconData: Icons.person_outline,
    routeName: '/staff/my-profile',
    allowedRoles: [
      'principal',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'receptionist',
    ],
  ),
  StaffMenuItem(
    id: 'my-attendance',
    label: 'My Attendance',
    iconData: Icons.calendar_today_outlined,
    routeName: '/staff/my-attendance',
    allowedRoles: [
      'principal',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'receptionist',
    ],
  ),
  StaffMenuItem(
    id: 'my-leave',
    label: 'My Leave',
    iconData: Icons.beach_access_outlined,
    routeName: '/staff/my-leave',
    allowedRoles: [
      'principal',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'receptionist',
    ],
  ),
  StaffMenuItem(
    id: 'my-payroll',
    label: 'My Payroll',
    iconData: Icons.account_balance_wallet_outlined,
    routeName: '/staff/my-payroll',
    allowedRoles: [
      'principal',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'receptionist',
    ],
  ),
  StaffMenuItem(
    id: 'my-library',
    label: 'My Library',
    iconData: Icons.local_library_outlined,
    routeName: '/staff/my-library',
    allowedRoles: [
      'principal',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'receptionist',
    ],
  ),
  StaffMenuItem(
    id: 'announcements',
    label: 'Announcements',
    iconData: Icons.campaign_outlined,
    routeName: '/staff/announcements',
    allowedRoles: [
      'principal',
      'teacher',
      'accountant',
      'librarian',
      'transport_manager',
      'receptionist',
    ],
  ),

  // --- ROLE SPECIFIC ---
  // Teacher (Class Teacher Only)
  StaffMenuItem(
    id: 'section-attendance',
    label: 'Section Attendance',
    iconData: Icons.how_to_reg_outlined,
    routeName: '/staff/section-attendance',
    allowedRoles: ['teacher', 'principal'],
    requiresClassTeacher: true,
  ),

  // Teacher (All Teachers)
  StaffMenuItem(
    id: 'my-classes',
    label: 'My Classes & Timetable',
    iconData: Icons.school_outlined,
    routeName: '/staff/my-classes',
    allowedRoles: ['teacher', 'principal'],
  ),
  StaffMenuItem(
    id: 'marks-entry',
    label: 'Marks & Assessments',
    iconData: Icons.fact_check_outlined,
    routeName: '/staff/marks-entry',
    allowedRoles: ['teacher', 'principal'],
  ),
  StaffMenuItem(
    id: 'homework',
    label: 'Homework & Coursework',
    iconData: Icons.assignment_outlined,
    routeName: '/staff/homework',
    allowedRoles: ['teacher', 'principal'],
  ),

  // Accountant
  StaffMenuItem(
    id: 'fee-collection',
    label: 'Fee & Cashier Desk',
    iconData: Icons.payments_outlined,
    routeName: '/staff/fee-collection',
    allowedRoles: ['accountant', 'principal'],
  ),
  StaffMenuItem(
    id: 'payroll-desk',
    label: 'Payroll & Salary Desk',
    iconData: Icons.receipt_long_outlined,
    routeName: '/staff/payroll-desk',
    allowedRoles: ['accountant', 'principal'],
  ),

  // Librarian
  StaffMenuItem(
    id: 'library-desk',
    label: 'Library Circulation Desk',
    iconData: Icons.book_outlined,
    routeName: '/staff/library-desk',
    allowedRoles: ['librarian', 'principal'],
  ),

  // Transport Manager
  StaffMenuItem(
    id: 'fleet-routes',
    label: 'Fleet & Transit Routes',
    iconData: Icons.directions_bus_outlined,
    routeName: '/staff/fleet-routes',
    allowedRoles: ['transport_manager', 'principal'],
  ),

  // Receptionist
  StaffMenuItem(
    id: 'visitor-log',
    label: 'Visitor & Gate Pass Log',
    iconData: Icons.badge_outlined,
    routeName: '/staff/visitor-log',
    allowedRoles: ['receptionist', 'principal'],
  ),
];

/// Helper to verify if a role has Super Admin privileges.
bool isSuperAdmin(String? role) {
  if (role == null) return false;
  final r = role.toLowerCase().trim();
  return r == 'admin' || r == 'administrator';
}

/// Administrative navigation items for Super Admin (Staff CRUD, Departments, Payroll Ledger)
const List<StaffMenuItem> adminStaffMenuItems = [
  StaffMenuItem(
    id: 'admin-staff-directory',
    label: 'Staff Directory',
    iconData: Icons.people_alt_outlined,
    routeName: '/admin/staff',
    allowedRoles: ['admin', 'administrator', 'principal'],
  ),
  StaffMenuItem(
    id: 'admin-add-staff',
    label: 'Add New Staff',
    iconData: Icons.person_add_alt_1_outlined,
    routeName: '/admin/add-staff',
    allowedRoles: ['admin', 'administrator'],
  ),
  StaffMenuItem(
    id: 'admin-departments',
    label: 'Staff Departments',
    iconData: Icons.domain_outlined,
    routeName: '/admin/staff-departments',
    allowedRoles: ['admin', 'administrator', 'principal'],
  ),
  StaffMenuItem(
    id: 'admin-accounts-ledger',
    label: 'Accounts & Ledger',
    iconData: Icons.account_balance_outlined,
    routeName: '/admin/accounts',
    allowedRoles: ['admin', 'administrator'],
  ),
];

/// Hierarchical navigation tree for Principal Portal
/// Organized into 6 core operational modules with respective sub-items.
const List<StaffMenuItem> principalMenuItems = [
  // 1. Student Admissions (Root Module)
  StaffMenuItem(
    id: 'student-admissions',
    label: 'Student Admissions',
    iconData: Icons.how_to_reg_outlined,
    routeName: RouteNames.staffAdmissionsPipeline,
    allowedRoles: ['principal'],
    subItems: [
      StaffMenuItem(
        id: 'principal-admissions-pipeline',
        label: 'Admissions Pipeline & Approvals',
        iconData: Icons.view_kanban_outlined,
        routeName: RouteNames.staffAdmissionsPipeline,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'principal-students',
        label: 'Student Directory',
        iconData: Icons.school_outlined,
        routeName: RouteNames.staffStudentDirectory,
        allowedRoles: ['principal'],
      ),
    ],
  ),

  // 3. Faculty & Staff (Root Module)
  StaffMenuItem(
    id: 'faculty-staff',
    label: 'Faculty & Staff',
    iconData: Icons.badge_outlined,
    routeName: RouteNames.adminStaff,
    allowedRoles: ['principal'],
    subItems: [
      StaffMenuItem(
        id: 'admin-staff-directory',
        label: 'Staff Directory',
        iconData: Icons.people_alt_outlined,
        routeName: RouteNames.adminStaff,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'principal-faculty-leaves',
        label: 'Faculty Leave Approvals',
        iconData: Icons.approval_outlined,
        routeName: RouteNames.staffFacultyLeaveApprovals,
        allowedRoles: ['principal'],
      ),
    ],
  ),

  // 4. Classes & Academics (Root Module)
  StaffMenuItem(
    id: 'classes-academics',
    label: 'Classes & Academics',
    iconData: Icons.class_outlined,
    routeName: RouteNames.staffClassesManagement,
    allowedRoles: ['principal'],
    subItems: [
      StaffMenuItem(
        id: 'principal-classes',
        label: 'Classes & Sections',
        iconData: Icons.meeting_room_outlined,
        routeName: RouteNames.staffClassesManagement,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'principal-teacher-workload',
        label: 'Teacher Workload & Assignment',
        iconData: Icons.assignment_ind_outlined,
        routeName: RouteNames.staffTeacherWorkload,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'principal-curriculum',
        label: 'Curriculum & Lesson Review',
        iconData: Icons.menu_book_outlined,
        routeName: RouteNames.staffCurriculumReview,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'principal-timetable',
        label: 'Master Timetable',
        iconData: Icons.calendar_month_outlined,
        routeName: RouteNames.staffMasterTimetable,
        allowedRoles: ['principal'],
      ),
    ],
  ),

  // 5. Examinations & Grading (Root Module)
  StaffMenuItem(
    id: 'examinations-grading',
    label: 'Examinations & Grading',
    iconData: Icons.quiz_outlined,
    routeName: RouteNames.staffExaminations,
    allowedRoles: ['principal'],
    subItems: [
      StaffMenuItem(
        id: 'principal-examinations',
        label: 'Examinations & Terms',
        iconData: Icons.event_note_outlined,
        routeName: RouteNames.staffExaminations,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'principal-marks-moderation',
        label: 'Marks Moderation & Report Cards',
        iconData: Icons.fact_check_outlined,
        routeName: RouteNames.staffMarksModeration,
        allowedRoles: ['principal'],
      ),
    ],
  ),

  // 6. Finance & Campus (Root Module)
  StaffMenuItem(
    id: 'finance-campus',
    label: 'Finance & Campus',
    iconData: Icons.account_balance_outlined,
    routeName: RouteNames.staffFeeAnalytics,
    allowedRoles: ['principal'],
    subItems: [
      StaffMenuItem(
        id: 'principal-fee-analytics',
        label: 'Fee Analytics & Defaulters',
        iconData: Icons.insights_outlined,
        routeName: RouteNames.staffFeeAnalytics,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'principal-fee-waivers',
        label: 'Fee Waiver Approvals',
        iconData: Icons.request_quote_outlined,
        routeName: RouteNames.staffFeeWaivers,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'visitor-log',
        label: 'Visitor & Gate Pass Log',
        iconData: Icons.door_sliding_outlined,
        routeName: RouteNames.staffVisitorLog,
        allowedRoles: ['principal'],
      ),
    ],
  ),

  // 7. Communication
  StaffMenuItem(
    id: 'announcements',
    label: 'Announcements & Circulars',
    iconData: Icons.campaign_outlined,
    routeName: RouteNames.staffAnnouncements,
    allowedRoles: ['principal'],
  ),

  // 8. Personal Workspace (Root Module)
  StaffMenuItem(
    id: 'principal-personal',
    label: 'My Workspace',
    iconData: Icons.person_pin_outlined,
    routeName: RouteNames.staffMyProfile,
    allowedRoles: ['principal'],
    subItems: [
      StaffMenuItem(
        id: 'my-profile',
        label: 'My Profile',
        iconData: Icons.person_outline,
        routeName: RouteNames.staffMyProfile,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'my-attendance',
        label: 'My Attendance',
        iconData: Icons.calendar_today_outlined,
        routeName: RouteNames.staffMyAttendance,
        allowedRoles: ['principal'],
      ),
      StaffMenuItem(
        id: 'my-leave',
        label: 'My Leave (Mgmt Sign-off)',
        iconData: Icons.beach_access_outlined,
        routeName: RouteNames.staffMyLeave,
        allowedRoles: ['principal'],
      ),
    ],
  ),
];

