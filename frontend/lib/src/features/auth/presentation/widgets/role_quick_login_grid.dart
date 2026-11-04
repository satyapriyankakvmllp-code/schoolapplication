import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../commonwidgets/responsive_layout.dart';
import '../../../../themes/app_colors.dart';
import '../../../staff/application/staff_auth_controller.dart';
import '../../../staff/application/staff_controller.dart';
import '../../../staff/domain/staff_member_model.dart';
import '../../../staff/domain/staff_menu_item.dart';
import '../../../authentication/domain/user_model.dart';
import '../../../authentication/application/auth_controller.dart';
import '../../../authentication/application/student_auth_controller.dart';
import '../../../authentication/application/parent_auth_controller.dart';
import '../../../../routing/route_names.dart';

/// Unified representation for an instant sign-in card
class _UnifiedLoginCard {
  final String id;
  final String fullName;
  final String email;
  final String subtitle;
  final String initials;
  final String rolePillText;
  final Color rolePillColor;
  final String buttonLabel;
  final Future<void> Function() onLogin;
  final String? extraBadgeText;
  final Color? extraBadgeColor;
  final IconData? extraBadgeIcon;

  const _UnifiedLoginCard({
    required this.id,
    required this.fullName,
    required this.email,
    required this.subtitle,
    required this.initials,
    required this.rolePillText,
    required this.rolePillColor,
    required this.buttonLabel,
    required this.onLogin,
    this.extraBadgeText,
    this.extraBadgeColor,
    this.extraBadgeIcon,
  });
}

