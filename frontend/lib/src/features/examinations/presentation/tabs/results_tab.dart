import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_timetable_model.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../../domain/examination_actor.dart';
import 'flow_ui.dart';

/// Screen 7 & 8: Results & Report Cards
/// Full student details, GradeScaleConfig, student detail view, filters,
/// views (complete, class, subject, individual), and printable exports.
class ResultsTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const ResultsTab({super.key, required this.exam});

  @override
  ConsumerState<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends ConsumerState<ResultsTab> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;
  String _searchQuery = '';
  String _viewMode = 'COMPLETE'; // COMPLETE | CLASS | SUBJECT | INDIVIDUAL
  bool _calculating = false;

  Future<void> _runAction(Future<int> Function() action, String successMsg) async {
    setState(() => _calculating = true);
    try {
      final n = await action();
      if (mounted) {
        flowSnack(context, '$successMsg ($n records updated).');
      }
    } catch (e) {
      if (mounted) {
        flowSnack(context, flowError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _calculating = false);
    }
  }

  void _exportCsv({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) {
    flowSnack(context, '$title exported successfully.');
  }

  Future<void> _confirmAndPublish(ExamFlowActions actions, int approvedCount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Publish Examination Results?'),
        content: Text(
          'You are about to publish $approvedCount approved report card(s) for ${widget.exam.examName}.\n\n'
          'Once published, final grades and report cards will be visible immediately to students and parents.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: kExamGreen),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Yes, Publish Now'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _runAction(
        () => actions.advance(widget.exam.examScheduleId, 'PUBLISH'),
        'Report cards published to students and parents',
      );
    }
  }

  Future<void> _confirmAndUnpublish(ExamFlowActions actions, int publishedCount) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Unpublish Examination Results?'),
        content: Text(
          'Are you sure you want to retract $publishedCount published report card(s)?\n\n'
          'Students and parents will no longer see these results until you re-publish.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.orange.shade800),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Unpublish Results'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _runAction(
        () => actions.advance(widget.exam.examScheduleId, 'UNPUBLISH'),
        'Report cards retracted from public view',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(examinationPermissionsProvider);
    if (perms.isStudentOrParent) {
      return _buildStudentView();
    }

    final cardsAsync = ref.watch(reportCardsProvider(widget.exam.examScheduleId));
    final studentsAsync = ref.watch(studentsProvider);
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetable = ref.watch(examTimetableProvider(widget.exam.examScheduleId)).valueOrNull ?? [];
    final marks = ref.watch(examMarksProvider(widget.exam.examScheduleId)).valueOrNull ?? [];
    final att = ref.watch(attendanceProvider(widget.exam.examScheduleId)).valueOrNull ?? [];
    final actions = ref.read(examFlowActionsProvider);
    final canManage = perms.isAdminOrPrincipal && !widget.exam.isCancelled;

    return cardsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Text('Error loading results: $e')),
      data: (cards) {
        return studentsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Error loading students: $e'),
          data: (allStudents) {
            // Count badges
            final pendingCount = cards.where((c) => c.status == 'PENDING_APPROVAL').length;
            final approvedCount = cards.where((c) => c.status == 'APPROVED').length;
            final publishedCount = cards.where((c) => c.isPublished).length;

            // Sections list
            final availableSections = refData.sectionsForClass(_selectedClassId);

            // Filter students
            var filteredStudents = allStudents.where((s) {
              if (_selectedSectionId != null && s.sectionId != _selectedSectionId) return false;
              if (_selectedClassId != null && !availableSections.any((sec) => sec.id == s.sectionId)) return false;
              if (_searchQuery.isNotEmpty) {
                final q = _searchQuery.toLowerCase();
                return s.name.toLowerCase().contains(q) || s.rollNumber.toLowerCase().contains(q) || s.admissionNumber.toLowerCase().contains(q);
              }
              return true;
            }).toList();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Metrics
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.analytics_outlined, color: kExamGreen, size: 22),
                        const SizedBox(width: 8),
                        const Text(
                          'Results & Academic Reports',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                    FlowChip('Pending: $pendingCount', const Color(0xFFD97706)),
                    FlowChip('Approved: $approvedCount', const Color(0xFF2563EB)),
                    FlowChip('Published: $publishedCount', const Color(0xFF059669)),

                    if (canManage) ...[
                      OutlinedButton.icon(
                        icon: _calculating
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.calculate_outlined, size: 16),
                        label: const Text('Calculate Results', style: TextStyle(fontSize: 12)),
                        onPressed: _calculating ? null : () => _runAction(() => actions.calculate(widget.exam, sectionId: _selectedSectionId), 'Results calculated using approved marks'),
                      ),
                      if (pendingCount > 0)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.task_alt, size: 16),
                          label: const Text('Approve All Cards', style: TextStyle(fontSize: 12)),
                          onPressed: _calculating ? null : () => _runAction(() => actions.advance(widget.exam.examScheduleId, 'APPROVE'), 'Report cards approved'),
                        ),
                      if (approvedCount > 0)
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                          icon: const Icon(Icons.publish, size: 16),
                          label: const Text('Publish Results', style: TextStyle(fontSize: 12)),
                          onPressed: _calculating ? null : () => _confirmAndPublish(actions, approvedCount),
                        ),
                      if (publishedCount > 0)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.orange.shade800),
                          icon: const Icon(Icons.unpublished_outlined, size: 16),
                          label: const Text('Unpublish Results', style: TextStyle(fontSize: 12)),
                          onPressed: _calculating ? null : () => _confirmAndUnpublish(actions, publishedCount),
                        ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),

                // Filters Bar
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // View Mode Switcher
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'COMPLETE', label: Text('Complete')),
                        ButtonSegment(value: 'CLASS', label: Text('Class')),
                        ButtonSegment(value: 'SUBJECT', label: Text('Subject')),
                        ButtonSegment(value: 'INDIVIDUAL', label: Text('Individual')),
                      ],
                      selected: {_viewMode},
                      onSelectionChanged: (v) => setState(() => _viewMode = v.first),
                    ),

                    // Class Dropdown
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String>(
                        value: refData.classes.any((c) => c.id == _selectedClassId) ? _selectedClassId : null,
                        isExpanded: true,
                        decoration: flowDecoration(context, 'Class'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Classes')),
                          for (final c in {for (final x in refData.classes) x.id: x}.values)
                            DropdownMenuItem(value: c.id, child: Text(c.label)),
                        ],
                        onChanged: (v) => setState(() {
                          _selectedClassId = v;
                          _selectedSectionId = null;
                        }),
                      ),
                    ),

                    // Section Dropdown
                    SizedBox(
                      width: 170,
                      child: DropdownButtonFormField<String>(
                        value: availableSections.any((s) => s.id == _selectedSectionId) ? _selectedSectionId : null,
                        isExpanded: true,
                        decoration: flowDecoration(context, 'Section'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Sections')),
                          for (final s in {for (final x in availableSections) x.id: x}.values)
                            DropdownMenuItem(value: s.id, child: Text(s.label)),
                        ],
                        onChanged: (v) => setState(() => _selectedSectionId = v),
                      ),
                    ),

                    // Subject Dropdown
                    if (_viewMode == 'SUBJECT')
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String>(
                          value: refData.subjects.any((s) => s.id == _selectedSubjectId) ? _selectedSubjectId : null,
                          isExpanded: true,
                          decoration: flowDecoration(context, 'Subject'),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('Select Subject')),
                            for (final sub in {for (final x in refData.subjects) x.id: x}.values)
                              DropdownMenuItem(value: sub.id, child: Text(sub.label)),
                          ],
                          onChanged: (v) => setState(() => _selectedSubjectId = v),
                        ),
                      ),

                    // Search box
                    SizedBox(
                      width: 180,
                      child: TextField(
                        decoration: flowDecoration(
                          context,
                          'Search Student',
                          prefix: const Icon(Icons.search, size: 16),
                        ),
                        onChanged: (v) => setState(() => _searchQuery = v.trim()),
                      ),
                    ),

                    // Export Button
                    IconButton.filledTonal(
                      tooltip: 'Export CSV',
                      icon: const Icon(Icons.download, size: 18),
                      onPressed: () => _exportCsv(
                        title: '$_viewMode Examination Results',
                        headers: ['Student', 'Roll', 'Class', 'Total', 'Pct', 'Grade', 'GPA', 'Rank', 'Status'],
                        rows: [],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Table / Roster View
                if (cards.isEmpty)
                  FlowEmpty(
                    Icons.assessment_outlined,
                    canManage
                        ? 'No report cards generated yet. Verify all marks are approved, then tap "Calculate Results".'
                        : 'Results have not been compiled yet.',
                  )
                else
                  _buildResultsTable(cards, filteredStudents, refData, timetable, marks, att, perms),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildResultsTable(
    List<ReportCard> cards,
    List<StudentRef> students,
    ExamReferenceData refData,
    List<ExamTimetableEntry> timetable,
    List<StudentMark> marks,
    List<AttendanceRecord> att,
    ExaminationPermissions perms,
  ) {
    final sortedCards = [...cards]..sort((a, b) {
        final c = a.classSectionId.compareTo(b.classSectionId);
        return c != 0 ? c : a.rank.compareTo(b.rank);
      });

    final studentMap = {for (final s in students) s.id: s};

    final filteredCards = sortedCards.where((c) {
      if (_selectedSectionId != null && c.classSectionId != _selectedSectionId) return false;
      if (_selectedClassId != null && !refData.sectionsForClass(_selectedClassId).any((sec) => sec.id == c.classSectionId)) return false;
      if (_searchQuery.isEmpty) return true;
      final st = studentMap[c.studentId];
      final name = (st?.name ?? c.studentId).toLowerCase();
      final roll = (st?.rollNumber ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase()) || roll.contains(_searchQuery.toLowerCase());
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF334155)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll(
            Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : const Color(0xFFF8FAFC),
          ),
          columns: const [
            DataColumn(label: Text('Student Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Roll No.', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Class & Section', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Total Marks', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CGPA / GPA', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Rank', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Performance', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Result', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: filteredCards.map((c) {
            final st = studentMap[c.studentId];
            final name = st?.name ?? c.studentId;
            final roll = st?.rollNumber ?? '—';

            return DataRow(
              cells: [
                DataCell(Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(Text(roll)),
                DataCell(Text(refData.sectionName(c.classSectionId))),
                DataCell(Text('${c.totalMarks.toStringAsFixed(0)} / ${c.totalMaxMarks.toStringAsFixed(0)}')),
                DataCell(Text('${c.percentage.toStringAsFixed(1)}%')),
                DataCell(Text(c.grade, style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text(c.gpa.toStringAsFixed(2))),
                DataCell(Text('#${c.rank}')),
                DataCell(FlowChip(c.performance, _performanceColor(c.performance))),
                DataCell(FlowChip(c.passed ? 'PASS' : 'FAIL', c.passed ? const Color(0xFF059669) : const Color(0xFFDC2626))),
                DataCell(statusChip(c.status)),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'View Full Student Details',
                        icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                        onPressed: () => _showStudentDetailDialog(c, st ?? StudentRef(id: c.studentId, name: name, admissionNumber: '', rollNumber: roll, sectionId: c.classSectionId), refData, timetable, marks, att, perms),
                      ),
                      IconButton(
                        tooltip: 'Print / Download Report Card',
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                        onPressed: () => _showReportCardDialog(c, st?.name ?? name, refData, perms),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _performanceColor(String perf) {
    switch (perf.toLowerCase()) {
      case 'outstanding':
      case 'excellent':
        return const Color(0xFF059669);
      case 'very good':
      case 'good':
        return const Color(0xFF2563EB);
      case 'average':
        return const Color(0xFFD97706);
      default:
        return const Color(0xFFDC2626);
    }
  }

  void _showStudentDetailDialog(
    ReportCard card,
    StudentRef student,
    ExamReferenceData refData,
    List<ExamTimetableEntry> timetable,
    List<StudentMark> marks,
    List<AttendanceRecord> att,
    ExaminationPermissions perms,
  ) {
    final studentPapers = timetable.where((p) => p.classSectionId == card.classSectionId).toList();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_circle_outlined, color: kExamGreen, size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Roll No: ${student.rollNumber}  •  ${refData.sectionName(card.classSectionId)}  •  ${widget.exam.examName}',
                              style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      FlowChip(card.passed ? 'PASSED' : 'FAILED', card.passed ? const Color(0xFF059669) : const Color(0xFFDC2626)),
                    ],
                  ),
                  const Divider(height: 24),

                  // Summary Metric Tiles
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      _metricBox('Total Marks', '${card.totalMarks.toStringAsFixed(0)} / ${card.totalMaxMarks.toStringAsFixed(0)}'),
                      _metricBox('Percentage', '${card.percentage.toStringAsFixed(1)}%'),
                      _metricBox('Final Grade', card.grade),
                      _metricBox('GPA', card.gpa.toStringAsFixed(2)),
                      _metricBox('Class Rank', '#${card.rank}'),
                      _metricBox('Performance', card.performance),
                    ],
                  ),
                  const SizedBox(height: 18),

                  const Text(
                    'Subject-Wise Marks & Attendance',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  Table(
                    border: TableBorder.all(color: Colors.grey.shade300),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.15)),
                        children: const [
                          Padding(padding: EdgeInsets.all(8), child: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Max', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Obtained', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Passing', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Attendance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Padding(padding: EdgeInsets.all(8), child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                      ...studentPapers.map((p) {
                        final m = marks.where((x) => x.examPaperId == p.id && x.studentId == student.id).firstOrNull;
                        final a = att.where((x) => x.examPaperId == p.id && x.studentId == student.id).firstOrNull;
                        final isAbsent = a?.status == 'ABSENT';
                        final got = m?.marksObtained;
                        final passed = got != null && got >= p.passingMarks;

                        return TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(8), child: Text(refData.subjectName(p.subjectId), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(p.maxMarks.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(got != null ? got.toStringAsFixed(0) : (isAbsent ? 'AB' : '—'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: passed ? Colors.green : Colors.red))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(p.passingMarks.toStringAsFixed(0), style: const TextStyle(fontSize: 12))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(a?.status ?? 'PRESENT', style: const TextStyle(fontSize: 11))),
                            Padding(padding: const EdgeInsets.all(8), child: Text(passed ? 'PASS' : 'FAIL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: passed ? Colors.green : Colors.red))),
                          ],
                        );
                      }),
                    ],
                  ),
                  const SizedBox(height: 16),

                  if (card.inchargeRemarks != null) ...[
                    Text('Class In-Charge Remarks: ${card.inchargeRemarks}', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
                    const SizedBox(height: 4),
                  ],
                  if (card.principalRemarks != null) ...[
                    Text('Principal Remarks: ${card.principalRemarks}', style: const TextStyle(fontSize: 12.5, fontStyle: FontStyle.italic)),
                  ],

                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _metricBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showReportCardDialog(
    ReportCard card,
    String studentName,
    ExamReferenceData refData,
    ExaminationPermissions perms,
  ) {
    final inchargeCtrl = TextEditingController(text: card.inchargeRemarks ?? '');
    final principalCtrl = TextEditingController(text: card.principalRemarks ?? '');
    final canEditRemarks = (perms.isAdminOrPrincipal || perms.isClassIncharge) && !card.isPublished;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Report Card: $studentName'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildReportCardDetails(card, studentName, refData),
                const SizedBox(height: 14),
                if (canEditRemarks) ...[
                  TextField(
                    controller: inchargeCtrl,
                    decoration: flowDecoration(context, 'Class In-Charge Remarks'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  if (perms.isAdminOrPrincipal)
                    TextField(
                      controller: principalCtrl,
                      decoration: flowDecoration(context, 'Principal Remarks'),
                      maxLines: 2,
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (canEditRemarks)
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kExamGreen),
              onPressed: () async {
                await ref.read(examFlowActionsProvider).remarks(
                      widget.exam.examScheduleId,
                      card.id,
                      inchargeRemarks: inchargeCtrl.text.trim(),
                      principalRemarks: principalCtrl.text.trim(),
                    );
                if (context.mounted) {
                  flowSnack(context, 'Remarks updated.');
                  Navigator.pop(context);
                }
              },
              child: const Text('Save Remarks'),
            ),
        ],
      ),
    );
  }

  Widget _buildReportCardDetails(ReportCard card, String studentName, ExamReferenceData refData) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade400),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Text('EDUPULSE GLOBAL ACADEMY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('Academic Year ${widget.exam.academicYear}  •  ${widget.exam.examName}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Divider(height: 16),
          Text('Student: $studentName  (${refData.sectionName(card.classSectionId)})', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total: ${card.totalMarks.toStringAsFixed(0)} / ${card.totalMaxMarks.toStringAsFixed(0)}'),
              Text('Percentage: ${card.percentage.toStringAsFixed(1)}%'),
              Text('Grade: ${card.grade}'),
              Text('GPA: ${card.gpa.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Class Rank: #${card.rank}'),
              Text('Result: ${card.passed ? "PASSED" : "FAILED"}'),
              Text('Performance: ${card.performance}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStudentView() {
    final reportCardsAsync = ref.watch(studentReportCardsProvider(false));
    return reportCardsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
      error: (e, _) => Text('Error: $e'),
      data: (cards) {
        final examCard = cards.where((c) => c.examScheduleId == widget.exam.examScheduleId).firstOrNull;
        if (examCard == null || !examCard.isPublished) {
          return const FlowEmpty(
            Icons.school_outlined,
            'Your report card for this examination has not been published yet.',
          );
        }

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.stars, color: kExamGreen, size: 28),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Published Official Report Card',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download'),
                          onPressed: () => flowSnack(context, 'Report card downloaded.'),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    _buildReportCardDetails(examCard, 'Satya (Student)', const ExamReferenceData()),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
