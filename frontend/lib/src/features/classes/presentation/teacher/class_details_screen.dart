import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../../admissions/domain/student_admission_model.dart';
import '../../../admissions/presentation/admin/add_student_form_screen.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/curriculum_controller.dart';
import '../../application/sections_controller.dart';
import '../../application/teacher_assignments_controller.dart';
import '../../application/subjects_controller.dart';
import '../../application/timetable_controller.dart';
import '../../application/teacher_work_controller.dart';
import '../../domain/class_model.dart';
import '../../domain/class_teacher_assignment_model.dart';
import '../../domain/classes_actor.dart';
import '../../domain/classroom_model.dart';
import '../../domain/curriculum_model.dart';
import '../../domain/section_model.dart';
import '../../domain/subject_model.dart';
import '../../domain/timetable_entry_model.dart';
import '../../domain/teacher_work_model.dart';
import '../admin/classroom_management_screen.dart' show openRoomModal;
import '../admin/curriculum_management_screen.dart' show openCurriculumModal;
import '../admin/sections_management_screen.dart' show openSectionModal;
import '../admin/subjects_management_screen.dart' show openSubjectModal;
import '../admin/timetable_management_screen.dart'
    show TimetableManagementScreen;
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Class Details screen supporting Admin, Teacher, and Student roles.
/// Can be pushed directly as a full page or embedded inline.
class ClassDetailsScreen extends StatelessWidget {
  final String classId;
  const ClassDetailsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Class Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ClassDetailsBody(
          classId: classId,
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }
}

/// The details body embedded inline inside the class list or on a separate page.
class ClassDetailsBody extends ConsumerStatefulWidget {
  final String classId;
  final VoidCallback? onBack;
  final VoidCallback? onEdit;

  const ClassDetailsBody({
    super.key,
    required this.classId,
    this.onBack,
    this.onEdit,
  });

  @override
  ConsumerState<ClassDetailsBody> createState() => _ClassDetailsBodyState();
}

class _ClassDetailsBodyState extends ConsumerState<ClassDetailsBody> {
  String? _selectedSectionId;
  String _activeTab =
      'Overview'; // Overview | Faculty | Students | Subjects | Curriculum | Timetable | Assignments
  String _studentSearchQuery = '';
  String _assignmentSortColumn = 'Due Date';
  bool _assignmentSortAscending = true;
  final Set<String> _expandedSubjects = {};

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final classesAsync = ref.watch(classesControllerProvider);
    final lookup = ref.watch(classesLookupProvider);
    final actor = ref.watch(classesActorProvider);
    final perms = actor.permissions;

    final sections =
        (ref.watch(sectionsControllerProvider).valueOrNull ?? const [])
            .where((s) => s.classId == widget.classId)
            .toList();
    final subjects =
        (ref.watch(subjectsControllerProvider).valueOrNull ?? const [])
            .where((s) => s.classId == widget.classId)
            .toList();
    final curriculum =
        (ref.watch(curriculumControllerProvider).valueOrNull ?? const [])
            .where((c) => c.classId == widget.classId)
            .toList();
    final timetable =
        (ref.watch(timetableControllerProvider).valueOrNull ?? const [])
            .where((t) => t.classId == widget.classId)
            .toList();
    final assignmentsAsync = ref.watch(teacherWorkControllerProvider);
    final classAssignmentsAsync = assignmentsAsync.whenData(
      (items) => items.where((item) => item.classId == widget.classId).toList(),
    );
    final classAssignments = classAssignmentsAsync.valueOrNull ?? const [];
    final visibleAdmissions =
        ref.watch(admissionsListProvider).valueOrNull ?? const [];
    final allAdmissions = perms.isStudent || perms.isParent
        ? visibleAdmissions
              .where((admission) => admission.student.id == actor.studentId)
              .toList()
        : visibleAdmissions;
    final allAssignments =
        (ref.watch(teacherAssignmentsControllerProvider).valueOrNull ??
                const <ClassTeacherAssignmentModel>[])
            .where((t) => t.classId == widget.classId)
            .toList();

