import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../commonwidgets/responsive_layout.dart';
import '../../../../themes/app_colors.dart';
import '../../application/staff_auth_controller.dart';
import '../../domain/staff_member_model.dart';
import '../../domain/staff_menu_item.dart';
import '../../../../commonwidgets/common_app_header.dart';

class StaffShellLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;
  final ValueChanged<String>? onNavigate;
  final VoidCallback? onLogout;
  final bool isDark;
  final VoidCallback? onToggleTheme;

  const StaffShellLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    this.onNavigate,
    this.onLogout,
    this.isDark = false,
    this.onToggleTheme,
  });

  @override
  ConsumerState<StaffShellLayout> createState() => _StaffShellLayoutState();
}

class _StaffShellLayoutState extends ConsumerState<StaffShellLayout> {
  bool _isSidebarCollapsed = false;
  final Set<String> _expandedMenuIds = {'student-admissions', 'faculty-staff', 'classes-academics'};

  void _handleNavigation(String routeName, bool isDrawer) {
    if (isDrawer && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    ref.read(staffAuthControllerProvider).setActiveRoute(routeName);
    widget.onNavigate?.call(routeName);
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
      case 'administrator':
        return const Color(0xFFDC2626); // Red accent for Super Admin
      case 'principal':
        return const Color(0xFF6366F1); // Indigo
      case 'teacher':
        return AppColors.success; // Emerald / Teal
      case 'accountant':
        return const Color(0xFFEC4899); // Pink
      case 'librarian':
        return const Color(0xFF8B5CF6); // Purple
      case 'transport_manager':
        return const Color(0xFFF97316); // Orange
      case 'receptionist':
        return AppColors.warning; // Amber
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final menuItems = ref.watch(filteredMenuProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final activeRoute = ref.watch(activeStaffRouteProvider);
    final effectiveRoute = widget.currentRoute.isNotEmpty ? widget.currentRoute : activeRoute;

    final bgColor = isDark ? AppColors.backgroundDark : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: isDesktop
          ? null
          : Drawer(
              backgroundColor: surfaceColor,
              child: SafeArea(
                child: _buildSidebarContent(
                  staff: staff,
                  menuItems: menuItems,
                  activeRoute: effectiveRoute,
                  isDrawer: true,
                  isDark: isDark,
                  textColor: textColor,
                  subColor: subColor,
                  borderColor: borderColor,
                ),
              ),
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: _isSidebarCollapsed ? 76 : 260,
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(right: BorderSide(color: borderColor, width: 1)),
              ),
              child: ClipRect(
                child: SizedBox(
                  width: _isSidebarCollapsed ? 76 : 260,
                  child: _buildSidebarContent(
                    staff: staff,
                    menuItems: menuItems,
                    activeRoute: effectiveRoute,
                    isDrawer: false,
                    isDark: isDark,
                    textColor: textColor,
                    subColor: subColor,
                    borderColor: borderColor,
                  ),
                ),
              ),
            ),
          Expanded(
            child: Column(
              children: [
                CommonAppHeader(
                  isDark: isDark,
                  isSidebarCollapsed: _isSidebarCollapsed,
                  onToggleSidebar: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                  onToggleTheme: widget.onToggleTheme,
                  onLogout: () async {
                    await ref.read(staffAuthControllerProvider).logout();
                    widget.onLogout?.call();
                  },
                ),
                Expanded(
                  child: widget.child,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }



  Widget _buildSidebarContent({
    required StaffMemberModel? staff,
    required List<StaffMenuItem> menuItems,
    required String activeRoute,
    required bool isDrawer,
    required bool isDark,
    required Color textColor,
    required Color subColor,
    required Color borderColor,
  }) {
    final showLabels = isDrawer || !_isSidebarCollapsed;

    return Column(
      children: [
        // Brand Header
        Container(
          height: 68,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFF14B8A6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.school, color: Colors.white, size: 20),
              ),
              if (showLabels) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EduPulse',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Faculty & Staff Workspace',
                        style: TextStyle(fontSize: 10, color: subColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isDrawer)
                  IconButton(
                    icon: Icon(Icons.close, size: 20, color: subColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              ],
            ],
          ),
        ),
        Divider(height: 1, color: borderColor),

        // Staff Info Card (if labels shown)
        if (showLabels && staff != null) ...[
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: _getRoleBadgeColor(staff.effectiveRole),
                  child: Text(
                    staff.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      Text(
                        staff.id,
                        style: TextStyle(fontSize: 10, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Menu items
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            itemCount: menuItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final item = menuItems[index];
              final hasSubItems = item.subItems.isNotEmpty;
              final isCurrent = activeRoute == item.routeName;
              final isSubActive = hasSubItems && item.subItems.any((sub) => sub.routeName == activeRoute);
              final isExpanded = _expandedMenuIds.contains(item.id) || isSubActive;

              if (!showLabels) {
                return Tooltip(
                  message: item.label,
                  preferBelow: false,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: (isCurrent || isSubActive) ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      icon: Icon(
                        item.iconData,
                        size: 20,
                        color: (isCurrent || isSubActive) ? Colors.white : subColor,
                      ),
                      onPressed: () {
                        if (hasSubItems) {
                          setState(() {
                            _isSidebarCollapsed = false;
                            _expandedMenuIds.add(item.id);
                          });
                        } else {
                          _handleNavigation(item.routeName, isDrawer);
                        }
                      },
                    ),
                  ),
                );
              }

              // Root item with sub-items
              if (hasSubItems) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      key: ValueKey('staff_menu_root_${item.id}'),
                      onTap: () {
                        setState(() {
                          if (_expandedMenuIds.contains(item.id)) {
                            _expandedMenuIds.remove(item.id);
                          } else {
                            _expandedMenuIds.add(item.id);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                          color: isSubActive ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.iconData,
                              size: 18,
                              color: isSubActive ? AppColors.primary : subColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.label,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: isSubActive ? FontWeight.w700 : FontWeight.w600,
                                  color: isSubActive ? (isDark ? Colors.white : AppColors.primary) : textColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Icon(
                              isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                              size: 16,
                              color: isSubActive ? AppColors.primary : subColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (isExpanded)
                      Padding(
                        padding: const EdgeInsets.only(left: 14, top: 2, bottom: 4),
                        child: Column(
                          children: item.subItems.map((sub) {
                            final isSubCurrent = activeRoute == sub.routeName;
                            return InkWell(
                              key: ValueKey('staff_menu_${sub.id}'),
                              onTap: () => _handleNavigation(sub.routeName, isDrawer),
                              borderRadius: BorderRadius.circular(6),
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 2),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isSubCurrent ? AppColors.primary : Colors.transparent,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isSubCurrent ? Colors.white : subColor.withValues(alpha: 0.6),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      sub.iconData,
                                      size: 14,
                                      color: isSubCurrent ? Colors.white : subColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        sub.label,
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: isSubCurrent ? FontWeight.w700 : FontWeight.w500,
                                          color: isSubCurrent
                                              ? Colors.white
                                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                  ],
                );
              }

              // Standard direct menu item (no sub-items)
              return InkWell(
                key: ValueKey('staff_menu_${item.id}'),
                onTap: () => _handleNavigation(item.routeName, isDrawer),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: isCurrent ? AppColors.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        item.iconData,
                        size: 18,
                        color: isCurrent ? Colors.white : subColor,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item.label,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                            color: isCurrent ? Colors.white : textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.requiresClassTeacher) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? Colors.white.withValues(alpha: 0.2)
                                : AppColors.secondary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Class',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.white : AppColors.secondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Divider(height: 1, color: borderColor),
        // Bottom Exit Item
        Padding(
          padding: const EdgeInsets.all(10),
          child: InkWell(
            onTap: () {
              if (isDrawer && Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
              ref.read(staffAuthControllerProvider).logout();
              widget.onLogout?.call();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.exit_to_app_rounded, size: 18, color: AppColors.error),
                  if (showLabels) ...[
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Exit to Gateway',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
