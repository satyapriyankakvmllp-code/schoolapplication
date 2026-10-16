import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/curriculum_controller.dart';
import '../../domain/curriculum_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Curriculum Screen matching Reference Image 3:
/// Dropdowns for Academic Year, Class, Section, Subject,
/// Overall Syllabus Coverage bar, 4 compact metric cards,
/// Chapter accordions with topic checkmarks and Completed/Pending badges,
/// and inline Add Curriculum modal.
class CurriculumManagementScreen extends ConsumerStatefulWidget {
  const CurriculumManagementScreen({super.key});

  @override
  ConsumerState<CurriculumManagementScreen> createState() => _CurriculumManagementScreenState();
}

class _CurriculumManagementScreenState extends ConsumerState<CurriculumManagementScreen> {
  String _selectedAcademicYear = '2026-2027';
  String? _selectedClassId;
  String? _selectedSectionId;
  String? _selectedSubjectId;
  final Set<String> _collapsedChapterIds = {};

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final curriculumAsync = ref.watch(curriculumControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    // Set default selections once loaded
    if (_selectedClassId == null && lookup.classes.isNotEmpty) {
      final cls10 = lookup.classes.where((c) => c.name.toLowerCase().contains('tenth') || c.name.contains('10'));
      _selectedClassId = cls10.isNotEmpty ? cls10.first.id : lookup.classes.first.id;
    }
    final sectionsForClass = lookup.sections.where((s) => s.classId == _selectedClassId).toList();
    if (_selectedSectionId == null && sectionsForClass.isNotEmpty) {
      _selectedSectionId = sectionsForClass.first.id;
    } else if (sectionsForClass.isNotEmpty && !sectionsForClass.any((s) => s.id == _selectedSectionId)) {
      _selectedSectionId = sectionsForClass.first.id;
    }

    final subjectsForClass = lookup.subjects.where((s) => s.classId == _selectedClassId).toList();
    if (_selectedSubjectId == null && subjectsForClass.isNotEmpty) {
      _selectedSubjectId = subjectsForClass.first.id;
    } else if (subjectsForClass.isNotEmpty && !subjectsForClass.any((s) => s.id == _selectedSubjectId)) {
      _selectedSubjectId = subjectsForClass.first.id;
    }

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Filter Bar matching Reference Image 3
            _buildTopFilters(lookup, isDark, isMobile),
            const SizedBox(height: 16),

            // Content Body
            curriculumAsync.when(
              data: (allCurriculum) {
                // Filter chapters by selected subject
                final filtered = allCurriculum
                    .where((c) => _selectedSubjectId == null || c.subjectId == _selectedSubjectId)
                    .toList();

                // Compute metrics matching Reference Image 3
                int totalChapters = filtered.length;
                int chaptersCompleted = filtered.where((c) => c.topics.isNotEmpty && c.completedTopics >= c.topics.length).length;
                int totalTopics = filtered.fold<int>(0, (sum, c) => sum + c.topics.length);
                int completedTopics = filtered.fold<int>(0, (sum, c) => sum + c.completedTopics);
                int pendingTopics = (totalTopics - completedTopics).clamp(0, 999);
                double coveragePct = totalTopics > 0 ? (completedTopics / totalTopics) : 0.0;

                final currentSubject = lookup.subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
                final teacherName = lookup.teacherName(currentSubject?.teacherId);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructor Banner & Overall Syllabus Coverage (Ref Image 3)
                    _buildCoverageBanner(
                      teacherName: teacherName,
                      coveragePct: coveragePct,
                      completedTopics: completedTopics,
                      totalTopics: totalTopics,
                      chaptersCompleted: chaptersCompleted,
                      totalChapters: totalChapters,
                      pendingTopics: pendingTopics,
                      isDark: isDark,
                      isMobile: isMobile,
                    ),
                    const SizedBox(height: 16),

                    // Chapter Accordions
                    if (filtered.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(40),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.library_books_outlined, size: 40, color: Colors.grey.shade400),
                            const SizedBox(height: 8),
                            const Text('No syllabus units added yet for this subject.'),
                            if (perms.canManageCurriculum) ...[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF109F83)),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('Add First Chapter'),
                                onPressed: () => _openCurriculumModal(context, ref, lookup),
                              ),
                            ],
                          ],
                        ),
                      )
                    else
                      for (int i = 0; i < filtered.length; i++)
                        _buildChapterAccordion(
                          context,
                          ref,
                          lookup,
                          filtered[i],
                          chapterIndex: i + 1,
                          isDark: isDark,
                          isMobile: isMobile,
                        ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (err, _) => Text('Error: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopFilters(ClassesLookup lookup, bool isDark, bool isMobile) {
    final perms = ref.watch(classesPermissionsProvider);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          // Academic Year
          _buildFilterPill(
            label: 'Academic Year',
            value: _selectedAcademicYear,
            items: const ['2026-2027', '2025-2026', '2024-2025'],
            onChanged: (v) {
              if (v != null) setState(() => _selectedAcademicYear = v);
            },
            isDark: isDark,
          ),

          // Class
          _buildFilterPill(
            label: 'Class',
            value: _selectedClassId ?? (lookup.classes.isNotEmpty ? lookup.classes.first.id : ''),
            itemsMap: {for (final c in lookup.classes) c.id: c.name},
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _selectedClassId = v;
                  _selectedSectionId = null;
                  _selectedSubjectId = null;
                });
              }
            },
            isDark: isDark,
          ),

          // Section
          () {
            final secs = lookup.sections.where((s) => s.classId == _selectedClassId).toList();
            return _buildFilterPill(
              label: 'Section',
              value: _selectedSectionId ?? (secs.isNotEmpty ? secs.first.id : ''),
              itemsMap: {for (final s in secs) s.id: s.name},
              onChanged: (v) {
                if (v != null) setState(() => _selectedSectionId = v);
              },
              isDark: isDark,
            );
          }(),

          // Subject
          () {
            final subs = lookup.subjects.where((s) => s.classId == _selectedClassId).toList();
            return _buildFilterPill(
              label: 'Subject',
              value: _selectedSubjectId ?? (subs.isNotEmpty ? subs.first.id : ''),
              itemsMap: {for (final s in subs) s.id: s.name},
              onChanged: (v) {
                if (v != null) setState(() => _selectedSubjectId = v);
              },
              isDark: isDark,
            );
          }(),

          if (perms.canManageCurriculum)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF109F83),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Curriculum', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              onPressed: () => _openCurriculumModal(context, ref, lookup),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterPill({
    required String label,
    required String value,
    List<String>? items,
    Map<String, String>? itemsMap,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final map = itemsMap ?? {for (final i in (items ?? <String>[])) i: i};
    final effectiveValue = map.containsKey(value) ? value : (map.isNotEmpty ? map.keys.first : null);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isDense: true,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              items: map.entries.map((e) {
                return DropdownMenuItem(value: e.key, child: Text(e.value));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCoverageBanner({
    required String teacherName,
    required double coveragePct,
    required int completedTopics,
    required int totalTopics,
    required int chaptersCompleted,
    required int totalChapters,
    required int pendingTopics,
    required bool isDark,
    required bool isMobile,
  }) {
    final pctInt = (coveragePct * 100).round();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructor row
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                child: Text(
                  teacherName.isNotEmpty ? teacherName[0] : 'T',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF109F83),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Instructor: $teacherName',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Published to Students',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Overall Syllabus Coverage title + count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Syllabus Coverage: $pctInt%',
                style: TextStyle(
                  fontSize: isMobile ? 14 : 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '$completedTopics of $totalTopics Topics Completed',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: coveragePct,
              minHeight: 7,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            ),
          ),
          const SizedBox(height: 16),

          // 4 Metric Cards matching Reference Image 3
          LayoutBuilder(
            builder: (ctx, constraints) {
              final width = (constraints.maxWidth - (isMobile ? 8 : 24)) / (isMobile ? 2 : 4);
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMetricBox(
                    label: 'Chapters Completed',
                    value: '$chaptersCompleted of $totalChapters',
                    bgColor: isDark ? const Color(0xFF0F2922) : const Color(0xFFF0FDF4),
                    borderColor: const Color(0xFF86EFAC),
                    width: width,
                  ),
                  _buildMetricBox(
                    label: 'Completed Topics',
                    value: '$completedTopics',
                    bgColor: isDark ? const Color(0xFF0C243B) : const Color(0xFFEFF6FF),
                    borderColor: const Color(0xFF93C5FD),
                    width: width,
                  ),
                  _buildMetricBox(
                    label: 'Pending Topics',
                    value: '$pendingTopics',
                    bgColor: isDark ? const Color(0xFF351F0A) : const Color(0xFFFFFBEB),
                    borderColor: const Color(0xFFFCD34D),
                    width: width,
                  ),
                  _buildMetricBox(
                    label: 'Target Term',
                    value: 'Mid-Term Exam',
                    bgColor: isDark ? const Color(0xFF1E1B4B) : const Color(0xFFEEF2FF),
                    borderColor: const Color(0xFFA5B4FC),
                    width: width,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color bgColor,
    required Color borderColor,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChapterAccordion(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup,
    CurriculumModel chapter, {
    required int chapterIndex,
    required bool isDark,
    required bool isMobile,
  }) {
    final perms = ref.watch(classesPermissionsProvider);
    final isCollapsed = _collapsedChapterIds.contains(chapter.id);
    final total = chapter.topics.length;
    final completed = chapter.completedTopics.clamp(0, total > 0 ? total : 1);
    final pct = total > 0 ? ((completed / total) * 100).round() : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (Expandable)
          InkWell(
            onTap: () {
              setState(() {
                if (isCollapsed) {
                  _collapsedChapterIds.remove(chapter.id);
                } else {
                  _collapsedChapterIds.add(chapter.id);
                }
              });
            },
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Curriculum #$chapterIndex',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF109F83),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          chapter.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lookup.className(chapter.classId)} · ${lookup.subjectName(chapter.subjectId)}${chapter.description.isNotEmpty ? ' · ${chapter.description}' : ''}',
                          style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$pct% Done',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF109F83),
                    ),
                  ),
                  if (perms.canManageCurriculum) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      tooltip: 'Edit Curriculum',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _openCurriculumModal(context, ref, lookup, existing: chapter),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                      tooltip: 'Delete Curriculum',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        if (await confirmDelete(context, chapter.title)) {
                          if (!context.mounted) return;
                          await runClassesAction(
                            context,
                            () => ref.read(curriculumControllerProvider.notifier).delete(chapter.id),
                          );
                        }
                      },
                    ),
                  ],
                  const SizedBox(width: 8),
                  Icon(
                    isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    size: 18,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          // Chapter Section: DISPLAY ONLY CHAPTER NAME (No subtopics required)
          if (!isCollapsed) ...[
            const Divider(height: 1),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
              child: Row(
                children: [
                  Text('Chapters (${chapter.topics.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  if (perms.canManageCurriculum)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: const Color(0xFF109F83),
                      ),
                      icon: const Icon(Icons.add, size: 14),
                      label: const Text('Add New Chapter', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                      onPressed: () => _openAddChapterModal(context, ref, chapter),
                    ),
                ],
              ),
            ),
            if (chapter.topics.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: Text('No chapters added to ${chapter.title} yet.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: chapter.topics.length,
                separatorBuilder: (_, _) => Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                itemBuilder: (ctx, topicIdx) {
                  final topicName = chapter.topics[topicIdx];
                  final isDone = topicIdx < completed;

                  return InkWell(
                    onTap: perms.canUpdateCurriculumProgress
                        ? () {
                            final newCount = isDone ? (completed - 1) : (completed + 1);
                            ref.read(curriculumControllerProvider.notifier).updateProgress(chapter.id, newCount);
                          }
                        : null,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        children: [
                          Icon(
                            isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                            size: 18,
                            color: isDone ? const Color(0xFF10B981) : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 10),
                          // Display ONLY the chapter name
                          Expanded(
                            child: Text(
                              topicName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              isDone ? 'Completed' : 'Pending',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: isDone ? const Color(0xFF10B981) : Colors.grey,
                              ),
                            ),
                          ),
                          if (perms.canManageCurriculum) ...[
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                              tooltip: 'Delete Chapter',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () async {
                                final nextTopics = List<String>.from(chapter.topics)..removeAt(topicIdx);
                                final updated = chapter.copyWith(topics: nextTopics);
                                await ref.read(curriculumControllerProvider.notifier).save(updated, isNew: false);
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            // Explicit Add New Chapter bottom option
            if (perms.canManageCurriculum) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Center(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF109F83),
                      side: const BorderSide(color: Color(0xFF109F83)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add New Chapter', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    onPressed: () => _openAddChapterModal(context, ref, chapter),
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Dialog to add a new chapter to an existing curriculum
  Future<void> _openAddChapterModal(
    BuildContext context,
    WidgetRef ref,
    CurriculumModel curriculum,
  ) async {
    final chapterCtrl = TextEditingController(text: 'Chapter ${curriculum.topics.length + 1}');
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.add_circle_outline, color: Color(0xFF109F83), size: 20),
                SizedBox(width: 8),
                Text('Add New Chapter', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SizedBox(
              width: 380,
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
                      child: Text(formError!, style: const TextStyle(fontSize: 12, color: Colors.red)),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text('Curriculum: ${curriculum.title}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  const Text('Chapter Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: chapterCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Chapter 1, Chapter 2',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF109F83)),
                onPressed: () async {
                  final chapterName = chapterCtrl.text.trim();
                  if (chapterName.isEmpty) {
                    setDialogState(() => formError = 'Chapter name is required');
                    return;
                  }
                  try {
                    final nextTopics = [...curriculum.topics, chapterName];
                    final updated = curriculum.copyWith(topics: nextTopics);
                    await ref.read(curriculumControllerProvider.notifier).save(updated, isNew: false);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Chapter "$chapterName" added successfully'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() => formError = e.toString().replaceAll('Exception:', '').trim());
                  }
                },
                child: const Text('Add Chapter'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Inline modal form to add or edit curriculum directly on page
  Future<void> _openCurriculumModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    CurriculumModel? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? 'Primary Mathematics');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final initialChapterCtrl = TextEditingController(text: existing?.topics.isNotEmpty == true ? existing!.topics.first : 'Chapter 1');
    var classId = existing?.classId ?? (_selectedClassId ?? (lookup.classes.isNotEmpty ? lookup.classes.first.id : 'cls-10'));
    
    final subjectsForClass = lookup.subjects.where((s) => s.classId == classId).toList();
    var subjectId = existing?.subjectId ?? (subjectsForClass.isNotEmpty ? subjectsForClass.first.id : (lookup.subjects.isNotEmpty ? lookup.subjects.first.id : ''));
    String academicYear = '2026-27';
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentSubjects = lookup.subjects.where((s) => s.classId == classId).toList();
          final effectiveSubjectList = currentSubjects.isNotEmpty ? currentSubjects : lookup.subjects;
          if (!effectiveSubjectList.any((s) => s.id == subjectId)) {
            subjectId = effectiveSubjectList.isNotEmpty ? effectiveSubjectList.first.id : '';
          }

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  existing == null ? Icons.add_circle_outline : Icons.edit_outlined,
                  color: const Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  existing == null ? 'Add Curriculum' : 'Edit Curriculum',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],

                    // Curriculum Name with Quick Suggestions
                    const Text('Curriculum Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: ['Primary Mathematics', 'Secondary Mathematics', 'Science Core', 'Physics Advanced'].map((preset) {
                        return ActionChip(
                          label: Text(preset, style: const TextStyle(fontSize: 11)),
                          padding: EdgeInsets.zero,
                          onPressed: () => setDialogState(() => titleCtrl.text = preset),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Primary Mathematics, Secondary Mathematics',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Class Dropdown
                    const Text('Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: classId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: lookup.classes.map((c) {
                        return DropdownMenuItem(
                          value: c.id,
                          child: Text(c.name, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            classId = v;
                            final subs = lookup.subjects.where((s) => s.classId == v).toList();
                            if (subs.isNotEmpty) subjectId = subs.first.id;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // Subject Dropdown
                    const Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: subjectId,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: effectiveSubjectList.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.name} (${lookup.className(s.classId)})', style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => subjectId = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Academic Year Dropdown
                    const Text('Academic Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: academicYear,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: const [
                        DropdownMenuItem(value: '2025-26', child: Text('2025-26')),
                        DropdownMenuItem(value: '2026-27', child: Text('2026-27')),
                        DropdownMenuItem(value: '2027-28', child: Text('2027-28')),
                        DropdownMenuItem(value: '2028-29', child: Text('2028-29')),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => academicYear = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Initial Chapter (No subtopics required)
                    if (existing == null) ...[
                      const Text('Initial Chapter (Subtopics not required)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: initialChapterCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Chapter 1',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Description
                    const Text('Description', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: descCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Curriculum overview and objectives',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
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
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFF109F83)),
                onPressed: () async {
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    setDialogState(() => formError = 'Curriculum name is required');
                    return;
                  }

                  List<String> chaptersList;
                  if (existing != null) {
                    chaptersList = existing.topics;
                  } else {
                    final initCh = initialChapterCtrl.text.trim();
                    chaptersList = initCh.isNotEmpty ? [initCh] : ['Chapter 1'];
                  }

                  try {
                    final model = CurriculumModel(
                      id: existing?.id ?? '',
                      classId: classId,
                      subjectId: subjectId,
                      title: title,
                      description: descCtrl.text.trim(),
                      topics: chaptersList,
                      completedTopics: existing?.completedTopics ?? 0,
                    );
                    await ref.read(curriculumControllerProvider.notifier).save(
                          model,
                          isNew: existing == null,
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null ? 'Curriculum "$title" created successfully' : 'Curriculum updated successfully'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      formError = e.toString().replaceAll('Exception:', '').replaceAll('ClassesDataException:', '').trim();
                    });
                  }
                },
                child: Text(existing == null ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