    return classesAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Error loading class details: $e',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
      data: (list) {
        final matches = list.where(
          (c) =>
              c.id.toLowerCase() == widget.classId.toLowerCase() ||
              c.code.toLowerCase() == widget.classId.toLowerCase() ||
              c.name.toLowerCase() == widget.classId.toLowerCase(),
        );
        if (matches.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.school_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Class not found or has been removed.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (widget.onBack != null)
                    OutlinedButton.icon(
                      icon: const Icon(Icons.arrow_back, size: 16),
                      label: const Text('Back to Academic Classes'),
                      onPressed: widget.onBack,
                    ),
                ],
              ),
            ),
          );
        }
        final c = matches.first;

        // Student role section lock
        if (perms.isStudent && actor.studentSection != null) {
          final studentSec = sections
              .where(
                (s) =>
                    s.name.toUpperCase() == actor.studentSection!.toUpperCase(),
              )
              .firstOrNull;
          if (studentSec != null) {
            _selectedSectionId = studentSec.id;
          }
        }

        // Validate or initialize selected section id
        if (_selectedSectionId != null &&
            !sections.any((section) => section.id == _selectedSectionId)) {
          _selectedSectionId = null;
        }
        _selectedSectionId ??= sections.isNotEmpty ? sections.first.id : null;

        final selectedSection = sections
            .where((section) => section.id == _selectedSectionId)
            .firstOrNull;

        // SECTION INDEPENDENT DATA:
        // 1. Students enrolled in this section only
        final sectionStudents = selectedSection == null
            ? <StudentAdmissionModel>[]
            : allAdmissions.where((a) {
                final matchesSectionId =
                    a.student.sectionId == selectedSection.id;
                final matchesSectionName =
                    a.student.section.trim().toLowerCase() ==
                    selectedSection.name.trim().toLowerCase();
                final matchesClass =
                    a.student.currentClassId == widget.classId ||
                    a.student.className
                            .toLowerCase()
                            .replaceAll('class', '')
                            .trim() ==
                        c.name.toLowerCase().replaceAll('class', '').trim();
                return (matchesSectionId && matchesClass) ||
                    (a.student.sectionId == null &&
                        matchesSectionName &&
                        matchesClass);
              }).toList();

        // 2. Teacher assignments for this section only
        final sectionAssignments = selectedSection == null
            ? <ClassTeacherAssignmentModel>[]
            : allAssignments
                  .where((a) => a.sectionId == selectedSection.id)
                  .toList();

        final sectionTeacherIds = <String>{
          if (selectedSection?.classTeacherId != null &&
              selectedSection!.classTeacherId!.isNotEmpty)
            lookup.canonicalTeacherId(selectedSection.classTeacherId!),
          for (final a in sectionAssignments)
            lookup.canonicalTeacherId(a.teacherId),
        };

        // 3. Timetable periods for this section only
        final sectionTimetable = selectedSection == null
            ? <TimetableEntryModel>[]
            : timetable
                  .where((t) => t.sectionId == selectedSection.id)
                  .toList();

        // 4. Section Classroom (Independent per section; not copied from Section A or Class default)
        final ClassroomModel? sectionRoom =
            (selectedSection?.classroomId != null &&
                selectedSection!.classroomId!.isNotEmpty)
            ? lookup.classrooms
                  .where((r) => r.id == selectedSection.classroomId)
                  .firstOrNull
            : null;

        // Curriculum progress stats
        final totalTopics = curriculum.fold<int>(
          0,
          (s, ch) => s + ch.topics.length,
        );
        final doneTopics = curriculum.fold<int>(
          0,
          (s, ch) => s + ch.completedTopics,
        );
        final curriculumPct = totalTopics == 0
            ? 0
            : ((doneTopics / totalTopics) * 100).round();

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Card
                _buildHeader(context, c, isDark, perms),
                const SizedBox(height: 12),

                // Section Navigation Bar
                _buildSectionNavigationBar(
                  context,
                  c,
                  sections,
                  selectedSection,
                  allAdmissions,
                  lookup,
                  isDark,
                  perms,
                ),
                const SizedBox(height: 14),

                // Responsive Summary Tiles (6 Rectangular Cards)
                _buildSummaryTiles(
                  context,
                  c,
                  selectedSection,
                  sectionRoom,
                  sectionTeacherIds,
                  sectionStudents,
                  subjects,
                  curriculum,
                  sectionTimetable,
                  doneTopics,
                  totalTopics,
                  curriculumPct,
                  lookup,
                  isDark,
                ),
                const SizedBox(height: 16),

                // Section Detail Tabs Header
                _buildDetailTabsHeader(
                  teacherCount: sectionTeacherIds.length,
                  studentCount: sectionStudents.length,
                  subjectCount: subjects.length,
                  unitCount: curriculum.length,
                  periodCount: sectionTimetable.length,
                  assignmentCount: classAssignments.length,
                  isDark: isDark,
                ),
                const SizedBox(height: 14),

                // Active Tab Content
                if (_activeTab == 'Overview')
                  _buildOverviewTab(
                    context,
                    c,
                    selectedSection,
                    sectionRoom,
                    sectionStudents,
                    sectionTeacherIds,
                    sectionAssignments,
                    subjects,
                    curriculum,
                    sectionTimetable,
                    lookup,
                    isDark,
                    perms,
                  )
                else if (_activeTab == 'Faculty')
                  _buildTeacherAssignmentTab(
                    context,
                    c,
                    selectedSection,
                    sectionAssignments,
                    subjects,
                    lookup,
                    isDark,
                    perms,
                  )
                else if (_activeTab == 'Students')
                  _buildStudentsTab(
                    context,
                    c,
                    selectedSection,
                    sectionStudents,
                    allAdmissions,
                    isDark,
                    perms,
                  )
                else if (_activeTab == 'Subjects')
                  _buildSubjectsTab(
                    context,
                    c,
                    selectedSection,
                    subjects,
                    sectionAssignments,
                    lookup,
                    isDark,
                    perms,
                  )
                else if (_activeTab == 'Curriculum')
                  _buildCurriculumTab(
                    context,
                    c,
                    selectedSection,
                    curriculum,
                    subjects,
                    lookup,
                    isDark,
                    perms,
                  )
                else if (_activeTab == 'Timetable')
                  _buildTimetableTab(
                    context,
                    c,
                    selectedSection,
                    sectionTimetable,
                    isDark,
                    perms,
                  )
                else if (_activeTab == 'Assignments')
                  _buildAssignmentsTab(
                    classAssignmentsAsync,
                    classAssignments,
                    lookup,
                    isDark,
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER
  // ---------------------------------------------------------------------------
  Widget _buildHeader(
    BuildContext context,
    ClassModel c,
    bool isDark,
    ClassesPermissions perms,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 10,
            runSpacing: 4,
            children: [
              if (widget.onBack != null)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text(
                    'Back to Academic Classes',
                    style: TextStyle(fontSize: 12),
                  ),
                  onPressed: widget.onBack,
                ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF109F83,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          c.code.isNotEmpty ? c.code : 'CLS-${c.gradeLevel}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF109F83),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Academic Year ${c.academicYear.isNotEmpty ? c.academicYear : '2026-27'}  ·  Grade ${c.gradeLevel}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color:
                      (c.isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B))
                          .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color:
                        (c.isActive
                                ? const Color(0xFF10B981)
                                : const Color(0xFFF59E0B))
                            .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 3.5,
                      backgroundColor: c.isActive
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      c.status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.isActive
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.onEdit != null && perms.canManageClasses)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF109F83),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text(
                    'Edit Class',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: widget.onEdit,
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. SECTION NAVIGATION BAR
  // ---------------------------------------------------------------------------
  Widget _buildSectionNavigationBar(
    BuildContext context,
    ClassModel c,
    List<SectionModel> sections,
    SectionModel? selectedSection,
    List<StudentAdmissionModel> allAdmissions,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  const Text(
                    'Sections:',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  if (sections.isEmpty)
                    const Text(
                      'No sections created yet.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    )
                  else
                    for (final sec in sections) ...[
                      Builder(
                        builder: (context) {
                          final isSelected = selectedSection?.id == sec.id;
                          final count = allAdmissions.where((a) {
                            return a.student.sectionId == sec.id ||
                                (a.student.sectionId == null &&
                                    a.student.section.trim().toLowerCase() ==
                                        sec.name.trim().toLowerCase() &&
                                    (a.student.currentClassId == c.id ||
                                        a.student.className.contains(
                                          c.gradeLevel.toString(),
                                        )));
                          }).length;

                          return InkWell(
                            onTap: perms.isStudent
                                ? null
                                : () {
                                    setState(() => _selectedSectionId = sec.id);
                                  },
                            borderRadius: BorderRadius.circular(8),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF109F83)
                                    : (isDark
                                          ? const Color(0xFF0F172A)
                                          : const Color(0xFFF1F5F9)),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF109F83)
                                      : (isDark
                                            ? const Color(0xFF334155)
                                            : const Color(0xFFCBD5E1)),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Section ${sec.name}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : (isDark
                                                ? Colors.white70
                                                : const Color(0xFF334155)),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 1.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white.withValues(alpha: 0.25)
                                          : (isDark
                                                ? const Color(0xFF334155)
                                                : const Color(0xFFE2E8F0)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: isSelected
                                            ? Colors.white
                                            : (isDark
                                                  ? Colors.white
                                                  : const Color(0xFF475569)),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                ],
              ),
              if (perms.canManageSections)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF109F83),
                    side: const BorderSide(color: Color(0xFF109F83)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Add Section',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => openSectionModal(
                    context,
                    ref,
                    lookup,
                    presetClassId: c.id,
                  ),
                ),
            ],
          ),
          if (sections.isEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No sections created for ${c.name}. Click "+ Add Section" to add Section A and begin assigning classroom, teachers, students, and timetable.',
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. SUMMARY TILES (6 RECTANGULAR CARDS IN RESPONSIVE GRID)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryTiles(
    BuildContext context,
    ClassModel c,
    SectionModel? selectedSection,
    ClassroomModel? sectionRoom,
    Set<String> sectionTeacherIds,
    List<StudentAdmissionModel> sectionStudents,
    List<SubjectModel> subjects,
    List<CurriculumModel> curriculum,
    List<TimetableEntryModel> sectionTimetable,
    int doneTopics,
    int totalTopics,
    int curriculumPct,
    ClassesLookup lookup,
    bool isDark,
  ) {
    final secStrength = (c.capacity > 0)
        ? (selectedSection != null &&
                  selectedSection.capacity > 0 &&
                  selectedSection.capacity != 40 &&
                  selectedSection.capacity != (sectionRoom?.capacity ?? 40)
              ? selectedSection.capacity
              : c.capacity)
        : ((selectedSection != null && selectedSection.capacity > 0)
              ? selectedSection.capacity
              : 0);

    // 6 Rectangular Cards: Classroom, Teachers, Students, Subjects, Units, Periods
    final cards = <Widget>[
      _buildRectangularSummaryCard(
        label: 'CLASSROOM',
        value:
            sectionRoom?.name ??
            (selectedSection?.classroomId != null &&
                    selectedSection!.classroomId!.isNotEmpty
                ? lookup.roomName(selectedSection.classroomId)
                : 'Not Assigned'),
        subtitle: sectionRoom != null
            ? 'Floor ${sectionRoom.displayFloor} · ${sectionRoom.capacity} Seats · ${sectionRoom.status}'
            : (selectedSection != null
                  ? 'No classroom assigned to Section ${selectedSection.name}'
                  : 'No section selected'),
        icon: Icons.meeting_room_outlined,
        color: const Color(0xFF3B82F6),
        isDark: isDark,
      ),
      _buildRectangularSummaryCard(
        label: 'TEACHERS',
        value: '${sectionTeacherIds.length} Assigned',
        subtitle:
            selectedSection?.classTeacherId != null &&
                selectedSection!.classTeacherId!.isNotEmpty
            ? 'Class Teacher: ${lookup.teacherName(selectedSection.classTeacherId)}'
            : 'Class Teacher: Unassigned',
        icon: Icons.person_outline,
        color: const Color(0xFF8B5CF6),
        isDark: isDark,
      ),
      _buildRectangularSummaryCard(
        label: 'STUDENTS',
        value: '${sectionStudents.length} Enrolled',
        subtitle: secStrength > 0
            ? 'Strength: $secStrength · Enrolled: ${sectionStudents.length}'
            : 'Enrolled: ${sectionStudents.length}',
        icon: Icons.people_outline,
        color: const Color(0xFF109F83),
        isDark: isDark,
      ),
      _buildRectangularSummaryCard(
        label: 'SUBJECTS',
        value: '${subjects.length} Subjects',
        subtitle:
            '${subjects.where((s) => !s.isPractical).length} Theory · ${subjects.where((s) => s.isPractical).length} Practical',
        icon: Icons.menu_book_outlined,
        color: const Color(0xFF06B6D4),
        isDark: isDark,
      ),
      _buildRectangularSummaryCard(
        label: 'UNITS',
        value: '${curriculum.length} Units',
        subtitle: '$doneTopics/$totalTopics Topics Done ($curriculumPct%)',
        icon: Icons.auto_stories_outlined,
        color: const Color(0xFFEC4899),
        isDark: isDark,
      ),
      _buildRectangularSummaryCard(
        label: 'PERIODS',
        value: '${sectionTimetable.length} Weekly Periods',
        subtitle: selectedSection != null
            ? 'Scheduled for Section ${selectedSection.name}'
            : 'No section selected',
        icon: Icons.calendar_month_outlined,
        color: const Color(0xFF14B8A6),
        isDark: isDark,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        int columns = 3;
        if (constraints.maxWidth < 640) {
          columns = 1;
        } else if (constraints.maxWidth < 960) {
          columns = 2;
        }

        final double spacing = 12;
        final double itemWidth =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final card in cards) SizedBox(width: itemWidth, child: card),
          ],
        );
      },
    );
  }

  Widget _buildRectangularSummaryCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. DETAIL TABS HEADER
  // ---------------------------------------------------------------------------
  Widget _buildDetailTabsHeader({
    required int teacherCount,
    required int studentCount,
    required int subjectCount,
    required int unitCount,
    required int periodCount,
    required int assignmentCount,
    required bool isDark,
  }) {
    final tabs = <Map<String, dynamic>>[
      {'name': 'Overview', 'count': null},
      {'name': 'Faculty', 'count': teacherCount},
      {'name': 'Students', 'count': studentCount},
      {'name': 'Subjects', 'count': subjectCount},
      {'name': 'Curriculum', 'count': unitCount},
      {'name': 'Timetable', 'count': periodCount},
      {'name': 'Assignments', 'count': assignmentCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final tab in tabs) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => setState(() => _activeTab = tab['name'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _activeTab == tab['name']
                        ? const Color(0xFF109F83)
                        : (isDark ? const Color(0xFF1E293B) : Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _activeTab == tab['name']
                          ? const Color(0xFF109F83)
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tab['name'] as String,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: _activeTab == tab['name']
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: _activeTab == tab['name']
                              ? Colors.white
                              : (isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155)),
                        ),
                      ),
                      if (tab['count'] != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: _activeTab == tab['name']
                                ? Colors.white.withValues(alpha: 0.25)
                                : (isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFE2E8F0)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${tab['count']}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: _activeTab == tab['name']
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF475569)),
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
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. TAB 1: OVERVIEW
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab(
    BuildContext context,
    ClassModel c,
    SectionModel? selectedSection,
    ClassroomModel? sectionRoom,
    List<StudentAdmissionModel> sectionStudents,
    Set<String> sectionTeacherIds,
    List<ClassTeacherAssignmentModel> sectionAssignments,
    List<SubjectModel> subjects,
    List<CurriculumModel> curriculum,
    List<TimetableEntryModel> sectionTimetable,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    if (selectedSection == null) {
      return _buildEmptySectionBanner(
        'Please select or create a section to view details.',
      );
    }

    final int secCapacity = (c.capacity > 0)
        ? (selectedSection.capacity > 0 &&
                  selectedSection.capacity != 40 &&
                  selectedSection.capacity != (sectionRoom?.capacity ?? 40)
              ? selectedSection.capacity
              : c.capacity)
        : (selectedSection.capacity > 0 ? selectedSection.capacity : 0);
    final double enrollmentRatio = secCapacity > 0
        ? (sectionStudents.length / secCapacity).clamp(0.0, 1.0)
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section Details Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF109F83,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 18,
                          color: Color(0xFF109F83),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Section ${selectedSection.name} Overview',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  if (perms.canManageSections)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      icon: const Icon(Icons.edit, size: 13),
                      label: const Text(
                        'Edit Section',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      onPressed: () => openSectionModal(
                        context,
                        ref,
                        lookup,
                        existing: selectedSection,
                        presetClassId: c.id,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Capacity Progress Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Student Enrollment',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  Text(
                    secCapacity > 0
                        ? '${sectionStudents.length} Enrolled / $secCapacity Strength (${(enrollmentRatio * 100).round()}%)'
                        : '${sectionStudents.length} Enrolled',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: enrollmentRatio,
                  minHeight: 8,
                  backgroundColor: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    enrollmentRatio >= 1.0
                        ? const Color(0xFFEF4444)
                        : (enrollmentRatio > 0.8
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF109F83)),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Key Section Info Grid
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  _buildDetailInfoTile(
                    'Class',
                    c.name,
                    Icons.school_outlined,
                    isDark,
                  ),
                  _buildDetailInfoTile(
                    'Section',
                    'Section ${selectedSection.name}',
                    Icons.groups_outlined,
                    isDark,
                  ),
                  _buildDetailInfoTile(
                    'Section Strength',
                    secCapacity > 0 ? '$secCapacity Students' : '—',
                    Icons.chair_outlined,
                    isDark,
                  ),
                  _buildDetailInfoTile(
                    'Enrolled Students',
                    '${sectionStudents.length} Students',
                    Icons.people_outline,
                    isDark,
                  ),
                  _buildDetailInfoTile(
                    'Assigned Classroom',
                    sectionRoom?.name ??
                        (selectedSection.classroomId != null &&
                                selectedSection.classroomId!.isNotEmpty
                            ? lookup.roomName(selectedSection.classroomId)
                            : 'Not Assigned'),
                    Icons.meeting_room_outlined,
                    isDark,
                  ),
                  _buildDetailInfoTile(
                    'Section Class Teacher',
                    selectedSection.classTeacherId != null &&
                            selectedSection.classTeacherId!.isNotEmpty
                        ? lookup.teacherName(selectedSection.classTeacherId)
                        : 'Unassigned',
                    Icons.person_outline,
                    isDark,
                  ),
                  _buildDetailInfoTile(
                    'Section Status',
                    selectedSection.status,
                    Icons.check_circle_outline,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Quick Split: Classroom Card & Class Teacher Card
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 700;
            return isNarrow
                ? Column(
                    children: [
                      _buildClassroomQuickCard(
                        context,
                        c,
                        selectedSection,
                        sectionRoom,
                        lookup,
                        isDark,
                        perms,
                      ),
                      const SizedBox(height: 12),
                      _buildTeacherQuickCard(
                        context,
                        c,
                        selectedSection,
                        lookup,
                        isDark,
                        perms,
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _buildClassroomQuickCard(
                          context,
                          c,
                          selectedSection,
                          sectionRoom,
                          lookup,
                          isDark,
                          perms,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTeacherQuickCard(
                          context,
                          c,
                          selectedSection,
                          lookup,
                          isDark,
                          perms,
                        ),
                      ),
                    ],
                  );
          },
        ),
        const SizedBox(height: 14),
        _buildCurriculumTab(
          context,
          c,
          selectedSection,
          curriculum,
          subjects,
          lookup,
          isDark,
          perms,
        ),
        const SizedBox(height: 14),
        _buildTimetableTab(
          context,
          c,
          selectedSection,
          sectionTimetable,
          isDark,
          perms,
        ),
      ],
    );
  }

  Widget _buildDetailInfoTile(
    String label,
    String value,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF109F83)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
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

  Widget _buildClassroomQuickCard(
    BuildContext context,
    ClassModel c,
    SectionModel selectedSection,
    ClassroomModel? sectionRoom,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.meeting_room_outlined,
                    size: 16,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Classroom Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (perms.canManageClassrooms && sectionRoom != null)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 15,
                    color: Color(0xFF3B82F6),
                  ),
                  onPressed: () =>
                      openRoomModal(context, ref, existing: sectionRoom),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (sectionRoom == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No classroom assigned to this section yet.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (perms.canManageSections)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.add, size: 13),
                      label: const Text(
                        'Assign Classroom',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: () => openSectionModal(
                        context,
                        ref,
                        lookup,
                        existing: selectedSection,
                        presetClassId: c.id,
                      ),
                    ),
                ],
              ),
            )
          else ...[
            Text(
              sectionRoom.name,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 4),
            Text(
              'Floor: ${sectionRoom.displayFloor}  ·  Capacity: ${sectionRoom.capacity} seats  ·  Type: ${sectionRoom.roomType}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:
                    (sectionRoom.isAvailable
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEF4444))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sectionRoom.isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: sectionRoom.isAvailable
                      ? const Color(0xFF10B981)
                      : const Color(0xFFEF4444),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTeacherQuickCard(
    BuildContext context,
    ClassModel c,
    SectionModel selectedSection,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    final teacher = lookup.teacherById(selectedSection.classTeacherId);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 16,
                    color: Color(0xFF8B5CF6),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Section Class Teacher',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
              if (perms.canManageSections)
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF8B5CF6),
                  ),
                  onPressed: () => _openAssignClassTeacherDialog(
                    context,
                    c,
                    selectedSection,
                    lookup,
                  ),
                  child: Text(
                    teacher == null ? 'Assign' : 'Change',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (teacher == null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F172A)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'No class teacher assigned to this section yet.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          else ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(
                    0xFF8B5CF6,
                  ).withValues(alpha: 0.15),
                  child: Text(
                    teacher.name.isNotEmpty
                        ? teacher.name[0].toUpperCase()
                        : 'T',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacher.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        [
                          teacher.designation,
                          if (teacher.department.isNotEmpty) teacher.department,
                        ].where((s) => s.isNotEmpty).join(' · '),
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (teacher.phone.isNotEmpty || teacher.email.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                [
                  if (teacher.phone.isNotEmpty) '📞 ${teacher.phone}',
                  if (teacher.email.isNotEmpty) '✉️ ${teacher.email}',
                ].join('  ·  '),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. TAB 2: TEACHER ASSIGNMENT (SEPARATE FROM CURRICULUM!)
  // ---------------------------------------------------------------------------
  Widget _buildTeacherAssignmentTab(
    BuildContext context,
    ClassModel c,
    SectionModel? selectedSection,
    List<ClassTeacherAssignmentModel> sectionAssignments,
    List<SubjectModel> subjects,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    if (selectedSection == null) {
      return _buildEmptySectionBanner(
        'Please select or create a section to manage teacher assignments.',
      );
    }

    final classTeacher = lookup.teacherById(selectedSection.classTeacherId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Add Teacher Action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Faculty · Section ${selectedSection.name}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (perms.canAssignTeachers)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF109F83),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 15),
                  label: const Text(
                    'Assign Teacher',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => _openAssignTeacherModal(
                    context,
                    c,
                    selectedSection,
                    subjects,
                    lookup,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Section Class Teacher Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFF8B5CF6), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Section Class Teacher',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8B5CF6),
                        ),
                      ),
                      Text(
                        classTeacher?.name ?? 'Unassigned',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      if (classTeacher != null &&
                          classTeacher.designation.isNotEmpty)
                        Text(
                          classTeacher.designation,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                    ],
                  ),
                ),
                if (perms.canManageSections)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: const BorderSide(color: Color(0xFF8B5CF6)),
                      foregroundColor: const Color(0xFF8B5CF6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                    ),
                    onPressed: () => _openAssignClassTeacherDialog(
                      context,
                      c,
                      selectedSection,
                      lookup,
                    ),
                    child: Text(
                      classTeacher == null ? 'Assign' : 'Change',
                      style: const TextStyle(fontSize: 11),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Subject Teacher Assignments List
          if (sectionAssignments.isEmpty)
            _buildEmptyTabState(
              icon: Icons.person_off_outlined,
              title: 'No Subject Teachers Assigned',
              subtitle:
                  'No faculty has been assigned to Section ${selectedSection.name} yet.',
              actionLabel: perms.canAssignTeachers ? 'Assign Teacher' : null,
              onAction: perms.canAssignTeachers
                  ? () => _openAssignTeacherModal(
                      context,
                      c,
                      selectedSection,
                      subjects,
                      lookup,
                    )
                  : null,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sectionAssignments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final a = sectionAssignments[i];
                final teacher = lookup.teacherById(a.teacherId);
                final subjectName = a.subjectId != null
                    ? lookup.subjectName(a.subjectId)
                    : 'All Subjects';
                final roomName = a.classroomId != null
                    ? lookup.roomName(a.classroomId)
                    : 'Room Unassigned';

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(
                          0xFF8B5CF6,
                        ).withValues(alpha: 0.15),
                        child: Text(
                          teacher != null && teacher.name.isNotEmpty
                              ? teacher.name[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              teacher?.name ?? lookup.teacherName(a.teacherId),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Subject: $subjectName  ·  Room: $roomName'
                              '${teacher?.designation != null && teacher!.designation.isNotEmpty ? '  ·  ${teacher.designation}' : ''}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (perms.canAssignTeachers)
                        IconButton(
                          tooltip: 'Remove Teacher Assignment',
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 17,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmRemoveTeacherAssignment(
                            context,
                            a,
                            teacher?.name ?? lookup.teacherName(a.teacherId),
                            selectedSection.name,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 7. TAB 3: STUDENTS
  // ---------------------------------------------------------------------------
  Widget _buildStudentsTab(
    BuildContext context,
    ClassModel c,
    SectionModel? selectedSection,
    List<StudentAdmissionModel> sectionStudents,
    List<StudentAdmissionModel> allAdmissions,
    bool isDark,
    ClassesPermissions perms,
  ) {
    if (selectedSection == null) {
      return _buildEmptySectionBanner(
        'Please select or create a section to manage students.',
      );
    }

    // Filter students by search query
    final query = _studentSearchQuery.trim().toLowerCase();
    final filtered = query.isEmpty
        ? sectionStudents
        : sectionStudents.where((st) {
            final name = st.user.fullName.toLowerCase();
            final admNo = st.student.admissionNumber.toLowerCase();
            final roll = (st.student.rollNumber ?? '').toLowerCase();
            return name.contains(query) ||
                admNo.contains(query) ||
                roll.contains(query);
          }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header & Add / Assign Actions
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 10,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.people_outline,
                      size: 18,
                      color: Color(0xFF109F83),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Enrolled Students · Section ${selectedSection.name} (${sectionStudents.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (perms.canManageClasses)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF109F83),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      icon: const Icon(Icons.person_add, size: 15),
                      label: const Text(
                        'Assign Student',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onPressed: () => _openAssignStudentModal(
                        context,
                        c,
                        selectedSection,
                        allAdmissions,
                      ),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      icon: const Icon(Icons.app_registration, size: 14),
                      label: const Text(
                        'New Admission',
                        style: TextStyle(fontSize: 11.5),
                      ),
                      onPressed: () =>
                          _openNewAdmissionForm(context, c, selectedSection),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 14),

          // Search Box
          TextField(
            onChanged: (v) => setState(() => _studentSearchQuery = v),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'Search by student name, admission no, roll no...',
              prefixIcon: const Icon(Icons.search, size: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFCBD5E1),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (filtered.isEmpty)
            _buildEmptyTabState(
              icon: Icons.people_outline,
              title: sectionStudents.isEmpty
                  ? 'No Students Enrolled in Section ${selectedSection.name}'
                  : 'No Matching Students Found',
              subtitle: sectionStudents.isEmpty
                  ? 'Assign existing admitted students or enroll a new student into this section.'
                  : 'Try searching with a different name or roll number.',
              actionLabel: (perms.canManageClasses && sectionStudents.isEmpty)
                  ? 'Assign Student'
                  : null,
              onAction: (perms.canManageClasses && sectionStudents.isEmpty)
                  ? () => _openAssignStudentModal(
                      context,
                      c,
                      selectedSection,
                      allAdmissions,
                    )
                  : null,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final st = filtered[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: const Color(
                          0xFF109F83,
                        ).withValues(alpha: 0.15),
                        child: Text(
                          st.user.firstName.isNotEmpty
                              ? st.user.firstName[0].toUpperCase()
                              : 'S',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF109F83),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              st.user.fullName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Adm No: ${st.student.admissionNumber}  ·  Roll No: ${st.student.rollNumber ?? '—'}'
                              '${!perms.isStudent && st.student.emergencyContactPhone.isNotEmpty ? '  ·  📞 ${st.student.emergencyContactPhone}' : ''}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Enrolled',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (perms.canManageClasses) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Remove from Section',
                          icon: const Icon(
                            Icons.person_remove_outlined,
                            size: 17,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmRemoveStudentFromSection(
                            context,
                            st,
                            selectedSection.name,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 8. TAB 4: SUBJECTS
  // ---------------------------------------------------------------------------
  Widget _buildSubjectsTab(
    BuildContext context,
    ClassModel c,
    SectionModel? selectedSection,
    List<SubjectModel> subjects,
    List<ClassTeacherAssignmentModel> sectionAssignments,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      size: 18,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Subjects (${subjects.length})',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              if (perms.canManageSubjects)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF109F83),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Add Subject',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => openSubjectModal(
                    context,
                    ref,
                    lookup,
                    presetClassId: c.id,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (subjects.isEmpty)
            _buildEmptyTabState(
              icon: Icons.menu_book_outlined,
              title: 'No Subjects Configured',
              subtitle: 'No subjects have been assigned to ${c.name} yet.',
              actionLabel: perms.canManageSubjects ? 'Add Subject' : null,
              onAction: perms.canManageSubjects
                  ? () => openSubjectModal(
                      context,
                      ref,
                      lookup,
                      presetClassId: c.id,
                    )
                  : null,
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final s = subjects[i];

                // Subject teacher assigned specifically to this section takes precedence
                final sectionTeacherAssignment = sectionAssignments
                    .where((a) => a.subjectId == s.id)
                    .firstOrNull;
                final teacherName = sectionTeacherAssignment != null
                    ? lookup.teacherName(sectionTeacherAssignment.teacherId)
                    : lookup.teacherName(s.teacherId);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF109F83,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.code.isNotEmpty ? s.code : 'SUB',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF109F83),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Teacher: $teacherName  ·  Max Marks: ${s.maxMarks}  ·  Pass: ${s.passMarks}',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (s.isPractical
                                      ? const Color(0xFF8B5CF6)
                                      : const Color(0xFF3B82F6))
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.type,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: s.isPractical
                                ? const Color(0xFF8B5CF6)
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                      if (perms.canManageSubjects) ...[
                        const SizedBox(width: 6),
                        IconButton(
                          tooltip: 'Edit Subject',
                          icon: const Icon(
                            Icons.edit_outlined,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                          onPressed: () => openSubjectModal(
                            context,
                            ref,
                            lookup,
                            existing: s,
                            presetClassId: c.id,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 9. TAB 5: CURRICULUM
  // ---------------------------------------------------------------------------
  Widget _buildCurriculumTab(
    BuildContext context,
    ClassModel c,
    SectionModel? selectedSection,
    List<CurriculumModel> curriculum,
    List<SubjectModel> subjects,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    final bySubject = <String, List<CurriculumModel>>{};
    for (final cur in curriculum) {
      bySubject.putIfAbsent(cur.subjectId, () => []).add(cur);
    }
    final orderedIds = <String>[
      for (final s in subjects)
        if (bySubject.containsKey(s.id)) s.id,
      for (final id in bySubject.keys)
        if (!subjects.any((s) => s.id == id)) id,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_stories_outlined,
                      size: 18,
                      color: Color(0xFFEC4899),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Curriculum & Syllabus',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEC4899).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${curriculum.length} Units',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFEC4899),
                      ),
                    ),
                  ),
                ],
              ),
              if (perms.canManageCurriculum)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF109F83),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 14),
                  label: const Text(
                    'Add Curriculum',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  onPressed: () => openCurriculumModal(
                    context,
                    ref,
                    lookup,
                    presetClassId: c.id,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),

          if (orderedIds.isEmpty)
            _buildEmptyTabState(
              icon: Icons.auto_stories_outlined,
              title: 'No Curriculum Added',
              subtitle:
                  'No curriculum units or syllabus topics have been added yet.',
              actionLabel: perms.canManageCurriculum ? 'Add Curriculum' : null,
              onAction: perms.canManageCurriculum
                  ? () => openCurriculumModal(
                      context,
                      ref,
                      lookup,
                      presetClassId: c.id,
                    )
                  : null,
            )
          else
            for (final subjectId in orderedIds)
              _buildSubjectCurriculumBlock(
                context,
                c,
                subjectId,
                bySubject[subjectId]!,
                lookup,
                isDark,
                perms,
              ),
        ],
      ),
    );
  }

  Widget _buildSubjectCurriculumBlock(
    BuildContext context,
    ClassModel c,
    String subjectId,
    List<CurriculumModel> chapters,
    ClassesLookup lookup,
    bool isDark,
    ClassesPermissions perms,
  ) {
    final total = chapters.fold<int>(0, (sum, ch) => sum + ch.topics.length);
    final done = chapters.fold<int>(0, (sum, ch) => sum + ch.completedTopics);
    final progress = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);
    final expanded = _expandedSubjects.contains(subjectId);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => setState(() {
              if (!_expandedSubjects.remove(subjectId)) {
                _expandedSubjects.add(subjectId);
              }
            }),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    height: 36,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 3.5,
                            backgroundColor: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progress >= 1.0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF109F83),
                            ),
                          ),
                        ),
                        Text(
                          '${(progress * 100).round()}%',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lookup.subjectName(subjectId),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${chapters.length} chapters · $done/$total topics completed',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(48, 0, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final ch in chapters)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          InkWell(
                            onTap:
                                perms.canUpdateCurriculumProgress &&
                                    ch.topics.isNotEmpty
                                ? () => ref
                                      .read(
                                        curriculumControllerProvider.notifier,
                                      )
                                      .updateProgress(
                                        ch.id,
                                        ch.completedTopics >= ch.topics.length
                                            ? 0
                                            : ch.topics.length,
                                      )
                                : null,
                            child: Icon(
                              ch.topics.isNotEmpty &&
                                      ch.completedTopics >= ch.topics.length
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color:
                                  ch.topics.isNotEmpty &&
                                      ch.completedTopics >= ch.topics.length
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              ch.title,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            ch.topics.isNotEmpty &&
                                    ch.completedTopics >= ch.topics.length
                                ? 'Completed'
                                : '${ch.completedTopics}/${ch.topics.length} done',
                            style: TextStyle(
                              fontSize: 11,
                              color:
                                  ch.topics.isNotEmpty &&
                                      ch.completedTopics >= ch.topics.length
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                          if (perms.canManageCurriculum) ...[
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => openCurriculumModal(
                                context,
                                ref,
                                lookup,
                                existing: ch,
                                presetClassId: c.id,
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 10. TAB 6: TIMETABLE
  // ---------------------------------------------------------------------------
  Widget _buildTimetableTab(
    BuildContext context,
    ClassModel c,
    SectionModel? selectedSection,
    List<TimetableEntryModel> sectionTimetable,
    bool isDark,
    ClassesPermissions perms,
  ) {
    if (selectedSection == null) {
      return _buildEmptySectionBanner(
        'Please select or create a section to view its timetable.',
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.calendar_month,
                  size: 18,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Class Timetable',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Section ${selectedSection.name} · ${sectionTimetable.length} Periods',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Embeds the existing Timetable screen, strictly locked to this class and section
          TimetableManagementScreen(
            key: ValueKey('tt-${c.id}-${selectedSection.id}'),
            initialClassId: c.id,
            initialSectionId: selectedSection.id,
            lockSection: true,
            embedded: false,
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentsTab(
    AsyncValue<List<TeacherWorkModel>> assignmentsAsync,
    List<TeacherWorkModel> assignments,
    ClassesLookup lookup,
    bool isDark,
  ) {
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: assignmentsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Error loading assignments: $error',
            style: const TextStyle(color: Colors.red),
          ),
        ),
        data: (_) {
          if (assignments.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text(
                  'No assignments recorded for this class.',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final sorted = [...assignments]
            ..sort((a, b) {
              final comparison = switch (_assignmentSortColumn) {
                'Assignment' => a.title.toLowerCase().compareTo(
                  b.title.toLowerCase(),
                ),
                'Subject' =>
                  lookup
                      .subjectName(a.subjectId)
                      .toLowerCase()
                      .compareTo(lookup.subjectName(b.subjectId).toLowerCase()),
                'Assigned Teacher' =>
                  lookup
                      .teacherName(a.teacherId)
                      .toLowerCase()
                      .compareTo(lookup.teacherName(b.teacherId).toLowerCase()),
                'Status' => a.status.toLowerCase().compareTo(
                  b.status.toLowerCase(),
                ),
                _ => a.dueDate.compareTo(b.dueDate),
              };
              return _assignmentSortAscending ? comparison : -comparison;
            });
          final sortColumnIndex = switch (_assignmentSortColumn) {
            'Assignment' => 0,
            'Subject' => 1,
            'Assigned Teacher' => 2,
            'Status' => 4,
            _ => 3,
          };

          void sortBy(String column) {
            setState(() {
              if (_assignmentSortColumn == column) {
                _assignmentSortAscending = !_assignmentSortAscending;
              } else {
                _assignmentSortColumn = column;
                _assignmentSortAscending = true;
              }
            });
          }

          DataColumn sortableColumn(String label) => DataColumn(
            onSort: (_, _) => sortBy(label),
            label: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assignments (${assignments.length})',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: borderColor),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 760),
                      child: DataTable(
                        sortColumnIndex: sortColumnIndex,
                        sortAscending: _assignmentSortAscending,
                        horizontalMargin: 12,
                        columnSpacing: 20,
                        headingRowHeight: 40,
                        dataRowMinHeight: 44,
                        dataRowMaxHeight: 56,
                        headingRowColor: WidgetStateProperty.all(
                          isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF8FAFC),
                        ),
                        columns: [
                          sortableColumn('Assignment'),
                          sortableColumn('Subject'),
                          sortableColumn('Assigned Teacher'),
                          sortableColumn('Due Date'),
                          sortableColumn('Status'),
                        ],
                        rows: sorted.map((work) {
                          final dueDate =
                              '${work.dueDate.year}-${work.dueDate.month.toString().padLeft(2, '0')}-${work.dueDate.day.toString().padLeft(2, '0')}';
                          final isComplete =
                              work.status == 'Reviewed' ||
                              work.status == 'Submitted';
                          final statusColor = isComplete
                              ? const Color(0xFF10B981)
                              : const Color(0xFFF59E0B);
                          return DataRow(
                            cells: [
                              DataCell(
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 220,
                                  ),
                                  child: Text(
                                    work.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  lookup.subjectName(work.subjectId),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Text(
                                  lookup.teacherName(work.teacherId),
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Text(
                                  dueDate,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                              DataCell(
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    work.status,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 11. MODALS & ASSIGNMENT FLOWS
  // ---------------------------------------------------------------------------

  /// Assign existing teacher to this section (validates against duplicates)
  Future<void> _openAssignTeacherModal(
    BuildContext context,
    ClassModel c,
    SectionModel selectedSection,
    List<SubjectModel> subjects,
    ClassesLookup lookup,
  ) async {
    String? teacherId;
    String? subjectId;
    String? roomId = selectedSection.classroomId ?? c.classroomId;
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final teacher = lookup.teacherById(teacherId);

          return AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.person_add_alt_1,
                  color: Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assign Teacher · Section ${selectedSection.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (formError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.red.shade300),
                        ),
                        child: Text(
                          formError!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.red,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // 1. Subject Dropdown
                    const Text(
                      'Subject *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Subject',
                      inlineLabel: false,
                      value: subjectId,
                      noneLabel: 'None (Select a Subject)',
                      options: {for (final s in subjects) s.id: s.name},
                      onChanged: (v) {
                        setDialogState(() {
                          subjectId = v;
                          formError = null;
                          if (teacherId != null && v != null) {
                            final subj = subjects
                                .where((s) => s.id == v)
                                .firstOrNull;
                            final qualified = lookup
                                .qualifiedTeachersForSubject(subj?.name);
                            if (!qualified.any((t) => t.id == teacherId)) {
                              teacherId = null;
                            }
                          } else if (v == null) {
                            teacherId = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Teacher Dropdown (dynamically filtered by selected subject)
                    const Text(
                      'Teacher (from Staff Directory) *',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (ctx) {
                        final selectedSubj = subjects
                            .where((s) => s.id == subjectId)
                            .firstOrNull;
                        final qualifiedTeachers = selectedSubj != null
                            ? lookup.qualifiedTeachersForSubject(
                                selectedSubj.name,
                              )
                            : lookup.teachers;

                        if (selectedSubj != null && qualifiedTeachers.isEmpty) {
                          return Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade400),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No teachers available for this subject.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }

                        return SearchableIdDropdown(
                          label: 'Teacher Name',
                          inlineLabel: false,
                          allowNone: false,
                          value: qualifiedTeachers.any((t) => t.id == teacherId)
                              ? teacherId
                              : null,
                          hint: selectedSubj != null
                              ? 'Select qualified teacher...'
                              : 'Select faculty member...',
                          options: {
                            for (final t in qualifiedTeachers) t.id: t.name,
                          },
                          onChanged: (v) => setDialogState(() {
                            teacherId = v;
                            formError = null;
                          }),
                        );
                      },
                    ),
                    if (teacher != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF8B5CF6,
                          ).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          [
                            teacher.designation,
                            if (teacher.department.isNotEmpty)
                              'Dept: ${teacher.department}',
                            if (teacher.specialization.isNotEmpty)
                              'Specialization: ${teacher.specialization}',
                            if (teacher.phone.isNotEmpty)
                              'Phone: ${teacher.phone}',
                            if (teacher.email.isNotEmpty) teacher.email,
                          ].where((e) => e.isNotEmpty).join('\n'),
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    const Text(
                      'Room Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Room Number',
                      inlineLabel: false,
                      value: roomId,
                      noneLabel: 'None (Section Room)',
                      options: {
                        for (final r in lookup.classrooms) r.id: r.name,
                      },
                      disabled: {
                        for (final r in lookup.classrooms)
                          if (!r.isAvailable) r.id: 'Unavailable',
                      },
                      onChanged: (v) => setDialogState(() => roomId = v),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                ),
                onPressed: () async {
                  if (teacherId == null || teacherId!.isEmpty) {
                    setDialogState(
                      () => formError = 'Please select a teacher.',
                    );
                    return;
                  }

                  // Check for duplicate assignment in this section
                  final currentAssignments =
                      ref
                          .read(teacherAssignmentsControllerProvider)
                          .valueOrNull ??
                      [];
                  final isDuplicate = currentAssignments.any(
                    (a) =>
                        a.classId == c.id &&
                        a.sectionId == selectedSection.id &&
                        a.teacherId == teacherId &&
                        a.subjectId == subjectId,
                  );

                  if (isDuplicate) {
                    setDialogState(
                      () => formError =
                          'This teacher is already assigned to this section for this subject.',
                    );
                    return;
                  }

                  try {
                    await ref
                        .read(teacherAssignmentsControllerProvider.notifier)
                        .add(
                          ClassTeacherAssignmentModel(
                            id: '',
                            classId: c.id,
                            sectionId: selectedSection.id,
                            subjectId: subjectId,
                            teacherId: teacherId!,
                            classroomId: roomId,
                          ),
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      showCompactSnackBar(
                        context,
                        'Teacher assigned to Section ${selectedSection.name}',
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      formError = e
                          .toString()
                          .replaceAll('Exception:', '')
                          .trim();
                    });
                  }
                },
                child: const Text('Assign'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Assign or change Section Class Teacher
  Future<void> _openAssignClassTeacherDialog(
    BuildContext context,
    ClassModel c,
    SectionModel selectedSection,
    ClassesLookup lookup,
  ) async {
    String? teacherId = selectedSection.classTeacherId;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.star, color: Color(0xFF8B5CF6), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Set Section Class Teacher · Section ${selectedSection.name}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 380,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Class Teacher:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  SearchableIdDropdown(
                    label: 'Class Teacher',
                    inlineLabel: false,
                    value: teacherId,
                    noneLabel: 'None (Unassigned)',
                    options: {for (final t in lookup.teachers) t.id: t.name},
                    onChanged: (v) => setDialogState(() => teacherId = v),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                ),
                onPressed: () async {
                  try {
                    final updated = selectedSection.copyWith(
                      classTeacherId: teacherId,
                      clearClassTeacher:
                          teacherId == null || teacherId!.isEmpty,
                    );
                    await ref
                        .read(sectionsControllerProvider.notifier)
                        .save(updated);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      showCompactSnackBar(
                        context,
                        'Section class teacher updated',
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      showCompactSnackBar(
                        context,
                        'Error updating class teacher: $e',
                        backgroundColor: Colors.red,
                        icon: Icons.error_outline,
                      );
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Remove teacher assignment with confirmation
  Future<void> _confirmRemoveTeacherAssignment(
    BuildContext context,
    ClassTeacherAssignmentModel assignment,
    String teacherName,
    String sectionName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Teacher Assignment'),
        content: Text(
          'Remove $teacherName from Section $sectionName?\n\nThe staff member\'s record in the Staff Directory will remain unchanged.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref
            .read(teacherAssignmentsControllerProvider.notifier)
            .remove(assignment.id);
        if (context.mounted) {
          showCompactSnackBar(
            context,
            'Teacher removed from Section $sectionName',
          );
        }
      } catch (e) {
        if (context.mounted) {
          showCompactSnackBar(
            context,
            'Error removing teacher: $e',
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
          );
        }
      }
    }
  }

  /// Assign existing admitted student to this section
  Future<void> _openAssignStudentModal(
    BuildContext context,
    ClassModel c,
    SectionModel selectedSection,
    List<StudentAdmissionModel> allAdmissions,
  ) async {
    // Filter available students (those not already in this section)
    final availableStudents = allAdmissions.where((a) {
      return a.student.sectionId != selectedSection.id;
    }).toList();

    String? selectedStudentId;
    String filterQuery = '';
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final q = filterQuery.trim().toLowerCase();
          final matchingStudents = q.isEmpty
              ? availableStudents
              : availableStudents.where((a) {
                  return a.user.fullName.toLowerCase().contains(q) ||
                      a.student.admissionNumber.toLowerCase().contains(q);
                }).toList();

          return AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.person_add,
                  color: Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assign Student · Section ${selectedSection.name}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            content: SizedBox(
              width: 440,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.red.shade300),
                      ),
                      child: Text(
                        formError!,
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    onChanged: (v) => setDialogState(() => filterQuery = v),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Search available students...',
                      prefixIcon: const Icon(Icons.search, size: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Select Student:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: matchingStudents.isEmpty
                        ? const Center(
                            child: Text(
                              'No available students found',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: matchingStudents.length,
                            separatorBuilder: (_, _) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final st = matchingStudents[i];
                              final isSelected =
                                  selectedStudentId == st.student.id;

                              return ListTile(
                                dense: true,
                                selected: isSelected,
                                selectedTileColor: const Color(
                                  0xFF109F83,
                                ).withValues(alpha: 0.1),
                                title: Text(
                                  st.user.fullName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  'Adm No: ${st.student.admissionNumber}  ·  Current: ${st.student.className.isNotEmpty ? st.student.className : 'Unassigned'} ${st.student.section}',
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onTap: () => setDialogState(
                                  () => selectedStudentId = st.student.id,
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                ),
                onPressed: () async {
                  if (selectedStudentId == null) {
                    setDialogState(
                      () => formError = 'Please select a student to assign.',
                    );
                    return;
                  }

                  final targetAdmission = availableStudents
                      .where((a) => a.student.id == selectedStudentId)
                      .firstOrNull;
                  if (targetAdmission == null) return;

                  try {
                    final updatedAdmission = targetAdmission.copyWith(
                      student: targetAdmission.student.copyWith(
                        currentClassId: c.id,
                        className: c.name,
                        sectionId: selectedSection.id,
                        section: selectedSection.name,
                      ),
                    );

                    await ref
                        .read(admissionsListProvider.notifier)
                        .saveAdmission(updatedAdmission);

                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      showCompactSnackBar(
                        context,
                        '${targetAdmission.user.fullName} assigned to Section ${selectedSection.name}',
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      formError = e
                          .toString()
                          .replaceAll('Exception:', '')
                          .trim();
                    });
                  }
                },
                child: const Text('Assign to Section'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Remove student from section with confirmation (preserves admission record)
  Future<void> _confirmRemoveStudentFromSection(
    BuildContext context,
    StudentAdmissionModel admission,
    String sectionName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Student from Section'),
        content: Text(
          'Remove ${admission.user.fullName} from Section $sectionName?\n\nThe student\'s admission and profile record will remain completely intact.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove from Section'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final updatedAdmission = admission.copyWith(
          student: admission.student.copyWith(sectionId: '', section: ''),
        );

        await ref
            .read(admissionsListProvider.notifier)
            .saveAdmission(updatedAdmission);

        if (context.mounted) {
          showCompactSnackBar(
            context,
            '${admission.user.fullName} removed from Section $sectionName',
          );
        }
      } catch (e) {
        if (context.mounted) {
          showCompactSnackBar(
            context,
            'Error removing student: $e',
            backgroundColor: Colors.red,
            icon: Icons.error_outline,
          );
        }
      }
    }
  }

  /// Navigate to new admission form
  Future<void> _openNewAdmissionForm(
    BuildContext context,
    ClassModel classModel,
    SectionModel selectedSection,
  ) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (routeContext) => AddStudentFormScreen(
          initialClassId: classModel.id,
          initialSectionId: selectedSection.id,
          onCancel: () => Navigator.of(routeContext).pop(),
          onSubmitted: (_) => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 12. HELPER BANNER / EMPTY STATES
  // ---------------------------------------------------------------------------
  Widget _buildEmptySectionBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(
          message,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEmptyTabState({
    required IconData icon,
    required String title,
    required String subtitle,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 36, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7),
                  ),
                ),
                icon: const Icon(Icons.add, size: 14),
                label: Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
