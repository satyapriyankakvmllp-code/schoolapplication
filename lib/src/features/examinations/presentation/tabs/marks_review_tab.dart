import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import 'flow_ui.dart';

/// Screen 6: Marks Review & Approval
/// Reviewer sees student, class, section, subject, max marks, marks obtained,
/// entering teacher, submitted date, reviewer, reviewed date, and remarks.
/// Actions: Mark Under Review, Approve, Reject (reason required), Bulk Approve.
class MarksReviewTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const MarksReviewTab({super.key, required this.exam});

  @override
  ConsumerState<MarksReviewTab> createState() => _MarksReviewTabState();
}

class _MarksReviewTabState extends ConsumerState<MarksReviewTab> {
  String? _selectedSectionId;
  String? _selectedSubjectId;
  String _statusFilter = 'ALL'; // ALL, SUBMITTED, UNDER_REVIEW, APPROVED, REJECTED
  bool _actionInProgress = false;

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return DateFormat('dd MMM, hh:mm a').format(dt);
    } catch (_) {
      return iso;
    }
  }

  Future<void> _handleReject(StudentMark mark, String studentName) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Reject Marks: $studentName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the reason for returning marks to the teacher for correction:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: flowDecoration(
                context,
                'Rejection Reason *',
                hint: 'e.g. Please re-check question 3 marks or total tally.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              if (reasonCtrl.text.trim().isEmpty) {
                flowSnack(context, 'Please enter a rejection reason.', error: true);
                return;
              }
              Navigator.pop(c, true);
            },
            child: const Text('Reject & Return to Teacher'),
          ),
        ],
      ),
    );

    final reason = reasonCtrl.text.trim();
    reasonCtrl.dispose();

    if (confirmed == true && reason.isNotEmpty) {
      setState(() => _actionInProgress = true);
      try {
        await ref.read(examFlowActionsProvider).rejectMark(
              widget.exam.examScheduleId,
              mark.id,
              reason,
            );
        if (mounted) flowSnack(context, 'Mark rejected and returned to teacher.');
      } catch (e) {
        if (mounted) flowSnack(context, flowError(e), error: true);
      } finally {
        if (mounted) setState(() => _actionInProgress = false);
      }
    }
  }

  Future<void> _handleApprove(StudentMark mark, String studentName) async {
    setState(() => _actionInProgress = true);
    try {
      await ref.read(examFlowActionsProvider).approveMark(
            widget.exam.examScheduleId,
            mark.id,
          );
      if (mounted) flowSnack(context, 'Mark approved for $studentName.');
    } catch (e) {
      if (mounted) flowSnack(context, flowError(e), error: true);
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _handleBulkApprove({String? paperId, String? sectionId}) async {
    setState(() => _actionInProgress = true);
    try {
      final n = await ref.read(examFlowActionsProvider).bulkApproveMarks(
            widget.exam.examScheduleId,
            paperId: paperId,
            sectionId: sectionId,
          );
      if (mounted) {
        flowSnack(
          context,
          n == 0 ? 'No pending marks found to approve.' : '$n marks approved successfully.',
        );
      }
    } catch (e) {
      if (mounted) flowSnack(context, flowError(e), error: true);
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  Future<void> _handleMarkUnderReview(String paperId) async {
    setState(() => _actionInProgress = true);
    try {
      final n = await ref.read(examFlowActionsProvider).markUnderReview(
            widget.exam.examScheduleId,
            paperId,
          );
      if (mounted) {
        flowSnack(
          context,
          n == 0 ? 'No submitted marks to put under review.' : '$n marks marked Under Review.',
        );
      }
    } catch (e) {
      if (mounted) flowSnack(context, flowError(e), error: true);
    } finally {
      if (mounted) setState(() => _actionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(examinationPermissionsProvider);
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final timetable = ref.watch(examTimetableProvider(widget.exam.examScheduleId)).valueOrNull ?? [];
    final marks = ref.watch(examMarksProvider(widget.exam.examScheduleId)).valueOrNull ?? [];
    final students = ref.watch(studentsProvider).valueOrNull ?? [];
    final canReview = perms.isClassIncharge || perms.isAdminOrPrincipal;

    // Filter available class sections
    var sectionIds = timetable.map((p) => p.classSectionId).whereType<String>().toSet().toList();
    if (perms.isClassIncharge) {
      sectionIds = sectionIds.where((s) => s == 'cls-sec-10a').toList();
    }

    if (sectionIds.isEmpty) {
      return const FlowEmpty(Icons.rule_folder_outlined, 'No timetable entries scheduled to review.');
    }

    final activeSection = sectionIds.contains(_selectedSectionId) ? _selectedSectionId! : sectionIds.first;
    final sectionPapers = timetable.where((p) => p.classSectionId == activeSection).toList();

    // Available subjects for this section
    final subjectIds = sectionPapers.map((p) => p.subjectId).whereType<String>().toSet().toList();
    final activeSubject = subjectIds.contains(_selectedSubjectId) ? _selectedSubjectId : null;

    final targetPaper = sectionPapers.where((p) => p.subjectId == activeSubject).firstOrNull;

    // Filter marks for active section & subject
    final targetPaperIds = targetPaper != null
        ? {targetPaper.id}
        : sectionPapers.map((p) => p.id).toSet();

    final relevantMarks = marks.where((m) {
      if (!targetPaperIds.contains(m.examPaperId)) return false;
      if (_statusFilter == 'ALL') return true;
      return m.status.toUpperCase() == _statusFilter.toUpperCase();
    }).toList();

    final pendingCount = marks.where((m) =>
        targetPaperIds.contains(m.examPaperId) &&
        (m.status == 'SUBMITTED' || m.status == 'UNDER_REVIEW')).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Filter Bar
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.fact_check_outlined, color: kExamGreen, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Marks Review & Verification',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ],
            ),

            // Class / Section Dropdown
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                value: sectionIds.contains(activeSection) ? activeSection : (sectionIds.isNotEmpty ? sectionIds.first : null),
                isExpanded: true,
                decoration: flowDecoration(context, 'Class / Section'),
                items: [
                  for (final sid in {for (final x in sectionIds) x: x}.values)
                    DropdownMenuItem(value: sid, child: Text(refData.sectionName(sid))),
                ],
                onChanged: (v) => setState(() {
                  _selectedSectionId = v;
                  _selectedSubjectId = null;
                }),
              ),
            ),

            // Subject Filter
            SizedBox(
              width: 190,
              child: DropdownButtonFormField<String>(
                value: subjectIds.contains(activeSubject) ? activeSubject : null,
                isExpanded: true,
                decoration: flowDecoration(context, 'Subject'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Subjects')),
                  for (final subId in {for (final x in subjectIds) x: x}.values)
                    DropdownMenuItem(value: subId, child: Text(refData.subjectName(subId))),
                ],
                onChanged: (v) => setState(() => _selectedSubjectId = v),
              ),
            ),

            // Status Filter
            SizedBox(
              width: 160,
              child: DropdownButtonFormField<String>(
                value: const ['ALL', 'SUBMITTED', 'UNDER_REVIEW', 'APPROVED', 'REJECTED'].contains(_statusFilter)
                    ? _statusFilter
                    : 'ALL',
                isExpanded: true,
                decoration: flowDecoration(context, 'Status'),
                items: const [
                  DropdownMenuItem(value: 'ALL', child: Text('All Statuses')),
                  DropdownMenuItem(value: 'SUBMITTED', child: Text('Submitted')),
                  DropdownMenuItem(value: 'UNDER_REVIEW', child: Text('Under Review')),
                  DropdownMenuItem(value: 'APPROVED', child: Text('Approved')),
                  DropdownMenuItem(value: 'REJECTED', child: Text('Rejected')),
                ],
                onChanged: (v) => setState(() => _statusFilter = v ?? 'ALL'),
              ),
            ),

            // Actions: Mark Under Review & Bulk Approve
            if (canReview && pendingCount > 0) ...[
              if (targetPaper != null)
                OutlinedButton.icon(
                  icon: const Icon(Icons.rate_review_outlined, size: 16),
                  label: const Text('Mark Under Review', style: TextStyle(fontSize: 12)),
                  onPressed: _actionInProgress ? null : () => _handleMarkUnderReview(targetPaper.id),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                icon: const Icon(Icons.verified, size: 16),
                label: Text('Approve All ($pendingCount)', style: const TextStyle(fontSize: 12)),
                onPressed: _actionInProgress
                    ? null
                    : () => _handleBulkApprove(
                          paperId: targetPaper?.id,
                          sectionId: targetPaper == null ? activeSection : null,
                        ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 14),

        // Marks Review Table
        if (relevantMarks.isEmpty)
          const FlowEmpty(
            Icons.task_alt,
            'No marks matching the chosen criteria. When teachers submit marks, they will appear here.',
          )
        else
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: WidgetStatePropertyAll(
                  Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF1E293B)
                      : const Color(0xFFF8FAFC),
                ),
                columns: const [
                  DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Subject', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Marks Obtained', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Max Marks', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Entered By', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Submitted At', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Reviewer & Remarks', style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: relevantMarks.map((m) {
                  final st = students.where((s) => s.id == m.studentId).firstOrNull;
                  final paper = timetable.where((p) => p.id == m.examPaperId).firstOrNull;
                  final studentName = st != null ? '${st.rollNumber.isNotEmpty ? "${st.rollNumber}. " : ""}${st.name}' : m.studentId;
                  final teacherName = m.enteredBy != null ? refData.teacherName(m.enteredBy) : 'Teacher';
                  final isUnderReviewOrSubmitted = m.status == 'SUBMITTED' || m.status == 'UNDER_REVIEW';

                  return DataRow(
                    cells: [
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(studentName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            if (st != null)
                              Text(
                                'Adm: ${st.admissionNumber}',
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                          ],
                        ),
                      ),
                      DataCell(Text(refData.sectionName(paper?.classSectionId))),
                      DataCell(Text(refData.subjectName(paper?.subjectId), style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(
                        m.marksObtained != null
                            ? Text(
                                m.marksObtained!.toStringAsFixed(m.marksObtained! % 1 == 0 ? 0 : 1),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: (paper != null && m.marksObtained! < paper.passingMarks)
                                      ? Colors.red
                                      : null,
                                ),
                              )
                            : const FlowChip('ABSENT', Colors.red),
                      ),
                      DataCell(Text(paper?.maxMarks.toStringAsFixed(0) ?? '100')),
                      DataCell(statusChip(m.status)),
                      DataCell(Text(teacherName, style: const TextStyle(fontSize: 12))),
                      DataCell(Text(_formatDate(m.submittedAt), style: const TextStyle(fontSize: 11.5))),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (m.reviewerName != null)
                              Text('By: ${m.reviewerName}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            if (m.rejectionReason != null)
                              Text('Reason: ${m.rejectionReason}', style: const TextStyle(fontSize: 11, color: Colors.red)),
                            if (m.remarks != null && m.remarks != m.rejectionReason)
                              Text(m.remarks!, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      DataCell(
                        canReview && isUnderReviewOrSubmitted
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    tooltip: 'Approve',
                                    icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                    onPressed: _actionInProgress ? null : () => _handleApprove(m, studentName),
                                  ),
                                  IconButton(
                                    tooltip: 'Reject with Reason',
                                    icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                                    onPressed: _actionInProgress ? null : () => _handleReject(m, studentName),
                                  ),
                                ],
                              )
                            : (m.status == 'APPROVED'
                                ? const Icon(Icons.check, color: Colors.green, size: 18)
                                : const Text('—')),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
      ],
    );
  }
}
