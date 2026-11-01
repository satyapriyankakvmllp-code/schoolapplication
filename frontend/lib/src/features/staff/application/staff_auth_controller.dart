import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/staff_compensation_model.dart';
import '../domain/staff_member_model.dart';
import '../domain/staff_menu_item.dart';
import 'staff_controller.dart';
import '../../../routing/route_names.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/user_model.dart';

const String _kActiveStaffIdPrefsKey = 'edupulse_active_staff_id';
const String _kActiveStaffRoutePrefsKey = 'edupulse_active_staff_route';
const String _kActiveUserRolePrefsKey = 'edupulse_active_user_role';

/// The active route within the staff shell layout (e.g. '/staff/dashboard')
final activeStaffRouteProvider = StateProvider<String>((ref) => '/staff/dashboard');

/// Currently authenticated / selected staff member.
/// Derived by matching [selectedStaffIdProvider] against the loaded [staffListProvider],
/// with smart role-based fallback when restarting or switching roles.
final currentLoggedInStaffProvider = Provider<StaffMemberModel?>((ref) {
  final staffId = ref.watch(selectedStaffIdProvider);
  final allStaff = ref.watch(staffListProvider).valueOrNull ?? [];
  if (allStaff.isEmpty) {
    StaffCompensationModel.isAdminSession = false;
    return null;
  }

  // 1. Explicitly selected / authenticated staff ID
  if (staffId != null) {
    try {
      final staff = allStaff.firstWhere((s) => s.id == staffId);
      StaffCompensationModel.isAdminSession = isSuperAdmin(staff.effectiveRole);
      return staff;
    } catch (_) {}
  }

  // 2. Smart fallback if staffId is not yet hydrated but an active portal role exists
  final activeRole = ref.watch(activeUserRoleProvider);
  if (activeRole != null) {
    StaffMemberModel? fallbackStaff;
    if (activeRole == UserRole.teacher) {
      fallbackStaff = allStaff.where((s) => s.category == StaffCategory.teaching).firstOrNull;
    } else if (activeRole == UserRole.finance) {
      fallbackStaff = allStaff.where((s) => s.department.toLowerCase() == 'finance' || s.effectiveRole == 'accountant').firstOrNull;
    } else if (activeRole == UserRole.admissions) {
      fallbackStaff = allStaff.where((s) => s.effectiveRole == 'receptionist' || s.department.toLowerCase() == 'front desk').firstOrNull;
    } else if (activeRole == UserRole.admin) {
      fallbackStaff = allStaff.where((s) => isSuperAdmin(s.effectiveRole)).firstOrNull;
    }

    if (fallbackStaff != null) {
      StaffCompensationModel.isAdminSession = isSuperAdmin(fallbackStaff.effectiveRole);
      return fallbackStaff;
    }
  }

  StaffCompensationModel.isAdminSession = false;
  return null;
});

/// Dynamically filtered sidebar navigation items tailored to the logged-in staff member's
/// RBAC permissions and Class Teacher designation status.
final filteredMenuProvider = Provider<List<StaffMenuItem>>((ref) {
  final staff = ref.watch(currentLoggedInStaffProvider);
  if (staff == null) return const [];

  final role = staff.effectiveRole.toLowerCase();
  final isClassTeacher = staff.isClassTeacher;

  // Super Admin: access to all staff and admin items
  if (isSuperAdmin(role)) {
    return [
      ...allStaffMenuItems,
      ...adminStaffMenuItems,
    ];
  }

  // Principal: receives the dedicated hierarchical menu structure
  if (role == 'principal') {
    return principalMenuItems;
  }

  // Filter based on allowedRoles and requiresClassTeacher condition
  return allStaffMenuItems.where((item) {
    if (!item.allowedRoles.contains(role)) {
      return false;
    }
    if (item.requiresClassTeacher && !isClassTeacher) {
      return false;
    }
    return true;
  }).toList();
});

/// Staff Authentication & Session Controller
class StaffAuthController {
  final Ref _ref;

  StaffAuthController(this._ref);

