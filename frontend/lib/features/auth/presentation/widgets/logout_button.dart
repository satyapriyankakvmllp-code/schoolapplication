import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/auth_controller.dart';

class LogoutButton extends ConsumerWidget {
  final VoidCallback? onLogout;

  const LogoutButton({
    super.key,
    this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Tooltip(
      message: 'Sign Out to Login Gateway',
      child: InkWell(
        onTap: () {
          ref.read(activeUserRoleProvider.notifier).state = null;
          onLogout?.call();
        },
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
