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
  final admissions = ref.watch(admissionsListProvider).valueOrNull ?? const [];
  final activeParentChildId = ref.watch(parentActiveChildIdProvider);
  final admission = switch (user?.userRole) {
    UserRole.student =>
      admissions
          .where(
            (item) =>
                item.student.userId == user!.id ||
                item.user.id == user.id ||
                item.student.id == user.id,
          )
          .firstOrNull,
    UserRole.parent => admissions.where((item) {
      final linkedToParent = [
        item.father?.userId,
        item.mother?.userId,
        item.guardian?.userId,
      ].contains(user!.id);
      final isSelectedChild =
          item.student.id == activeParentChildId ||
          item.student.userId == activeParentChildId ||
          item.user.id == activeParentChildId;
      return linkedToParent && isSelectedChild;
    }).firstOrNull,
    _ => null,
  };

  return ClassesActor(
    role: user?.userRole,
    userId: user?.id ?? '',
    studentClassName: admission?.student.className,
    studentSection: admission?.student.section,
    studentId: admission?.student.id,
    studentUserId: admission?.student.userId,
    studentClassId: admission?.student.currentClassId,
    studentSectionId: admission?.student.sectionId,
    linkedParentUserId: user?.userRole == UserRole.parent && admission != null
        ? user?.id
        : null,
  );
});
