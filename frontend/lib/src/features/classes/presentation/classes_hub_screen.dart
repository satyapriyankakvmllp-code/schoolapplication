import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/edupluse_scaffold.dart';
import '../../staff/application/staff_controller.dart';
import '../application/classes_access.dart';
import '../domain/classes_actor.dart';
import 'admin/classes_list_screen.dart';
import 'admin/classroom_management_screen.dart';
import 'admin/curriculum_management_screen.dart';
import 'admin/sections_management_screen.dart';
import 'admin/subjects_management_screen.dart';
import 'admin/timetable_management_screen.dart';
import 'parent/parent_class_screen.dart';
import 'student/student_class_screen.dart';
import 'teacher/assigned_classes_screen.dart';
import 'widgets/classes_ui.dart';
import 'teacher/teacher_work_management_screen.dart';

/// Entry point for the Classes feature.
/// Sub-screens are selected via the expandable sidebar submenu (or compact dropdown)
/// without permanent horizontal chip rows or clutter.
class ClassesHubScreen extends ConsumerStatefulWidget {
  final EdupluseNavPage activeNavPage;
  final bool isDark;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onToggleTheme;
  final VoidCallback? onExitToGateway;

  const ClassesHubScreen({
    super.key,
    this.activeNavPage = EdupluseNavPage.classes,
    this.isDark = false,
    this.onNavigate,
    this.onToggleTheme,
    this.onExitToGateway,
  });

  @override
  ConsumerState<ClassesHubScreen> createState() => _ClassesHubScreenState();
}

