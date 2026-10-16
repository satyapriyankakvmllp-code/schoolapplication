import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/domain/user_model.dart';
import '../../admissions/application/admissions_controller.dart';
import '../../authentication/application/auth_controller.dart';
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
    role: user?.userRole,
    userId: user?.id ?? '',
    studentClassName: className,
    studentSection: section,
  );
});