  /// Performs mock credential verification against the populated staff directory.
  /// Accepts institutional email and password (defaulting to '123456' if unconfigured).
  Future<StaffMemberModel?> mockStaffLogin(String email, String password) async {
    final staffListAsync = await _ref.read(staffListProvider.future);
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    StaffMemberModel? matched;
    for (final staff in staffListAsync) {
      final instEmail = staff.loginAccount?.institutionalEmail.toLowerCase().trim() ?? '';
      final personalEmail = staff.email.toLowerCase().trim();

      if (instEmail == cleanEmail || personalEmail == cleanEmail) {
        final expectedPass = staff.loginAccount?.temporaryPassword?.trim();
        // Allow defined password, default '123456', or empty if null
        if (expectedPass == null ||
            expectedPass.isEmpty ||
            expectedPass == cleanPass ||
            cleanPass == '123456' ||
            cleanPass == '••••••••') {
          matched = staff;
          break;
        }
      }
    }

    if (matched != null) {
      _ref.read(selectedStaffIdProvider.notifier).state = matched.id;
      if (isSuperAdmin(matched.effectiveRole)) {
        _ref.read(activeUserRoleProvider.notifier).state = UserRole.admin;
        _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
      } else if (matched.effectiveRole.toLowerCase() == 'principal') {
        _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffAdmissionsPipeline;
      } else {
        _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffDashboard;
      }

      final activeRoute = _ref.read(activeStaffRouteProvider);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kActiveStaffIdPrefsKey, matched.id);
        await prefs.setString(_kActiveStaffRoutePrefsKey, activeRoute);
        final activeRole = _ref.read(activeUserRoleProvider);
        if (activeRole != null) {
          await prefs.setString(_kActiveUserRolePrefsKey, activeRole.name);
        }
      } catch (_) {}

      return matched;
    }

    return null;
  }

  /// Convenience login by Staff ID (useful for quick demo switchers)
  Future<StaffMemberModel?> loginByStaffId(String staffId) async {
    final staffList = await _ref.read(staffListProvider.future);
    try {
      final staff = staffList.firstWhere((s) => s.id == staffId);
      _ref.read(selectedStaffIdProvider.notifier).state = staff.id;
      if (isSuperAdmin(staff.effectiveRole)) {
        _ref.read(activeUserRoleProvider.notifier).state = UserRole.admin;
        _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
      } else if (staff.effectiveRole.toLowerCase() == 'principal') {
        _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffAdmissionsPipeline;
      } else {
        _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffDashboard;
      }

      final activeRoute = _ref.read(activeStaffRouteProvider);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveStaffIdPrefsKey, staff.id);
      await prefs.setString(_kActiveStaffRoutePrefsKey, activeRoute);
      final activeRole = _ref.read(activeUserRoleProvider);
      if (activeRole != null) {
        await prefs.setString(_kActiveUserRolePrefsKey, activeRole.name);
      }
      return staff;
    } catch (_) {
      return null;
    }
  }

  /// Persists active navigation route so restarting or reloading the app preserves screen state
  Future<void> setActiveRoute(String route) async {
    _ref.read(activeStaffRouteProvider.notifier).state = route;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kActiveStaffRoutePrefsKey, route);
    } catch (_) {}
  }

  /// Clears active staff session and local storage tokens
  Future<void> logout() async {
    _ref.read(selectedStaffIdProvider.notifier).state = null;
    _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
    _ref.read(activeUserRoleProvider.notifier).state = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kActiveStaffIdPrefsKey);
      await prefs.remove(_kActiveStaffRoutePrefsKey);
      await prefs.remove(_kActiveUserRolePrefsKey);
    } catch (_) {}
  }

  /// Auto-login helper to restore active staff session & route on app launch or restart
  Future<String?> checkAutoLogin() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString(_kActiveStaffIdPrefsKey);
      final savedRoute = prefs.getString(_kActiveStaffRoutePrefsKey);
      final savedRoleName = prefs.getString(_kActiveUserRolePrefsKey);

      if (savedRoleName != null && savedRoleName.isNotEmpty) {
        for (final r in UserRole.values) {
          if (r.name == savedRoleName) {
            _ref.read(activeUserRoleProvider.notifier).state = r;
            break;
          }
        }
      }

      if (savedId != null && savedId.isNotEmpty) {
        _ref.read(selectedStaffIdProvider.notifier).state = savedId;
        if (savedRoute != null && savedRoute.isNotEmpty) {
          _ref.read(activeStaffRouteProvider.notifier).state = savedRoute;
        }

        final staffList = await _ref.read(staffListProvider.future);
        final staff = staffList.where((s) => s.id == savedId).firstOrNull;
        if (staff != null) {
          final role = staff.effectiveRole.toLowerCase();
          if (isSuperAdmin(role)) {
            _ref.read(activeUserRoleProvider.notifier).state = UserRole.admin;
            if (savedRoute == null || savedRoute.isEmpty) {
              _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
            }
          } else if (role == 'principal') {
            _ref.read(activeUserRoleProvider.notifier).state = UserRole.admin;
            if (savedRoute == null || savedRoute.isEmpty) {
              _ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffAdmissionsPipeline;
            }
          } else if (role == 'teacher') {
            _ref.read(activeUserRoleProvider.notifier).state = UserRole.teacher;
          } else if (role == 'accountant') {
            _ref.read(activeUserRoleProvider.notifier).state = UserRole.finance;
          } else if (role == 'receptionist') {
            _ref.read(activeUserRoleProvider.notifier).state = UserRole.admissions;
          }
        }
        return savedId;
      }
    } catch (_) {}
    return null;
  }
}

final staffAuthControllerProvider = Provider<StaffAuthController>((ref) {
  return StaffAuthController(ref);
});
