import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../../admissions/domain/student_admission_model.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/classroom_controller.dart';
import '../../application/sections_controller.dart';
import '../../domain/classroom_model.dart';
import '../../domain/section_model.dart';
import '../widgets/classes_lookup.dart';

/// Clean, dedicated Section Details view for navigation from Sections or Academic Classes.
class SectionDetailsView extends ConsumerWidget {
  final String sectionId;
  final String breadcrumbBase;
  final String backButtonText;
  final VoidCallback onBack;
  final void Function(String roomId)? onOpenRoom;

  const SectionDetailsView({
    super.key,
    required this.sectionId,
    required this.breadcrumbBase,
    required this.backButtonText,
    required this.onBack,
    this.onOpenRoom,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sections = ref.watch(sectionsControllerProvider).valueOrNull ?? const <SectionModel>[];
    final section = sections.where((s) => s.id == sectionId).firstOrNull;
    final lookup = ref.watch(classesLookupProvider);
    final actor = ref.watch(classesActorProvider);
    final perms = actor.permissions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.sizeOf(context).width < 768;

    if (section == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(backButtonText),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Center(child: Text('Section not found.')),
        ],
      );
    }

    final parentClass = ref.watch(classesControllerProvider).valueOrNull?.where((c) => c.id == section.classId).firstOrNull;
    final rooms = ref.watch(classroomControllerProvider).valueOrNull ?? const <ClassroomModel>[];
    final room = rooms.where((r) => r.id == section.classroomId).firstOrNull;
    final allAdmissions = ref.watch(admissionsListProvider).valueOrNull ?? const <StudentAdmissionModel>[];

    // Unique enrolled students in this section
    final sectionStudents = allAdmissions.where((adm) {
      if ((perms.isStudent || perms.isParent) &&
          adm.student.id != actor.studentId) {
        return false;
      }
      final matchesSectionId = adm.student.sectionId == section.id;
      final normStudentClass = adm.student.className
          .toLowerCase()
          .replaceAll('class', '')
          .replaceAll('th', '')
          .replaceAll('st', '')
          .replaceAll('nd', '')
          .replaceAll('rd', '')
          .trim();
      final normSectionClass = lookup
          .className(section.classId)
          .toLowerCase()
          .replaceAll('class', '')
          .replaceAll('th', '')
          .replaceAll('st', '')
          .replaceAll('nd', '')
          .replaceAll('rd', '')
          .trim();
      final matchesClassAndSec = (adm.student.currentClassId == section.classId ||
              normStudentClass == normSectionClass) &&
          adm.student.section.toUpperCase() == section.name.toUpperCase();
      return matchesSectionId || matchesClassAndSec;
    }).toList();

    // Remove duplicates if any
    final uniqueStudents = <StudentAdmissionModel>[];
    final seenIds = <String>{};
    for (final s in sectionStudents) {
      if (seenIds.add(s.user.id)) {
        uniqueStudents.add(s);
      }
    }

    // Capacity calculation: individual section capacity, falling back to parent class strength
    final capacity = (parentClass != null && parentClass.capacity > 0)
        ? (section.capacity > 0 && section.capacity != (room?.capacity ?? 40) && section.capacity != 40
            ? section.capacity
            : parentClass.capacity)
        : (section.capacity > 0 ? section.capacity : 20);
    final occupancy = uniqueStudents.length;
    final floorStr = (room != null && room.displayFloor.isNotEmpty && room.displayFloor != '—')
        ? room.displayFloor
        : 'Ground Floor';
    final roomName = room != null ? room.name : (lookup.roomName(section.classroomId));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Navigation Bar & Back Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section Details: Section ${section.name}',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$breadcrumbBase / Section ${section.name}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back, size: 16),
                label: Text(backButtonText),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Metric Cards
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildMetricCard(
                'Class',
                lookup.className(section.classId),
                Icons.school_outlined,
                const Color(0xFF3B82F6),
                isDark,
              ),
              _buildMetricCard(
                'Section',
                'Section ${section.name}',
                Icons.grid_view_outlined,
                const Color(0xFF109F83),
                isDark,
              ),
              _buildMetricCard(
                'Classroom',
                roomName.isNotEmpty ? roomName : 'Unassigned',
                Icons.meeting_room_outlined,
                const Color(0xFF8B5CF6),
                isDark,
              ),
              _buildMetricCard(
                'Floor',
                floorStr,
                Icons.layers_outlined,
                const Color(0xFF0EA5E9),
                isDark,
              ),
              _buildMetricCard(
                'Capacity',
                capacity > 0 ? '$capacity Seats' : 'Standard',
                Icons.chair_outlined,
                const Color(0xFFF59E0B),
                isDark,
              ),
              _buildMetricCard(
                'Occupancy',
                capacity > 0 ? '$occupancy / $capacity' : '$occupancy Students',
                Icons.people_outline,
                const Color(0xFF10B981),
                isDark,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Section Overview Details Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Section Information',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Academic Class', lookup.className(section.classId), isDark),
                const SizedBox(height: 8),
                _buildInfoRow('Section Name', 'Section ${section.name}', isDark),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Assigned Classroom',
                  roomName.isNotEmpty ? roomName : 'Unassigned',
                  isDark,
                  onTap: (room != null && onOpenRoom != null) ? () => onOpenRoom!(room.id) : null,
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Floor', floorStr, isDark),
                const SizedBox(height: 8),
                _buildInfoRow(
                  'Class Teacher',
                  section.classTeacherId != null && section.classTeacherId!.isNotEmpty
                      ? lookup.teacherName(section.classTeacherId)
                      : 'Unassigned',
                  isDark,
                ),
                const SizedBox(height: 8),
                _buildInfoRow('Section Strength / Capacity', capacity > 0 ? '$capacity Seats' : 'Standard', isDark),
                const SizedBox(height: 8),
                _buildInfoRow('Classroom Capacity', room != null ? '${room.capacity} Seats' : 'Unassigned', isDark),
                const SizedBox(height: 8),
                _buildInfoRow('Current Occupancy', '$occupancy / $capacity (${uniqueStudents.length} Enrolled)', isDark),
                const SizedBox(height: 8),
                _buildInfoRow('Status', section.status, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Enrolled Students Table Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Enrolled Students (${uniqueStudents.length})',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (uniqueStudents.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: Text(
                        'No students enrolled in this section yet.',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: uniqueStudents.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final adm = uniqueStudents[idx];
                      final guardianName = adm.guardian?.fullName ?? adm.father?.fullName ?? '—';
                      final rollNo = (adm.student.rollNumber != null && adm.student.rollNumber!.isNotEmpty)
                          ? adm.student.rollNumber!
                          : '—';
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 14,
                          backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.1),
                          child: Text(
                            adm.user.firstName.isNotEmpty
                              ? adm.user.firstName[0].toUpperCase()
                              : 'S',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF109F83),
                            ),
                          ),
                        ),
                        title: Text(
                          '${adm.user.firstName} ${adm.user.lastName}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        subtitle: Text(
                          'Adm No: ${adm.student.admissionNumber} | Roll: $rollNo | Guardian: $guardianName',
                          style: const TextStyle(fontSize: 11),
                        ),
                        trailing: Chip(
                          label: Text(
                            adm.student.enrollmentStatus.displayName,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark, {VoidCallback? onTap}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ),
        Expanded(
          child: onTap != null
              ? InkWell(
                  onTap: onTap,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                    ),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
        ),
      ],
    );
  }
}
