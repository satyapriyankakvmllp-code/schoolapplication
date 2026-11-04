import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/authentication/domain/user_model.dart';
import '../features/staff/application/staff_auth_controller.dart';
import '../features/staff/domain/staff_menu_item.dart';
import 'logout_button.dart';

/// Common institutional header bar rendered across all application screens.
///
/// Features:
/// - Left side: Menu icon button to toggle/collapse sidebar on desktop or open drawer on mobile.
/// - Center: Clean empty spacer for modern minimal layout.
/// - Right side:
///   1. Compact Role Pill (e.g. Admin, Principal, Teacher, Accountant, Front Desk, Student, Parent).
///   2. Theme toggle button (Sun/Moon).
///   3. Unified red institutional Logout button.
class CommonAppHeader extends ConsumerWidget implements PreferredSizeWidget {
  final bool isDark;
  final VoidCallback? onToggleSidebar;
  final bool isSidebarCollapsed;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onLogout;
  final String? roleOverride;
  final Color? roleColorOverride;
  final Widget? leading;

  const CommonAppHeader({
    super.key,
    required this.isDark,
    this.onToggleSidebar,
    this.isSidebarCollapsed = false,
    this.onToggleTheme,
    this.onLogout,
    this.roleOverride,
    this.roleColorOverride,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  ({String label, Color color}) _resolveRole(WidgetRef ref) {
    if (roleOverride != null) {
      return (
        label: roleOverride!,
        color: roleColorOverride ?? const Color(0xFF6366F1),
      );
    }

    // 1. Staff session check
    final staff = ref.watch(currentLoggedInStaffProvider);
    if (staff != null) {
      final role = staff.effectiveRole.toLowerCase();
      if (isSuperAdmin(role)) {
        return (label: 'Admin', color: const Color(0xFF6366F1));
      }
      if (role == 'principal') {
        return (label: 'Principal', color: const Color(0xFF8B5CF6));
      }
      if (role == 'teacher') {
        return (label: 'Teacher', color: const Color(0xFF109F83));
      }
      if (role == 'accountant') {
        return (label: 'Accountant', color: const Color(0xFF0284C7));
      }
      if (role == 'librarian') {
        return (label: 'Librarian', color: const Color(0xFFD97706));
      }
      if (role == 'transport_manager' || role == 'transport') {
        return (label: 'Transport', color: const Color(0xFFEA580C));
      }
      if (role == 'receptionist' || role == 'frontdesk') {
        return (label: 'Front Desk', color: const Color(0xFFF59E0B));
      }
      return (label: staff.designation, color: const Color(0xFF64748B));
    }

    // 2. Fallback to active UserRole enum
    final activeRole = ref.watch(activeUserRoleProvider);
    if (activeRole != null) {
      switch (activeRole) {
        case UserRole.admin:
          return (label: 'Admin', color: const Color(0xFF6366F1));
        case UserRole.teacher:
          return (label: 'Teacher', color: const Color(0xFF109F83));
        case UserRole.student:
          return (label: 'Student', color: const Color(0xFF06B6D4));
        case UserRole.parent:
          return (label: 'Parent', color: const Color(0xFF10B981));
        case UserRole.admissions:
          return (label: 'Front Desk', color: const Color(0xFFF59E0B));
        case UserRole.finance:
          return (label: 'Finance', color: const Color(0xFF0284C7));
      }
    }

    return (label: 'Admin', color: const Color(0xFF6366F1));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth >= 1024;
    final isMobile = screenWidth < 768;

    final roleInfo = _resolveRole(ref);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20),
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(bottom: BorderSide(color: borderColor, width: 1)),
      ),
      child: Row(
        children: [
          // Left side: Menu / Toggle icon
          if (leading != null)
            leading!
          else if (isDesktop && onToggleSidebar != null)
            IconButton(
              icon: Icon(
                isSidebarCollapsed ? Icons.menu_open : Icons.menu,
                color: iconColor,
                size: 20,
              ),
              tooltip: isSidebarCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
              onPressed: onToggleSidebar,
            )
          else
            Builder(
              builder: (ctx) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: iconColor,
                  size: 20,
                ),
                tooltip: 'Open Menu',
                onPressed: () {
                  final scaffoldState = Scaffold.maybeOf(ctx);
                  if (scaffoldState != null && scaffoldState.hasDrawer) {
                    scaffoldState.openDrawer();
                  } else if (onToggleSidebar != null) {
                    onToggleSidebar!();
                  }
                },
              ),
            ),

          // Center: Clean empty spacer
          const Spacer(),

          // Right side 1: Compact Role Pill
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 8 : 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: roleInfo.color.withValues(alpha: isDark ? 0.20 : 0.10),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: roleInfo.color.withValues(alpha: isDark ? 0.45 : 0.35),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: roleInfo.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  roleInfo.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : roleInfo.color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Right side 2: Theme Toggle Button
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              size: 20,
              color: isDark ? const Color(0xFFFBBF24) : Colors.grey.shade700,
            ),
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: onToggleTheme,
          ),
          const SizedBox(width: 6),

          // Right side 3: Unified Logout Button
          LogoutButton(
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }
}
