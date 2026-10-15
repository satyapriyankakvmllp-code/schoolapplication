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
  static const String adminSettings = '/admin/settings';
}
