import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/teacher_assignments_controller.dart';
import 'teacher_class_workspace_screen.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Teacher: classes where the teacher is class teacher or teaches a subject/period.
/// Read-only; no unauthorized create/edit/delete management actions are shown.
class AssignedClassesScreen extends ConsumerWidget {
  const AssignedClassesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(classesPermissionsProvider);
    final actor = ref.watch(classesActorProvider);
    final lookup = ref.watch(classesLookupProvider);
    final classesAsync = ref.watch(classesControllerProvider);
    final allAdmissions =
        ref.watch(admissionsListProvider).valueOrNull ?? const [];
    final teacherAssignments =
        ref.watch(teacherAssignmentsControllerProvider).valueOrNull ?? const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AccessGuard(
      allowed: perms.isTeacher || perms.isAdmin,
      child: ClassesPageFrame(
        title: 'Assigned Classes',
        child: AsyncListBody(
          value: classesAsync,
          onRetry: () => ref.invalidate(classesControllerProvider),
          emptyTitle: 'No classes assigned',
          emptySubtitle: 'Ask an administrator to assign you to a class.',
          builder: (items) {
            // Filter to classes assigned to this teacher
            final assignedClasses = items.where((c) {
              if (perms.isAdmin) return true;
              final tid = actor.userId;
              if (lookup.matchesTeacher(c.classTeacherId, tid)) return true;
              if (lookup.sections.any(
                (s) =>
                    s.classId == c.id &&
                    lookup.matchesTeacher(s.classTeacherId, tid),
              ))
                return true;
              if (lookup.subjects.any(
                (s) =>
                    s.classId == c.id &&
                    lookup.matchesTeacher(s.teacherId, tid),
              ))
                return true;
              if (teacherAssignments.any(
                (a) =>
                    a.classId == c.id &&
                    lookup.matchesTeacher(a.teacherId, tid),
              ))
                return true;
              return false;
            }).toList();

            if (assignedClasses.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.assignment_outlined,
                        size: 48,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'No classes assigned to you yet.',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ask an administrator to allocate you as a class teacher or subject faculty.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.only(bottom: 24),
              itemCount: assignedClasses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final c = assignedClasses[i];
                final room = lookup.classrooms
                    .where((r) => r.id == c.classroomId)
                    .firstOrNull;
                final classSections = lookup.sections
                    .where((s) => s.classId == c.id)
                    .map((s) => s.name)
                    .toList();

                // Compute enrolled student count
                final enrolledCount = allAdmissions.where((a) {
                  final matchesId = a.student.currentClassId == c.id;
                  final normStudentClass = a.student.className
                      .toLowerCase()
                      .replaceAll('class', '')
                      .replaceAll('th', '')
                      .trim();
                  final normClassName = c.name
                      .toLowerCase()
                      .replaceAll('class', '')
                      .replaceAll('th', '')
                      .replaceAll('st', '')
                      .replaceAll('nd', '')
                      .replaceAll('rd', '')
                      .trim();
                  return matchesId || normStudentClass == normClassName;
                }).length;

                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            TeacherClassWorkspaceScreen(classId: c.id),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF109F83,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.class_outlined,
                                  color: Color(0xFF109F83),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Academic Year: ${c.academicYear} · Code: ${c.code.isNotEmpty ? c.code : 'CLS-${c.gradeLevel > 0 ? c.gradeLevel : 1}'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          const Divider(height: 20),
                          Wrap(
                            spacing: 16,
                            runSpacing: 10,
                            children: [
                              if (classSections.isNotEmpty)
                                _buildDetailChip(
                                  Icons.splitscreen_outlined,
                                  'Sections',
                                  classSections.join(', '),
                                  isDark,
                                ),
                              _buildDetailChip(
                                Icons.meeting_room_outlined,
                                'Room',
                                room != null
                                    ? '${room.name} (${room.displayFloor})'
                                    : 'Unassigned',
                                isDark,
                              ),
                              if (room != null && room.capacity > 0)
                                _buildDetailChip(
                                  Icons.event_seat_outlined,
                                  'Room Capacity',
                                  '${room.capacity} seats',
                                  isDark,
                                ),
                              _buildDetailChip(
                                Icons.group_outlined,
                                'Class Strength',
                                '${c.capacity > 0 ? c.capacity : '—'} max',
                                isDark,
                              ),
                              _buildDetailChip(
                                Icons.how_to_reg_outlined,
                                'Enrolled Students',
                                '$enrolledCount students',
                                isDark,
                                color: const Color(0xFF109F83),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildDetailChip(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    Color? color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color:
              color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
