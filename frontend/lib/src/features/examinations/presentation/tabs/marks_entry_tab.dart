import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../data/exam_flow_repository.dart';
import '../../domain/examination_actor.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_timetable_model.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import 'flow_ui.dart';

/// Screen 5: Marks Entry
/// Cascading Flow: Exam -> Class -> Section -> Subject -> Students loaded automatically.
/// Local form-state buffering, validation, absent handling, and unsaved changes guard.
class MarksEntryTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const MarksEntryTab({super.key, required this.exam});

  @override
  ConsumerState<MarksEntryTab> createState() => _MarksEntryTabState();
}

class _MarksEntryTabState extends ConsumerState<MarksEntryTab> {
  String? _classId;
  String? _sectionId;
  String? _subjectId;

  // Local draft buffering: studentId -> text value
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _localValues = {};
  bool _isDirty = false;
  bool _saving = false;
  String? _activePaperId;

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
    _localValues.clear();
    _isDirty = false;
  }

  Future<bool> _confirmDiscardChanges() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Unsaved Changes'),
        content: const Text(
          'You have unsaved marks entries. Are you sure you want to discard them and switch?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Keep Editing'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard == true;
  }

  void _syncControllersWithMarks(
    List<StudentRef> students,
    List<StudentMark> marks,
    Set<String> absentIds,
  ) {
    for (final s in students) {
      final isAbsent = absentIds.contains(s.id);
      final mark = marks.where((m) => m.studentId == s.id).firstOrNull;

      String initialText = '';
      if (!isAbsent && mark?.marksObtained != null) {
        final val = mark!.marksObtained!;
        initialText = val % 1 == 0 ? val.toInt().toString() : val.toString();
      }

      if (!_localValues.containsKey(s.id)) {
        _localValues[s.id] = initialText;
      }

      if (!_controllers.containsKey(s.id)) {
        final ctrl = TextEditingController(text: _localValues[s.id] ?? initialText);
        ctrl.addListener(() {
          if (_localValues[s.id] != ctrl.text) {
            _localValues[s.id] = ctrl.text;
            if (!_isDirty) {
              setState(() => _isDirty = true);
            }
          }
        });
        _controllers[s.id] = ctrl;
      }
    }
  }

  Future<void> _handleSave(
    ExamTimetableEntry paper,
    List<StudentRef> students,
    Set<String> absentIds,
    bool submit,
  ) async {
    final values = <String, double?>{};
    final missingStudents = <String>[];

    for (final s in students) {
      if (absentIds.contains(s.id)) {
        values[s.id] = null;
        continue;
      }

      final text = _localValues[s.id]?.trim() ?? '';
      if (text.isEmpty) {
        values[s.id] = null;
        if (submit) {
          missingStudents.add('${s.rollNumber.isNotEmpty ? "${s.rollNumber}. " : ""}${s.name}');
        }
      } else {
        final numVal = double.tryParse(text);
        if (numVal == null) {
          flowSnack(context, 'Marks for ${s.name} must be a valid number.', error: true);
          return;
        }
        if (numVal < 0) {
          flowSnack(context, 'Marks cannot be negative.', error: true);
          return;
        }
        if (numVal > paper.maxMarks) {
          flowSnack(
            context,
            'Marks for ${s.name} cannot exceed max marks of ${paper.maxMarks.toStringAsFixed(0)}.',
            error: true,
          );
          return;
        }
        values[s.id] = numVal;
      }
    }

    if (submit && missingStudents.isNotEmpty) {
      final preview = missingStudents.take(3).join(', ');
      final rest = missingStudents.length > 3 ? ' and ${missingStudents.length - 3} more' : '';
      flowSnack(
        context,
        'Cannot submit: Enter marks for all present students ($preview$rest).',
        error: true,
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await ref.read(examFlowActionsProvider).saveMarks(
            widget.exam.examScheduleId,
            paper,
            values,
            submit,
          );
      setState(() => _isDirty = false);
      if (mounted) {
        flowSnack(
          context,
          submit ? 'Marks submitted for review.' : 'Marks draft saved.',
        );
      }
    } catch (e) {
      if (mounted) {
        flowSnack(context, flowError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final r = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetableAsync = ref.watch(examTimetableProvider(widget.exam.examScheduleId));
    final studentsAsync = ref.watch(studentsProvider);
    final myTeacher = ExamFlowRepository.teacherIdFor(actor);

    return timetableAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Center(child: Text('Error loading timetable: $e')),
      data: (timetable) {
        // Teacher filter: only see timetable entries for subjects/classes they teach
        final visibleTimetable = (myTeacher == null || perms.isAdminOrPrincipal)
            ? timetable
            : timetable.where((p) => r.defaultTeacherFor(p.classSectionId, p.subjectId) == myTeacher).toList();

        // Distinct available classes
        final classIdsWithEntries = visibleTimetable.map((p) => p.classId ?? r.classIdForSection(p.classSectionId)).whereType<String>().toSet();
        final availableClasses = r.classes.where((c) => classIdsWithEntries.contains(c.id)).toList();

        // Sections filtered by selected class
        final sectionsWithEntries = visibleTimetable
            .where((p) => _classId == null || (p.classId ?? r.classIdForSection(p.classSectionId)) == _classId)
            .map((p) => p.classSectionId)
            .whereType<String>()
            .toSet();
        final availableSections = r.sections.where((s) => sectionsWithEntries.contains(s.id)).toList();

        // Subjects filtered by selected class and section
        final availableSubjects = visibleTimetable
            .where((p) =>
                (_classId == null || (p.classId ?? r.classIdForSection(p.classSectionId)) == _classId) &&
                (_sectionId == null || p.classSectionId == _sectionId))
            .map((p) => p.subjectId)
            .whereType<String>()
            .toSet();

        // Find the matched timetable entry
        final currentPaper = visibleTimetable.where((p) {
          final matchesClass = _classId == null || (p.classId ?? r.classIdForSection(p.classSectionId)) == _classId;
          final matchesSection = _sectionId == null || p.classSectionId == _sectionId;
          final matchesSubject = _subjectId == null || p.subjectId == _subjectId;
          return matchesClass && matchesSection && matchesSubject;
        }).firstOrNull;

        if (currentPaper?.id != _activePaperId) {
          _activePaperId = currentPaper?.id;
          _disposeControllers();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.edit_note, color: kExamGreen, size: 24),
                const SizedBox(width: 8),
                const Text(
                  'Marks Entry Portal',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                if (_isDirty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.amber.shade700),
                    ),
                    child: Text(
                      'Unsaved Changes',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Cascading Dropdowns: Exam -> Class -> Section -> Subject
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. Class
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: availableClasses.any((c) => c.id == _classId) ? _classId : null,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Class'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select Class')),
                      for (final c in availableClasses)
                        DropdownMenuItem(value: c.id, child: Text(c.label)),
                    ],
                    onChanged: (v) async {
                      if (v != _classId && await _confirmDiscardChanges()) {
                        setState(() {
                          _classId = v;
                          _sectionId = null;
                          _subjectId = null;
                          _disposeControllers();
                        });
                      }
                    },
                  ),
                ),

                // 2. Section
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    value: availableSections.any((s) => s.id == _sectionId) ? _sectionId : null,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Section'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select Section')),
                      for (final s in availableSections)
                        DropdownMenuItem(value: s.id, child: Text(s.label)),
                    ],
                    onChanged: (v) async {
                      if (v != _sectionId && await _confirmDiscardChanges()) {
                        setState(() {
                          _sectionId = v;
                          _subjectId = null;
                          _disposeControllers();
                        });
                      }
                    },
                  ),
                ),

                // 3. Subject
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    value: availableSubjects.contains(_subjectId) ? _subjectId : null,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Subject'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Select Subject')),
                      for (final sid in availableSubjects)
                        DropdownMenuItem(value: sid, child: Text(r.subjectName(sid))),
                    ],
                    onChanged: (v) async {
                      if (v != _subjectId && await _confirmDiscardChanges()) {
                        setState(() {
                          _subjectId = v;
                          _disposeControllers();
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Content Area
            if (currentPaper == null)
              FlowEmpty(
                Icons.assignment_outlined,
                visibleTimetable.isEmpty
                    ? (perms.isTeacher
                        ? 'No exam timetable entries are assigned to your profile.'
                        : 'No timetable entries scheduled for this examination.')
                    : 'Select Class, Section, and Subject above to enter marks.',
              )
            else
              _buildPaperRoster(currentPaper, r, studentsAsync),
          ],
        );
      },
    );
  }

  Widget _buildPaperRoster(
    ExamTimetableEntry paper,
    ExamReferenceData refData,
    AsyncValue<List<StudentRef>> studentsAsync,
  ) {
    final perms = ref.watch(examinationPermissionsProvider);
    final marksAsync = ref.watch(marksProvider(paper.id));
    final attAsync = ref.watch(attendanceProvider(paper.id));

    return studentsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => Text('Error loading students: $e'),
      data: (allStudents) {
        final students = allStudents.where((s) => s.sectionId == paper.classSectionId).toList();
        if (students.isEmpty) {
          return const FlowEmpty(Icons.people_outline, 'No students enrolled in this class section.');
        }

        return marksAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
          error: (e, _) => Text('Error loading marks: $e'),
          data: (marks) {
            final attList = attAsync.valueOrNull ?? [];
            final absentIds = attList.where((a) => a.status == 'ABSENT').map((a) => a.studentId).toSet();

            // Populate text controllers
            _syncControllersWithMarks(students, marks, absentIds);

            // Determine status of overall marks submission
            final isTeacher = perms.canEnterMarks;
            final hasSubmitted = marks.any((m) => m.status == 'SUBMITTED' || m.status == 'UNDER_REVIEW');
            final hasApproved = marks.any((m) => m.status == 'APPROVED');
            final rejectedMark = marks.where((m) => m.status == 'REJECTED').firstOrNull;
            final isLocked = (hasSubmitted || hasApproved) && rejectedMark == null;
            final canEditMarks = isTeacher && !isLocked;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info & Status Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E293B)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : const Color(0xFFCBD5E1),
                    ),
                  ),
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.school, size: 18, color: kExamGreen),
                          const SizedBox(width: 6),
                          Text(
                            '${refData.subjectName(paper.subjectId)}  •  ${refData.sectionName(paper.classSectionId)}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        'Max: ${paper.maxMarks.toStringAsFixed(0)}   |   Pass: ${paper.passingMarks.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                      if (hasApproved)
                        const FlowChip('APPROVED', Color(0xFF059669))
                      else if (hasSubmitted)
                        const FlowChip('SUBMITTED (READ-ONLY)', Color(0xFF2563EB))
                      else if (rejectedMark != null)
                        const FlowChip('REJECTED (EDITABLE)', Color(0xFFDC2626))
                      else
                        const FlowChip('DRAFT (EDITABLE)', Color(0xFFD97706)),
                    ],
                  ),
                ),

                // Admin Informational Banner
                if (perms.isAdminOrPrincipal) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Color(0xFF2563EB), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin View: Marks are entered by assigned faculty teachers. As an Admin, you view marks here and verify / approve submissions in the Marks Review tab.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Rejection Alert Banner
                if (rejectedMark != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Marks Submission Returned for Correction',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Reason: ${rejectedMark.rejectionReason ?? "Please re-evaluate and correct entries."}',
                                style: TextStyle(color: Colors.red.shade900, fontSize: 12.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // Table of Students & Marks
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF334155)
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: students.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = students[index];
                      final isAbsent = absentIds.contains(s.id);
                      final ctrl = _controllers[s.id];

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 36,
                              child: Text(
                                s.rollNumber.isNotEmpty ? s.rollNumber : '${index + 1}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                                  Text(
                                    'Adm: ${s.admissionNumber}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      color: Theme.of(context).brightness == Brightness.dark
                                          ? Colors.white60
                                          : Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isAbsent) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'Absent (Attendance)',
                                  style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 80),
                            ] else ...[
                              SizedBox(
                                width: 110,
                                child: TextFormField(
                                  controller: ctrl,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  enabled: canEditMarks && !_saving,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    hintText: '/ ${paper.maxMarks.toStringAsFixed(0)}',
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                    border: const OutlineInputBorder(),
                                    enabledBorder: OutlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white30
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Bottom Sticky/Actions Bar (Teachers only)
                if (isTeacher && !isLocked)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save Draft'),
                        onPressed: _saving
                            ? null
                            : () => _handleSave(paper, students, absentIds, false),
                      ),
                      const SizedBox(width: 12),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kExamGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: const Text('Submit for Verification'),
                        onPressed: _saving
                            ? null
                            : () => _handleSave(paper, students, absentIds, true),
                      ),
                    ],
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
