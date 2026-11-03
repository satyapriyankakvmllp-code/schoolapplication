import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/sections_controller.dart';
import '../../domain/section_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';
import 'section_details_view.dart';

/// Sections Management Screen with Class, Section Name, Room Number,
/// working search filter, and duplicate prevention for the same class.
class SectionsManagementScreen extends ConsumerStatefulWidget {
  final String? initialClassId;
  final String? initialSectionId;
  final ValueChanged<String>? onOpenClassroom;
  final ValueChanged<String>? onOpenClass;
  final ValueChanged<String>? onOpenStaff;

  const SectionsManagementScreen({
    super.key,
    this.initialClassId,
    this.initialSectionId,
    this.onOpenClassroom,
    this.onOpenClass,
    this.onOpenStaff,
  });

  @override
  ConsumerState<SectionsManagementScreen> createState() =>
      _SectionsManagementScreenState();
}

class _SectionsManagementScreenState
    extends ConsumerState<SectionsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClassFilter = 'all';
  String _selectedStatusFilter = 'All';
  String? _selectedSectionId;
  int? _sortColumn;
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialClassId != null && widget.initialClassId!.isNotEmpty) {
      _selectedClassFilter = widget.initialClassId!;
    }
    _selectedSectionId = widget.initialSectionId;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void didUpdateWidget(covariant SectionsManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialClassId != oldWidget.initialClassId &&
        widget.initialClassId != null &&
        widget.initialClassId!.isNotEmpty) {
      setState(() {
        _selectedClassFilter = widget.initialClassId!;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  DataColumn _buildSortableColumn(String title, int columnIndex, bool isDark) {
    final isSorted = _sortColumn == columnIndex;
    final activeColor = isDark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF0284C7);
    final inactiveColor = isDark
        ? const Color(0xFF64748B)
        : const Color(0xFF94A3B8);

    return DataColumn(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                key: ValueKey('sections-sort-$columnIndex-asc'),
                onTap: () => setState(() {
                  _sortColumn = columnIndex;
                  _sortAscending = true;
                }),
                child: Icon(
                  Icons.arrow_drop_up,
                  size: 15,
                  color: isSorted && _sortAscending
                      ? activeColor
                      : inactiveColor,
                ),
              ),
              InkWell(
                key: ValueKey('sections-sort-$columnIndex-desc'),
                onTap: () => setState(() {
                  _sortColumn = columnIndex;
                  _sortAscending = false;
                }),
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 15,
                  color: isSorted && !_sortAscending
                      ? activeColor
                      : inactiveColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final sectionsAsync = ref.watch(sectionsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: _selectedSectionId != null
            ? SectionDetailsView(
                sectionId: _selectedSectionId!,
                breadcrumbBase: 'Dashboard / Classes / Sections',
                backButtonText: 'Back to Sections',
                onBack: () => setState(() => _selectedSectionId = null),
              )
            : Column(
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
                              'Sections',
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
                              'Dashboard / Classes / Sections',
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
                      if (perms.canManageSections)
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
                            'Add Section',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: lookup.classes.isEmpty
                              ? null
                              : () => _openSectionModal(context, ref, lookup),
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
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.04,
                          ),
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
                              'Section Directory',
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
                                // Class Filter Dropdown (Test: When selecting Class 1, only its sections show)
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
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
                                          setState(
                                            () => _selectedClassFilter = v,
                                          );
                                      },
                                    ),
                                  ),
                                ),
                                // Status filter, right next to the All Classes filter
                                Container(
                                  height: 34,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                  ),
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
                                      value: _selectedStatusFilter,
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
                                          child: Text('Status: All'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Active',
                                          child: Text('Status: Active'),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Inactive',
                                          child: Text('Status: Inactive'),
                                        ),
                                      ],
                                      onChanged: (v) {
                                        if (v != null)
                                          setState(
                                            () => _selectedStatusFilter = v,
                                          );
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
                                        hintText: 'Search sections...',
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
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 0,
                                            ),
                                        filled: true,
                                        fillColor: isDark
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF8FAFC),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
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
                        sectionsAsync.when(
                          data: (items) {
                            final allAdmissions =
                                ref.watch(admissionsListProvider).valueOrNull ??
                                const [];

                            List<dynamic> studentsForSection(
                              SectionModel section,
                            ) {
                              final normSectionClass = lookup
                                  .className(section.classId)
                                  .toLowerCase()
                                  .replaceAll('class', '')
                                  .replaceAll('th', '')
                                  .replaceAll('st', '')
                                  .replaceAll('nd', '')
                                  .replaceAll('rd', '')
                                  .trim();
                              return allAdmissions.where((adm) {
                                final matchesSectionId =
                                    adm.student.sectionId == section.id;
                                final normStudentClass = adm.student.className
                                    .toLowerCase()
                                    .replaceAll('class', '')
                                    .replaceAll('th', '')
                                    .trim();
                                final matchesClassAndSection =
                                    (adm.student.currentClassId ==
                                            section.classId ||
                                        normStudentClass == normSectionClass) &&
                                    adm.student.section.toUpperCase() ==
                                        section.name.toUpperCase();
                                return matchesSectionId ||
                                    matchesClassAndSection;
                              }).toList();
                            }

                            final filtered = items.where((s) {
                              if (_selectedClassFilter != 'all' &&
                                  s.classId != _selectedClassFilter)
                                return false;
                              if (_selectedStatusFilter != 'All' &&
                                  s.status.toLowerCase() !=
                                      _selectedStatusFilter.toLowerCase())
                                return false;
                              if (_searchQuery.isEmpty) return true;
                              final className = lookup
                                  .className(s.classId)
                                  .toLowerCase();
                              final secName = s.name.toLowerCase();
                              final room = lookup
                                  .roomName(s.classroomId)
                                  .toLowerCase();
                              final teacher = lookup
                                  .teacherName(s.classTeacherId)
                                  .toLowerCase();
                              return className.contains(_searchQuery) ||
                                  secName.contains(_searchQuery) ||
                                  room.contains(_searchQuery) ||
                                  teacher.contains(_searchQuery);
                            }).toList();

                            if (_sortColumn != null) {
                              filtered.sort((a, b) {
                                final comparison = switch (_sortColumn) {
                                  0 =>
                                    lookup
                                        .className(a.classId)
                                        .toLowerCase()
                                        .compareTo(
                                          lookup
                                              .className(b.classId)
                                              .toLowerCase(),
                                        ),
                                  1 => a.name.toLowerCase().compareTo(
                                    b.name.toLowerCase(),
                                  ),
                                  2 =>
                                    lookup
                                        .teacherName(a.classTeacherId)
                                        .toLowerCase()
                                        .compareTo(
                                          lookup
                                              .teacherName(b.classTeacherId)
                                              .toLowerCase(),
                                        ),
                                  3 =>
                                    lookup
                                        .roomName(a.classroomId)
                                        .toLowerCase()
                                        .compareTo(
                                          lookup
                                              .roomName(b.classroomId)
                                              .toLowerCase(),
                                        ),
                                  4 => studentsForSection(a).length.compareTo(
                                    studentsForSection(b).length,
                                  ),
                                  5 => a.status.toLowerCase().compareTo(
                                    b.status.toLowerCase(),
                                  ),
                                  _ => 0,
                                };
                                return _sortAscending
                                    ? comparison
                                    : -comparison;
                              });
                            }

                            if (filtered.isEmpty) {
                              return Container(
                                padding: const EdgeInsets.all(32),
                                alignment: Alignment.center,
                                child: Text(
                                  _searchQuery.isNotEmpty
                                      ? 'No sections matching "$_searchQuery"'
                                      : 'No sections enrolled yet.',
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
                                          ? 600
                                          : (screenWidth - (isMobile ? 50 : 80))
                                                .clamp(750, 2400),
                                    ),
                                    child: DataTable(
                                      showCheckboxColumn: false,
                                      horizontalMargin: 16,
                                      columnSpacing: 24,
                                      headingRowHeight: 40,
                                      dataRowMinHeight: 44,
                                      dataRowMaxHeight: 50,
                                      headingRowColor: WidgetStateProperty.all(
                                        isDark
                                            ? const Color(0xFF0F172A)
                                            : const Color(0xFFF8FAFC),
                                      ),
                                      columns: [
                                        _buildSortableColumn(
                                          'Class',
                                          0,
                                          isDark,
                                        ),
                                        _buildSortableColumn(
                                          'Section Name',
                                          1,
                                          isDark,
                                        ),
                                        _buildSortableColumn(
                                          'Class Teacher',
                                          2,
                                          isDark,
                                        ),
                                        _buildSortableColumn(
                                          'Room Number',
                                          3,
                                          isDark,
                                        ),
                                        _buildSortableColumn(
                                          'Enrolled',
                                          4,
                                          isDark,
                                        ),
                                        _buildSortableColumn(
                                          'Status',
                                          5,
                                          isDark,
                                        ),
                                        if (perms.canManageSections)
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
                                        final sectionStudents =
                                            studentsForSection(s);

                                        return DataRow(
                                          cells: [
                                            DataCell(
                                              InkWell(
                                                onTap:
                                                    widget.onOpenClass == null
                                                    ? null
                                                    : () => widget.onOpenClass!(
                                                        s.classId,
                                                      ),
                                                child: Text(
                                                  lookup.className(s.classId),
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12.5,
                                                    color:
                                                        widget.onOpenClass !=
                                                            null
                                                        ? const Color(
                                                            0xFF109F83,
                                                          )
                                                        : (isDark
                                                              ? Colors.white
                                                              : const Color(
                                                                  0xFF0F172A,
                                                                )),
                                                    decoration:
                                                        widget.onOpenClass !=
                                                            null
                                                        ? TextDecoration
                                                              .underline
                                                        : TextDecoration.none,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                onTap: () => setState(
                                                  () =>
                                                      _selectedSectionId = s.id,
                                                ),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color: const Color(
                                                      0xFF109F83,
                                                    ).withValues(alpha: 0.1),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          4,
                                                        ),
                                                  ),
                                                  child: Text(
                                                    'Section ${s.name}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      decoration: TextDecoration
                                                          .underline,
                                                      color: Color(0xFF109F83),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Builder(
                                                builder: (context) {
                                                  final teacherId =
                                                      s.classTeacherId ==
                                                              null ||
                                                          s
                                                              .classTeacherId!
                                                              .isEmpty
                                                      ? null
                                                      : lookup
                                                            .canonicalTeacherId(
                                                              s.classTeacherId!,
                                                            );
                                                  final teacherName =
                                                      teacherId == null
                                                      ? 'Unassigned'
                                                      : lookup.teacherName(
                                                          teacherId,
                                                        );
                                                  final canOpenTeacher =
                                                      perms.isAdmin &&
                                                      teacherId != null &&
                                                      lookup.teacherById(
                                                            teacherId,
                                                          ) !=
                                                          null &&
                                                      widget.onOpenStaff !=
                                                          null;

                                                  return InkWell(
                                                    onTap: canOpenTeacher
                                                        ? () =>
                                                              widget
                                                                  .onOpenStaff!(
                                                                teacherId,
                                                              )
                                                        : null,
                                                    child: Text(
                                                      teacherName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: canOpenTeacher
                                                            ? const Color(
                                                                0xFF109F83,
                                                              )
                                                            : (teacherId == null
                                                                  ? Colors.grey
                                                                  : (isDark
                                                                        ? Colors
                                                                              .white70
                                                                        : const Color(
                                                                            0xFF334155,
                                                                          ))),
                                                        decoration:
                                                            canOpenTeacher
                                                            ? TextDecoration
                                                                  .underline
                                                            : TextDecoration
                                                                  .none,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            DataCell(
                                              Builder(
                                                builder: (context) {
                                                  final room = lookup.classrooms
                                                      .where(
                                                        (room) =>
                                                            room.id ==
                                                            s.classroomId,
                                                      )
                                                      .firstOrNull;
                                                  final roomName =
                                                      room?.name ??
                                                      lookup.roomName(
                                                        s.classroomId,
                                                      );
                                                  final canOpenRoom =
                                                      s.classroomId != null &&
                                                      s
                                                          .classroomId!
                                                          .isNotEmpty &&
                                                      room != null &&
                                                      widget.onOpenClassroom !=
                                                          null;

                                                  return InkWell(
                                                    onTap: canOpenRoom
                                                        ? () =>
                                                              widget
                                                                  .onOpenClassroom!(
                                                                s.classroomId!,
                                                              )
                                                        : null,
                                                    child: Text(
                                                      roomName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: canOpenRoom
                                                            ? const Color(
                                                                0xFF109F83,
                                                              )
                                                            : (isDark
                                                                  ? Colors
                                                                        .white70
                                                                  : const Color(
                                                                      0xFF334155,
                                                                    )),
                                                        decoration: canOpenRoom
                                                            ? TextDecoration
                                                                  .underline
                                                            : TextDecoration
                                                                  .none,
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            DataCell(
                                              InkWell(
                                                onTap: sectionStudents.isEmpty
                                                    ? null
                                                    : () =>
                                                          _showSectionStudentsDialog(
                                                            context,
                                                            s,
                                                            sectionStudents,
                                                            lookup,
                                                            isDark,
                                                          ),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                child: Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 3,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    color:
                                                        sectionStudents
                                                            .isNotEmpty
                                                        ? const Color(
                                                            0xFF109F83,
                                                          ).withValues(
                                                            alpha: 0.12,
                                                          )
                                                        : (isDark
                                                              ? const Color(
                                                                  0xFF334155,
                                                                )
                                                              : const Color(
                                                                  0xFFF1F5F9,
                                                                )),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          6,
                                                        ),
                                                    border: Border.all(
                                                      color:
                                                          sectionStudents
                                                              .isNotEmpty
                                                          ? const Color(
                                                              0xFF109F83,
                                                            ).withValues(
                                                              alpha: 0.3,
                                                            )
                                                          : Colors.transparent,
                                                    ),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.people_outline,
                                                        size: 13,
                                                        color:
                                                            sectionStudents
                                                                .isNotEmpty
                                                            ? const Color(
                                                                0xFF109F83,
                                                              )
                                                            : Colors.grey,
                                                      ),
                                                      const SizedBox(width: 4),
                                                      Builder(
                                                        builder: (context) {
                                                          final parentClass =
                                                              lookup.classes
                                                                  .where(
                                                                    (c) =>
                                                                        c.id ==
                                                                        s.classId,
                                                                  )
                                                                  .firstOrNull;
                                                          final room = lookup
                                                              .classrooms
                                                              .where(
                                                                (r) =>
                                                                    r.id ==
                                                                    s.classroomId,
                                                              )
                                                              .firstOrNull;
                                                          final secCapacity =
                                                              (parentClass !=
                                                                      null &&
                                                                  parentClass
                                                                          .capacity >
                                                                      0)
                                                              ? (s.capacity >
                                                                            0 &&
                                                                        s.capacity !=
                                                                            (room?.capacity ??
                                                                                40) &&
                                                                        s.capacity !=
                                                                            40
                                                                    ? s.capacity
                                                                    : parentClass
                                                                          .capacity)
                                                              : (s.capacity > 0
                                                                    ? s.capacity
                                                                    : 20);
                                                          return Text(
                                                            '${sectionStudents.length} / $secCapacity',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                              color:
                                                                  sectionStudents
                                                                      .isNotEmpty
                                                                  ? const Color(
                                                                      0xFF109F83,
                                                                    )
                                                                  : Colors.grey,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                            DataCell(
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 3,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color:
                                                      (s.isActive
                                                              ? const Color(
                                                                  0xFF10B981,
                                                                )
                                                              : const Color(
                                                                  0xFFF59E0B,
                                                                ))
                                                          .withValues(
                                                            alpha: 0.12,
                                                          ),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 3,
                                                      backgroundColor:
                                                          s.isActive
                                                          ? const Color(
                                                              0xFF10B981,
                                                            )
                                                          : const Color(
                                                              0xFFF59E0B,
                                                            ),
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      s.status,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: s.isActive
                                                            ? const Color(
                                                                0xFF10B981,
                                                              )
                                                            : const Color(
                                                                0xFFF59E0B,
                                                              ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            if (perms.canManageSections)
                                              DataCell(
                                                PopupMenuButton<String>(
                                                  icon: const Icon(
                                                    Icons.more_vert,
                                                    size: 18,
                                                  ),
                                                  padding: EdgeInsets.zero,
                                                  itemBuilder: (ctx) => [
                                                    const PopupMenuItem(
                                                      value: 'edit',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons.edit_outlined,
                                                            size: 15,
                                                            color: Color(
                                                              0xFF3B82F6,
                                                            ),
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Edit',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'toggle_status',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            s.isActive
                                                                ? Icons
                                                                      .block_outlined
                                                                : Icons
                                                                      .check_circle_outline,
                                                            size: 15,
                                                            color: s.isActive
                                                                ? const Color(
                                                                    0xFFF59E0B,
                                                                  )
                                                                : const Color(
                                                                    0xFF10B981,
                                                                  ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Text(
                                                            s.isActive
                                                                ? 'Deactivate'
                                                                : 'Activate',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                    const PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .delete_outline,
                                                            size: 15,
                                                            color: Colors.red,
                                                          ),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Delete',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: Colors.red,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                  onSelected: (action) async {
                                                    if (action == 'edit') {
                                                      _openSectionModal(
                                                        context,
                                                        ref,
                                                        lookup,
                                                        existing: s,
                                                      );
                                                    } else if (action ==
                                                        'toggle_status') {
                                                      final next = s.isActive
                                                          ? 'Inactive'
                                                          : 'Active';
                                                      await runClassesAction(
                                                        context,
                                                        () => ref
                                                            .read(
                                                              sectionsControllerProvider
                                                                  .notifier,
                                                            )
                                                            .save(
                                                              s.copyWith(
                                                                status: next,
                                                              ),
                                                              isNew: false,
                                                            ),
                                                      );
                                                      if (context.mounted) {
                                                        showCompactSnackBar(
                                                          context,
                                                          'Section ${s.name} marked as $next',
                                                          backgroundColor:
                                                              next == 'Active'
                                                              ? const Color(
                                                                  0xFF10B981,
                                                                )
                                                              : const Color(
                                                                  0xFFF59E0B,
                                                                ),
                                                        );
                                                      }
                                                    } else if (action ==
                                                        'delete') {
                                                      if (await confirmDelete(
                                                        context,
                                                        'Section ${s.name}',
                                                      )) {
                                                        if (!context.mounted)
                                                          return;
                                                        await runClassesAction(
                                                          context,
                                                          () => ref
                                                              .read(
                                                                sectionsControllerProvider
                                                                    .notifier,
                                                              )
                                                              .delete(s.id),
                                                        );
                                                      }
                                                    }
                                                  },
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

  /// Inline modal form to add or edit section without navigating away
  Future<void> _openSectionModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    SectionModel? existing,
  }) => openSectionModal(context, ref, lookup, existing: existing);

  void _showSectionStudentsDialog(
    BuildContext context,
    SectionModel section,
    List<dynamic> students,
    ClassesLookup lookup,
    bool isDark,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF109F83).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.groups,
                  color: Color(0xFF109F83),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Section ${section.name} Enrolled Students',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '${lookup.className(section.classId)} · ${students.length} enrolled',
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
            ],
          ),
          content: SizedBox(
            width: 480,
            child: students.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No students currently enrolled in this section.',
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: students.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final st = students[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF109F83,
                          ).withValues(alpha: 0.15),
                          child: Text(
                            st.user.firstName.isNotEmpty
                                ? st.user.firstName[0].toUpperCase()
                                : 'S',
                            style: const TextStyle(
                              color: Color(0xFF109F83),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          st.user.fullName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          'Adm No: ${st.student.admissionNumber} · Roll: ${st.student.rollNumber ?? '—'}',
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF10B981,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Enrolled',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

Future<void> openSectionModal(
  BuildContext context,
  WidgetRef ref,
  ClassesLookup lookup, {
  SectionModel? existing,
  String? presetClassId,
}) async {
  var classId =
      existing?.classId ??
      (presetClassId != null && lookup.classes.any((c) => c.id == presetClassId)
          ? presetClassId
          : (lookup.classes.isNotEmpty ? lookup.classes.first.id : ''));
  final nameCtrl = TextEditingController(text: existing?.name ?? '');
  final initialClassModel = lookup.classes
      .where((c) => c.id == classId)
      .firstOrNull;
  final capacityCtrl = TextEditingController(
    text: (existing != null && existing.capacity > 0)
        ? '${existing.capacity}'
        : (initialClassModel != null && initialClassModel.capacity > 0
              ? '${initialClassModel.capacity}'
              : '20'),
  );
  String? roomId =
      existing?.classroomId ??
      (classId.isNotEmpty
          ? lookup.classes
                .where((c) => c.id == classId)
                .firstOrNull
                ?.classroomId
          : null);
  final canonicalTeacher = lookup.canonicalTeacherId(
    existing?.classTeacherId ?? '',
  );
  String? teacherId = canonicalTeacher.isEmpty ? null : canonicalTeacher;
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
                existing == null ? 'Add Section' : 'Edit Section',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
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
                        // 1. Class Dropdown
                        const Text(
                          'Class',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (lookup.classes.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade300),
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
                                    'No classes available. Please create a class first.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<String>(
                            key: const ValueKey('section-class-dropdown'),
                            isExpanded: true,
                            initialValue:
                                classId.isNotEmpty &&
                                    lookup.classes.any((c) => c.id == classId)
                                ? classId
                                : lookup.classes.first.id,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            items: lookup.classes.map((c) {
                              return DropdownMenuItem<String>(
                                value: c.id,
                                child: Text(
                                  '${c.name} (${c.code.isNotEmpty ? c.code : c.id})',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) {
                                setDialogState(() {
                                  classId = v;
                                  roomId = lookup.classes
                                      .where((c) => c.id == v)
                                      .firstOrNull
                                      ?.classroomId;
                                });
                              }
                            },
                          ),
                        const SizedBox(height: 12),

                        // 2. Classroom / Room Number Dropdown
                        const Text(
                          'Room Number',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (lookup.classrooms.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.amber.shade300),
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
                                    'No classrooms available. Please create a classroom in Classrooms module first.',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          DropdownButtonFormField<String?>(
                            key: ValueKey('section-room-dropdown-$roomId'),
                            isExpanded: true,
                            initialValue:
                                (roomId != null &&
                                    lookup.classrooms.any(
                                      (r) => r.id == roomId,
                                    ))
                                ? roomId
                                : null,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                            ),
                            hint: const Text(
                              'Select Classroom / Room Number',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text(
                                  'None (Select Room)',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              ...lookup.classrooms.map((r) {
                                final blocked = roomsBlockedFor(
                                  classId: classId,
                                  classes: lookup.classes,
                                  sections: lookup.sections,
                                  classrooms: lookup.classrooms,
                                )..remove(existing?.classroomId);
                                final reason = blocked[r.id];
                                final isBlocked = reason != null;
                                return DropdownMenuItem<String?>(
                                  value: r.id,
                                  enabled: !isBlocked,
                                  child: Text(
                                    '${r.name}${r.displayFloor.isNotEmpty && r.displayFloor != '—' ? ' (${r.displayFloor})' : ''} · Capacity: ${r.capacity}${isBlocked ? ' ($reason)' : ''}',
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isBlocked ? Colors.grey : null,
                                    ),
                                  ),
                                );
                              }),
                            ],
                            onChanged: (v) => setDialogState(() => roomId = v),
                          ),
                        const SizedBox(height: 12),

                        const Text(
                          'Section Name (e.g. A, B, C)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: nameCtrl,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            TextInputFormatter.withFunction(
                              (oldValue, newValue) => newValue.copyWith(
                                text: newValue.text.toUpperCase(),
                              ),
                            ),
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Enter section (e.g. A, B, C)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Section Strength / Capacity Field
                        const Text(
                          'Section Strength / Capacity',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        TextFormField(
                          controller: capacityCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: const InputDecoration(
                            hintText: 'Enter section strength (e.g. 20)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Class Teacher (Optional) - from the Staff Directory
                        SearchableIdDropdown(
                          label: 'Class Teacher (Optional)',
                          value: teacherId,
                          options: {
                            for (final t in lookup.teachers) t.id: t.name,
                          },
                          onChanged: (v) => setDialogState(() => teacherId = v),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
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
                // "a" and "A" are the same section: always stored upper-case.
                final sectionName = nameCtrl.text.trim().toUpperCase();
                if (sectionName.isEmpty) {
                  setDialogState(() => formError = 'Section name is required');
                  return;
                }
                if (classId.isEmpty) {
                  setDialogState(() => formError = 'Please select a class.');
                  return;
                }
                // Duplicate check for the same class
                final isDuplicate = lookup.sections.any(
                  (s) =>
                      (existing == null || s.id != existing.id) &&
                      s.classId == classId &&
                      s.name.trim().toLowerCase() == sectionName.toLowerCase(),
                );
                if (isDuplicate) {
                  setDialogState(
                    () => formError =
                        'Section "$sectionName" already exists for this class.',
                  );
                  return;
                }

                final parsedCapacity =
                    int.tryParse(capacityCtrl.text.trim()) ?? 0;
                if (parsedCapacity <= 0) {
                  setDialogState(
                    () => formError =
                        'Please enter a valid positive strength for the section.',
                  );
                  return;
                }

                if (roomId != null && roomId!.isNotEmpty) {
                  final room = lookup.classrooms
                      .where((r) => r.id == roomId)
                      .firstOrNull;
                  if (room != null &&
                      room.capacity > 0 &&
                      parsedCapacity > room.capacity) {
                    setDialogState(
                      () => formError =
                          'Section strength ($parsedCapacity) cannot exceed selected classroom capacity (${room.capacity}).',
                    );
                    return;
                  }
                }

                try {
                  final model = SectionModel(
                    id: existing?.id ?? '',
                    classId: classId,
                    name: sectionName,
                    capacity: parsedCapacity,
                    classroomId: roomId,
                    classTeacherId: teacherId,
                    status: existing?.status ?? 'Active',
                  );
                  await ref
                      .read(sectionsControllerProvider.notifier)
                      .save(model, isNew: existing == null);

                  // If the class didn't have a classroom directly assigned, sync the assigned classroom to the class as well
                  if (roomId != null && roomId!.isNotEmpty) {
                    final targetClass = lookup.classes
                        .where((c) => c.id == classId)
                        .firstOrNull;
                    if (targetClass != null &&
                        (targetClass.classroomId == null ||
                            targetClass.classroomId!.isEmpty)) {
                      final updatedClass = targetClass.copyWith(
                        classroomId: roomId,
                      );
                      await ref
                          .read(classesControllerProvider.notifier)
                          .save(updatedClass, isNew: false);
                    }
                  }

                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    showCompactSnackBar(
                      context,
                      existing == null
                          ? 'Section created successfully'
                          : 'Section updated',
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