/// Metadata definition for the 8 ordered institutional sign-in groups
class _GroupMetadata {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _GroupMetadata({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

/// Single Unified Institutional Sign-In Gateway Grid
///
/// Features 8 ordered groups:
/// 1. Super Administrator (1)
/// 2. Principal & Leadership (1)
/// 3. Teaching Faculty - Class Teacher + Subject Teacher
/// 4. Finance & Support [Accountant, Librarian, Transport, Receptionist]
/// 5. Student Hub [4-6 demo students with class]
/// 6. Parent Portal [4 demo parents]
/// 7. Front-Desk Desk [receptionist]
/// 8. Finance Ledger [accountant]
class RoleQuickLoginGrid extends ConsumerStatefulWidget {
  final bool isDark;
  final String searchQuery;
  final ValueChanged<StaffMemberModel>? onStaffSelected;

  const RoleQuickLoginGrid({
    super.key,
    required this.isDark,
    this.searchQuery = '',
    this.onStaffSelected,
  });

  @override
  ConsumerState<RoleQuickLoginGrid> createState() => _RoleQuickLoginGridState();
}

class _RoleQuickLoginGridState extends ConsumerState<RoleQuickLoginGrid> {
  String? _loggingInId;

  static const List<_GroupMetadata> _groups = [
    _GroupMetadata(
      id: 'super_admin',
      title: 'School Administrator',
      subtitle: 'Executive Leadership & Institutional Governance',
      icon: Icons.admin_panel_settings_rounded,
      color: Color(0xFF6366F1), // Indigo
    ),
    _GroupMetadata(
      id: 'principal',
      title: 'Principal & Leadership',
      subtitle: 'Head of Institution & Academic Governance',
      icon: Icons.workspace_premium_rounded,
      color: Color(0xFF8B5CF6),
    ),
    _GroupMetadata(
      id: 'teaching_faculty',
      title: 'Teaching Faculty - Class Teacher + Subject Teacher',
      subtitle: 'Grade in-charges and subject specialized pedagogical mentors',
      icon: Icons.school_rounded,
      color: Color(0xFF109F83),
    ),
    _GroupMetadata(
      id: 'finance_support',
      title: 'Finance & Support',
      subtitle: 'Accountant, Librarian, Transport Coordinator & Receptionist',
      icon: Icons.supervised_user_circle_rounded,
      color: Color(0xFFEC4899),
    ),
    _GroupMetadata(
      id: 'student_hub',
      title: 'Student Hub',
      subtitle: 'Enrolled students accessing grades, homework & timetable',
      icon: Icons.backpack_rounded,
      color: Color(0xFF06B6D4),
    ),
    _GroupMetadata(
      id: 'parent_portal',
      title: 'Parent Portal',
      subtitle: 'Guardians monitoring student performance & fee accounts',
      icon: Icons.family_restroom_rounded,
      color: Color(0xFF10B981),
    ),
    _GroupMetadata(
      id: 'front_desk',
      title: 'Front-Desk Desk',
      subtitle: 'Receptionist desk, visitor log & admissions intake',
      icon: Icons.support_agent_rounded,
      color: Color(0xFF0EA5E9),
    ),
    _GroupMetadata(
      id: 'finance_ledger',
      title: 'Finance Ledger',
      subtitle: 'Accountant desk, student fee collections & payroll ledger',
      icon: Icons.account_balance_wallet_rounded,
      color: Color(0xFFEC4899),
    ),
  ];

  String _extractFirstName(String fullName) {
    final lower = fullName.toLowerCase().trim();
    if (lower.contains('super admin') || lower == 'administrator') {
      return 'Admin';
    }
    final stripped = fullName
        .replaceAll(RegExp(r'^(Dr\.|Mr\.|Mrs\.|Ms\.|Prof\.)\s*', caseSensitive: false), '')
        .trim();
    final parts = stripped.split(RegExp(r'\s+'));
    return parts.isNotEmpty ? parts.first : fullName;
  }

  String _getClassTeacherBadgeText(StaffMemberModel staff) {
    final assignment = staff.primaryClassAssignment;
    if (assignment != null) {
      final cleanGrade = assignment.grade
          .replaceAll(RegExp(r'^(Class\s*|Grade\s*)', caseSensitive: false), '')
          .trim();
      return 'Class Teacher • $cleanGrade-${assignment.section}';
    }
    return 'Class Teacher';
  }

  bool _matchesQuery(_UnifiedLoginCard card, String query) {
    if (query.isEmpty) return true;
    final q = query.toLowerCase().trim();
    if (card.fullName.toLowerCase().contains(q)) return true;
    if (card.email.toLowerCase().contains(q)) return true;
    if (card.rolePillText.toLowerCase().contains(q)) return true;
    if (card.subtitle.toLowerCase().contains(q)) return true;
    if (card.extraBadgeText != null && card.extraBadgeText!.toLowerCase().contains(q)) return true;
    return false;
  }

  Future<void> _executeStaffLogin(
    StaffMemberModel staff, {
    bool isAdmin = false,
    UserRole? overrideRole,
  }) async {
    setState(() => _loggingInId = staff.id);
    try {
      final email = staff.loginAccount?.institutionalEmail ?? staff.email;
      final loggedIn =
          await ref.read(staffAuthControllerProvider).mockStaffLogin(email, '123456');

      if (loggedIn != null && mounted) {
        widget.onStaffSelected?.call(loggedIn);
        if (overrideRole != null) {
          ref.read(activeUserRoleProvider.notifier).state = overrideRole;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authenticated as ${loggedIn.fullName} (${loggedIn.designation})',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );

        final targetRoute =
            (isAdmin || isSuperAdmin(loggedIn.effectiveRole)) ? '/admin/staff' : '/staff/dashboard';

        try {
          context.go(targetRoute);
        } catch (_) {}
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not authenticate staff credentials', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login error: $e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loggingInId = null);
      }
    }
  }

  Future<void> _executeStudentLogin(StudentDemoModel student) async {
    setState(() => _loggingInId = student.id);
    try {
      final loggedIn =
          await ref.read(studentAuthControllerProvider).mockStudentLogin(student.email, '123456');

      if (loggedIn != null && mounted) {
        ref.read(activeUserRoleProvider.notifier).state = UserRole.student;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authenticated as ${loggedIn.fullName} (${loggedIn.className})',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF06B6D4),
            behavior: SnackBarBehavior.floating,
          ),
        );

        try {
          context.go('/student/dashboard');
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Student login error: $e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loggingInId = null);
      }
    }
  }

  Future<void> _executeParentLogin(ParentDemoModel parent) async {
    setState(() => _loggingInId = parent.id);
    try {
      final loggedIn =
          await ref.read(parentAuthControllerProvider).mockParentLogin(parent.email, '123456');

      if (loggedIn != null && mounted) {
        ref.read(activeUserRoleProvider.notifier).state = UserRole.parent;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Authenticated as ${loggedIn.fullName} (Guardian of ${loggedIn.childName})',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );

        try {
          context.go('/parent/dashboard');
        } catch (_) {}
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Parent login error: $e', style: GoogleFonts.inter()),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loggingInId = null);
      }
    }
  }

  List<_UnifiedLoginCard> _buildCardsForGroup(
    String groupId,
    List<StaffMemberModel> staffList,
    List<StudentDemoModel> studentList,
    List<ParentDemoModel> parentList,
  ) {
    switch (groupId) {
      case 'super_admin':
      case 'school_admin':
        // 1. School Administrator (Dr. Sarah Jenkins)
        return [
          _UnifiedLoginCard(
            id: 'USR-ADMIN-01',
            fullName: 'Dr. Sarah Jenkins',
            email: 'admin@edupulse.edu',
            subtitle: 'School Administrator & Executive',
            initials: 'SJ',
            rolePillText: 'School Admin',
            rolePillColor: const Color(0xFF6366F1),
            buttonLabel: 'Login as Admin',
            onLogin: () async {
              setState(() => _loggingInId = 'USR-ADMIN-01');
              try {
                await ref.read(staffAuthControllerProvider).mockStaffLogin('admin@edupulse.edu.in', '123456');
                ref.read(activeUserRoleProvider.notifier).state = UserRole.admin;
                ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Authenticated as Dr. Sarah Jenkins (School Administrator)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  try {
                    context.go(RouteNames.adminStaff);
                  } catch (_) {}
                }
              } finally {
                if (mounted) setState(() => _loggingInId = null);
              }
            },
            extraBadgeText: 'School Governance',
            extraBadgeColor: const Color(0xFF6366F1),
            extraBadgeIcon: Icons.admin_panel_settings_rounded,
          ),
        ];

      case 'principal':
        // 2. Principal & Leadership (1)
        final principals = staffList
            .where((s) => !s.isSuperAdmin && s.effectiveRole == 'principal')
            .toList();
        final principal = principals.isNotEmpty ? principals.first : null;
        if (principal == null) return [];
        return [
          _UnifiedLoginCard(
            id: principal.id,
            fullName: principal.fullName,
            email: principal.loginAccount?.institutionalEmail ?? principal.email,
            subtitle: principal.designation,
            initials: principal.initials,
            rolePillText: 'Principal',
            rolePillColor: const Color(0xFF8B5CF6),
            buttonLabel: 'Login as ${_extractFirstName(principal.fullName)}',
            onLogin: () => _executeStaffLogin(principal),
            extraBadgeText: 'Academic Governance Head',
            extraBadgeColor: const Color(0xFF8B5CF6),
            extraBadgeIcon: Icons.workspace_premium_rounded,
          ),
        ];

      case 'teaching_faculty':
        // 3. Teaching Faculty - Class Teacher + Subject Teacher
        final teachers = staffList.where((s) => s.effectiveRole == 'teacher').toList();
        // Sort: Class Teachers first, then Subject Teachers
        teachers.sort((a, b) {
          if (a.isClassTeacher && !b.isClassTeacher) return -1;
          if (!a.isClassTeacher && b.isClassTeacher) return 1;
          return a.fullName.compareTo(b.fullName);
        });

        return teachers.map((teacher) {
          final isCt = teacher.isClassTeacher;
          final firstName = _extractFirstName(teacher.fullName);
          final pillColor = isCt ? const Color(0xFF109F83) : const Color(0xFF2563EB);

          return _UnifiedLoginCard(
            id: teacher.id,
            fullName: teacher.fullName,
            email: teacher.loginAccount?.institutionalEmail ?? teacher.email,
            subtitle: teacher.designation,
            initials: teacher.initials,
            rolePillText: isCt ? 'Class Teacher' : 'Subject Teacher',
            rolePillColor: pillColor,
            buttonLabel: 'Login as $firstName',
            onLogin: () => _executeStaffLogin(teacher),
            extraBadgeText: isCt ? _getClassTeacherBadgeText(teacher) : teacher.department,
            extraBadgeColor: pillColor,
            extraBadgeIcon: isCt ? Icons.stars_rounded : Icons.menu_book_rounded,
          );
        }).toList();

      case 'finance_support':
        // 4. Finance & Support [Accountant, Librarian, Transport, Receptionist]
        final supportStaff = staffList.where((s) {
          final role = s.effectiveRole;
          return role == 'accountant' ||
              role == 'librarian' ||
              role == 'transport_manager' ||
              role == 'receptionist';
        }).toList();

        return supportStaff.map((staff) {
          final firstName = _extractFirstName(staff.fullName);
          Color pillColor;
          String pillLabel;

          switch (staff.effectiveRole) {
            case 'accountant':
              pillColor = const Color(0xFFEC4899); // Rose/Pink - NOT RED
              pillLabel = 'Accountant';
              break;
            case 'librarian':
              pillColor = const Color(0xFF8B5CF6);
              pillLabel = 'Librarian';
              break;
            case 'transport_manager':
              pillColor = const Color(0xFFF59E0B);
              pillLabel = 'Transport Mgr';
              break;
            case 'receptionist':
              pillColor = const Color(0xFF0EA5E9);
              pillLabel = 'Receptionist';
              break;
            default:
              pillColor = AppColors.primary;
              pillLabel = staff.effectiveRole;
          }

          return _UnifiedLoginCard(
            id: staff.id,
            fullName: staff.fullName,
            email: staff.loginAccount?.institutionalEmail ?? staff.email,
            subtitle: staff.designation,
            initials: staff.initials,
            rolePillText: pillLabel,
            rolePillColor: pillColor,
            buttonLabel: 'Login as $firstName',
            onLogin: () => _executeStaffLogin(staff),
            extraBadgeText: staff.department,
            extraBadgeColor: pillColor,
            extraBadgeIcon: Icons.badge_rounded,
          );
        }).toList();

      case 'student_hub':
        // 5. Student Hub [show 4-6 demo students with class e.g., Class 10-A]
        return studentList.map((student) {
          final firstName = _extractFirstName(student.fullName);
          const color = Color(0xFF06B6D4); // Cyan for students

          return _UnifiedLoginCard(
            id: student.id,
            fullName: student.fullName,
            email: student.email,
            subtitle: '${student.admissionNumber} • Roll: ${student.rollNumber}',
            initials: student.initials,
            rolePillText: student.className,
            rolePillColor: color,
            buttonLabel: 'Login as $firstName',
            onLogin: () => _executeStudentLogin(student),
            extraBadgeText: 'Student • ${student.className}',
            extraBadgeColor: color,
            extraBadgeIcon: Icons.backpack_rounded,
          );
        }).toList();

      case 'parent_portal':
        // 6. Parent Portal [show 4 demo parents]
        return parentList.map((parent) {
          final firstName = _extractFirstName(parent.fullName);
          const color = Color(0xFF10B981); // Emerald for parents

          return _UnifiedLoginCard(
            id: parent.id,
            fullName: parent.fullName,
            email: parent.email,
            subtitle: 'Guardian of ${parent.childName}',
            initials: parent.initials,
            rolePillText: parent.childClass,
            rolePillColor: color,
            buttonLabel: 'Login as $firstName',
            onLogin: () => _executeParentLogin(parent),
            extraBadgeText: 'Ward: ${parent.childName}',
            extraBadgeColor: color,
            extraBadgeIcon: Icons.family_restroom_rounded,
          );
        }).toList();

      case 'front_desk':
        // 7. Front-Desk Desk [receptionist]
        final receptionists = staffList.where((s) => s.effectiveRole == 'receptionist').toList();
        final receptionist = receptionists.isNotEmpty ? receptionists.first : null;
        if (receptionist == null) return [];
        return [
          _UnifiedLoginCard(
            id: receptionist.id,
            fullName: receptionist.fullName,
            email: receptionist.loginAccount?.institutionalEmail ?? receptionist.email,
            subtitle: 'Front-Desk & Visitor Log Desk',
            initials: receptionist.initials,
            rolePillText: 'Front-Desk Officer',
            rolePillColor: const Color(0xFF0EA5E9),
            buttonLabel: 'Login as ${_extractFirstName(receptionist.fullName)}',
            onLogin: () => _executeStaffLogin(
              receptionist,
              overrideRole: UserRole.admissions,
            ),
            extraBadgeText: 'Admissions Intake Gatekeeper',
            extraBadgeColor: const Color(0xFF0EA5E9),
            extraBadgeIcon: Icons.support_agent_rounded,
          ),
        ];

      case 'finance_ledger':
        // 8. Finance Ledger [accountant]
        final accountants = staffList.where((s) => s.effectiveRole == 'accountant').toList();
        final accountant = accountants.isNotEmpty ? accountants.first : null;
        if (accountant == null) return [];
        return [
          _UnifiedLoginCard(
            id: accountant.id,
            fullName: accountant.fullName,
            email: accountant.loginAccount?.institutionalEmail ?? accountant.email,
            subtitle: 'Fee Collections & Payroll Ledger',
            initials: accountant.initials,
            rolePillText: 'Accounts Comptroller',
            rolePillColor: const Color(0xFFEC4899), // Rose/Pink - NOT RED
            buttonLabel: 'Login as ${_extractFirstName(accountant.fullName)}',
            onLogin: () => _executeStaffLogin(
              accountant,
              overrideRole: UserRole.finance,
            ),
            extraBadgeText: 'Accounts & Fee Comptroller',
            extraBadgeColor: const Color(0xFFEC4899),
            extraBadgeIcon: Icons.account_balance_wallet_rounded,
          ),
        ];

      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final staffAsync = ref.watch(staffListProvider);
    final studentAsync = ref.watch(studentListProvider);
    final parentAsync = ref.watch(parentListProvider);

    final allStaff = staffAsync.valueOrNull ?? [];
    final allStudents = studentAsync.valueOrNull ?? [];
    final allParents = parentAsync.valueOrNull ?? [];

    if (staffAsync.isLoading && allStaff.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _groups.map((group) {
        final cards = _buildCardsForGroup(
          group.id,
          allStaff,
          allStudents,
          allParents,
        ).where((c) => _matchesQuery(c, widget.searchQuery)).toList();

        // If searching and this group has no matches, omit group
        if (widget.searchQuery.isNotEmpty && cards.isEmpty) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildGroupHeader(group, cards.length, isDark),
              const SizedBox(height: 12),
              if (cards.isEmpty)
                _buildEmptyPlaceholder(group, isDark)
              else
                _buildResponsiveGrid(cards, isDark),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGroupHeader(_GroupMetadata group, int count, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: group.color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: group.color.withValues(alpha: 0.3),
              width: 1.0,
            ),
          ),
          child: Icon(group.icon, size: 16, color: group.color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 1),
              Text(
                group.subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : AppColors.borderLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey.shade300,
              width: 0.8,
            ),
          ),
          child: Text(
            '$count',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPlaceholder(_GroupMetadata group, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark.withValues(alpha: 0.5) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Center(
        child: Text(
          'No matching records found in this group',
          style: GoogleFonts.inter(
            fontSize: 12,
            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
          ),
        ),
      ),
    );
  }

  Widget _buildResponsiveGrid(List<_UnifiedLoginCard> cards, bool isDark) {
    return ResponsiveLayout(
      mobile: _buildColumns(cards, 1, isDark),
      tablet: _buildColumns(cards, 2, isDark),
      desktop: _buildColumns(cards, 4, isDark),
    );
  }

  Widget _buildColumns(List<_UnifiedLoginCard> cards, int columns, bool isDark) {
    if (columns == 1) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCardItem(card, isDark),
              ),
            )
            .toList(),
      );
    }

    final rows = <Widget>[];
    for (int i = 0; i < cards.length; i += columns) {
      final rowCards = cards.skip(i).take(columns).toList();
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int j = 0; j < columns; j++) ...[
                if (j > 0) const SizedBox(width: 12),
                Expanded(
                  child: j < rowCards.length
                      ? _buildCardItem(rowCards[j], isDark)
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  Widget _buildCardItem(_UnifiedLoginCard card, bool isDark) {
    final isLoggingIn = _loggingInId == card.id;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Avatar, Name & Role/Class Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: card.rolePillColor.withValues(alpha: 0.15),
                child: Text(
                  card.initials,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: card.rolePillColor,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.fullName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      card.subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      card.email,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Role / Class Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: card.rolePillColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: card.rolePillColor.withValues(alpha: 0.35),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  card.rolePillText,
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: card.rolePillColor,
                  ),
                ),
              ),
            ],
          ),

          // Extra context badge (Class Teacher / Subject / Ward)
          if (card.extraBadgeText != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (card.extraBadgeColor ?? card.rolePillColor).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (card.extraBadgeColor ?? card.rolePillColor).withValues(alpha: 0.30),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    card.extraBadgeIcon ?? Icons.info_outline_rounded,
                    size: 12,
                    color: card.extraBadgeColor ?? card.rolePillColor,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      card.extraBadgeText!,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: card.extraBadgeColor ?? card.rolePillColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 11),

          // ONE Direct Login Button
          SizedBox(
            width: double.infinity,
            height: 35,
            child: ElevatedButton.icon(
              icon: isLoggingIn
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.login_rounded, size: 14),
              label: Text(
                card.buttonLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: card.rolePillColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: (_loggingInId != null) ? null : () => card.onLogin(),
            ),
          ),
        ],
      ),
    );
  }
}
