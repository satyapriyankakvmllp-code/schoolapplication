import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/teacher_work_controller.dart';
import '../../domain/teacher_work_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

const List<String> kWorkTypes = [
  'Homework',
  'Project',
  'Worksheet',
  'Lab Report',
  'Reading',
];
const List<String> kWorkStatuses = [
  'Assigned',
  'In Progress',
  'Submitted',
  'Reviewed',
];

/// Teacher Work Screen (Replacing Assignments for teacher-assigned academic work):
/// Clean table/card layout, working search filter, role-based controls,
/// and inline Add/Edit modal dialog.
class TeacherWorkManagementScreen extends ConsumerStatefulWidget {
  const TeacherWorkManagementScreen({super.key});

  @override
  ConsumerState<TeacherWorkManagementScreen> createState() =>
      _TeacherWorkManagementScreenState();
}

class _TeacherWorkManagementScreenState
    extends ConsumerState<TeacherWorkManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedTypeFilter = 'All';
  String _selectedStatusFilter = 'All';
  String _sortColumn = 'Due Date';
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final workAsync = ref.watch(teacherWorkControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assignments',
                        style: TextStyle(
                          fontSize: isMobile ? 18 : 22,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Academic work, homework, and project monitoring',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (perms.canManageTeacherWork)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF109F83),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 16,
                        vertical: isMobile ? 8 : 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(
                      'Add Assignment',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: lookup.subjects.isEmpty
                        ? null
                        : () => _openWorkModal(context, ref, lookup),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Container
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isMobile ? 12 : 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filters + Search Row
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 10,
                    children: [
                      Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Academic Tasks',
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Type filter
                          _buildFilterDropdown(
                            label: 'Type',
                            value: _selectedTypeFilter,
                            items: ['All', ...kWorkTypes],
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _selectedTypeFilter = v);
                            },
                            isDark: isDark,
                          ),
                          // Status filter
                          _buildFilterDropdown(
                            label: 'Status',
                            value: _selectedStatusFilter,
                            items: ['All', ...kWorkStatuses],
                            onChanged: (v) {
                              if (v != null)
                                setState(() => _selectedStatusFilter = v);
                            },
                            isDark: isDark,
                          ),
                        ],
                      ),
                      // Search box
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isMobile ? 160 : 220,
                        ),
                        child: SizedBox(
                          height: 34,
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Search work...',
                              hintStyle: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                size: 16,
                                color: Colors.grey,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 14),
                                      onPressed: () =>
                                          _searchController.clear(),
                                    )
                                  : null,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 0,
                              ),
                              filled: true,
                              fillColor: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                                borderSide: BorderSide(
                                  color: isDark
                                      ? const Color(0xFF334155)
                                      : const Color(0xFFCBD5E1),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // Table Content
                  workAsync.when(
                    data: (items) {
                      final filtered = items.where((w) {
                        if (_selectedTypeFilter != 'All' &&
                            w.workType != _selectedTypeFilter)
                          return false;
                        if (_selectedStatusFilter != 'All' &&
                            w.status != _selectedStatusFilter)
                          return false;
                        if (_searchQuery.isNotEmpty) {
                          final q = _searchQuery;
                          final title = w.title.toLowerCase();
                          final sub = lookup
                              .subjectName(w.subjectId)
                              .toLowerCase();
                          final teacher = lookup
                              .teacherName(w.teacherId)
                              .toLowerCase();
                          return title.contains(q) ||
                              sub.contains(q) ||
                              teacher.contains(q);
                        }
                        return true;
                      }).toList();
                      final sorted = [...filtered]
                        ..sort((a, b) {
                          final comparison = switch (_sortColumn) {
                            'Task Title' => a.title.toLowerCase().compareTo(
                              b.title.toLowerCase(),
                            ),
                            'Class & Section' =>
                              '${lookup.className(a.classId)} - ${lookup.sectionName(a.sectionId)}'
                                  .toLowerCase()
                                  .compareTo(
                                    '${lookup.className(b.classId)} - ${lookup.sectionName(b.sectionId)}'
                                        .toLowerCase(),
                                  ),
                            'Subject' =>
                              lookup
                                  .subjectName(a.subjectId)
                                  .toLowerCase()
                                  .compareTo(
                                    lookup
                                        .subjectName(b.subjectId)
                                        .toLowerCase(),
                                  ),
                            'Teacher' =>
                              lookup
                                  .teacherName(a.teacherId)
                                  .toLowerCase()
                                  .compareTo(
                                    lookup
                                        .teacherName(b.teacherId)
                                        .toLowerCase(),
                                  ),
                            'Type' => a.workType.toLowerCase().compareTo(
                              b.workType.toLowerCase(),
                            ),
                            'Status' => a.status.toLowerCase().compareTo(
                              b.status.toLowerCase(),
                            ),
                            _ => a.dueDate.compareTo(b.dueDate),
                          };
                          return _sortAscending ? comparison : -comparison;
                        });

                      void sortBy(String column) {
                        setState(() {
                          if (_sortColumn == column) {
                            _sortAscending = !_sortAscending;
                          } else {
                            _sortColumn = column;
                            _sortAscending = true;
                          }
                        });
                      }

                      DataColumn sortableColumn(String label) => DataColumn(
                        onSort: (_, _) => sortBy(label),
                        label: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      );

                      if (filtered.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No work items matching "$_searchQuery"'
                                : 'No Assignments recorded yet.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF334155)
                                  : const Color(0xFFE2E8F0),
                            ),
                          ),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: isMobile ? 750 : 950,
                              ),
                              child: DataTable(
                                sortColumnIndex: switch (_sortColumn) {
                                  'Task Title' => 0,
                                  'Class & Section' => 1,
                                  'Subject' => 2,
                                  'Teacher' => 3,
                                  'Type' => 4,
                                  'Status' => 6,
                                  _ => 5,
                                },
                                sortAscending: _sortAscending,
                                horizontalMargin: 12,
                                columnSpacing: 18,
                                headingRowHeight: 40,
                                dataRowMinHeight: 46,
                                dataRowMaxHeight: 56,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF8FAFC),
                                ),
                                columns: [
                                  sortableColumn('Task Title'),
                                  sortableColumn('Class & Section'),
                                  sortableColumn('Subject'),
                                  sortableColumn('Teacher'),
                                  sortableColumn('Type'),
                                  sortableColumn('Due Date'),
                                  sortableColumn('Status'),
                                  if (perms.canManageTeacherWork)
                                    const DataColumn(
                                      label: Text(
                                        'Action',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                ],
                                rows: sorted.map((w) {
                                  final dueStr =
                                      '${w.dueDate.year}-${w.dueDate.month.toString().padLeft(2, '0')}-${w.dueDate.day.toString().padLeft(2, '0')}';

                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        ConstrainedBox(
                                          constraints: const BoxConstraints(
                                            maxWidth: 220,
                                          ),
                                          child: Text(
                                            w.title,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12.5,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF0F172A),
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${lookup.className(w.classId)} - ${lookup.sectionName(w.sectionId)}',
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lookup.subjectName(w.subjectId),
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lookup.teacherName(w.teacherId),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF109F83,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            w.workType,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF109F83),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          dueStr,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (w.status == 'Reviewed' ||
                                                    w.status == 'Submitted')
                                                ? const Color(
                                                    0xFF10B981,
                                                  ).withValues(alpha: 0.12)
                                                : const Color(
                                                    0xFFF59E0B,
                                                  ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            w.status,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  (w.status == 'Reviewed' ||
                                                      w.status == 'Submitted')
                                                  ? const Color(0xFF10B981)
                                                  : const Color(0xFFF59E0B),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (perms.canManageTeacherWork)
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                ),
                                                tooltip: 'Edit Work',
                                                onPressed: () => _openWorkModal(
                                                  context,
                                                  ref,
                                                  lookup,
                                                  existing: w,
                                                ),
                                              ),
                                              // Admins can view/edit assignments but never delete them.
                                              if (perms.canDeleteTeacherWork)
                                                IconButton(
                                                  icon: const Icon(
                                                    Icons.delete_outline,
                                                    size: 16,
                                                    color: Colors.red,
                                                  ),
                                                  tooltip: 'Delete Work',
                                                  onPressed: () async {
                                                    if (await confirmDelete(
                                                      context,
                                                      w.title,
                                                    )) {
                                                      if (!context.mounted)
                                                        return;
                                                      await runClassesAction(
                                                        context,
                                                        () => ref
                                                            .read(
                                                              teacherWorkControllerProvider
                                                                  .notifier,
                                                            )
                                                            .delete(w.id),
                                                      );
                                                    }
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
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Text('Error: $err'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    final effectiveValue = items.contains(value) ? value : items.first;

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: effectiveValue,
              isDense: true,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
              items: items.map((i) {
                return DropdownMenuItem(value: i, child: Text(i));
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  /// Inline modal form to add or edit teacher work directly on page
  Future<void> _openWorkModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    TeacherWorkModel? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final instructionsCtrl = TextEditingController(
      text: existing?.instructions ?? '',
    );
    final guidelinesCtrl = TextEditingController(
      text: existing?.submissionGuidelines ?? '',
    );
    var classId =
        existing?.classId ??
        (lookup.classes.isNotEmpty ? lookup.classes.first.id : '');
    final sectionsForClass = lookup.sections
        .where((s) => s.classId == classId)
        .toList();
    var sectionId =
        existing?.sectionId ??
        (sectionsForClass.isNotEmpty ? sectionsForClass.first.id : null);
    final subjectsForClass = lookup.subjects
        .where((s) => s.classId == classId)
        .toList();
    var subjectId =
        existing?.subjectId ??
        (subjectsForClass.isNotEmpty ? subjectsForClass.first.id : '');
    String? teacherId =
        existing?.teacherId ??
        lookup.subjects.where((s) => s.id == subjectId).firstOrNull?.teacherId;
    var workType = existing?.workType ?? kWorkTypes.first;
    var status = existing?.status ?? kWorkStatuses.first;
    DateTime dueDate =
        existing?.dueDate ?? DateTime.now().add(const Duration(days: 7));
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  existing == null ? Icons.add_task : Icons.edit_outlined,
                  color: const Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  existing == null ? 'New Assignment' : 'Edit Assignment',
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
                    const Text(
                      'Task Title',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter task title',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Class',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Class',
                      inlineLabel: false,
                      allowNone: false,
                      value: classId.isEmpty ? null : classId,
                      options: {for (final c in lookup.classes) c.id: c.name},
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            classId = v;
                            final secs = lookup.sections
                                .where((section) => section.classId == v)
                                .toList();
                            sectionId = secs.isNotEmpty ? secs.first.id : null;
                            final subs = lookup.subjects
                                .where((subject) => subject.classId == v)
                                .toList();
                            subjectId = subs.isNotEmpty ? subs.first.id : '';
                            teacherId = subs.isNotEmpty
                                ? subs.first.teacherId
                                : null;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Section',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Section',
                      inlineLabel: false,
                      allowNone: false,
                      value: sectionId,
                      options: {
                        for (final s in lookup.sections.where(
                          (s) => s.classId == classId,
                        ))
                          s.id: s.name,
                      },
                      onChanged: (v) => setDialogState(() => sectionId = v),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Subject',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SearchableIdDropdown(
                      label: 'Subject',
                      inlineLabel: false,
                      allowNone: false,
                      value: subjectId.isEmpty ? null : subjectId,
                      options: {
                        for (final s in lookup.subjects.where(
                          (s) => s.classId == classId,
                        ))
                          s.id: s.name,
                      },
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            subjectId = v;
                            final subj = lookup.subjects
                                .where((s) => s.id == v)
                                .firstOrNull;
                            final qualified = lookup
                                .qualifiedTeachersForSubject(subj?.name);
                            if (teacherId != null &&
                                !qualified.any((t) => t.id == teacherId)) {
                              teacherId = qualified.isNotEmpty
                                  ? qualified.first.id
                                  : null;
                            } else if (teacherId == null &&
                                qualified.isNotEmpty) {
                              teacherId =
                                  subj?.teacherId != null &&
                                      qualified.any(
                                        (t) => t.id == subj!.teacherId,
                                      )
                                  ? subj!.teacherId
                                  : (qualified.isNotEmpty
                                        ? qualified.first.id
                                        : null);
                            }
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Teacher',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Builder(
                      builder: (ctx) {
                        final subj = lookup.subjects
                            .where((s) => s.id == subjectId)
                            .firstOrNull;
                        final qualified = subj != null
                            ? lookup.qualifiedTeachersForSubject(subj.name)
                            : lookup.teachers;

                        if (subj != null && qualified.isEmpty) {
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
                          label: 'Teacher',
                          inlineLabel: false,
                          value: qualified.any((t) => t.id == teacherId)
                              ? teacherId
                              : null,
                          hint: subj != null
                              ? 'Select qualified teacher...'
                              : 'Select teacher...',
                          options: {
                            for (final teacher in qualified)
                              teacher.id: teacher.name,
                          },
                          onChanged: (v) => setDialogState(() => teacherId = v),
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Current assignment: ${lookup.className(classId)} · ${lookup.sectionName(sectionId)} · ${lookup.subjectName(subjectId)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    // Work Type & Status row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Work Type',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: workType,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                items: kWorkTypes
                                    .map(
                                      (t) => DropdownMenuItem(
                                        value: t,
                                        child: Text(t),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null)
                                    setDialogState(() => workType = v);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: status,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 8,
                                  ),
                                ),
                                items: kWorkStatuses
                                    .map(
                                      (s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) {
                                  if (v != null)
                                    setDialogState(() => status = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Instructions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: instructionsCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter task instructions',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'Submission Guidelines',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: guidelinesCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Enter submission guidelines',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        'Due Date: ${dueDate.toLocal().toString().split(' ').first}',
                      ),
                      onPressed: () async {
                        final selected = await showDatePicker(
                          context: ctx,
                          initialDate: dueDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (selected != null)
                          setDialogState(() => dueDate = selected);
                      },
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
                  final title = titleCtrl.text.trim();
                  if (title.isEmpty) {
                    setDialogState(() => formError = 'Task title is required');
                    return;
                  }
                  if (classId.isEmpty ||
                      sectionId == null ||
                      subjectId.isEmpty ||
                      teacherId == null) {
                    setDialogState(
                      () => formError =
                          'Select a class, section, subject, and teacher.',
                    );
                    return;
                  }

                  try {
                    final model = TeacherWorkModel(
                      id: existing?.id ?? '',
                      title: title,
                      classId: classId,
                      sectionId: sectionId,
                      subjectId: subjectId,
                      teacherId: teacherId!,
                      workType: workType,
                      dueDate: dueDate,
                      status: status,
                      instructions: instructionsCtrl.text.trim(),
                      submissionGuidelines: guidelinesCtrl.text.trim(),
                    );
                    await ref
                        .read(teacherWorkControllerProvider.notifier)
                        .save(model, isNew: existing == null);
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      final isNew = existing == null;
                      final screenWidth = MediaQuery.sizeOf(context).width;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 28,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isNew ? 'Task assigned' : 'Task updated',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Saved successfully',
                                      style: TextStyle(fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: const Color(0xFF10B981),
                          behavior: SnackBarBehavior.floating,
                          width: screenWidth >= 560 ? 480 : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          duration: const Duration(seconds: 4),
                        ),
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
                child: Text(existing == null ? 'Assign' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
