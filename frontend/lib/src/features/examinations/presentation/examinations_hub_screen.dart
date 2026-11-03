import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commonwidgets/edupluse_scaffold.dart';
import '../../authentication/application/auth_controller.dart';
import '../../authentication/domain/user_model.dart';
import '../application/exam_controller.dart';
import '../application/examination_access.dart';
import '../domain/examination_actor.dart';
import 'admin/admin_examinations_screen.dart';
import 'parent/parent_examinations_screen.dart';
import 'student/student_examinations_screen.dart';
import 'teacher/teacher_examinations_screen.dart';

/// Entry point / Hub for the Examination Module.
/// Follows the architecture of ClassesHubScreen:
/// Inspects the active user role (Admin, Teacher, Student, Parent)
/// and displays the dedicated role-specific presentation screen.
class ExaminationsHubScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onExitToGateway;

  const ExaminationsHubScreen({
    super.key,
    this.isDark = false,
    this.onToggleTheme,
    this.onNavigate,
    this.onExitToGateway,
  });

  @override
  ConsumerState<ExaminationsHubScreen> createState() => _ExaminationsHubScreenState();
}

class _ExaminationsHubScreenState extends ConsumerState<ExaminationsHubScreen> {
  Future<void> _handleResetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will restore all examination schedules, timetables, and demo marks to their original state.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
              foregroundColor: Colors.white,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(examListControllerProvider.notifier).resetDemoData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo examination data reset successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeAppRole = ref.watch(activeUserRoleProvider);
    final examActor = ref.watch(currentExamActorProvider);
    final globalSetupAsync = ref.watch(globalSetupProvider);
    final setup = globalSetupAsync.valueOrNull;

    final isDark = widget.isDark || Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    // Determine effective role:
    // If activeAppRole is set from the App Gateway (Teacher, Student, Parent), honor it;
    // otherwise fallback to the ExaminationActor role from global.json / switcher.
    final effectiveRole = activeAppRole ?? _mapExamRoleToUserRole(examActor.role);

    return EdupluseScaffold(
      activePage: EdupluseNavPage.examinations,
      isDark: widget.isDark,
      onNavigate: widget.onNavigate,
      onToggleTheme: widget.onToggleTheme,
      onExitToGateway: widget.onExitToGateway,
      body: Column(
        children: [
          // Sub-header Bar with Breadcrumb, Role Switcher & Reset Button
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 20,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_outlined,
                  size: 18,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 8),
                Text(
                  'Examinations',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  _roleLabel(effectiveRole),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF109F83),
                  ),
                ),

                const Spacer(),

                // Reset Demo Data Button
                if (!isMobile)
                  TextButton.icon(
                    onPressed: _handleResetDemoData,
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset demo data', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      foregroundColor: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                    ),
                  ),

                const SizedBox(width: 10),

                // Role Switcher Dropdown (for testing and demo switching)
                if (setup != null && setup.users.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: setup.currentUser?.id,
                        hint: const Text('Role', style: TextStyle(fontSize: 12)),
                        isDense: true,
                        items: setup.users.map((u) {
                          return DropdownMenuItem<String>(
                            value: u.id,
                            child: Row(
                              children: [
                                _roleIcon(u.role),
                                const SizedBox(width: 6),
                                Text(
                                  '${u.name} (${u.role})',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (selectedUserId) {
                          if (selectedUserId != null) {
                            // Update examination setup
                            ref.read(globalSetupProvider.notifier).switchUser(selectedUserId);
                            // Also update app-wide role provider if appropriate
                            final chosenUser = setup.users.firstWhere((u) => u.id == selectedUserId);
                            final mappedRole = _mapStringToUserRole(chosenUser.role);
                            ref.read(activeUserRoleProvider.notifier).state = mappedRole;
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Role-Specific Screen Content
          Expanded(
            child: _buildRoleScreen(effectiveRole),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleScreen(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return TeacherExaminationsScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          onExitToGateway: widget.onExitToGateway,
        );

      case UserRole.student:
        return StudentExaminationsScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          onExitToGateway: widget.onExitToGateway,
        );

      case UserRole.parent:
        return ParentExaminationsScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          onExitToGateway: widget.onExitToGateway,
        );

      case UserRole.admin:
      case UserRole.admissions:
      case UserRole.finance:
        return AdminExaminationsScreen(
          isDark: widget.isDark,
          onToggleTheme: widget.onToggleTheme,
          onExitToGateway: widget.onExitToGateway,
        );
    }
  }

  UserRole _mapExamRoleToUserRole(ExamRole role) {
    switch (role) {
      case ExamRole.teacher:
      case ExamRole.classIncharge:
        return UserRole.teacher;
      case ExamRole.student:
        return UserRole.student;
      case ExamRole.parent:
        return UserRole.parent;
      case ExamRole.admin:
      case ExamRole.principal:
        return UserRole.admin;
    }
  }

  UserRole _mapStringToUserRole(String rawRole) {
    switch (rawRole.toUpperCase()) {
      case 'TEACHER':
      case 'CLASS_INCHARGE':
        return UserRole.teacher;
      case 'STUDENT':
        return UserRole.student;
      case 'PARENT':
        return UserRole.parent;
      case 'ADMIN':
      case 'PRINCIPAL':
      default:
        return UserRole.admin;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.teacher:
        return 'Teacher Workspace';
      case UserRole.student:
        return 'Student Hub';
      case UserRole.parent:
        return 'Parent Portal';
      case UserRole.admin:
      default:
        return 'Admin Console';
    }
  }

  Widget _roleIcon(String rawRole) {
    IconData icon;
    Color color;
    switch (rawRole.toUpperCase()) {
      case 'ADMIN':
      case 'PRINCIPAL':
        icon = Icons.admin_panel_settings;
        color = const Color(0xFF6366F1);
        break;
      case 'TEACHER':
      case 'CLASS_INCHARGE':
        icon = Icons.school;
        color = const Color(0xFF3B82F6);
        break;
      case 'STUDENT':
        icon = Icons.person;
        color = const Color(0xFF06B6D4);
        break;
      case 'PARENT':
        icon = Icons.family_restroom;
        color = const Color(0xFF10B981);
        break;
      default:
        icon = Icons.account_circle;
        color = Colors.grey;
    }
    return Icon(icon, size: 14, color: color);
  }
}