class _ClassesHubScreenState extends ConsumerState<ClassesHubScreen> {
  late EdupluseNavPage _currentPage;
  String? _sectionClassFilterId;
  String? _selectedClassroomId;
  String? _selectedAcademicClassId;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.activeNavPage;
  }

  @override
  void didUpdateWidget(covariant ClassesHubScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeNavPage != widget.activeNavPage) {
      setState(() {
        _currentPage = widget.activeNavPage;
      });
    }
  }

  void _handleSectionChange(EdupluseNavPage page) {
    setState(() {
      _sectionClassFilterId = null;
      _selectedClassroomId = null;
      _selectedAcademicClassId = null;
      _currentPage = page;
    });
    widget.onNavigate?.call(page);
  }

  String _sectionTitle(EdupluseNavPage page) {
    switch (page) {
      case EdupluseNavPage.classesSubjects:
        return 'Subjects';
      case EdupluseNavPage.classesSections:
        return 'Sections';
      case EdupluseNavPage.classesCurriculum:
        return 'Curriculum';
      case EdupluseNavPage.classesTimetable:
        return 'Timetable';
      case EdupluseNavPage.classesClassrooms:
        return 'Classrooms';
      case EdupluseNavPage.classesTeacherWork:
        return 'Assignments';
      case EdupluseNavPage.classes:
      default:
        return 'Academic Classes';
    }
  }

  Widget _buildActiveBody(ClassesPermissions perms) {
    switch (_currentPage) {
      case EdupluseNavPage.classesSubjects:
        return SubjectsManagementScreen(
          onOpenClass: (classId) {
            setState(() {
              _selectedAcademicClassId = classId;
              _currentPage = EdupluseNavPage.classes;
            });
            widget.onNavigate?.call(EdupluseNavPage.classes);
          },
        );
      case EdupluseNavPage.classesSections:
        return SectionsManagementScreen(
          initialClassId: _sectionClassFilterId,
          onOpenClass: (classId) {
            setState(() {
              _selectedAcademicClassId = classId;
              _currentPage = EdupluseNavPage.classes;
            });
            widget.onNavigate?.call(EdupluseNavPage.classes);
          },
          onOpenClassroom: perms.isAdmin
              ? (roomId) {
                  setState(() {
                    _selectedClassroomId = roomId;
                    _currentPage = EdupluseNavPage.classesClassrooms;
                  });
                  widget.onNavigate?.call(EdupluseNavPage.classesClassrooms);
                }
              : null,
          onOpenStaff: perms.isAdmin
              ? (staffId) {
                  ref.read(selectedStaffIdProvider.notifier).state = staffId;
                  widget.onNavigate?.call(EdupluseNavPage.staffDetails);
                }
              : null,
        );
      case EdupluseNavPage.classesCurriculum:
        return const CurriculumManagementScreen();
      case EdupluseNavPage.classesTimetable:
        return const TimetableManagementScreen();
      case EdupluseNavPage.classesClassrooms:
        if (!perms.isAdmin) {
          return perms.isTeacher
              ? const AssignedClassesScreen()
              : perms.isStudent
              ? const StudentClassScreen()
              : const ParentClassScreen();
        }
        return ClassroomManagementScreen(
          initialRoomId: _selectedClassroomId,
          onOpenClass: (classId) {
            setState(() {
              _selectedAcademicClassId =
                  null; // Navigates to Academic Class page (not class details)
              _currentPage = EdupluseNavPage.classes;
            });
            widget.onNavigate?.call(EdupluseNavPage.classes);
          },
        );
      case EdupluseNavPage.classesTeacherWork:
        return const TeacherWorkManagementScreen();
      case EdupluseNavPage.classes:
      default:
        return AdminClassesListScreen(
          initialClassId: _selectedAcademicClassId,
          onOpenClassroom: perms.isAdmin
              ? (roomId) {
                  setState(() {
                    _selectedClassroomId = roomId;
                    _currentPage = EdupluseNavPage.classesClassrooms;
                  });
                  widget.onNavigate?.call(EdupluseNavPage.classesClassrooms);
                }
              : null,
          onOpenSections: (classId) {
            setState(() {
              _sectionClassFilterId = classId;
              _currentPage = EdupluseNavPage.classesSections;
            });
            widget.onNavigate?.call(EdupluseNavPage.classesSections);
          },
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final isDark =
        widget.isDark || Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return EdupluseScaffold(
      activePage: _currentPage,
      isDark: widget.isDark,
      onNavigate: (page) {
        setState(() {
          _currentPage = page;
        });
        widget.onNavigate?.call(page);
      },
      onToggleTheme: widget.onToggleTheme,
      onExitToGateway: widget.onExitToGateway,
      body: AccessGuard(
        allowed: perms.canAccessClasses,
        child: Column(
          children: [
            // Compact Header Bar with clickable Dropdown Menu (only opens when clicked)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 20,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                border: Border(
                  bottom: BorderSide(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 18,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Classes',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                  const SizedBox(width: 6),
                  // Dropdown that opens downward neatly only when clicked
                  Flexible(
                    child: PopupMenuButton<EdupluseNavPage>(
                      tooltip: 'Switch Module',
                      initialValue: _currentPage,
                      onSelected: _handleSectionChange,
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: EdupluseNavPage.classes,
                          child: Row(
                            children: [
                              Icon(Icons.class_outlined, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Academic Classes',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        if (perms.isAdmin || perms.isTeacher)
                          const PopupMenuItem(
                            value: EdupluseNavPage.classesSubjects,
                            child: Row(
                              children: [
                                Icon(Icons.menu_book_outlined, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Subjects',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        if (perms.isAdmin)
                          const PopupMenuItem(
                            value: EdupluseNavPage.classesSections,
                            child: Row(
                              children: [
                                Icon(Icons.groups_outlined, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Sections',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        const PopupMenuItem(
                          value: EdupluseNavPage.classesCurriculum,
                          child: Row(
                            children: [
                              Icon(Icons.library_books_outlined, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Curriculum',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: EdupluseNavPage.classesTimetable,
                          child: Row(
                            children: [
                              Icon(Icons.schedule, size: 16),
                              SizedBox(width: 8),
                              Text(
                                'Timetable',
                                style: TextStyle(fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                        if (perms.isAdmin)
                          const PopupMenuItem(
                            value: EdupluseNavPage.classesClassrooms,
                            child: Row(
                              children: [
                                Icon(Icons.meeting_room_outlined, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Classrooms',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                        if (perms.canViewTeacherWork)
                          const PopupMenuItem(
                            value: EdupluseNavPage.classesTeacherWork,
                            child: Row(
                              children: [
                                Icon(Icons.assignment_outlined, size: 16),
                                SizedBox(width: 8),
                                Text(
                                  'Assignments',
                                  style: TextStyle(fontSize: 12.5),
                                ),
                              ],
                            ),
                          ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                _sectionTitle(_currentPage),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Sub-screen Body
            Expanded(child: _buildActiveBody(perms)),
          ],
        ),
      ),
    );
  }
}
