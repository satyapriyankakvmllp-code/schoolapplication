import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Teacher Marks Entry Screen
/// Allows teachers to input student marks, save drafts, and submit for admin approval.
class TeacherExamMarksEntryScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const TeacherExamMarksEntryScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<TeacherExamMarksEntryScreen> createState() => _TeacherExamMarksEntryScreenState();
}

class _TeacherExamMarksEntryScreenState extends ConsumerState<TeacherExamMarksEntryScreen> {
  String? _selectedExamScheduleId;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  final Map<String, TextEditingController> _marksControllers = {};
  final Map<String, TextEditingController> _remarksControllers = {};
  final Map<String, bool> _absentMap = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
  }

  @override
  void dispose() {
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    for (final c in _remarksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _syncControllers(List<StudentMarkEntry> entries) {
    for (final e in entries) {
      if (!_marksControllers.containsKey(e.studentId)) {
        _marksControllers[e.studentId] = TextEditingController(
          text: e.marksObtained.toStringAsFixed(0),
        );
        _remarksControllers[e.studentId] = TextEditingController(text: e.remarks ?? '');
        _absentMap[e.studentId] = e.isAbsent;
      }
    }
  }

  Future<void> _saveMarks({required bool submit}) async {
    if (_selectedExamScheduleId == null || _selectedSubjectId == null || _selectedSectionId == null) {
      flowSnack(context, 'Please select Class, Section, and Subject first.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final actions = ref.read(examFlowActionsProvider);
      final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
      final sub = refData.subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
      final maxMarks = sub?.maxMarks ?? 100.0;
      final passMarks = sub?.passMarks ?? 35.0;

      final updatedEntries = <StudentMarkEntry>[];
      for (final entry in _marksControllers.entries) {
        final studentId = entry.key;
        final isAbsent = _absentMap[studentId] ?? false;
        final rawVal = double.tryParse(entry.value.text.trim()) ?? 0.0;
        final marks = isAbsent ? 0.0 : rawVal.clamp(0.0, maxMarks);

        updatedEntries.add(
          StudentMarkEntry(
            studentId: studentId,
            marksObtained: marks,
            isAbsent: isAbsent,
            remarks: _remarksControllers[studentId]?.text.trim(),
          ),
        );
      }

      final sheet = MarksEntrySheet(
        id: 'marks-${_selectedExamScheduleId}-${_selectedSubjectId}-${_selectedSectionId}',
        examScheduleId: _selectedExamScheduleId!,
        subjectId: _selectedSubjectId!,
        classSectionId: _selectedSectionId!,
        maxMarks: maxMarks,
        passingMarks: passMarks,
        status: submit ? 'SUBMITTED' : 'DRAFT',
        teacherId: 'TCH-CURRENT',
        entries: updatedEntries,
      );

      await actions.saveMarks(sheet);
      if (mounted) {
        flowSnack(
          context,
          submit ? 'Marks submitted for admin approval.' : 'Draft marks saved successfully.',
        );
      }
    } catch (e) {
      if (mounted) flowSnack(context, flowError(e), error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exams = ref.watch(examListControllerProvider).valueOrNull ?? [];
    if (exams.isEmpty) {
      return const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No examinations scheduled.')));
    }

    final activeExam = exams.firstWhere(
      (e) => e.examScheduleId == _selectedExamScheduleId,
      orElse: () => exams.first,
    );

    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final studentsAsync = ref.watch(studentsProvider);
    final marksAsync = ref.watch(marksSheetProvider(
      MarksSheetKey(
        examScheduleId: activeExam.examScheduleId,
        subjectId: _selectedSubjectId ?? '',
        classSectionId: _selectedSectionId ?? '',
      ),
    ));

    final availableSections = _selectedClassId == null
        ? refData.sections
        : refData.sections.where((s) => s.classId == _selectedClassId).toList();

    final availableSubjects = _selectedClassId == null
        ? refData.subjects
        : refData.subjects.where((s) => s.classId == _selectedClassId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Selection Bar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_note, size: 22, color: kExamGreen),
                    const SizedBox(width: 8),
                    const Text('Student Marks Entry', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    // Exam Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: activeExam.examScheduleId,
                        decoration: flowDecoration(context, 'Examination'),
                        items: exams.map((e) => DropdownMenuItem(value: e.examScheduleId, child: Text(e.examName))).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setState(() {
                              _selectedExamScheduleId = v;
                              _marksControllers.clear();
                              _remarksControllers.clear();
                              _absentMap.clear();
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Class Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedClassId,
                        decoration: flowDecoration(context, 'Class *'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select Class')),
                          for (final c in {for (final x in refData.classes) x.id: x}.values)
                            DropdownMenuItem(value: c.id, child: Text(c.label)),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedClassId = v;
                            _selectedSectionId = null;
                            _selectedSubjectId = null;
                            _marksControllers.clear();
                            _remarksControllers.clear();
                            _absentMap.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Section Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: availableSections.any((s) => s.id == _selectedSectionId) ? _selectedSectionId : null,
                        decoration: flowDecoration(context, 'Section *'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select Section')),
                          for (final s in {for (final x in availableSections) x.id: x}.values)
                            DropdownMenuItem(value: s.id, child: Text(s.label)),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedSectionId = v;
                            _marksControllers.clear();
                            _remarksControllers.clear();
                            _absentMap.clear();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Subject Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: availableSubjects.any((s) => s.id == _selectedSubjectId) ? _selectedSubjectId : null,
                        decoration: flowDecoration(context, 'Subject *'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('Select Subject')),
                          for (final sub in {for (final x in availableSubjects) x.id: x}.values)
                            DropdownMenuItem(value: sub.id, child: Text(sub.label)),
                        ],
                        onChanged: (v) {
                          setState(() {
                            _selectedSubjectId = v;
                            _marksControllers.clear();
                            _remarksControllers.clear();
                            _absentMap.clear();
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Main Marks Entry Content
          if (_selectedClassId == null || _selectedSectionId == null || _selectedSubjectId == null)
            Container(
              padding: const EdgeInsets.all(40),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: const Text('Please select Class, Section, and Subject above to enter student marks.', style: TextStyle(color: Colors.grey)),
            )
          else
            marksAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
              error: (e, _) => Center(child: Text('Error loading marks sheet: $e')),
              data: (sheet) {
                final students = studentsAsync.valueOrNull ?? [];
                final enrolledStudents = students.where((s) => s.sectionId == _selectedSectionId).toList();

                // If sheet has existing entries, sync them; otherwise initialize from enrolled students
                List<StudentMarkEntry> entries = sheet?.entries ?? [];
                if (entries.isEmpty && enrolledStudents.isNotEmpty) {
                  entries = enrolledStudents
                      .map((s) => StudentMarkEntry(studentId: s.id, marksObtained: 0.0))
                      .toList();
                }

                _syncControllers(entries);

                final isLocked = sheet?.status == 'SUBMITTED' || sheet?.status == 'APPROVED';

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sheet Status Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isLocked ? Colors.amber.shade50 : Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isLocked ? Colors.amber.shade300 : Colors.teal.shade300,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isLocked ? Icons.lock_outline : Icons.edit_note,
                            color: isLocked ? Colors.amber.shade900 : Colors.teal.shade900,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              isLocked
                                  ? 'This marks sheet is ${sheet?.status ?? "LOCKED"}. Editing is disabled until review.'
                                  : 'Draft Mode: Enter marks for each student and submit for admin approval.',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isLocked ? Colors.amber.shade900 : Colors.teal.shade900,
                              ),
                            ),
                          ),
                          if (!isLocked) ...[
                            OutlinedButton.icon(
                              onPressed: _saving ? null : () => _saveMarks(submit: false),
                              icon: const Icon(Icons.save_outlined, size: 16),
                              label: const Text('Save Draft'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton.icon(
                              onPressed: _saving ? null : () => _saveMarks(submit: true),
                              icon: const Icon(Icons.send_outlined, size: 16),
                              label: const Text('Submit Marks'),
                              style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Students Ledger Table
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      ),
                      child: entries.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(40),
                              child: Center(child: Text('No students found in this class section.')),
                            )
                          : DataTable(
                              headingRowColor: MaterialStateProperty.all(
                                isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                              ),
                              columns: const [
                                DataColumn(label: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Absent', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Marks (Max: 100)', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: entries.map((entry) {
                                final s = enrolledStudents.where((x) => x.id == entry.studentId).firstOrNull;
                                final name = s?.name ?? refData.studentName(entry.studentId);
                                final roll = s?.rollNumber ?? '—';
                                final isAbsent = _absentMap[entry.studentId] ?? false;

                                return DataRow(
                                  cells: [
                                    DataCell(Text(roll)),
                                    DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(
                                      Checkbox(
                                        value: isAbsent,
                                        onChanged: isLocked
                                            ? null
                                            : (v) {
                                                setState(() {
                                                  _absentMap[entry.studentId] = v ?? false;
                                                  if (v == true) {
                                                    _marksControllers[entry.studentId]?.text = '0';
                                                  }
                                                });
                                              },
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 100,
                                        child: TextFormField(
                                          controller: _marksControllers[entry.studentId],
                                          enabled: !isLocked && !isAbsent,
                                          keyboardType: TextInputType.number,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ),
                                    DataCell(
                                      SizedBox(
                                        width: 180,
                                        child: TextFormField(
                                          controller: _remarksControllers[entry.studentId],
                                          enabled: !isLocked,
                                          decoration: const InputDecoration(
                                            isDense: true,
                                            hintText: 'Optional remark',
                                            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }
}
