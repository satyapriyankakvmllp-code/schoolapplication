/// Centralized route path and name definitions
class RouteNames {
  RouteNames._();

  static const String initial = '/';
  static const String login = '/login';

  // Admin shell & subroutes
  static const String admin = '/admin';
  static const String adminDashboard = '/admin/dashboard';
  static const String adminAdmissions = '/admin/admissions';
  static const String admissionDetail = '/admin/admissions/:id';
  static const String newAdmission = '/admin/admissions/new';
  static const String adminPipeline = '/admin/pipeline';
  static const String adminEditStudent = '/admin/edit-student';
  static const String adminSettings = '/admin/settings';
  static const String adminStaff = '/admin/staff';
  static const String adminAddStaff = '/admin/add-staff';
  static const String adminStaffDetails = '/admin/staff-details';
  static const String adminStaffDepartments = '/admin/staff-departments';
  static const String adminAccounts = '/admin/accounts';
  static const String adminEditStaff = '/admin/edit-staff';

  // Staff shell & subroutes
  static const String portalGateway = '/portal-gateway';
  static const String staff = '/staff';
  static const String staffDashboard = '/staff/dashboard';
  static const String staffMyProfile = '/staff/my-profile';
  static const String staffMyAttendance = '/staff/my-attendance';
  static const String staffMyLeave = '/staff/my-leave';
  static const String staffMyPayroll = '/staff/my-payroll';
  static const String staffMyLibrary = '/staff/my-library';
  static const String staffAnnouncements = '/staff/announcements';
  static const String staffSectionAttendance = '/staff/section-attendance';
  static const String staffMyClasses = '/staff/my-classes';
  static const String staffMarksEntry = '/staff/marks-entry';
  static const String staffHomework = '/staff/homework';
  static const String staffFeeCollection = '/staff/fee-collection';
  static const String staffPayrollDesk = '/staff/payroll-desk';
  static const String staffLibraryDesk = '/staff/library-desk';
  static const String staffFleetRoutes = '/staff/fleet-routes';
  static const String staffVisitorLog = '/staff/visitor-log';

  // Principal Executive Modules
  static const String staffAdmissionsPipeline = '/staff/admissions-pipeline';
  static const String staffStudentDirectory = '/staff/students';
  static const String staffFacultyLeaveApprovals = '/staff/leave-approvals';
  static const String staffClassesManagement = '/staff/classes-management';
  static const String staffTeacherWorkload = '/staff/teacher-workload';
  static const String staffCurriculumReview = '/staff/curriculum-review';
  static const String staffMasterTimetable = '/staff/master-timetable';
  static const String staffExaminations = '/staff/examinations';
  static const String staffMarksModeration = '/staff/marks-moderation';
  static const String staffFeeAnalytics = '/staff/fee-analytics';
  static const String staffFeeWaivers = '/staff/fee-waivers';

  // Institutional Sign In Gateway & Student/Parent routes
  static const String signInGateway = '/sign-in-gateway';
  static const String studentDashboard = '/student/dashboard';
  static const String studentProfile = '/student/my-profile';
  static const String parentDashboard = '/parent/dashboard';
}
