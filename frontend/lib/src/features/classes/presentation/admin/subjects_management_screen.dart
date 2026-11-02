import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/subjects_controller.dart';
import '../../domain/subject_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Subjects Management Screen: organized table/card layout, working search,
/// and inline Add/Edit modal dialog.
class SubjectsManagementScreen extends ConsumerStatefulWidget {
  final ValueChanged<String>? onOpenClass;

  const SubjectsManagementScreen({super.key, this.onOpenClass});

  @override
  ConsumerState<SubjectsManagementScreen> createState() =>
      _SubjectsManagementScreenState();
}

class _SubjectsManagementScreenState
    extends ConsumerState<SubjectsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClassFilter = 'all';
  String _statusFilter = 'All'; // All | Assigned | Not Assigned

  // Sorting: 0 Code, 1 Subject Name, 2 Class, 3 Type, 4 Syllabus, 5 Teacher, 6 Status
  int _sortColumn = 0;
  bool _sortAscending = true;

  static bool _isAssigned(SubjectModel s) =>
      (s.teacherId ?? '').trim().isNotEmpty;

  void _sortBy(int column, {bool? ascending}) {
    setState(() {
      if (ascending != null) {
        _sortColumn = column;
        _sortAscending = ascending;
      } else if (_sortColumn == column) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumn = column;
        _sortAscending = true;
      }
    });
  }

  Widget _header(String title, int column) => SortableHeader(
    title: title,
    isSorted: _sortColumn == column,
    ascending: _sortAscending,
    onToggle: () => _sortBy(column),
    onAscending: () => _sortBy(column, ascending: true),
    onDescending: () => _sortBy(column, ascending: false),
  );

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
    final subjectsAsync = ref.watch(subjectsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subjects Management',
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
                        'Dashboard / Classes / Subjects',
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
                if (perms.canManageSubjects)
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
                      'Add Subject',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: lookup.classes.isEmpty
                        ? null
                        : () => _openSubjectModal(context, ref, lookup),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Card Container
            Container(
              width: double.infinity,
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Controls row: Title, Class Filter dropdown, and Search bar
                  Wrap(
                    spacing: 12,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subject Catalog',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Class Filter Dropdown (Test: When selecting Class 1, only its subjects show)
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedClassFilter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                dropdownColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Classes'),
                                  ),
                                  ...lookup.classes.map(
                                    (c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null)
                                    setState(() => _selectedClassFilter = v);
                                },
                              ),
                            ),
                          ),
                          // Status filter: Assigned / Not Assigned (teacher assigned or not)
                          Container(
                            height: 34,
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF0F172A)
                                  : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF334155)
                                    : const Color(0xFFCBD5E1),
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _statusFilter,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                dropdownColor: isDark
                                    ? const Color(0xFF1E293B)
                                    : Colors.white,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'All',
                                    child: Text('All Status'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Assigned',
                                    child: Text('Assigned'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'Not Assigned',
                                    child: Text('Not Assigned'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null)
                                    setState(() => _statusFilter = v);
                                },
                              ),
                            ),
                          ),
                          // Search bar
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: isMobile ? 160 : 200,
                            ),
                            child: SizedBox(
                              height: 34,
                              child: TextField(
                                controller: _searchController,
                                style: const TextStyle(fontSize: 12),
                                decoration: InputDecoration(
                                  hintText: 'Search subjects...',
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
                                          icon: const Icon(
                                            Icons.clear,
                                            size: 14,
                                          ),
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
                    ],
                  ),
                  const Divider(height: 24),

                  // Table
                  subjectsAsync.when(
                    data: (items) {
                      final filtered = items.where((s) {
                        if (_selectedClassFilter != 'all' &&
                            s.classId != _selectedClassFilter) {
                          return false;
                        }
                        if (_statusFilter == 'Assigned' && !_isAssigned(s))
                          return false;
                        if (_statusFilter == 'Not Assigned' && _isAssigned(s))
                          return false;
                        if (_searchQuery.isEmpty) return true;
                        final name = s.name.toLowerCase();
                        final code = s.code.toLowerCase();
                        final className = lookup
                            .className(s.classId)
                            .toLowerCase();
                        final teacher = lookup
                            .teacherName(s.teacherId)
                            .toLowerCase();
                        final type = s.type.toLowerCase();
                        final syllabus = (s.syllabus ?? '').toLowerCase();
                        return name.contains(_searchQuery) ||
                            code.contains(_searchQuery) ||
                            className.contains(_searchQuery) ||
                            teacher.contains(_searchQuery) ||
                            type.contains(_searchQuery) ||
                            syllabus.contains(_searchQuery);
                      }).toList();

                      filtered.sort((a, b) {
                        int cmp;
                        switch (_sortColumn) {
                          case 1:
                            cmp = a.name.toLowerCase().compareTo(
                              b.name.toLowerCase(),
                            );
                            break;
                          case 2:
                            cmp = lookup
                                .className(a.classId)
                                .toLowerCase()
                                .compareTo(
                                  lookup.className(b.classId).toLowerCase(),
                                );
                            break;
                          case 3:
                            cmp = a.type.toLowerCase().compareTo(
                              b.type.toLowerCase(),
                            );
                            break;
                          case 4:
                            cmp = (a.syllabus ?? '').toLowerCase().compareTo(
                              (b.syllabus ?? '').toLowerCase(),
                            );
                            break;
                          case 5:
                            cmp = lookup
                                .teacherName(a.teacherId)
                                .toLowerCase()
                                .compareTo(
                                  lookup.teacherName(b.teacherId).toLowerCase(),
                                );
                            break;
                          case 6:
                            cmp = (_isAssigned(a) ? 0 : 1).compareTo(
                              _isAssigned(b) ? 0 : 1,
                            );
                            break;
                          default:
                            cmp = a.code.toLowerCase().compareTo(
                              b.code.toLowerCase(),
                            );
                        }
                        return _sortAscending ? cmp : -cmp;
                      });

                      if (filtered.isEmpty) {
                        return Container(
                          padding: const EdgeInsets.all(32),
                          alignment: Alignment.center,
                          child: Text(
                            _searchQuery.isNotEmpty
                                ? 'No subjects matching "$_searchQuery"'
                                : (_statusFilter != 'All' ||
                                      _selectedClassFilter != 'all')
                                ? 'No subjects match the selected filters.'
                                : 'No subjects enrolled yet.',
                            style: const TextStyle(color: Colors.grey),
                          ),
                        );
                      }

                      return ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: double.infinity,
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
                                minWidth: isMobile
                                    ? 760
                                    : (screenWidth - (isMobile ? 50 : 80))
                                          .clamp(900, 2400),
                              ),
                              child: DataTable(
                                showCheckboxColumn: false,
                                horizontalMargin: 16,
                                columnSpacing: 20,
                                headingRowHeight: 40,
                                dataRowMinHeight: 44,
                                dataRowMaxHeight: 52,
                                headingRowColor: WidgetStateProperty.all(
                                  isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF8FAFC),
                                ),
                                columns: [
                                  DataColumn(label: _header('Code', 0)),
                                  DataColumn(label: _header('Subject Name', 1)),
                                  DataColumn(label: _header('Class', 2)),
                                  DataColumn(label: _header('Type', 3)),
                                  DataColumn(label: _header('Syllabus', 4)),
                                  DataColumn(
                                    label: _header('Assigned Teacher', 5),
                                  ),
                                  DataColumn(label: _header('Status', 6)),
                                  if (perms.canManageSubjects)
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
                                rows: filtered.map((s) {
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF6366F1,
                                            ).withValues(alpha: 0.1),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            s.code,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11.5,
                                              color: Color(0xFF6366F1),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          s.name,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12.5,
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        InkWell(
                                          onTap: widget.onOpenClass == null
                                              ? null
                                              : () => widget.onOpenClass!(
                                                  s.classId,
                                                ),
                                          child: Text(
                                            lookup.className(s.classId),
                                            style: TextStyle(
                                              fontSize: 12,
                                              decoration:
                                                  widget.onOpenClass == null
                                                  ? TextDecoration.none
                                                  : TextDecoration.underline,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: s.isPractical
                                                ? const Color(
                                                    0xFFF59E0B,
                                                  ).withValues(alpha: 0.12)
                                                : const Color(
                                                    0xFF109F83,
                                                  ).withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          child: Text(
                                            s.type,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: s.isPractical
                                                  ? const Color(0xFFD97706)
                                                  : const Color(0xFF109F83),
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          s.syllabus?.isNotEmpty == true
                                              ? s.syllabus!
                                              : '—',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                s.syllabus?.isNotEmpty == true
                                                ? (isDark
                                                      ? Colors.white70
                                                      : const Color(0xFF334155))
                                                : Colors.grey,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          lookup.teacherName(s.teacherId),
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
                                            color:
                                                (_isAssigned(s)
                                                        ? const Color(
                                                            0xFF109F83,
                                                          )
                                                        : const Color(
                                                            0xFF94A3B8,
                                                          ))
                                                    .withValues(alpha: 0.14),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: Text(
                                            _isAssigned(s)
                                                ? 'Assigned'
                                                : 'Not Assigned',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 11,
                                              color: _isAssigned(s)
                                                  ? const Color(0xFF109F83)
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (perms.canManageSubjects)
                                        DataCell(
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.edit_outlined,
                                                  size: 16,
                                                ),
                                                tooltip: 'Edit Subject',
                                                onPressed: () =>
                                                    _openSubjectModal(
                                                      context,
                                                      ref,
                                                      lookup,
                                                      existing: s,
                                                    ),
                                              ),
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.delete_outline,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                tooltip: 'Delete Subject',
                                                onPressed: () async {
                                                  if (await confirmDelete(
                                                    context,
                                                    s.name,
                                                  )) {
                                                    if (!context.mounted)
                                                      return;
                                                    await runClassesAction(
                                                      context,
                                                      () => ref
                                                          .read(
                                                            subjectsControllerProvider
                                                                .notifier,
                                                          )
                                                          .delete(s.id),
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

  /// Inline modal form to add or edit subject without navigating away
  Future<void> _openSubjectModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    SubjectModel? existing,
  }) => openSubjectModal(
    context,
    ref,
    lookup,
    existing: existing,
    presetClassId: _selectedClassFilter != 'all' ? _selectedClassFilter : null,
  );
}

Future<void> openSubjectModal(
  BuildContext context,
  WidgetRef ref,
  ClassesLookup lookup, {
  SubjectModel? existing,
  String? presetClassId,
}) async {
  String? teacherId = existing?.teacherId;
  var classId =
      existing?.classId ??
      (presetClassId != null && lookup.classes.any((c) => c.id == presetClassId)
          ? presetClassId
          : lookup.classes.first.id);
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final codeCtrl = TextEditingController(text: existing?.code ?? '');
  var type = existing?.type ?? 'Theory';
  final syllabusCtrl = TextEditingController(text: existing?.syllabus ?? '');
  String? formError;

  await showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setDialogState) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                existing == null
                    ? Icons.add_circle_outline
                    : Icons.edit_outlined,
                color: const Color(0xFF109F83),
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                existing == null ? 'Add Subject' : 'Edit Subject',
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
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  // Class selector containing created classes
                  const Text(
                    'Class *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  SearchableIdDropdown(
                    label: 'Class',
                    inlineLabel: false,
                    allowNone: false,
                    value: classId,
                    options: {for (final c in lookup.classes) c.id: c.name},
                    onChanged: (v) {
                      if (v != null) setDialogState(() => classId = v);
                    },
                  ),
                  const SizedBox(height: 12),

                  // Quick suggestion chips for standard subjects
                  const Text(
                    'Quick Select Subject:',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children:
                        [
                          'Mathematics',
                          'Science',
                          'English',
                          'Social Studies',
                          'Physics',
                          'Chemistry',
                          'Biology',
                        ].map((preset) {
                          return ActionChip(
                            label: Text(
                              preset,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            onPressed: () {
                              setDialogState(() {
                                nameCtrl.text = preset;
                                if (codeCtrl.text.isEmpty) {
                                  codeCtrl.text =
                                      '${preset.substring(0, 3).toUpperCase()}-101';
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 10),

                  // Subject Name
                  const Text(
                    'Subject Name *',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Mathematics, Science, English',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (v) {
                      if (codeCtrl.text.isEmpty && v.trim().length >= 3) {
                        codeCtrl.text =
                            '${v.trim().substring(0, 3).toUpperCase()}-101';
                      }
                    },
                  ),
                  const SizedBox(height: 12),

                  // Subject Code
                  const Text(
                    'Subject Code (auto-generated if empty)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: codeCtrl,
                    decoration: const InputDecoration(
                      hintText: 'MTH-101',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subject Type - Theory / Practical
                  const Text(
                    'Subject Type',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  DropdownButtonFormField<String>(
                    value: type,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Theory',
                        child: Text(
                          'Theory (Standard Academic)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'Practical',
                        child: Text(
                          'Practical / Lab',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialogState(() => type = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Assigned Teacher',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  SearchableIdDropdown(
                    label: 'Assigned Teacher',
                    inlineLabel: false,
                    value: teacherId,
                    options: {for (final t in lookup.teachers) t.id: t.name},
                    onChanged: (v) => setDialogState(() => teacherId = v),
                  ),
                  const SizedBox(height: 12),

                  // Syllabus
                  const Text(
                    'Syllabus / Outline (optional)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    controller: syllabusCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Units 1-5, Algebra, Geometry basics',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                final name = nameCtrl.text.trim();
                var code = codeCtrl.text.trim();
                if (name.isEmpty) {
                  setDialogState(() => formError = 'Subject name is required');
                  return;
                }
                if (code.isEmpty) {
                  code = name.length >= 3
                      ? '${name.substring(0, 3).toUpperCase()}-101'
                      : '${name.toUpperCase()}-101';
                }

                try {
                  final model = SubjectModel(
                    id: existing?.id ?? '',
                    classId: classId,
                    name: name,
                    code: code,
                    type: type,
                    syllabus: syllabusCtrl.text.trim().isNotEmpty
                        ? syllabusCtrl.text.trim()
                        : null,
                    teacherId: teacherId,
                  );
                  await ref
                      .read(subjectsControllerProvider.notifier)
                      .save(model, isNew: existing == null);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    showCompactSnackBar(
                      context,
                      existing == null
                          ? 'Subject "$name" created successfully'
                          : 'Subject updated successfully',
                    );
                  }
                } catch (e) {
                  setDialogState(() {
                    formError = e
                        .toString()
                        .replaceAll('Exception:', '')
                        .replaceAll('ClassesDataException:', '')
                        .trim();
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
