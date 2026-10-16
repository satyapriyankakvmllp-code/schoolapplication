import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../shared/class_details_screen.dart';
import '../widgets/classes_ui.dart';

/// Student: own class only (read-only). Shows the shared class details view.
class StudentClassScreen extends ConsumerWidget {
  const StudentClassScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(classesPermissionsProvider);
    final classes = ref.watch(classesControllerProvider);
    return AccessGuard(
      allowed: perms.isStudent || perms.isAdmin,
      child: AsyncListBody(
        value: classes,
        onRetry: () => ref.invalidate(classesControllerProvider),
        emptyTitle: 'No class found',
        emptySubtitle: 'We could not match your admission record to a class.',
        builder: (items) => ClassDetailsBody(classId: items.first.id),
      ),
    );
  }
}
