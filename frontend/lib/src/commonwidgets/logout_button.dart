import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/authentication/application/student_auth_controller.dart';
import '../features/authentication/application/parent_auth_controller.dart';
import '../features/staff/application/staff_auth_controller.dart';
import '../features/staff/application/staff_controller.dart';
import '../features/admissions/application/admissions_controller.dart';
import '../routing/route_names.dart';

class LogoutButton extends ConsumerWidget {
  final VoidCallback? onLogout;

  const LogoutButton({
    super.key,
    this.onLogout,
  });

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    // 1. Clear active user role & selection
    ref.read(activeUserRoleProvider.notifier).state = null;
    ref.read(selectedStudentIdProvider.notifier).state = null;

    // 2. Clear staff auth & storage token
    ref.read(selectedStaffIdProvider.notifier).state = null;
    await ref.read(staffAuthControllerProvider).logout();

    // 3. Clear student auth
    ref.read(selectedStudentUserIdProvider.notifier).state = null;
    ref.read(studentAuthControllerProvider).logout();

    // 4. Clear parent auth
    ref.read(selectedParentUserIdProvider.notifier).state = null;
    ref.read(parentAuthControllerProvider).logout();

    // 5. Trigger caller-provided custom callback
    onLogout?.call();

    // 6. Navigate to login gateway if GoRouter is active in tree
    if (context.mounted) {
      try {
        GoRouter.of(context).go(RouteNames.signInGateway);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Tooltip(
      message: 'Sign Out to Login Gateway',
      child: InkWell(
        onTap: () => _handleLogout(context, ref),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 8 : 12,
            vertical: 7,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 16,
                color: Color(0xFFEF4444),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 6),
                const Text(
                  'Logout',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
