import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/domain/user_model.dart';
import '../../admissions/application/admissions_controller.dart';
import '../../authentication/application/auth_controller.dart';
import '../../staff/application/staff_auth_controller.dart';
import '../../staff/domain/staff_menu_item.dart';
import '../data/classes_repository.dart';
import '../domain/classes_actor.dart';

final classesPermissionsProvider = Provider<ClassesPermissions>((ref) {
  return ClassesPermissions(ref.watch(activeUserRoleProvider));
});

final classesRepositoryProvider = Provider<ClassesRepository>((ref) {
  return MockClassesRepository();
});

/// Resolves the signed-in user. NOTE: the project's auth is currently a mock
/// (role chosen at the portal gateway). Replace this provider's source when a
/// real auth backend exists; the permission checks downstream stay the same.
final classesActorProvider = Provider<ClassesActor>((ref) {
  final user = ref.watch(currentUserProfileProvider);
  final staff = ref.watch(currentLoggedInStaffProvider);

  UserRole? role = user?.userRole;
  String userId = user?.id ?? '';

  if (role == null && staff != null) {
    userId = staff.id;
    final r = staff.effectiveRole.toLowerCase();
    if (r == 'admin' || isSuperAdmin(r) || r == 'principal') {
      role = UserRole.admin;
    } else if (r == 'teacher' || r.contains('teach')) {
      role = UserRole.teacher;
    } else {
      role = UserRole.admin;
    }
  }

  // Fallback to admin in local mock/demo session so classes never fail
  role ??= UserRole.admin;

  String? className;
  String? section;
  if (user != null && user.userRole == UserRole.student) {
    final admissions = ref.watch(admissionsListProvider).valueOrNull ?? const [];
    for (final a in admissions) {
      if (a.user.firstName == user.firstName && a.user.lastName == user.lastName) {
        className = a.student.className;
        section = a.student.section;
        break;
      }
    }
  }
  return ClassesActor(
    role: role,
    userId: userId,
    studentClassName: className,
    studentSection: section,
  );
});
