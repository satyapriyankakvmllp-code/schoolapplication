import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/loading_indicator.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import '../role_views/principal_workspace_screen.dart';
import '../role_views/teacher_workspace_screen.dart';
import '../role_views/accountant_workspace_screen.dart';
import '../role_views/librarian_workspace_screen.dart';
import '../role_views/transport_workspace_screen.dart';
import '../role_views/receptionist_workspace_screen.dart';

/// Dynamically renders the appropriate role-based workspace based on the
/// authenticated staff member's effective system role.
class DashboardSwitcher extends ConsumerWidget {
  final bool isDark;

  const DashboardSwitcher({
    super.key,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(currentLoggedInStaffProvider);

    if (staff == null) {
      return const Center(
        child: LoadingIndicator(
          message: 'Loading staff workspace...',
        ),
      );
    }

    final role = staff.effectiveRole.toLowerCase();

    switch (role) {
      case 'principal':
        return PrincipalWorkspaceScreen(isDark: isDark);

      case 'teacher':
        return TeacherWorkspaceScreen(isDark: isDark);

      case 'accountant':
        return AccountantWorkspaceScreen(isDark: isDark);

      case 'librarian':
        return LibrarianWorkspaceScreen(isDark: isDark);

      case 'transport_manager':
        return TransportWorkspaceScreen(isDark: isDark);

      case 'receptionist':
        return ReceptionistWorkspaceScreen(isDark: isDark);

      case 'admin':
      case 'superadmin':
        return PrincipalWorkspaceScreen(isDark: isDark);

      default:
        return PrincipalWorkspaceScreen(isDark: isDark);
    }
  }
}
