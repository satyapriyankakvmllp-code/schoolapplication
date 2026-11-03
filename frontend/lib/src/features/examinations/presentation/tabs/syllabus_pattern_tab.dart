import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_flow_controller.dart';
import '../../application/exam_paper_controller.dart';
import '../../application/examination_access.dart';
import '../../domain/exam_flow_models.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../../domain/examination_actor.dart';
import 'flow_ui.dart';

/// Screen 7: Syllabus Tab - Subject-Wise and Chapter-Wise
class SyllabusTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const SyllabusTab({super.key, required this.exam});

  @override
  ConsumerState<SyllabusTab> createState() => _SyllabusTabState();
}

class _SyllabusTabState extends ConsumerState<SyllabusTab> {
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;

  void _openAddEditDialog(BuildContext context, SyllabusChapter? existingChapter, {String? defaultSubjectId}) {
    showDialog(
      context: context,
      builder: (ctx) => AddSyllabusDialog(
        existingChapter: existingChapter,
        defaultClassId: _selectedClassId ?? 'cls-10',
        defaultSectionId: _selectedSectionId,
        defaultSubjectId: defaultSubjectId ?? _selectedSubjectId,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, SyllabusChapter ch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Syllabus Chapter?'),
        content: Text('Are you sure you want to remove "${ch.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(examFlowActionsProvider).deleteSyllabus(ch.id);
        if (mounted) flowSnack(context, 'Chapter deleted successfully');
      } catch (e) {
        if (mounted) flowSnack(context, 'Failed to delete: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final syllabusAsync = ref.watch(syllabusProvider);
    final actor = ref.watch(currentExamActorProvider);
    final canManage = actor.permissions.isAdminOrPrincipal ||
        actor.role == ExamRole.teacher ||
        actor.role == ExamRole.classIncharge;

    final availableSections = refData.sectionsForClass(_selectedClassId);
    final validSectionId = availableSections.any((s) => s.id == _selectedSectionId) ? _selectedSectionId : null;

    final availableSubjects = validSectionId != null
        ? refData.subjectsForSection(validSectionId)
        : refData.subjectsForClass(_selectedClassId);
    final validSubjectId = availableSubjects.any((s) => s.id == _selectedSubjectId) ? _selectedSubjectId : null;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Bar: Title, Filters & Add Syllabus Button
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.menu_book_outlined, color: kExamGreen, size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Examination Syllabus',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Subject-wise curriculum coverage and marks weightage',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),

            if (canManage)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kExamGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Syllabus', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _openAddEditDialog(context, null),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Bar: Class, Section, Subject Dropdowns
        Card(
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Class Dropdown
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: refData.classes.any((c) => c.id == _selectedClassId) ? _selectedClassId : null,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Class'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Classes')),
                      for (final c in refData.classes)
                        DropdownMenuItem(value: c.id, child: Text(c.label)),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedClassId = v;
                      _selectedSectionId = null;
                      _selectedSubjectId = null;
                    }),
                  ),
                ),

                // Section Dropdown (Cascaded from Class)
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: validSectionId,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Section'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Sections')),
                      for (final s in availableSections)
                        DropdownMenuItem(value: s.id, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() {
                      _selectedSectionId = v;
                      _selectedSubjectId = null;
                    }),
                  ),
                ),

                // Subject Dropdown (Cascaded from Class & Section)
                SizedBox(
                  width: 200,
                  child: DropdownButtonFormField<String>(
                    value: validSubjectId,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Subject'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      for (final s in availableSubjects)
                        DropdownMenuItem(value: s.id, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() => _selectedSubjectId = v),
                  ),
                ),

                if (_selectedClassId != null || validSectionId != null || validSubjectId != null)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _selectedClassId = null;
                      _selectedSectionId = null;
                      _selectedSubjectId = null;
                    }),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Reset filters'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Syllabus Content Grouped Subject-Wise & Chapter-Wise
        syllabusAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Text('Error loading syllabus: $err', style: const TextStyle(color: Colors.red)),
            ),
          ),
          data: (allChapters) {
            // Filter chapters based on active dropdowns
            final filteredChapters = allChapters.where((ch) {
              if (_selectedClassId != null && _selectedClassId!.isNotEmpty) {
                final targetDigits = RegExp(r'\d+').firstMatch(_selectedClassId!)?.group(0);
                final chDigits = RegExp(r'\d+').firstMatch(ch.classId)?.group(0);
                if (ch.classId != _selectedClassId && (targetDigits == null || chDigits != targetDigits)) {
                  return false;
                }
              }
              if (validSectionId != null && validSectionId.isNotEmpty) {
                if (ch.classSectionId != null && ch.classSectionId!.isNotEmpty && ch.classSectionId != validSectionId) {
                  return false;
                }
              }
              if (validSubjectId != null && validSubjectId.isNotEmpty) {
                if (ch.subjectId != validSubjectId) {
                  return false;
                }
              }
              return true;
            }).toList();

            if (filteredChapters.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.menu_book, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text(
                        'No syllabus chapters found for the selected criteria.',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Click "+ Add Syllabus" to create chapters for this subject.',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      if (canManage) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: kExamGreen, foregroundColor: Colors.white),
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Syllabus Chapter'),
                          onPressed: () => _openAddEditDialog(context, null),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }

            // Group chapters by subjectId
            final Map<String, List<SyllabusChapter>> subjectGroups = {};
            for (final ch in filteredChapters) {
              subjectGroups.putIfAbsent(ch.subjectId, () => []).add(ch);
            }

            // Sort subjects according to available subjects list or name
            final subjectIds = subjectGroups.keys.toList()
              ..sort((a, b) => refData.subjectName(a).compareTo(refData.subjectName(b)));

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjectIds.length,
              separatorBuilder: (_, _) => const SizedBox(height: 20),
              itemBuilder: (context, idx) {
                final subjId = subjectIds[idx];
                final chapters = subjectGroups[subjId]!
                  ..sort((a, b) => a.chapterNumber.compareTo(b.chapterNumber));
                final subjName = refData.subjectName(subjId);
                final totalWeightage = chapters.fold<int>(0, (sum, c) => sum + c.weightage);

                return Container(
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
                      // Subject Header Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: kExamGreen.withValues(alpha: isDark ? 0.2 : 0.08),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                          border: Border(
                            bottom: BorderSide(
                              color: kExamGreen.withValues(alpha: 0.2),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: kExamGreen.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.bookmark_border, color: kExamGreen, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    subjName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text(
                                    '${chapters.length} ${chapters.length == 1 ? 'Chapter' : 'Chapters'} configured • Total Weightage: $totalWeightage%',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: kExamGreen,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '$totalWeightage% Weightage',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            ),
                            if (canManage) ...[
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Add Chapter to $subjName',
                                icon: const Icon(Icons.add_circle_outline, color: kExamGreen, size: 22),
                                onPressed: () => _openAddEditDialog(context, null, defaultSubjectId: subjId),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Chapter List for this subject
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            for (final ch in chapters)
                              Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Top Chapter Title Row
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              'Ch. ${ch.chapterNumber}',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  ch.title,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                                ),
                                                if (ch.description.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    ch.description,
                                                    style: TextStyle(
                                                      fontSize: 12.5,
                                                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              '${ch.weightage}%',
                                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          statusChip(ch.status),
                                          if (canManage) ...[
                                            const SizedBox(width: 4),
                                            PopupMenuButton<String>(
                                              icon: const Icon(Icons.more_vert, size: 18),
                                              onSelected: (action) {
                                                if (action == 'edit') {
                                                  _openAddEditDialog(context, ch);
                                                } else if (action == 'delete') {
                                                  _confirmDelete(context, ch);
                                                }
                                              },
                                              itemBuilder: (_) => [
                                                const PopupMenuItem(
                                                  value: 'edit',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.edit, size: 16),
                                                      SizedBox(width: 8),
                                                      Text('Edit Chapter'),
                                                    ],
                                                  ),
                                                ),
                                                const PopupMenuItem(
                                                  value: 'delete',
                                                  child: Row(
                                                    children: [
                                                      Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                      SizedBox(width: 8),
                                                      Text('Delete', style: TextStyle(color: Colors.red)),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),

                                      // Topics Section
                                      if (ch.topics.isNotEmpty) ...[
                                        const SizedBox(height: 10),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 6,
                                          children: [
                                            for (final t in ch.topics)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(
                                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
                                                  ),
                                                ),
                                                child: Text(
                                                  '• $t',
                                                  style: TextStyle(
                                                    fontSize: 11.5,
                                                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

/// Add / Edit Syllabus Chapter Dialog Form
class AddSyllabusDialog extends ConsumerStatefulWidget {
  final SyllabusChapter? existingChapter;
  final String? defaultClassId;
  final String? defaultSectionId;
  final String? defaultSubjectId;

  const AddSyllabusDialog({
    super.key,
    this.existingChapter,
    this.defaultClassId,
    this.defaultSectionId,
    this.defaultSubjectId,
  });

  @override
  ConsumerState<AddSyllabusDialog> createState() => _AddSyllabusDialogState();
}

class _AddSyllabusDialogState extends ConsumerState<AddSyllabusDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _weightageCtrl;
  late TextEditingController _chapterNumCtrl;
  late TextEditingController _topicInputCtrl;

  String? _classId;
  String? _sectionId;
  String? _subjectId;
  String _status = 'Planned';
  final List<String> _topics = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final ch = widget.existingChapter;
    _classId = ch?.classId ?? widget.defaultClassId;
    _sectionId = ch?.classSectionId ?? widget.defaultSectionId;
    _subjectId = ch?.subjectId ?? widget.defaultSubjectId;
    _status = ch?.status ?? 'Planned';
    if (ch != null) {
      _topics.addAll(ch.topics);
    }

    _titleCtrl = TextEditingController(text: ch?.title ?? '');
    _descCtrl = TextEditingController(text: ch?.description ?? '');
    _weightageCtrl = TextEditingController(text: ch != null ? '${ch.weightage}' : '20');
    _chapterNumCtrl = TextEditingController(text: ch != null ? '${ch.chapterNumber}' : '1');
    _topicInputCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _weightageCtrl.dispose();
    _chapterNumCtrl.dispose();
    _topicInputCtrl.dispose();
    super.dispose();
  }

  void _addTopic() {
    final text = _topicInputCtrl.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _topics.add(text);
        _topicInputCtrl.clear();
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_classId == null || _classId!.isEmpty) {
      flowSnack(context, 'Please select a Class.');
      return;
    }
    if (_subjectId == null || _subjectId!.isEmpty) {
      flowSnack(context, 'Please select a Subject.');
      return;
    }

    setState(() => _saving = true);

    try {
      final chapter = SyllabusChapter(
        id: widget.existingChapter?.id ?? '',
        classId: _classId!,
        classSectionId: _sectionId,
        subjectId: _subjectId!,
        chapterNumber: int.tryParse(_chapterNumCtrl.text.trim()) ?? 1,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        topics: List.from(_topics),
        weightage: int.tryParse(_weightageCtrl.text.trim()) ?? 0,
        status: _status,
      );

      await ref.read(examFlowActionsProvider).saveSyllabus(chapter);
      if (mounted) {
        Navigator.pop(context);
        flowSnack(
          context,
          widget.existingChapter == null ? 'Syllabus chapter added.' : 'Syllabus chapter updated.',
        );
      }
    } catch (e) {
      if (mounted) flowSnack(context, 'Error saving chapter: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final availableSections = refData.sectionsForClass(_classId);
    final availableSubjects = _sectionId != null
        ? refData.subjectsForSection(_sectionId)
        : refData.subjectsForClass(_classId);

    final isEdit = widget.existingChapter != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Syllabus Chapter' : 'Add Syllabus Chapter',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // 1. Class Dropdown
                DropdownButtonFormField<String>(
                  value: refData.classes.any((c) => c.id == _classId) ? _classId : null,
                  decoration: flowDecoration(context, 'Class *'),
                  items: [
                    for (final c in refData.classes)
                      DropdownMenuItem(value: c.id, child: Text(c.label)),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Class is required' : null,
                  onChanged: (v) => setState(() {
                    _classId = v;
                    _sectionId = null;
                    _subjectId = null;
                  }),
                ),
                const SizedBox(height: 12),

                // 2. Section Dropdown (Cascaded from Class)
                DropdownButtonFormField<String>(
                  value: availableSections.any((s) => s.id == _sectionId) ? _sectionId : null,
                  decoration: flowDecoration(context, 'Section (Optional / All Sections)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Sections')),
                    for (final s in availableSections)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  onChanged: (v) => setState(() {
                    _sectionId = v;
                    _subjectId = null;
                  }),
                ),
                const SizedBox(height: 12),

                // 3. Subject Dropdown (Cascaded from Class & Section)
                DropdownButtonFormField<String>(
                  value: availableSubjects.any((s) => s.id == _subjectId) ? _subjectId : null,
                  decoration: flowDecoration(context, 'Subject *'),
                  items: [
                    for (final s in availableSubjects)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Subject is required' : null,
                  onChanged: (v) => setState(() => _subjectId = v),
                ),
                const SizedBox(height: 12),

                // 4. Chapter Number & Title
                Row(
                  children: [
                    SizedBox(
                      width: 100,
                      child: TextFormField(
                        controller: _chapterNumCtrl,
                        keyboardType: TextInputType.number,
                        decoration: flowDecoration(context, 'Ch. # *'),
                        validator: (v) => v == null || v.isEmpty ? 'Req.' : null,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _titleCtrl,
                        decoration: flowDecoration(context, 'Chapter Title * (e.g. Real Numbers)'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Chapter title is required' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 5. Description
                TextFormField(
                  controller: _descCtrl,
                  maxLines: 2,
                  decoration: flowDecoration(context, 'Description / Overview'),
                ),
                const SizedBox(height: 12),

                // 6. Weightage & Status
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _weightageCtrl,
                        keyboardType: TextInputType.number,
                        decoration: flowDecoration(context, 'Weightage (%)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: flowDecoration(context, 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'Planned', child: Text('Planned')),
                          DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                          DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                        ],
                        onChanged: (v) => setState(() => _status = v ?? 'Planned'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 7. Topics / Sub-units
                const Text('Topics / Sub-Units Covered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _topicInputCtrl,
                        decoration: flowDecoration(context, 'Enter topic and tap + to add'),
                        onSubmitted: (_) => _addTopic(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kExamGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onPressed: _addTopic,
                      child: const Icon(Icons.add),
                    ),
                  ],
                ),
                if (_topics.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (int i = 0; i < _topics.length; i++)
                        Chip(
                          label: Text(_topics[i], style: const TextStyle(fontSize: 12)),
                          onDeleted: () => setState(() => _topics.removeAt(i)),
                          deleteIconColor: Colors.red,
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kExamGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'Update Chapter' : 'Save Chapter'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 7: Exam Pattern Tab - Fully Configurable (Admin & Faculty)
class ExamPatternTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const ExamPatternTab({super.key, required this.exam});

  @override
  ConsumerState<ExamPatternTab> createState() => _ExamPatternTabState();
}

class _ExamPatternTabState extends ConsumerState<ExamPatternTab> {
  String? _selectedPatternId;

  void _openConfigDialog(BuildContext context, ExamPattern? existingPattern) {
    showDialog(
      context: context,
      builder: (ctx) => ConfigureExamPatternDialog(
        examScheduleId: widget.exam.examScheduleId,
        existingPattern: existingPattern,
      ),
    );
  }

  Future<void> _deletePattern(BuildContext context, ExamPattern p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Exam Pattern?'),
        content: Text('Are you sure you want to delete "${p.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(examFlowActionsProvider).deletePattern(widget.exam.examScheduleId, p.id);
        if (mounted) flowSnack(context, 'Exam pattern deleted.');
      } catch (e) {
        if (mounted) flowSnack(context, 'Failed to delete pattern: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final patternsAsync = ref.watch(examPatternsProvider(widget.exam.examScheduleId));
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final actor = ref.watch(currentExamActorProvider);
    final canManage = actor.permissions.isAdminOrPrincipal ||
        actor.role == ExamRole.teacher ||
        actor.role == ExamRole.classIncharge;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return patternsAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
      error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error: $e', style: const TextStyle(color: Colors.red)))),
      data: (patterns) {
        // Fallback default pattern if empty
        final activePattern = patterns.where((p) => p.id == _selectedPatternId).firstOrNull ??
            patterns.firstOrNull ??
            ExamPattern(
              id: 'pat-default-100',
              examScheduleId: widget.exam.examScheduleId,
              classId: 'cls-10',
              subjectId: 'sbj-101',
              title: 'Standard 100-Mark Question Paper Pattern',
              totalMarks: 100,
              internalAssessmentMarks: 20,
              sections: const [
                PatternSection(name: 'Section A: Objective & MCQs', type: 'MCQ', questionCount: 20, marksPerQuestion: 1),
                PatternSection(name: 'Section B: Short Answer Type I', type: 'Short Answer', questionCount: 6, marksPerQuestion: 2),
                PatternSection(name: 'Section C: Short Answer Type II', type: 'Short Answer', questionCount: 7, marksPerQuestion: 3),
                PatternSection(name: 'Section D: Long Answer Case Questions', type: 'Long Answer', questionCount: 4, marksPerQuestion: 5),
                PatternSection(name: 'Section E: Case-Based Integrated Units', type: 'Case Study', questionCount: 3, marksPerQuestion: 4),
              ],
            );

        final totalTheory = activePattern.sectionsTotalMarks;
        final internalMarks = activePattern.internalAssessmentMarks;
        final grandTotal = activePattern.grandTotalMarks;
        final isValid = activePattern.isValidTotal;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Title & Action Buttons
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.dashboard_customize_outlined, color: kExamGreen, size: 24),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Question Paper Blueprint & Pattern',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Section-wise question distribution, marks weightage & internal assessment',
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ],
                ),
                if (canManage)
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: kExamGreen,
                          side: const BorderSide(color: kExamGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Pattern'),
                        onPressed: () => _openConfigDialog(context, activePattern),
                      ),
                      if (patterns.any((p) => p.id == activePattern.id))
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 16),
                          label: const Text('Delete'),
                          onPressed: () => _deletePattern(context, activePattern),
                        ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kExamGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('New Pattern'),
                        onPressed: () => _openConfigDialog(context, null),
                      ),
                    ],
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Pattern Selection Tabs (if multiple configured)
            if (patterns.length > 1) ...[
              Wrap(
                spacing: 8,
                children: [
                  for (final p in patterns)
                    ChoiceChip(
                      selected: p.id == activePattern.id,
                      label: Text(
                        p.subjectId != null
                            ? '${refData.subjectName(p.subjectId)} (${p.totalMarks.toStringAsFixed(0)}M)'
                            : p.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: p.id == activePattern.id ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selectedColor: kExamGreen.withValues(alpha: 0.2),
                      onSelected: (_) => setState(() => _selectedPatternId = p.id),
                    ),
                ],
              ),
              const SizedBox(height: 14),
            ],

            // Active Pattern Details Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              activePattern.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Class: ${refData.className(activePattern.classId)} • Subject: ${refData.subjectName(activePattern.subjectId)} • Duration: ${activePattern.durationMinutes ~/ 60}h ${activePattern.durationMinutes % 60}m',
                              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      FlowChip('${grandTotal.toStringAsFixed(0)} / ${activePattern.totalMarks.toStringAsFixed(0)} Marks', kExamGreen),
                    ],
                  ),
                  const Divider(height: 24),

                  // Validation Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isValid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isValid ? Colors.green.withValues(alpha: 0.4) : Colors.orange.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isValid ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                          color: isValid ? Colors.green.shade700 : Colors.orange.shade800,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isValid
                                ? 'Validation Passed: Theory Questions (${totalTheory.toStringAsFixed(0)} marks) + Internal Assessment (${internalMarks.toStringAsFixed(0)} marks) = ${grandTotal.toStringAsFixed(0)} Marks.'
                                : 'Validation Warning: Current pattern totals ${grandTotal.toStringAsFixed(0)} marks (${totalTheory.toStringAsFixed(0)} theory + ${internalMarks.toStringAsFixed(0)} internal). Target is ${activePattern.totalMarks.toStringAsFixed(0)} marks.',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isValid ? Colors.green.shade800 : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Internal Assessment Component Indicator
                  if (internalMarks > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: isDark ? 0.2 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.assignment_turned_in_outlined, color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Internal Assessment Component (Projects, Assignments, Periodic Tests & Practical Lab):',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            '${internalMarks.toStringAsFixed(0)} Marks',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Question Paper Sections Table
                  Table(
                    border: TableBorder.all(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    children: [
                      // Table Header
                      TableRow(
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100),
                        children: const [
                          Padding(padding: EdgeInsets.all(10), child: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Question Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('No. of Questions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Marks Each', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Padding(padding: EdgeInsets.all(10), child: Text('Total Section Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                        ],
                      ),
                      // Section Rows
                      for (final s in activePattern.sections)
                        TableRow(
                          children: [
                            Padding(padding: const EdgeInsets.all(10), child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5))),
                            Padding(padding: const EdgeInsets.all(10), child: Text(s.type, style: const TextStyle(fontSize: 12.5))),
                            Padding(padding: const EdgeInsets.all(10), child: Text('${s.questionCount}', style: const TextStyle(fontSize: 12.5))),
                            Padding(padding: const EdgeInsets.all(10), child: Text('${s.marksPerQuestion.toStringAsFixed(0)} mark${s.marksPerQuestion == 1 ? '' : 's'}', style: const TextStyle(fontSize: 12.5))),
                            Padding(padding: const EdgeInsets.all(10), child: Text('${s.totalMarks.toStringAsFixed(0)} Marks', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          ],
                        ),
                      // Theory Total Summary Row
                      TableRow(
                        decoration: BoxDecoration(color: (isDark ? Colors.black : Colors.grey.shade50).withValues(alpha: 0.5)),
                        children: [
                          const Padding(padding: EdgeInsets.all(10), child: Text('Theory Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                          const Padding(padding: EdgeInsets.all(10), child: Text('—')),
                          Padding(padding: const EdgeInsets.all(10), child: Text('${activePattern.sections.fold<int>(0, (sum, s) => sum + s.questionCount)} Questions', style: const TextStyle(fontWeight: FontWeight.bold))),
                          const Padding(padding: EdgeInsets.all(10), child: Text('—')),
                          Padding(padding: const EdgeInsets.all(10), child: Text('${totalTheory.toStringAsFixed(0)} Marks', style: const TextStyle(fontWeight: FontWeight.bold, color: kExamGreen))),
                        ],
                      ),
                      // Internal Assessment Row (if configured)
                      if (internalMarks > 0)
                        TableRow(
                          decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.05)),
                          children: [
                            const Padding(padding: EdgeInsets.all(10), child: Text('Internal Assessment', style: TextStyle(fontWeight: FontWeight.bold))),
                            const Padding(padding: EdgeInsets.all(10), child: Text('Continuous Evaluation')),
                            const Padding(padding: EdgeInsets.all(10), child: Text('Portfolio / Lab')),
                            const Padding(padding: EdgeInsets.all(10), child: Text('—')),
                            Padding(padding: const EdgeInsets.all(10), child: Text('${internalMarks.toStringAsFixed(0)} Marks', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue))),
                          ],
                        ),
                      // Grand Total Row
                      TableRow(
                        decoration: BoxDecoration(color: kExamGreen.withValues(alpha: 0.1)),
                        children: [
                          const Padding(padding: EdgeInsets.all(10), child: Text('Grand Total Marks', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
                          const Padding(padding: EdgeInsets.all(10), child: Text('Theory + Internal', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                          const Padding(padding: EdgeInsets.all(10), child: Text('—')),
                          const Padding(padding: EdgeInsets.all(10), child: Text('—')),
                          Padding(padding: const EdgeInsets.all(10), child: Text('${grandTotal.toStringAsFixed(0)} Marks', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: kExamGreen))),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // General Instructions Preview
                  if (activePattern.instructions.isNotEmpty) ...[
                    const Text('General Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 6),
                    Text(
                      activePattern.instructions,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.4),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Configure / Edit Exam Pattern Dialog
class ConfigureExamPatternDialog extends ConsumerStatefulWidget {
  final String examScheduleId;
  final ExamPattern? existingPattern;

  const ConfigureExamPatternDialog({
    super.key,
    required this.examScheduleId,
    this.existingPattern,
  });

  @override
  ConsumerState<ConfigureExamPatternDialog> createState() => _ConfigureExamPatternDialogState();
}

class _ConfigureExamPatternDialogState extends ConsumerState<ConfigureExamPatternDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _totalMarksCtrl;
  late TextEditingController _internalMarksCtrl;
  late TextEditingController _durationCtrl;
  late TextEditingController _instructionsCtrl;

  String? _classId;
  String? _subjectId;
  String? _syllabusId;
  late List<PatternSection> _sections;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.existingPattern;
    if (p != null) {
      _titleCtrl = TextEditingController(text: p.title);
      _totalMarksCtrl = TextEditingController(text: p.totalMarks.toStringAsFixed(0));
      _internalMarksCtrl = TextEditingController(text: p.internalAssessmentMarks.toStringAsFixed(0));
      _durationCtrl = TextEditingController(text: '${p.durationMinutes}');
      _instructionsCtrl = TextEditingController(text: p.instructions);
      _classId = p.classId;
      _subjectId = p.subjectId;
      _sections = List.from(p.sections);
    } else {
      // Clean form for New Exam Pattern with proper labels
      _titleCtrl = TextEditingController();
      _totalMarksCtrl = TextEditingController(text: '100');
      _internalMarksCtrl = TextEditingController(text: '0');
      _durationCtrl = TextEditingController(text: '180');
      _instructionsCtrl = TextEditingController(text: '1. All questions are compulsory.\n2. Write answers clearly.');
      _classId = null;
      _subjectId = null;
      _sections = [];
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _totalMarksCtrl.dispose();
    _internalMarksCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  double get _currentSectionsTotal => _sections.fold(0.0, (sum, s) => sum + s.totalMarks);
  double get _currentInternalMarks => double.tryParse(_internalMarksCtrl.text.trim()) ?? 0.0;
  double get _currentGrandTotal => _currentSectionsTotal + _currentInternalMarks;
  double get _targetTotal => double.tryParse(_totalMarksCtrl.text.trim()) ?? 100.0;

  void _addSection() {
    setState(() {
      final nextLetter = String.fromCharCode(65 + (_sections.length % 26));
      _sections.add(PatternSection(
        name: 'Section $nextLetter: Additional Questions',
        type: 'Short Answer',
        questionCount: 5,
        marksPerQuestion: 2,
      ));
    });
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    if (_sections.isEmpty) {
      flowSnack(context, 'Please add at least one section.');
      return;
    }

    setState(() => _saving = true);
    try {
      final pattern = ExamPattern(
        id: widget.existingPattern?.id ?? '',
        examScheduleId: widget.examScheduleId,
        classId: _classId,
        subjectId: _subjectId,
        title: _titleCtrl.text.trim(),
        totalMarks: _targetTotal,
        internalAssessmentMarks: _currentInternalMarks,
        durationMinutes: int.tryParse(_durationCtrl.text.trim()) ?? 180,
        instructions: _instructionsCtrl.text.trim(),
        sections: List.from(_sections),
      );

      await ref.read(examFlowActionsProvider).savePattern(pattern);
      if (mounted) {
        Navigator.pop(context);
        flowSnack(context, 'Exam pattern saved successfully.');
      }
    } catch (e) {
      if (mounted) flowSnack(context, 'Failed to save pattern: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final syllabusAsync = ref.watch(syllabusProvider);
    final allSyllabus = syllabusAsync.valueOrNull ?? [];
    final availableSubjects = refData.subjectsForClass(_classId);
    final isValid = (_currentGrandTotal - _targetTotal).abs() < 0.01;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 680,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.existingPattern == null ? 'Configure New Exam Pattern' : 'Edit Exam Pattern',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // 1. Pattern Title
                const Text('Pattern Title *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _titleCtrl,
                  decoration: flowDecoration(context, 'e.g. Mid-Term 100-Mark Question Pattern'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Pattern Title is required' : null,
                ),
                const SizedBox(height: 12),

                // 2. Linked Syllabus (Automatically populated from Syllabus module)
                const Text('Linked Syllabus Chapter (Optional - auto-links class and subject)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  value: allSyllabus.any((s) => s.id == _syllabusId) ? _syllabusId : null,
                  isExpanded: true,
                  decoration: flowDecoration(
                    context,
                    'Select Syllabus Chapter',
                    hint: allSyllabus.isEmpty ? 'No syllabus chapters added yet' : 'Auto-links class and subject',
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— None / General Syllabus —')),
                    for (final s in allSyllabus)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text('Ch.${s.chapterNumber}: ${s.title} (${refData.subjectName(s.subjectId)})'),
                      ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _syllabusId = v;
                      if (v != null) {
                        final ch = allSyllabus.where((c) => c.id == v).firstOrNull;
                        if (ch != null) {
                          if (ch.classId.isNotEmpty) _classId = ch.classId;
                          if (ch.subjectId.isNotEmpty) _subjectId = ch.subjectId;
                          if (_titleCtrl.text.trim().isEmpty) {
                            _titleCtrl.text = '${ch.title} Exam Pattern';
                          }
                        }
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 3. Class & Subject Row with proper labels
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Target Class *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: refData.classes.any((c) => c.id == _classId) ? _classId : null,
                            decoration: flowDecoration(context, 'Select Class'),
                            items: [
                              for (final c in refData.classes)
                                DropdownMenuItem(value: c.id, child: Text(c.label)),
                            ],
                            validator: (v) => v == null || v.isEmpty ? 'Class required' : null,
                            onChanged: (v) => setState(() {
                              _classId = v;
                              _subjectId = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Subject *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          DropdownButtonFormField<String>(
                            value: availableSubjects.any((s) => s.id == _subjectId) ? _subjectId : null,
                            decoration: flowDecoration(context, 'Select Subject'),
                            items: [
                              for (final s in availableSubjects)
                                DropdownMenuItem(value: s.id, child: Text(s.label)),
                            ],
                            validator: (v) => v == null || v.isEmpty ? 'Subject required' : null,
                            onChanged: (v) => setState(() => _subjectId = v),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 4. Marks & Duration Setup with proper labels
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Target Marks *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _totalMarksCtrl,
                            keyboardType: TextInputType.number,
                            decoration: flowDecoration(context, 'e.g. 100'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Total marks required' : null,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Internal Marks', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _internalMarksCtrl,
                            keyboardType: TextInputType.number,
                            decoration: flowDecoration(context, 'e.g. 20 (or 0)'),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Duration (Minutes) *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: flowDecoration(context, 'e.g. 180'),
                            validator: (v) => v == null || v.trim().isEmpty ? 'Duration required' : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Live Calculation Status
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isValid ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: isValid ? Colors.green.withValues(alpha: 0.4) : Colors.orange.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(isValid ? Icons.check_circle_outline : Icons.info_outline, color: isValid ? Colors.green : Colors.orange, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Calculated: ${_currentSectionsTotal.toStringAsFixed(0)} Theory + ${_currentInternalMarks.toStringAsFixed(0)} Internal = ${_currentGrandTotal.toStringAsFixed(0)} / ${_targetTotal.toStringAsFixed(0)} Marks',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isValid ? Colors.green.shade900 : Colors.orange.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Sections List Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Question Paper Sections:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    TextButton.icon(
                      onPressed: _addSection,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Section'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (_sections.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Text('No question paper sections added yet.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                          const SizedBox(height: 8),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add First Section'),
                            onPressed: _addSection,
                          ),
                        ],
                      ),
                    ),
                  ),

                // Sections Dynamic Editor
                for (int i = 0; i < _sections.length; i++) ...[
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  initialValue: _sections[i].name,
                                  decoration: flowDecoration(context, 'Section Name (e.g. Section A: Objective)'),
                                  onChanged: (v) => _sections[i] = _sections[i].copyWith(name: v),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: DropdownButtonFormField<String>(
                                  value: _sections[i].type,
                                  decoration: flowDecoration(context, 'Type'),
                                  items: const [
                                    DropdownMenuItem(value: 'MCQ', child: Text('MCQ')),
                                    DropdownMenuItem(value: 'Short Answer', child: Text('Short Ans.')),
                                    DropdownMenuItem(value: 'Long Answer', child: Text('Long Ans.')),
                                    DropdownMenuItem(value: 'Case Study', child: Text('Case Study')),
                                    DropdownMenuItem(value: 'Practical', child: Text('Practical')),
                                  ],
                                  onChanged: (v) => setState(() => _sections[i] = _sections[i].copyWith(type: v ?? 'Short Answer')),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                onPressed: () => setState(() => _sections.removeAt(i)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${_sections[i].questionCount}',
                                  keyboardType: TextInputType.number,
                                  decoration: flowDecoration(context, 'No. of Questions'),
                                  onChanged: (v) => setState(() {
                                    final count = int.tryParse(v) ?? 1;
                                    _sections[i] = _sections[i].copyWith(questionCount: count);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: '${_sections[i].marksPerQuestion.toStringAsFixed(0)}',
                                  keyboardType: TextInputType.number,
                                  decoration: flowDecoration(context, 'Marks Each'),
                                  onChanged: (v) => setState(() {
                                    final m = double.tryParse(v) ?? 1.0;
                                    _sections[i] = _sections[i].copyWith(marksPerQuestion: m);
                                  }),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
                                child: Text('Total: ${_sections[i].totalMarks.toStringAsFixed(0)}M', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),

                // General Instructions
                const Text('General Exam Instructions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 4),
                TextFormField(
                  controller: _instructionsCtrl,
                  maxLines: 2,
                  decoration: flowDecoration(context, 'e.g. 1. All questions compulsory. 2. Calculators prohibited.'),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kExamGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _saving ? null : _handleSave,
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Save Pattern'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Screen 7: Question Paper Tab - Teacher Upload & Admin Review Workflow
class QuestionPaperTab extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  const QuestionPaperTab({super.key, required this.exam});

  @override
  ConsumerState<QuestionPaperTab> createState() => _QuestionPaperTabState();
}

class _QuestionPaperTabState extends ConsumerState<QuestionPaperTab> {
  String? _filterClassId;
  String? _filterSectionId;
  String? _filterSubjectId;

  void _openUploadDialog(BuildContext context, {String? initialFileName}) {
    showDialog(
      context: context,
      builder: (ctx) => UploadQuestionPaperDialog(
        examScheduleId: widget.exam.examScheduleId,
        defaultClassId: _filterClassId ?? 'cls-10',
        defaultSectionId: _filterSectionId,
        defaultSubjectId: _filterSubjectId,
        initialPickedFileName: initialFileName,
      ),
    );
  }

  Future<void> _pickAndUploadQuestionPaper(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
      );
      if (result != null && result.files.isNotEmpty && mounted) {
        final picked = result.files.first;
        _openUploadDialog(context, initialFileName: picked.name);
      }
    } catch (_) {
      if (mounted) {
        _openUploadDialog(context);
      }
    }
  }

  void _openPreviewDialog(BuildContext context, UploadedQuestionPaper paper) {
    showDialog(
      context: context,
      builder: (ctx) => QuestionPaperPreviewDialog(
        exam: widget.exam,
        paper: paper,
      ),
    );
  }

  void _openReviewDialog(BuildContext context, UploadedQuestionPaper paper, ExamReferenceData refData) {
    showDialog(
      context: context,
      builder: (ctx) => ReviewQuestionPaperDialog(
        exam: widget.exam,
        paper: paper,
        refData: refData,
      ),
    );
  }

  Future<void> _approvePaper(BuildContext context, UploadedQuestionPaper paper) async {
    try {
      await ref.read(examFlowActionsProvider).reviewPaper(widget.exam.examScheduleId, paper.id, 'APPROVED', 'Approved by Administration');
      if (mounted) flowSnack(context, 'Question paper "${paper.title}" approved.');
    } catch (e) {
      if (mounted) flowSnack(context, 'Failed to approve paper: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final papersAsync = ref.watch(questionPapersProvider(widget.exam.examScheduleId));
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final actor = ref.watch(currentExamActorProvider);
    final isTeacher = actor.role == ExamRole.teacher || actor.role == ExamRole.classIncharge;
    final isAdmin = actor.permissions.isAdminOrPrincipal;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final availableSections = refData.sectionsForClass(_filterClassId);
    final validSectionId = availableSections.any((s) => s.id == _filterSectionId) ? _filterSectionId : null;

    final availableSubjects = validSectionId != null
        ? refData.subjectsForSection(validSectionId)
        : refData.subjectsForClass(_filterClassId);
    final validSubjectId = availableSubjects.any((s) => s.id == _filterSubjectId) ? _filterSubjectId : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row: Title & Upload Button
        Wrap(
          spacing: 12,
          runSpacing: 10,
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.description_outlined, color: kExamGreen, size: 24),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Question Papers Repository',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    Text(
                      isAdmin
                          ? 'Review and approve question papers submitted by faculty teachers'
                          : 'Upload and manage examination papers for your assigned classes',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
            // Upload button available ONLY for faculty Teachers
            if (isTeacher)
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kExamGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(Icons.upload_file, size: 18),
                label: const Text('Upload Question Paper', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _pickAndUploadQuestionPaper(context),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Filter Bar: Class, Section, Subject
        Card(
          elevation: 0,
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: refData.classes.any((c) => c.id == _filterClassId) ? _filterClassId : null,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Class'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Classes')),
                      for (final c in refData.classes)
                        DropdownMenuItem(value: c.id, child: Text(c.label)),
                    ],
                    onChanged: (v) => setState(() {
                      _filterClassId = v;
                      _filterSectionId = null;
                      _filterSubjectId = null;
                    }),
                  ),
                ),
                SizedBox(
                  width: 170,
                  child: DropdownButtonFormField<String>(
                    value: validSectionId,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Section'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Sections')),
                      for (final s in availableSections)
                        DropdownMenuItem(value: s.id, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() {
                      _filterSectionId = v;
                      _filterSubjectId = null;
                    }),
                  ),
                ),
                SizedBox(
                  width: 190,
                  child: DropdownButtonFormField<String>(
                    value: validSubjectId,
                    isExpanded: true,
                    decoration: flowDecoration(context, 'Subject'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('All Subjects')),
                      for (final s in availableSubjects)
                        DropdownMenuItem(value: s.id, child: Text(s.label)),
                    ],
                    onChanged: (v) => setState(() => _filterSubjectId = v),
                  ),
                ),
                if (_filterClassId != null || validSectionId != null || validSubjectId != null)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _filterClassId = null;
                      _filterSectionId = null;
                      _filterSubjectId = null;
                    }),
                    icon: const Icon(Icons.clear, size: 16),
                    label: const Text('Reset filters'),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Uploaded Papers List
        papersAsync.when(
          loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
          error: (e, _) => Center(child: Padding(padding: const EdgeInsets.all(40), child: Text('Error loading papers: $e', style: const TextStyle(color: Colors.red)))),
          data: (papers) {
            final filteredPapers = papers.where((p) {
              if (_filterClassId != null && _filterClassId!.isNotEmpty) {
                final targetDigits = RegExp(r'\d+').firstMatch(_filterClassId!)?.group(0);
                final pDigits = RegExp(r'\d+').firstMatch(p.classId)?.group(0);
                if (p.classId != _filterClassId && (targetDigits == null || pDigits != targetDigits)) {
                  return false;
                }
              }
              if (validSectionId != null && validSectionId.isNotEmpty) {
                if (p.classSectionId != validSectionId) return false;
              }
              if (validSubjectId != null && validSubjectId.isNotEmpty) {
                if (p.subjectId != validSubjectId) return false;
              }
              return true;
            }).toList();

            if (filteredPapers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    children: [
                      Icon(Icons.upload_file_outlined, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      const Text('No question papers uploaded yet for the selected criteria.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 6),
                      Text(
                        isTeacher ? 'Tap "+ Upload Question Paper" to submit a question paper.' : 'Teachers can submit question papers for review.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12.5),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kExamGreen, foregroundColor: Colors.white),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Upload First Paper'),
                        onPressed: () => _openUploadDialog(context),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredPapers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, idx) {
                final p = filteredPapers[idx];
                final subjName = refData.subjectName(p.subjectId);
                final secName = refData.sectionName(p.classSectionId);

                return Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Title & Status Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (p.fileType.contains('Image') ? Colors.purple : Colors.red).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                p.fileType.contains('Image') ? Icons.image_outlined : Icons.picture_as_pdf_outlined,
                                color: p.fileType.contains('Image') ? Colors.purple : Colors.red,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15.5),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      Text(
                                        'Class & Section: $secName',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                                      ),
                                      const Text('•', style: TextStyle(color: Colors.grey)),
                                      Text(
                                        'Subject: $subjName',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: kExamGreen),
                                      ),
                                      const Text('•', style: TextStyle(color: Colors.grey)),
                                      Text(
                                        'File: ${p.fileName} (${p.fileType})',
                                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildPaperStatusChip(p.status),
                          ],
                        ),
                        // Admin Suggestions / Feedback Box
                        if (p.reviewRemarks != null && p.reviewRemarks!.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: p.status == 'APPROVED'
                                  ? Colors.green.withValues(alpha: 0.08)
                                  : (p.status == 'CHANGES_REQUESTED'
                                      ? Colors.amber.withValues(alpha: 0.12)
                                      : Colors.blue.withValues(alpha: 0.08)),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: p.status == 'APPROVED'
                                    ? Colors.green.shade300
                                    : (p.status == 'CHANGES_REQUESTED'
                                        ? Colors.amber.shade400
                                        : Colors.blue.shade200),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  p.status == 'APPROVED' ? Icons.check_circle_outline : Icons.rate_review_outlined,
                                  size: 16,
                                  color: p.status == 'APPROVED'
                                      ? Colors.green.shade800
                                      : (p.status == 'CHANGES_REQUESTED'
                                          ? Colors.amber.shade900
                                          : Colors.blue.shade800),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.status == 'APPROVED'
                                            ? 'Admin Approval Note:'
                                            : 'Admin Suggestions & Review Feedback:',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: p.status == 'APPROVED'
                                              ? Colors.green.shade900
                                              : (p.status == 'CHANGES_REQUESTED'
                                                  ? Colors.amber.shade900
                                                  : Colors.blue.shade900),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        p.reviewRemarks!,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const Divider(height: 20),

                        // Row 2: Teacher details & Actions
                        Row(
                          children: [
                            const Icon(Icons.person_pin_outlined, size: 16, color: Colors.grey),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Uploaded by: ${p.uploadedByTeacherName} • Submitted on ${p.uploadedAt.substring(0, 10)}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              icon: const Icon(Icons.visibility_outlined, size: 16),
                              label: const Text('Preview / Open', style: TextStyle(fontSize: 12)),
                              onPressed: () => _openPreviewDialog(context, p),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 8),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF109F83),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                icon: const Icon(Icons.rate_review_outlined, size: 16),
                                label: const Text('Review & Suggestions', style: TextStyle(fontSize: 12)),
                                onPressed: () => _openReviewDialog(context, p, refData),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPaperStatusChip(String status) {
    Color bg;
    Color fg;
    String label = status;
    switch (status.toUpperCase()) {
      case 'APPROVED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'APPROVED';
        break;
      case 'CHANGES_REQUESTED':
        bg = Colors.amber.shade50;
        fg = Colors.amber.shade900;
        label = 'CHANGES REQUESTED';
        break;
      case 'REJECTED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'REJECTED';
        break;
      case 'UNDER_REVIEW':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        label = 'UNDER REVIEW';
        break;
      default:
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade700;
        label = 'UPLOADED';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}

/// Upload Question Paper Dialog
class UploadQuestionPaperDialog extends ConsumerStatefulWidget {
  final String examScheduleId;
  final String? defaultClassId;
  final String? defaultSectionId;
  final String? defaultSubjectId;
  final String? initialPickedFileName;

  const UploadQuestionPaperDialog({
    super.key,
    required this.examScheduleId,
    this.defaultClassId,
    this.defaultSectionId,
    this.defaultSubjectId,
    this.initialPickedFileName,
  });

  @override
  ConsumerState<UploadQuestionPaperDialog> createState() => _UploadQuestionPaperDialogState();
}

class _UploadQuestionPaperDialogState extends ConsumerState<UploadQuestionPaperDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl;
  late TextEditingController _fileNameCtrl;
  late TextEditingController _instructionsCtrl;

  String? _classId;
  String? _sectionId;
  String? _subjectId;
  String _fileType = 'PDF Document';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _classId = widget.defaultClassId ?? 'cls-10';
    _sectionId = widget.defaultSectionId ?? 'cls-sec-10a';
    _subjectId = widget.defaultSubjectId ?? 'sbj-101';
    _titleCtrl = TextEditingController(text: 'Class 10 – Section A – Mathematics Question Paper');
    final defaultFile = widget.initialPickedFileName ?? 'Class10A_Mathematics_MidTerm_Official.pdf';
    _fileNameCtrl = TextEditingController(text: defaultFile);
    if (defaultFile.toLowerCase().endsWith('.png') ||
        defaultFile.toLowerCase().endsWith('.jpg') ||
        defaultFile.toLowerCase().endsWith('.jpeg')) {
      _fileType = 'Image Document';
    }
    _instructionsCtrl = TextEditingController(text: '1. Calculators are prohibited.\n2. Graph paper will be provided.\n3. Time allowed: 3 Hours.');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _fileNameCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  void _updateSuggestedTitle(ExamReferenceData refData) {
    final cName = refData.className(_classId);
    final sName = refData.sections.where((s) => s.id == _sectionId).firstOrNull?.sectionName ?? 'Section A';
    final subName = refData.subjectName(_subjectId);
    setState(() {
      _titleCtrl.text = '$cName – Section $sName – $subName Question Paper';
      _fileNameCtrl.text = '${cName.replaceAll(' ', '')}_Sec${sName}_${subName.replaceAll(' ', '')}_Paper.${_fileType.contains('Image') ? 'png' : 'pdf'}';
    });
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_classId == null || _classId!.isEmpty) {
      flowSnack(context, 'Please select a Class.');
      return;
    }
    if (_subjectId == null || _subjectId!.isEmpty) {
      flowSnack(context, 'Please select a Subject.');
      return;
    }

    setState(() => _uploading = true);
    final actor = ref.read(currentExamActorProvider);
    final refData = ref.read(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    final teacherName = refData.teacherName(actor.userId);

    try {
      final paper = UploadedQuestionPaper(
        id: '',
        examScheduleId: widget.examScheduleId,
        classId: _classId!,
        classSectionId: _sectionId ?? 'cls-sec-10a',
        subjectId: _subjectId!,
        title: _titleCtrl.text.trim(),
        uploadedByTeacherId: actor.userId,
        uploadedByTeacherName: teacherName.isEmpty ? 'Faculty Teacher' : teacherName,
        fileName: _fileNameCtrl.text.trim(),
        fileType: _fileType,
        fileUrl: 'assets/docs/${_fileNameCtrl.text.trim()}',
        status: actor.permissions.isAdminOrPrincipal ? 'APPROVED' : 'UPLOADED',
        instructions: _instructionsCtrl.text.trim(),
        uploadedAt: DateTime.now().toIso8601String(),
      );

      await ref.read(examFlowActionsProvider).uploadPaper(paper);
      if (mounted) {
        Navigator.pop(context);
        flowSnack(context, 'Question paper uploaded successfully and submitted to Admin.');
      }
    } catch (e) {
      if (mounted) flowSnack(context, 'Failed to upload paper: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final refData = ref.watch(examReferenceProvider).valueOrNull ?? const ExamReferenceData();
    if (_classId == null && refData.classes.isNotEmpty) {
      _classId = refData.classes.first.id;
    }
    final availableSections = refData.sectionsForClass(_classId);
    if (_sectionId == null && availableSections.isNotEmpty) {
      _sectionId = availableSections.first.id;
    }
    final availableSubjects = _sectionId != null
        ? refData.subjectsForSection(_sectionId)
        : refData.subjectsForClass(_classId);
    if (_subjectId == null && availableSubjects.isNotEmpty) {
      _subjectId = availableSubjects.first.id;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(22),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Upload Examination Question Paper', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // 1. Class Dropdown
                DropdownButtonFormField<String>(
                  value: refData.classes.any((c) => c.id == _classId) ? _classId : null,
                  decoration: flowDecoration(context, '1. Select Class *', hint: 'Select Class'),
                  items: [
                    for (final c in refData.classes)
                      DropdownMenuItem(value: c.id, child: Text(c.label)),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Class required' : null,
                  onChanged: (v) {
                    setState(() {
                      _classId = v;
                      _sectionId = null;
                      _subjectId = null;
                    });
                    _updateSuggestedTitle(refData);
                  },
                ),
                const SizedBox(height: 12),

                // 2. Section Dropdown (Cascaded from Class)
                DropdownButtonFormField<String>(
                  value: availableSections.any((s) => s.id == _sectionId) ? _sectionId : null,
                  decoration: flowDecoration(context, '2. Select Section *', hint: 'Select Section'),
                  items: [
                    for (final s in availableSections)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Section required' : null,
                  onChanged: (v) {
                    setState(() {
                      _sectionId = v;
                    });
                    _updateSuggestedTitle(refData);
                  },
                ),
                const SizedBox(height: 12),

                // 3. Subject Dropdown (Cascaded from Class & Section)
                DropdownButtonFormField<String>(
                  value: availableSubjects.any((s) => s.id == _subjectId) ? _subjectId : null,
                  decoration: flowDecoration(context, '3. Select Subject *', hint: 'Select Subject'),
                  items: [
                    for (final s in availableSubjects)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  validator: (v) => v == null || v.isEmpty ? 'Subject required' : null,
                  onChanged: (v) {
                    setState(() => _subjectId = v);
                    _updateSuggestedTitle(refData);
                  },
                ),
                const SizedBox(height: 12),

                // Title
                TextFormField(
                  controller: _titleCtrl,
                  decoration: flowDecoration(context, 'Question Paper Title *'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Title required' : null,
                ),
                const SizedBox(height: 14),

                // 4. Question Paper Upload File Type (PDF or Image)
                const Text('4. Attachment Document / Image File:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('PDF Document (.pdf)', style: TextStyle(fontSize: 13)),
                        value: 'PDF Document',
                        groupValue: _fileType,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) {
                          setState(() {
                            _fileType = v!;
                            _fileNameCtrl.text = _fileNameCtrl.text.replaceAll('.png', '.pdf');
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Scanned Image (.png/.jpg)', style: TextStyle(fontSize: 13)),
                        value: 'Image Document',
                        groupValue: _fileType,
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        onChanged: (v) {
                          setState(() {
                            _fileType = v!;
                            _fileNameCtrl.text = _fileNameCtrl.text.replaceAll('.pdf', '.png');
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // File name & Mock File Picker
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(_fileType.contains('Image') ? Icons.image : Icons.picture_as_pdf, color: kExamGreen, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _fileNameCtrl,
                          decoration: const InputDecoration(
                            isDense: true,
                            border: InputBorder.none,
                            hintText: 'Attached File Name',
                          ),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade200,
                          foregroundColor: Colors.black87,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.attach_file, size: 16),
                        label: const Text('Browse', style: TextStyle(fontSize: 12)),
                        onPressed: () async {
                          try {
                            final result = await FilePicker.platform.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['pdf', 'doc', 'docx', 'png', 'jpg', 'jpeg'],
                            );
                            if (result != null && result.files.isNotEmpty) {
                              final picked = result.files.first;
                              setState(() {
                                _fileNameCtrl.text = picked.name;
                                final ext = picked.extension?.toLowerCase() ?? '';
                                if (ext == 'png' || ext == 'jpg' || ext == 'jpeg') {
                                  _fileType = 'Image Document';
                                } else {
                                  _fileType = 'PDF Document';
                                }
                              });
                              if (context.mounted) {
                                flowSnack(context, 'Selected: ${picked.name}');
                              }
                            }
                          } catch (e) {
                            if (context.mounted) {
                              flowSnack(context, 'Error selecting file: $e', error: true);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Instructions
                TextFormField(
                  controller: _instructionsCtrl,
                  maxLines: 2,
                  decoration: flowDecoration(context, 'Special Instructions / Notes for Admin & Invigilators'),
                ),
                const SizedBox(height: 20),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kExamGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      onPressed: _uploading ? null : _handleUpload,
                      child: _uploading
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Submit Question Paper'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Admin Question Paper Review & Suggestions Modal
class ReviewQuestionPaperDialog extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  final UploadedQuestionPaper paper;
  final ExamReferenceData refData;

  const ReviewQuestionPaperDialog({
    super.key,
    required this.exam,
    required this.paper,
    required this.refData,
  });

  @override
  ConsumerState<ReviewQuestionPaperDialog> createState() => _ReviewQuestionPaperDialogState();
}

class _ReviewQuestionPaperDialogState extends ConsumerState<ReviewQuestionPaperDialog> {
  late String _status;
  late final TextEditingController _remarksCtrl;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final s = widget.paper.status.toUpperCase();
    if (s == 'APPROVED' || s == 'CHANGES_REQUESTED' || s == 'UNDER_REVIEW' || s == 'REJECTED') {
      _status = s;
    } else {
      _status = 'APPROVED';
    }
    _remarksCtrl = TextEditingController(text: widget.paper.reviewRemarks ?? '');
  }

  @override
  void dispose() {
    _remarksCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    setState(() => _submitting = true);
    try {
      await ref.read(examFlowActionsProvider).reviewPaper(
        widget.exam.examScheduleId,
        widget.paper.id,
        _status,
        _remarksCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        flowSnack(context, 'Question paper review saved. Status: "$_status".');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        flowSnack(context, 'Failed to update review: $e', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final subjName = widget.refData.subjectName(widget.paper.subjectId);
    final clsName = widget.refData.className(widget.paper.classId);
    final secName = widget.refData.sectionName(widget.paper.classSectionId);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(22),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.rate_review_outlined, color: kExamGreen, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Review Examination Paper',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 10),

              // Paper Meta Information Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.paper.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        _metaChip(Icons.school, 'Class & Sec: $clsName ($secName)', const Color(0xFF6366F1)),
                        _metaChip(Icons.menu_book, 'Subject: $subjName', kExamGreen),
                        _metaChip(Icons.person_outline, 'Faculty: ${widget.paper.uploadedByTeacherName}', isDark ? Colors.grey.shade400 : Colors.grey.shade700),
                        _metaChip(Icons.attach_file, '${widget.paper.fileName} (${widget.paper.fileType})', Colors.deepOrange),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Review Status Selection
              const Text(
                '1. Review Decision / Status *',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _status,
                isExpanded: true,
                decoration: flowDecoration(context, 'Set Status'),
                items: const [
                  DropdownMenuItem(
                    value: 'APPROVED',
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF059669), size: 18),
                        SizedBox(width: 8),
                        Text('APPROVED — Validated for Examination', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF059669))),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'CHANGES_REQUESTED',
                    child: Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 18),
                        SizedBox(width: 8),
                        Text('CHANGES REQUESTED — Revision / Feedback Provided', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFD97706))),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'UNDER_REVIEW',
                    child: Row(
                      children: [
                        Icon(Icons.hourglass_top, color: Color(0xFF2563EB), size: 18),
                        SizedBox(width: 8),
                        Text('UNDER REVIEW — Verification In Progress', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2563EB))),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'REJECTED',
                    child: Row(
                      children: [
                        Icon(Icons.cancel_outlined, color: Color(0xFFDC2626), size: 18),
                        SizedBox(width: 8),
                        Text('REJECTED — Paper Not Accepted', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
                      ],
                    ),
                  ),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _status = v);
                },
              ),
              const SizedBox(height: 14),

              // Suggestions and Feedback
              const Text(
                '2. Admin Suggestions & Review Remarks:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 4),
              const Text(
                'Provide constructive suggestions or corrections for the faculty teacher.',
                style: TextStyle(fontSize: 11.5, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _remarksCtrl,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: flowDecoration(
                  context,
                  'Suggestions / Feedback',
                  hint: 'e.g. Please add internal choice for Question 5, verify marks total...',
                ),
              ),
              const SizedBox(height: 16),

              // Preview button & Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('Preview Document', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => QuestionPaperPreviewDialog(
                          exam: widget.exam,
                          paper: widget.paper,
                        ),
                      );
                    },
                  ),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: _submitting ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: kExamGreen,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                        ),
                        icon: _submitting
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send, size: 16),
                        label: const Text('Submit Review & Status'),
                        onPressed: _submitting ? null : _submitReview,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}

/// Question Paper Preview Modal (Teacher and Admin)
class QuestionPaperPreviewDialog extends StatelessWidget {
  final ExamSchedule exam;
  final UploadedQuestionPaper paper;

  const QuestionPaperPreviewDialog({
    super.key,
    required this.exam,
    required this.paper,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 720,
        height: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(paper.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('Submitted by ${paper.uploadedByTeacherName} • Status: ${paper.status}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 10),

            // Document Preview Container (Simulating Printed Board Paper Layout)
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // School Header
                      const Text('EDUPULSE INTERNATIONAL SCHOOL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2, color: Colors.black87)),
                      const Text('ACADEMIC YEAR 2026-2027 • OFFICIAL EXAMINATION PAPER', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 10),
                      Text(exam.examName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: kExamGreen)),
                      const Divider(thickness: 1.5),

                      // Paper Meta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Time Allowed: 3 Hours', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.black87)),
                          Text(paper.title.split('–').last.trim().toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          const Text('Maximum Marks: 100', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                        ],
                      ),
                      const Divider(thickness: 1.5),
                      const SizedBox(height: 10),

                      // Instructions
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(6)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('General Instructions:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black87)),
                            const SizedBox(height: 4),
                            Text(
                              paper.instructions.isNotEmpty
                                  ? paper.instructions
                                  : '1. All questions are compulsory.\n2. The question paper contains 5 Sections A, B, C, D, and E.\n3. Section A carries 20 MCQs of 1 mark each.\n4. Section B carries 6 Short Answer questions of 2 marks each.',
                              style: const TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Sample Section Previews
                      _buildPreviewSection('SECTION A — OBJECTIVE & MULTIPLE CHOICE QUESTIONS (20 MARKS)', [
                        'Q1. If two positive integers a and b are written as a = x^3 y^2 and b = xy^3, where x, y are prime numbers, then HCF(a, b) is:',
                        'Q2. The zeroes of the quadratic polynomial x^2 + 99x + 127 are:\n     (a) both positive   (b) both negative   (c) one positive and one negative   (d) both equal',
                        'Q3. If the lines given by 3x + 2ky = 2 and 2x + 5y + 1 = 0 are parallel, then the value of k is:\n     (a) -5/4   (b) 2/5   (c) 15/4   (d) 3/2',
                        'Q4. The distance of the point P(-6, 8) from the origin is:\n     (a) 8   (b) 2sqrt(7)   (c) 10   (d) 6',
                      ]),
                      const SizedBox(height: 14),

                      _buildPreviewSection('SECTION B — SHORT ANSWER TYPE QUESTIONS (12 MARKS)', [
                        'Q21. Prove that 5 + 2sqrt(3) is an irrational number, given that sqrt(3) is irrational.',
                        'Q22. Find the coordinates of the point which divides the line segment joining (-1, 7) and (4, -3) in the ratio 2:3 internally.',
                      ]),
                      const SizedBox(height: 14),

                      _buildPreviewSection('SECTION C — SHORT ANSWER TYPE II QUESTIONS (18 MARKS)', [
                        'Q27. Solve the following pair of linear equations by elimination method:\n     2x + 3y = 11 and 2x - 4y = -24. Hence find the value of m for which y = mx + 3.',
                        'Q28. If the sum of the first 14 terms of an AP is 1050 and its first term is 10, find the 20th term.',
                      ]),
                      const SizedBox(height: 20),

                      // Official Watermark Verification
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green.shade400),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.verified, color: Colors.green, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Verified Paper Copy • Uploaded by ${paper.uploadedByTeacherName} • Document File: ${paper.fileName}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.green),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: kExamGreen, foregroundColor: Colors.white),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Download PDF'),
                      onPressed: () {
                        flowSnack(context, 'Downloading ${paper.fileName}...');
                      },
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.print, size: 16),
                      label: const Text('Print Paper'),
                      onPressed: () {
                        flowSnack(context, 'Sending ${paper.fileName} to school printer...');
                      },
                    ),
                  ],
                ),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildPreviewSection(String heading, List<String> questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          color: Colors.grey.shade200,
          child: Text(heading, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Colors.black87)),
        ),
        const SizedBox(height: 8),
        for (final q in questions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(q, style: const TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3)),
            ),
          ),
      ],
    );
  }
}

