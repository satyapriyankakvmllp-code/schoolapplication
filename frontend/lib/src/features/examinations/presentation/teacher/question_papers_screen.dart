import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Teacher Question Papers Screen
/// Allows teachers to create and upload question papers with approval tracking.
class TeacherQuestionPapersScreen extends ConsumerStatefulWidget {
  final String? initialExamScheduleId;

  const TeacherQuestionPapersScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  ConsumerState<TeacherQuestionPapersScreen> createState() => _TeacherQuestionPapersScreenState();
}

class _TeacherQuestionPapersScreenState extends ConsumerState<TeacherQuestionPapersScreen> {
  String? _selectedExamScheduleId;
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _selectedExamScheduleId = widget.initialExamScheduleId;
  }

  void _openUploadDialog(String examId, ExamReferenceData refData) {
    if (_selectedClassId == null || _selectedSubjectId == null) {
      flowSnack(context, 'Please select Class and Subject first.', error: true);
      return;
    }

    final titleCtrl = TextEditingController(text: '${refData.subjectName(_selectedSubjectId)} Final Assessment');
    final marksCtrl = TextEditingController(text: '100');
    final descCtrl = TextEditingController();
    String fileName = 'question_paper_${_selectedSubjectId?.toLowerCase()}.pdf';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Upload Question Paper'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: titleCtrl,
                  decoration: flowDecoration(ctx, 'Paper Title *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: marksCtrl,
                  keyboardType: TextInputType.number,
                  decoration: flowDecoration(ctx, 'Total Marks *'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: flowDecoration(ctx, 'Instructions / Blueprint Notes'),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: kExamGreen),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setDialogState(() {
                            fileName = 'updated_paper_${DateTime.now().millisecondsSinceEpoch}.pdf';
                          });
                        },
                        child: const Text('Browse'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: kExamGreen),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final actions = ref.read(examFlowActionsProvider);
                final paper = UploadedQuestionPaper(
                  id: 'qp-${DateTime.now().millisecondsSinceEpoch}',
                  examScheduleId: examId,
                  classId: _selectedClassId ?? '',
                  classSectionId: _selectedSectionId ?? '',
                  subjectId: _selectedSubjectId!,
                  title: titleCtrl.text.trim(),
                  uploadedByTeacherId: 'TCH-CURRENT',
                  uploadedByTeacherName: 'Faculty Teacher',
                  fileName: fileName,
                  fileType: 'PDF Document',
                  fileUrl: fileName,
                  status: 'UNDER_REVIEW',
                  instructions: descCtrl.text.trim(),
                  uploadedAt: DateTime.now().toIso8601String(),
                );
                await actions.uploadPaper(paper);
                if (mounted) {
                  Navigator.pop(ctx);
                  flowSnack(context, 'Question paper submitted for admin approval.');
                }
              },
              child: const Text('Submit for Approval'),
            ),
          ],
        ),
      ),
    );
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
    final qpAsync = ref.watch(questionPapersProvider(activeExam.examScheduleId));

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
          // Filter & Upload Header
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
                    const Icon(Icons.description_outlined, size: 20, color: kExamGreen),
                    const SizedBox(width: 8),
                    const Text('Question Papers Repository', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () => _openUploadDialog(activeExam.examScheduleId, refData),
                      icon: const Icon(Icons.upload_file, size: 16),
                      label: const Text('Upload Question Paper'),
                      style: FilledButton.styleFrom(backgroundColor: kExamGreen),
                    ),
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
                          if (v != null) setState(() => _selectedExamScheduleId = v);
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
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Section Dropdown
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: availableSections.any((s) => s.id == _selectedSectionId) ? _selectedSectionId : null,
                        decoration: flowDecoration(context, 'Section'),
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Sections')),
                          for (final s in {for (final x in availableSections) x.id: x}.values)
                            DropdownMenuItem(value: s.id, child: Text(s.label)),
                        ],
                        onChanged: (v) => setState(() => _selectedSectionId = v),
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
                        onChanged: (v) => setState(() => _selectedSubjectId = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Question Papers List
          qpAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (e, _) => Center(child: Text('Error loading papers: $e')),
            data: (allPapers) {
              final filtered = allPapers.where((p) {
                if (_selectedSubjectId != null && p.subjectId != _selectedSubjectId) return false;
                if (_selectedSectionId != null && p.classSectionId != null && p.classSectionId != _selectedSectionId) {
                  return false;
                }
                return true;
              }).toList();

              if (filtered.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.description, size: 40, color: Colors.grey),
                      SizedBox(height: 10),
                      Text('No question papers uploaded yet for the selected criteria.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, idx) {
                  final paper = filtered[idx];
                  final subName = refData.subjectName(paper.subjectId);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: kExamGreen.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.picture_as_pdf, color: kExamGreen, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(paper.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(
                                '$subName • File: ${paper.fileName} (${paper.fileType})',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                              if (paper.reviewRemarks != null && paper.reviewRemarks!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: Colors.amber.shade300),
                                  ),
                                  child: Text(
                                    'Admin Feedback: ${paper.reviewRemarks}',
                                    style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        _statusBadge(paper.status),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        break;
      case 'REJECTED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        break;
      case 'PENDING_APPROVAL':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade800;
        break;
      case 'DRAFT':
      default:
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade700;
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Text(
        status.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
