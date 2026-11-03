import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';
import 'report_cards_screen.dart';

/// Admin Results Screen
/// Manages results computation, grading ledger, approval, and publication.
class AdminResultsScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const AdminResultsScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends ConsumerState<AdminResultsScreen> {
  String? _selectedExamScheduleId;
  String? _selectedClassId;
  String? _selectedSectionId;
  String _searchQuery = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
  }

  Future<void> _runAction(Future<int> Function() action, String successMsg) async {
    setState(() => _busy = true);
    try {
      final count = await action();
      if (mounted) {
        flowSnack(context, '$successMsg ($count records affected).');
      }
    } catch (e) {
      if (mounted) {
        flowSnack(context, flowError(e), error: true);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmAndPublish(ExamFlowActions actions, ExamSchedule exam, int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Publish Examination Results?'),
        content: Text(
          'You are about to publish $count approved report cards for ${exam.examName}.\n\n'
          'Once published, results and report cards will be visible immediately to students and parents.',
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
        () => actions.advance(exam.examScheduleId, 'PUBLISH'),
        'Report cards published to students and parents',
      );
    }
  }

  Future<void> _confirmAndUnpublish(ExamFlowActions actions, ExamSchedule exam, int count) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Unpublish Examination Results?'),
        content: Text(
          'Are you sure you want to retract $count published report cards for ${exam.examName}?\n\n'
          'Students and parents will no longer see these results until you publish again.',
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
        () => actions.advance(exam.examScheduleId, 'UNPUBLISH'),
        'Report cards retracted from public view',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final exams = ref.watch(examListControllerProvider).valueOrNull ?? [];
    if (exams.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Text('No examinations scheduled yet.'),
        ),
      );
    }

    final activeExam = exams.firstWhere(
      (e) => e.examScheduleId == _selectedExamScheduleId,
      orElse: () => exams.first,
    );

    final perms = ref.watch(examinationPermissionsProvider);
    final actions = ref.read(examFlowActionsProvider);
    final cardsAsync = ref.watch(reportCardsProvider(activeExam.examScheduleId));
    final studentsAsync = ref.watch(studentsProvider);
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetable = ref.watch(examTimetableProvider(activeExam.examScheduleId)).valueOrNull ?? [];

    final availableSections = _selectedClassId == null
        ? refData.sections
        : refData.sections.where((s) => s.classId == _selectedClassId).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Exam Selector Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.assessment_outlined, size: 20, color: kExamGreen),
                const SizedBox(width: 10),
                const Text(
                  'Select Examination:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: activeExam.examScheduleId,
                      isExpanded: true,
                      items: exams.map((e) {
                        return DropdownMenuItem<String>(
                          value: e.examScheduleId,
                          child: Text(
                            '${e.examName} (${e.academicYear})',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedExamScheduleId = val);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          cardsAsync.when(
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (e, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error loading results: $e'),
              ),
            ),
            data: (allCards) {
              final students = studentsAsync.valueOrNull ?? [];
              final studentMap = {for (final s in students) s.id: s};

              // Filter cards
              final filtered = allCards.where((c) {
                if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
                  final sec = refData.sections.where((s) => s.id == c.classSectionId).firstOrNull;
                  if (sec?.classId != _selectedClassId) return false;
                }
                if (_selectedSectionId != null && _selectedSectionId!.isNotEmpty) {
                  if (c.classSectionId != _selectedSectionId) return false;
                }
                if (_searchQuery.isNotEmpty) {
                  final s = studentMap[c.studentId];
                  final name = s?.name.toLowerCase() ?? '';
                  final id = c.studentId.toLowerCase();
                  final q = _searchQuery.toLowerCase();
                  if (!name.contains(q) && !id.contains(q)) return false;
                }
                return true;
              }).toList();

              final approvedCount = allCards.where((c) => c.status == 'APPROVED').length;
              final publishedCount = allCards.where((c) => c.status == 'PUBLISHED').length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // KPI Overview Header
                  Row(
                    children: [
                      Expanded(
                        child: _kpiCard(
                          title: 'Total Generated',
                          value: '${allCards.length}',
                          color: const Color(0xFF3B82F6),
                          icon: Icons.assignment_outlined,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpiCard(
                          title: 'Approved',
                          value: '$approvedCount',
                          color: const Color(0xFF109F83),
                          icon: Icons.check_circle_outline,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _kpiCard(
                          title: 'Published',
                          value: '$publishedCount',
                          color: const Color(0xFF8B5CF6),
                          icon: Icons.public,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Actions & Filters Bar
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
                        // Action Buttons Row
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            FilledButton.icon(
                              onPressed: _busy
                                  ? null
                                  : () => _runAction(
                                        () => actions.advance(activeExam.examScheduleId, 'GENERATE'),
                                        'Results computed for all students',
                                      ),
                              icon: const Icon(Icons.calculate_outlined, size: 16),
                              label: const Text('Compute / Re-Calculate Results'),
                              style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                            ),
                            if (perms.isAdminOrPrincipal) ...[
                              FilledButton.icon(
                                onPressed: _busy
                                    ? null
                                    : () => _runAction(
                                          () => actions.advance(activeExam.examScheduleId, 'APPROVE'),
                                          'All completed report cards approved',
                                        ),
                                icon: const Icon(Icons.done_all, size: 16),
                                label: const Text('Approve All Completed'),
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0F766E)),
                              ),
                              FilledButton.icon(
                                onPressed: (_busy || approvedCount == 0)
                                    ? null
                                    : () => _confirmAndPublish(actions, activeExam, approvedCount),
                                icon: const Icon(Icons.publish, size: 16),
                                label: Text('Publish Results ($approvedCount)'),
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16A34A)),
                              ),
                              if (publishedCount > 0)
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _confirmAndUnpublish(actions, activeExam, publishedCount),
                                  icon: const Icon(Icons.undo, size: 16, color: Colors.orange),
                                  label: Text(
                                    'Unpublish ($publishedCount)',
                                    style: const TextStyle(color: Colors.orange),
                                  ),
                                ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Dropdown Filters
                        Row(
                          children: [
                            // Class Filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedClassId,
                                decoration: flowDecoration(context, 'Filter by Class'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Classes')),
                                  for (final c in {for (final x in refData.classes) x.id: x}.values)
                                    DropdownMenuItem(value: c.id, child: Text(c.label)),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _selectedClassId = val;
                                    _selectedSectionId = null;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Section Filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: availableSections.any((s) => s.id == _selectedSectionId)
                                    ? _selectedSectionId
                                    : null,
                                decoration: flowDecoration(context, 'Filter by Section'),
                                items: [
                                  const DropdownMenuItem(value: null, child: Text('All Sections')),
                                  for (final s in {for (final x in availableSections) x.id: x}.values)
                                    DropdownMenuItem(value: s.id, child: Text(s.label)),
                                ],
                                onChanged: (val) => setState(() => _selectedSectionId = val),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Search Field
                            Expanded(
                              child: TextField(
                                decoration: flowDecoration(
                                  context,
                                  'Search Student',
                                  hint: 'Name or admission no...',
                                  prefix: const Icon(Icons.search, size: 18),
                                ),
                                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Results Ledger Table
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(40),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.assignment_turned_in_outlined, size: 40, color: Colors.grey),
                                  const SizedBox(height: 10),
                                  Text(
                                    allCards.isEmpty
                                        ? 'No report cards generated yet. Click "Compute / Re-Calculate Results" above.'
                                        : 'No results match the selected filters.',
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: DataTable(
                                headingRowColor: MaterialStateProperty.all(
                                  isDark ? const Color(0xFF334155) : const Color(0xFFF8FAFC),
                                ),
                                columns: const [
                                  DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Roll No', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Class & Section', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Total Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Percentage', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Result', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: filtered.map((card) {
                                  final s = studentMap[card.studentId];
                                  final name = s?.name ?? refData.studentName(card.studentId);
                                  final roll = s?.rollNumber ?? '—';
                                  final secName = refData.sectionName(card.classSectionId);

                                  final isPass = card.passed;

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: kExamGreen.withOpacity(0.15),
                                              child: Text(
                                                name.isNotEmpty ? name[0] : 'S',
                                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: kExamGreen),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                                Text(card.studentId, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      DataCell(Text(roll)),
                                      DataCell(Text(secName)),
                                      DataCell(Text('${card.totalMarks.toStringAsFixed(1)} / ${card.totalMaxMarks.toStringAsFixed(0)}')),
                                      DataCell(Text('${card.percentage.toStringAsFixed(1)}%')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.blue.shade200),
                                          ),
                                          child: Text(
                                            card.grade,
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue.shade700),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: isPass ? Colors.green.shade50 : Colors.red.shade50,
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: isPass ? Colors.green.shade200 : Colors.red.shade200),
                                          ),
                                          child: Text(
                                            isPass ? 'PASS' : 'FAIL',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: isPass ? Colors.green.shade700 : Colors.red.shade700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(_statusBadge(card.status)),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_outlined, size: 18, color: kExamGreen),
                                              tooltip: 'View Report Card',
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => AdminReportCardsScreen(
                                                      exam: activeExam,
                                                      initialStudentId: card.studentId,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
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

  Widget _kpiCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'PUBLISHED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'APPROVED':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade700;
        break;
      case 'SUBMITTED':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        break;
      case 'DRAFT':
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
