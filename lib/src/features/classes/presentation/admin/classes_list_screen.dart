import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../admissions/application/admissions_controller.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/sections_controller.dart';
import '../../domain/class_model.dart';
import '../../domain/section_model.dart';
import '../../domain/classes_actor.dart';
import '../teacher/class_details_screen.dart';
import 'section_details_view.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Admin Classes Screen matching Reference Image 5 (PreSkool style)
/// with clean table layout, active search, row-per-page, inline add/edit modal,
/// and duplicate class prevention.
class AdminClassesListScreen extends ConsumerStatefulWidget {
  final String? initialClassId;
  final void Function(String? roomId)? onOpenClassroom;
  final void Function(String? classId)? onOpenSections;
  const AdminClassesListScreen({
    super.key,
    this.initialClassId,
    this.onOpenClassroom,
    this.onOpenSections,
  });

  @override
  ConsumerState<AdminClassesListScreen> createState() =>
      _AdminClassesListScreenState();
}

class _AcademicClassRowItem {
  final ClassModel classModel;
  final SectionModel? section;

  const _AcademicClassRowItem({required this.classModel, this.section});
}

class _AdminClassesListScreenState
    extends ConsumerState<AdminClassesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _classSearchFocusNode = FocusNode();
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;
  String _sortBy = 'A-Z';
  int? _tableSortColumn;
  bool _tableSortAscending = true;
  String _selectedAcademicYear = 'All Years';
  String _selectedStatus = 'All'; // All | Active | Inactive
  String? _selectedClassId;
  String? _selectedSectionId;

  @override
  void initState() {
    super.initState();
    _selectedClassId = widget.initialClassId;
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _currentPage = 1;
      });
    });
  }

  @override
  void didUpdateWidget(covariant AdminClassesListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialClassId != oldWidget.initialClassId &&
        widget.initialClassId != null) {
      setState(() {
        _selectedClassId = widget.initialClassId;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _classSearchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final classesAsync = ref.watch(classesControllerProvider);
    final fieldDefinitions =
        ref.watch(classFieldDefinitionsProvider).valueOrNull ?? const [];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    if (_selectedSectionId != null) {
      return AccessGuard(
        allowed: perms.canAccessClasses,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: SectionDetailsView(
            sectionId: _selectedSectionId!,
            breadcrumbBase: 'Dashboard / Classes / Academic Classes',
            backButtonText: 'Back to Academic Classes',
            onBack: () => setState(() => _selectedSectionId = null),
            onOpenRoom: (roomId) {
              widget.onOpenClassroom?.call(roomId);
            },
          ),
        ),
      );
    }

    if (_selectedClassId != null) {
      return AccessGuard(
        allowed: perms.canAccessClasses,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          child: ClassDetailsBody(
            classId: _selectedClassId!,
            onBack: () => setState(() => _selectedClassId = null),
            onEdit: () {
              final classes = classesAsync.valueOrNull ?? [];
              final target = classes
                  .where((c) => c.id == _selectedClassId)
                  .firstOrNull;
              if (target != null) {
                _openClassModal(context, ref, lookup, existing: target);
              }
            },
          ),
        ),
      );
    }

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 12 : 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Breadcrumb & Action Row
            _buildTopBar(context, ref, lookup, isDark, isMobile),
            const SizedBox(height: 16),

            // Class List Card (PreSkool Style)
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
                  // Card Header: Title + Academic date + Filter + Sort
                  _buildCardHeader(isDark, isMobile),
                  const Divider(height: 24),

                  // Search + Rows Per Page
                  _buildControlsRow(isDark, isMobile),
                  const SizedBox(height: 14),

                  // Table / List Content
                  classesAsync.when(
                    data: (items) => _buildTableContent(
                      items,
                      lookup,
                      fieldDefinitions,
                      isDark,
                      isMobile,
                      screenWidth,
                    ),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Text(
                              'Error: $err',
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () =>
                                  ref.invalidate(classesControllerProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup,
    bool isDark,
    bool isMobile,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Academic Classes',
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Dashboard / Classes / Academic Classes',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? const Color(0xFF94A3B8)
                    : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: 'Refresh',
              onPressed: () => ref.invalidate(classesControllerProvider),
            ),
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.file_download_outlined, size: 20),
                tooltip: 'Export JSON',
                onPressed: () => _showExportJsonDialog(context, ref),
              ),
            if (!isMobile) ...[
              IconButton(
                icon: const Icon(Icons.print_outlined, size: 20),
                tooltip: 'Print',
                onPressed: () {
                  showCompactSnackBar(context, 'Print preview generated');
                },
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.file_download_outlined, size: 16),
                label: const Text(
                  'Export JSON',
                  style: TextStyle(fontSize: 12),
                ),
                onPressed: () => _showExportJsonDialog(context, ref),
              ),
            ],
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF109F83),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 18,
                  vertical: isMobile ? 10 : 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 16),
              label: Text(
                'Add Class',
                style: TextStyle(
                  fontSize: isMobile ? 12 : 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => _openClassModal(context, ref, lookup),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCardHeader(bool isDark, bool isMobile) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'Academic Classes',
          style: TextStyle(
            fontSize: isMobile ? 15 : 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Academic Year Selector / Manager
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedAcademicYear,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'All Years',
                      child: Text('Academic Year: All'),
                    ),
                    DropdownMenuItem(
                      value: '2026-27',
                      child: Text('Academic Year: 2026-27'),
                    ),
                    DropdownMenuItem(
                      value: '2027-28',
                      child: Text('Academic Year: 2027-28'),
                    ),
                    DropdownMenuItem(
                      value: '2028-29',
                      child: Text('Academic Year: 2028-29'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedAcademicYear = v);
                  },
                ),
              ),
            ),
            // Status filter (beside Academic Year)
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStatus,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('Status: All')),
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
                    if (v != null) {
                      setState(() {
                        _selectedStatus = v;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
            // Sort Dropdown
            Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sortBy,
                  isDense: true,
                  icon: const Icon(Icons.arrow_drop_down, size: 18),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A-Z', child: Text('Sort By A-Z')),
                    DropdownMenuItem(
                      value: 'Grade',
                      child: Text('Sort By Grade'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        _sortBy = v;
                        _tableSortColumn = null;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildControlsRow(bool isDark, bool isMobile) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Row Per Page: ',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF334155)
                            : const Color(0xFFE2E8F0),
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _rowsPerPage,
                        isDense: true,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                        items: const [
                          DropdownMenuItem(value: 5, child: Text('5')),
                          DropdownMenuItem(value: 10, child: Text('10')),
                          DropdownMenuItem(value: 20, child: Text('20')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _rowsPerPage = v);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    'Entries',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(child: _buildClassSearchField(isDark: isDark, maxWidth: 280)),
        ],
      );
    }

    return Row(
      children: [
        // Left: Row Per Page
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Row Per Page: ',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF334155)
                      : const Color(0xFFE2E8F0),
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _rowsPerPage,
                  isDense: true,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  items: const [
                    DropdownMenuItem(value: 5, child: Text('5')),
                    DropdownMenuItem(value: 10, child: Text('10')),
                    DropdownMenuItem(value: 20, child: Text('20')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _rowsPerPage = v);
                  },
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Text(
              'Entries',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        // Center: Smaller search bar
        _buildClassSearchField(isDark: isDark, maxWidth: 260),
        const Spacer(),
        // Symmetrical balance widget
        const SizedBox(width: 120),
      ],
    );
  }

  Widget _buildClassSearchField({
    required bool isDark,
    required double maxWidth,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: SizedBox(
        height: 38,
        child: RawAutocomplete<ClassModel>(
          textEditingController: _searchController,
          focusNode: _classSearchFocusNode,
          displayStringForOption: (option) => option.name,
          optionsBuilder: (value) {
            final query = value.text.trim().toLowerCase();
            if (query.isEmpty) return const Iterable<ClassModel>.empty();
            final classes =
                ref.read(classesControllerProvider).valueOrNull ??
                const <ClassModel>[];
            return classes
                .where((item) => item.name.toLowerCase().contains(query))
                .take(8);
          },
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(6),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: 240),
                child: ListView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  children: [
                    for (final option in options)
                      ListTile(
                        dense: true,
                        title: Text(
                          option.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                        subtitle: Text(
                          option.code,
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => onSelected(option),
                      ),
                  ],
                ),
              ),
            ),
          ),
          fieldViewBuilder:
              (context, controller, focusNode, onFieldSubmitted) => TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search classes...',
                  hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 16,
                    color: Colors.grey,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 14),
                          onPressed: _searchController.clear,
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
                ),
              ),
        ),
      ),
    );
  }

  DataColumn _buildSortableColumn(String title, int columnIndex, bool isDark) {
    final isSorted = _tableSortColumn == columnIndex;
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
                key: ValueKey('academic-class-sort-$columnIndex-asc'),
                onTap: () => setState(() {
                  _tableSortColumn = columnIndex;
                  _tableSortAscending = true;
                  _currentPage = 1;
                }),
                child: Icon(
                  Icons.arrow_drop_up,
                  size: 15,
                  color: isSorted && _tableSortAscending
                      ? activeColor
                      : inactiveColor,
                ),
              ),
              InkWell(
                key: ValueKey('academic-class-sort-$columnIndex-desc'),
                onTap: () => setState(() {
                  _tableSortColumn = columnIndex;
                  _tableSortAscending = false;
                  _currentPage = 1;
                }),
                child: Icon(
                  Icons.arrow_drop_down,
                  size: 15,
                  color: isSorted && !_tableSortAscending
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

  Widget _buildTableContent(
    List<ClassModel> allItems,
    ClassesLookup lookup,
    List<Map<String, dynamic>> fieldDefinitions,
    bool isDark,
    bool isMobile,
    double screenWidth,
  ) {
    final perms = ref.watch(classesPermissionsProvider);
    final allAdmissions =
        ref.watch(admissionsListProvider).valueOrNull ?? const [];

    // Enrolled student count dynamic calculator
    int getEnrolledCount(ClassModel c) {
      return allAdmissions.where((a) {
        final matchesId = a.student.currentClassId == c.id;
        final normStudentClass = a.student.className
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .trim();
        final normClassName = c.name
            .toLowerCase()
            .replaceAll('class', '')
            .replaceAll('th', '')
            .replaceAll('st', '')
            .replaceAll('nd', '')
            .replaceAll('rd', '')
            .trim();
        return matchesId || normStudentClass == normClassName;
      }).length;
    }

    // 1. Filter
    var filtered = allItems.where((c) {
      if (_selectedAcademicYear != 'All Years') {
        final yearNormalized = c.academicYear
            .replaceAll('2026-2027', '2026-27')
            .replaceAll('2027-2028', '2027-28');
        final filterNormalized = _selectedAcademicYear;
        if (!c.academicYear.contains(filterNormalized) &&
            !yearNormalized.contains(filterNormalized)) {
          return false;
        }
      }
      if (_selectedStatus != 'All' &&
          c.status.toLowerCase() != _selectedStatus.toLowerCase()) {
        return false;
      }
      if (_searchQuery.isEmpty) return true;
      final name = c.name.toLowerCase();
      final id = c.id.toLowerCase();
      final code = c.code.toLowerCase();
      final year = c.academicYear.toLowerCase();
      final room = lookup.roomName(c.classroomId).toLowerCase();
      final classSections = lookup.sections.where((s) => s.classId == c.id);
      final secNames = classSections.map((s) => s.name.toLowerCase()).join(' ');
      final secRooms = classSections
          .where((s) => s.classroomId != null)
          .map((s) => lookup.roomName(s.classroomId).toLowerCase())
          .join(' ');
      return name.contains(_searchQuery) ||
          id.contains(_searchQuery) ||
          code.contains(_searchQuery) ||
          year.contains(_searchQuery) ||
          room.contains(_searchQuery) ||
          secNames.contains(_searchQuery) ||
          secRooms.contains(_searchQuery);
    }).toList();

    // 2. Sort
    if (_sortBy == 'A-Z') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else {
      filtered.sort((a, b) => a.gradeLevel.compareTo(b.gradeLevel));
    }

    // 3. Expand classes to separate section entries/rows without duplicate classes
    final rowItems = <_AcademicClassRowItem>[];
    for (final c in filtered) {
      final classSections = lookup.sections
          .where((s) => s.classId == c.id)
          .toList();
      classSections.sort((a, b) => a.name.compareTo(b.name));
      if (classSections.isEmpty) {
        rowItems.add(_AcademicClassRowItem(classModel: c, section: null));
      } else {
        for (final sec in classSections) {
          if (_searchQuery.isNotEmpty) {
            final classMatches =
                c.name.toLowerCase().contains(_searchQuery) ||
                c.code.toLowerCase().contains(_searchQuery) ||
                c.academicYear.toLowerCase().contains(_searchQuery) ||
                c.id.toLowerCase().contains(_searchQuery);
            final secNameMatches = sec.name.toLowerCase().contains(
              _searchQuery,
            );
            final secRoomMatches = lookup
                .roomName(sec.classroomId)
                .toLowerCase()
                .contains(_searchQuery);
            if (classMatches || secNameMatches || secRoomMatches) {
              rowItems.add(_AcademicClassRowItem(classModel: c, section: sec));
            }
          } else {
            rowItems.add(_AcademicClassRowItem(classModel: c, section: sec));
          }
        }
      }
    }

    String classCode(_AcademicClassRowItem item) {
      final code = item.classModel.code;
      return code.isNotEmpty
          ? code
          : 'CLS-${item.classModel.gradeLevel > 0 ? item.classModel.gradeLevel : 1}';
    }

    int classStrength(_AcademicClassRowItem item) {
      final section = item.section;
      return section != null && section.capacity > 0
          ? section.capacity
          : (item.classModel.capacity > 0 ? item.classModel.capacity : 0);
    }

    String classroomLabel(_AcademicClassRowItem item) {
      final sectionRoomId = item.section?.classroomId;
      final roomId = sectionRoomId != null && sectionRoomId.isNotEmpty
          ? sectionRoomId
          : item.classModel.classroomId;
      final room = lookup.classrooms.where((r) => r.id == roomId).firstOrNull;
      if (room != null) {
        return '${room.name}${room.displayFloor.isNotEmpty && room.displayFloor != '—' ? ' (${room.displayFloor})' : ''}';
      }
      if (roomId != null && roomId.isNotEmpty) {
        return lookup.roomName(roomId);
      }
      return 'Assign Room';
    }

    String classStatus(_AcademicClassRowItem item) {
      final status = item.classModel.status;
      return status.isNotEmpty
          ? status
          : (item.classModel.isActive ? 'Active' : 'Inactive');
    }

    if (_tableSortColumn != null) {
      rowItems.sort((a, b) {
        final comparison = switch (_tableSortColumn) {
          0 => a.classModel.academicYear.toLowerCase().compareTo(
            b.classModel.academicYear.toLowerCase(),
          ),
          1 => classCode(a).toLowerCase().compareTo(classCode(b).toLowerCase()),
          2 => a.classModel.name.toLowerCase().compareTo(
            b.classModel.name.toLowerCase(),
          ),
          3 => (a.section?.name ?? '—').toLowerCase().compareTo(
            (b.section?.name ?? '—').toLowerCase(),
          ),
          4 => classroomLabel(
            a,
          ).toLowerCase().compareTo(classroomLabel(b).toLowerCase()),
          5 => classStrength(a).compareTo(classStrength(b)),
          6 => classStatus(
            a,
          ).toLowerCase().compareTo(classStatus(b).toLowerCase()),
          _ => 0,
        };
        return _tableSortAscending ? comparison : -comparison;
      });
    }

    if (rowItems.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              Icons.search_off_outlined,
              size: 40,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No classes matching "$_searchQuery"'
                  : 'No classes found',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // 4. Paginate expanded rows
    final totalCount = rowItems.length;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final paged = rowItems.skip(startIndex).take(_rowsPerPage).toList();
    final totalPages = (totalCount / _rowsPerPage).ceil();

    // Responsive Mobile Layout: Modern Card Stack to avoid horizontal scrolling
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final item in paged) ...[
            _buildMobileClassCard(
              item: item,
              lookup: lookup,
              enrolledCount: getEnrolledCount(item.classModel),
              perms: perms,
              isDark: isDark,
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 8),
          _buildPaginationBar(
            startIndex,
            paged.length,
            totalCount,
            totalPages,
            isDark,
          ),
        ],
      );
    }

    // Desktop Layout: Compact 8-column Table
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
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
                  minWidth: (screenWidth - 80).clamp(880, 2400),
                ),
                child: DataTable(
                  showCheckboxColumn: false,
                  horizontalMargin: 16,
                  columnSpacing: 14,
                  headingRowHeight: 40,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 52,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                  columns: [
                    _buildSortableColumn('Academic Year', 0, isDark),
                    _buildSortableColumn('Class Code', 1, isDark),
                    _buildSortableColumn('Class Name', 2, isDark),
                    _buildSortableColumn('Section Name', 3, isDark),
                    _buildSortableColumn('Classroom / Room Number', 4, isDark),
                    _buildSortableColumn('Class Strength', 5, isDark),
                    _buildSortableColumn('Status', 6, isDark),
                    DataColumn(
                      label: Text(
                        'Action',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                  rows: paged.map((item) {
                    final c = item.classModel;
                    final sec = item.section;
                    final displayCode = c.code.isNotEmpty
                        ? c.code
                        : 'CLS-${c.gradeLevel > 0 ? c.gradeLevel : 1}';

                    // Dynamically resolve room from the specific section, falling back to class room
                    final effectiveRoomId =
                        (sec?.classroomId != null &&
                            sec!.classroomId!.isNotEmpty)
                        ? sec.classroomId
                        : c.classroomId;
                    final room = lookup.classrooms
                        .where((r) => r.id == effectiveRoomId)
                        .firstOrNull;
                    final hasRoom =
                        effectiveRoomId != null &&
                        effectiveRoomId.isNotEmpty &&
                        room != null;
                    final roomLabel = hasRoom
                        ? '${room.name}${room.displayFloor.isNotEmpty && room.displayFloor != '—' ? ' (${room.displayFloor})' : ''}'
                        : (effectiveRoomId != null && effectiveRoomId.isNotEmpty
                              ? lookup.roomName(effectiveRoomId)
                              : 'Assign Room');

                    // Section name for this specific entry
                    final sectionDisplay = sec != null ? sec.name : '—';
                    final hasSection = sec != null;

                    // Class Strength: simple numeric value (e.g. 25, not 25/40)
                    final int effectiveStrength =
                        (sec != null && sec.capacity > 0)
                        ? sec.capacity
                        : (c.capacity > 0 ? c.capacity : 0);
                    final String strengthDisplay = effectiveStrength > 0
                        ? '$effectiveStrength'
                        : '—';

                    return DataRow(
                      cells: [
                        // 1. Academic Year
                        DataCell(
                          Text(
                            c.academicYear.isNotEmpty ? c.academicYear : '—',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),

                        // 2. Class Code (Underlined, clickable to Class Details)
                        DataCell(
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () =>
                                setState(() => _selectedClassId = c.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Text(
                                displayCode,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF109F83),
                                  fontWeight: FontWeight.w700,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 3. Class Name (Underlined, clickable to Class Details)
                        DataCell(
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () =>
                                setState(() => _selectedClassId = c.id),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Text(
                                c.name,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? const Color(0xFF34D399)
                                      : const Color(0xFF0D9488),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 4. Section (from Sections module, clickable to Section Details)
                        DataCell(
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              if (sec != null) {
                                setState(() => _selectedSectionId = sec.id);
                              } else if (widget.onOpenSections != null) {
                                widget.onOpenSections!(c.id);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Text(
                                sectionDisplay,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: hasSection
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: hasSection
                                      ? (isDark
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFF0D9488))
                                      : Colors.grey,
                                  decoration: hasSection
                                      ? TextDecoration.underline
                                      : TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // 5. Assigned Classroom (Underlined, clickable to classroom page)
                        DataCell(
                          InkWell(
                            borderRadius: BorderRadius.circular(4),
                            onTap: () {
                              if (hasRoom) {
                                if (widget.onOpenClassroom != null) {
                                  widget.onOpenClassroom!(effectiveRoomId);
                                } else if (perms.canManageClasses) {
                                  _showAssignClassroomDialog(
                                    context,
                                    ref,
                                    lookup,
                                    c,
                                  );
                                }
                              } else if (perms.canManageClasses) {
                                _showAssignClassroomDialog(
                                  context,
                                  ref,
                                  lookup,
                                  c,
                                );
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 2,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.meeting_room_outlined,
                                    size: 14,
                                    color: hasRoom
                                        ? const Color(0xFF109F83)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    roomLabel,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: hasRoom
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: hasRoom
                                          ? (isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A))
                                          : Colors.grey,
                                      decoration: hasRoom
                                          ? TextDecoration.underline
                                          : TextDecoration.none,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // 6. Class Strength (single numeric value: e.g. 25, not 25/40)
                        DataCell(
                          Text(
                            strengthDisplay,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ),

                        // 7. Status
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.isActive
                                  ? const Color(
                                      0xFF10B981,
                                    ).withValues(alpha: 0.1)
                                  : Colors.grey.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: c.isActive
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.3)
                                    : Colors.grey.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              c.status.isNotEmpty
                                  ? c.status
                                  : (c.isActive ? 'Active' : 'Inactive'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: c.isActive
                                    ? const Color(0xFF10B981)
                                    : (isDark
                                          ? Colors.grey.shade400
                                          : Colors.grey.shade700),
                              ),
                            ),
                          ),
                        ),

                        // 8. Action (view for everyone; management for admins)
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            padding: EdgeInsets.zero,
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 15,
                                      color: Color(0xFF109F83),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'View',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (perms.canManageClasses) ...[
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.edit_outlined,
                                        size: 15,
                                        color: Color(0xFF3B82F6),
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        'Edit',
                                        style: TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'toggle_status',
                                  child: Row(
                                    children: [
                                      Icon(
                                        c.isActive
                                            ? Icons.block_outlined
                                            : Icons.check_circle_outline,
                                        size: 15,
                                        color: c.isActive
                                            ? const Color(0xFFF59E0B)
                                            : const Color(0xFF10B981),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        c.isActive ? 'Deactivate' : 'Activate',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline,
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
                            ],
                            onSelected: (action) async {
                              if (action == 'view') {
                                setState(() => _selectedClassId = c.id);
                              } else if (action == 'edit' &&
                                  perms.canManageClasses) {
                                _openClassModal(
                                  context,
                                  ref,
                                  lookup,
                                  existing: c,
                                  existingSection: sec,
                                );
                              } else if (action == 'toggle_status' &&
                                  perms.canManageClasses) {
                                final nextStatus = c.isActive
                                    ? 'Inactive'
                                    : 'Active';
                                await runClassesAction(
                                  context,
                                  () => ref
                                      .read(classesControllerProvider.notifier)
                                      .save(
                                        c.copyWith(status: nextStatus),
                                        isNew: false,
                                      ),
                                  success:
                                      'Class "${c.name}" marked as $nextStatus',
                                );
                              } else if (action == 'delete' &&
                                  perms.canManageClasses) {
                                if (await confirmDelete(context, c.name)) {
                                  if (!mounted) return;
                                  await runClassesAction(
                                    context,
                                    () => ref
                                        .read(
                                          classesControllerProvider.notifier,
                                        )
                                        .delete(c.id),
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
        ),
        const SizedBox(height: 12),
        _buildPaginationBar(
          startIndex,
          paged.length,
          totalCount,
          totalPages,
          isDark,
        ),
      ],
    );
  }

  Widget _buildMobileClassCard({
    required _AcademicClassRowItem item,
    required ClassesLookup lookup,
    required int enrolledCount,
    required ClassesPermissions perms,
    required bool isDark,
  }) {
    final c = item.classModel;
    final sec = item.section;
    final displayCode = c.code.isNotEmpty
        ? c.code
        : 'CLS-${c.gradeLevel > 0 ? c.gradeLevel : 1}';
    final effectiveRoomId =
        (sec?.classroomId != null && sec!.classroomId!.isNotEmpty)
        ? sec.classroomId
        : c.classroomId;
    final room = lookup.classrooms
        .where((r) => r.id == effectiveRoomId)
        .firstOrNull;
    final hasRoom =
        effectiveRoomId != null && effectiveRoomId.isNotEmpty && room != null;
    final roomLabel = hasRoom
        ? '${room.name}${room.displayFloor.isNotEmpty && room.displayFloor != '—' ? ' (${room.displayFloor})' : ''}'
        : (effectiveRoomId != null && effectiveRoomId.isNotEmpty
              ? lookup.roomName(effectiveRoomId)
              : 'Assign Room');

    final sectionDisplay = sec != null ? sec.name : '—';
    final hasSection = sec != null;
    final int effectiveStrength =
        (item.section != null && item.section!.capacity > 0)
        ? item.section!.capacity
        : (c.capacity > 0 ? c.capacity : 0);
    final String strengthDisplay = effectiveStrength > 0
        ? '$effectiveStrength'
        : '—';

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => setState(() => _selectedClassId = c.id),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Class Name, Code, Status, 3-dots
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFF34D399)
                                : const Color(0xFF0D9488),
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF109F83,
                                ).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                displayCode,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF109F83),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: c.isActive
                                    ? const Color(
                                        0xFF10B981,
                                      ).withValues(alpha: 0.1)
                                    : Colors.grey.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: c.isActive
                                      ? const Color(
                                          0xFF10B981,
                                        ).withValues(alpha: 0.3)
                                      : Colors.grey.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                c.status.isNotEmpty
                                    ? c.status
                                    : (c.isActive ? 'Active' : 'Inactive'),
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: c.isActive
                                      ? const Color(0xFF10B981)
                                      : (isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: perms.canManageClasses
                        ? PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            padding: EdgeInsets.zero,
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'view',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.visibility_outlined,
                                      size: 15,
                                      color: Color(0xFF109F83),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'View',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: Color(0xFF3B82F6),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Edit',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_status',
                                child: Row(
                                  children: [
                                    Icon(
                                      c.isActive
                                          ? Icons.block_outlined
                                          : Icons.check_circle_outline,
                                      size: 15,
                                      color: c.isActive
                                          ? const Color(0xFFF59E0B)
                                          : const Color(0xFF10B981),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      c.isActive ? 'Deactivate' : 'Activate',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
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
                              if (action == 'view') {
                                setState(() => _selectedClassId = c.id);
                              } else if (action == 'edit') {
                                _openClassModal(
                                  context,
                                  ref,
                                  lookup,
                                  existing: c,
                                  existingSection: sec,
                                );
                              } else if (action == 'toggle_status') {
                                final nextStatus = c.isActive
                                    ? 'Inactive'
                                    : 'Active';
                                await runClassesAction(
                                  context,
                                  () => ref
                                      .read(classesControllerProvider.notifier)
                                      .save(
                                        c.copyWith(status: nextStatus),
                                        isNew: false,
                                      ),
                                  success:
                                      'Class "${c.name}" marked as $nextStatus',
                                );
                              } else if (action == 'delete') {
                                if (await confirmDelete(context, c.name)) {
                                  if (!mounted) return;
                                  await runClassesAction(
                                    context,
                                    () => ref
                                        .read(
                                          classesControllerProvider.notifier,
                                        )
                                        .delete(c.id),
                                  );
                                }
                              }
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
              const Divider(height: 16),
              // Body Details Grid
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  _buildCardDetailItem(
                    Icons.calendar_today_outlined,
                    'Academic Year',
                    c.academicYear.isNotEmpty ? c.academicYear : '—',
                    isDark,
                  ),
                  _buildCardDetailItem(
                    Icons.groups_outlined,
                    'Section',
                    sectionDisplay,
                    isDark,
                    color: hasSection
                        ? (isDark
                              ? const Color(0xFF34D399)
                              : const Color(0xFF0D9488))
                        : null,
                    onTap: () {
                      if (widget.onOpenSections != null) {
                        widget.onOpenSections!(c.id);
                      }
                    },
                  ),
                  _buildCardDetailItem(
                    Icons.meeting_room_outlined,
                    'Classroom',
                    roomLabel,
                    isDark,
                    onTap: hasRoom
                        ? () {
                            if (widget.onOpenClassroom != null) {
                              widget.onOpenClassroom!(effectiveRoomId);
                            } else {
                              _showAssignClassroomDialog(
                                context,
                                ref,
                                lookup,
                                c,
                              );
                            }
                          }
                        : (perms.canManageClasses
                              ? () => _showAssignClassroomDialog(
                                  context,
                                  ref,
                                  lookup,
                                  c,
                                )
                              : null),
                  ),
                  _buildCardDetailItem(
                    Icons.group_outlined,
                    'Class Strength',
                    strengthDisplay,
                    isDark,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardDetailItem(
    IconData icon,
    String label,
    String value,
    bool isDark, {
    VoidCallback? onTap,
    Color? color,
  }) {
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 13,
          color:
              color ?? (isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$label: ',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color:
                        color ??
                        (isDark ? Colors.white : const Color(0xFF0F172A)),
                    decoration: onTap != null ? TextDecoration.underline : null,
                  ),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(onTap: onTap, child: content);
    }
    return content;
  }

  Widget _buildPaginationBar(
    int startIndex,
    int pagedLength,
    int totalCount,
    int totalPages,
    bool isDark,
  ) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 10,
      children: [
        Text(
          'Showing ${startIndex + 1} to ${(startIndex + pagedLength)} of $totalCount entries',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _currentPage > 1
                    ? () => setState(() => _currentPage--)
                    : null,
                child: const Text('Prev', style: TextStyle(fontSize: 11)),
              ),
              const SizedBox(width: 6),
              for (int p = 1; p <= totalPages; p++)
                InkWell(
                  onTap: () => setState(() => _currentPage = p),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _currentPage == p
                          ? const Color(0xFF109F83)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '$p',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _currentPage == p
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: _currentPage < totalPages
                    ? () => setState(() => _currentPage++)
                    : null,
                child: const Text('Next', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Quick dialog allowing the admin to assign an existing classroom to a class (e.g. Class 10 → Room 101)
  Future<void> _showAssignClassroomDialog(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup,
    ClassModel c,
  ) async {
    String? selectedRoomId = c.classroomId;
    final classrooms = lookup.classrooms;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(
                  Icons.meeting_room_outlined,
                  color: Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Assign Classroom: ${c.name}',
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assign an existing classroom to ${c.name} (e.g. ${c.name} → Room 101):',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: selectedRoomId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Select Classroom',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text(
                          'None (Unassigned)',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                      for (final r in classrooms)
                        DropdownMenuItem<String?>(
                          value: r.id,
                          child: Text(
                            '${r.name} | ${r.displayFloor} | ${r.capacity} Seats (${r.status})',
                            style: const TextStyle(fontSize: 12.5),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (val) {
                      setDialogState(() => selectedRoomId = val);
                    },
                  ),
                  if (selectedRoomId != null) ...[
                    const SizedBox(height: 10),
                    Builder(
                      builder: (_) {
                        final targetRoom = classrooms
                            .where((r) => r.id == selectedRoomId)
                            .firstOrNull;
                        if (targetRoom == null) return const SizedBox.shrink();
                        final isUnavailable =
                            !targetRoom.isAvailable ||
                            targetRoom.status.toLowerCase() ==
                                'not available' ||
                            targetRoom.status.toLowerCase() == 'unavailable';
                        return Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUnavailable
                                ? Colors.red.withValues(alpha: 0.1)
                                : const Color(
                                    0xFF109F83,
                                  ).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isUnavailable
                                  ? Colors.red.shade300
                                  : const Color(
                                      0xFF109F83,
                                    ).withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isUnavailable
                                    ? Icons.info_outline
                                    : Icons.check_circle_outline,
                                size: 14,
                                color: isUnavailable
                                    ? Colors.red
                                    : const Color(0xFF109F83),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  isUnavailable
                                      ? 'Note: This room is currently marked as Not Available.'
                                      : 'Selected: ${targetRoom.name} | ${targetRoom.displayFloor} | ${targetRoom.capacity} Seats',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isUnavailable
                                        ? Colors.red
                                        : const Color(0xFF109F83),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
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
                  final updated = selectedRoomId == null
                      ? c.copyWith(clearClassroom: true)
                      : c.copyWith(classroomId: selectedRoomId);
                  await ref
                      .read(classesControllerProvider.notifier)
                      .save(updated, isNew: false);
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    final roomName = selectedRoomId != null
                        ? lookup.roomName(selectedRoomId)
                        : 'Unassigned';
                    showCompactSnackBar(
                      context,
                      selectedRoomId != null
                          ? '${c.name} assigned to $roomName'
                          : '${c.name} classroom unassigned',
                    );
                  }
                },
                child: const Text('Save Assignment'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Inline modal form to add or edit class directly on the current page without route navigation
  Future<void> _openClassModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    ClassModel? existing,
    SectionModel? existingSection,
  }) async {
    final isNew = existing == null;
    const supportedYears = ['2026-2027', '2027-2028', '2028-2029'];
    final existingYear = existing?.academicYear.trim() ?? '';
    final yearOptions = [
      ...supportedYears,
      if (existingYear.isNotEmpty && !supportedYears.contains(existingYear))
        existingYear,
    ];
    String selectedYear =
        existingYear.isNotEmpty && yearOptions.contains(existingYear)
        ? existingYear
        : supportedYears.first;
    String? selectedClassroomId =
        existingSection?.classroomId ?? existing?.classroomId;
    final blockedRooms = roomsBlockedFor(
      classId: existing?.id,
      classes: lookup.classes,
      sections: lookup.sections,
      classrooms: lookup.classrooms,
    );
    final selectableRooms = lookup.classrooms.where(
      (room) => !blockedRooms.containsKey(room.id),
    );
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final codeCtrl = TextEditingController(text: existing?.code ?? '');
    final initialStrength =
        (existingSection != null && existingSection.capacity > 0)
        ? '${existingSection.capacity}'
        : ((existing?.capacity != null && existing!.capacity > 0)
              ? '${existing.capacity}'
              : '');
    final strengthCtrl = TextEditingController(text: initialStrength);
    String status = existing?.status ?? 'Active';

    final fieldDefinitions = List<Map<String, dynamic>>.from(
      await ref.read(classFieldDefinitionsProvider.future),
    );
    final customFieldControllers = <String, TextEditingController>{
      for (final field in fieldDefinitions)
        field['id'] as String: TextEditingController(
          text: existing?.customFields[field['id']] ?? '',
        ),
    };

    String? formError;
    if (!context.mounted) return;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  isNew ? Icons.add_circle_outline : Icons.edit_outlined,
                  color: const Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  isNew ? 'Add New Class' : 'Edit Class',
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
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                formError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // 1. Academic Year — dropdown
                    const Text(
                      'Academic Year',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: selectedYear,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: yearOptions.map((y) {
                        return DropdownMenuItem<String>(
                          value: y,
                          child: Text(y),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() => selectedYear = v);
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Classroom — optional selection from existing rooms
                    const Text(
                      'Classroom / Room Number',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String?>(
                      key: const ValueKey('class-room-dropdown'),
                      initialValue: selectedClassroomId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        hintText: 'Select a classroom (optional)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('None (Unassigned)'),
                        ),
                        for (final room in selectableRooms)
                          DropdownMenuItem<String?>(
                            value: room.id,
                            child: Text(
                              '${room.name} · ${room.displayFloor} · Capacity: ${room.capacity}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (selectedClassroomId != null &&
                            !lookup.classrooms.any(
                              (room) => room.id == selectedClassroomId,
                            ))
                          DropdownMenuItem<String?>(
                            value: selectedClassroomId,
                            child: Text(
                              'Unavailable room (${lookup.roomName(selectedClassroomId)})',
                            ),
                          ),
                        if (selectedClassroomId != null &&
                            blockedRooms.containsKey(selectedClassroomId) &&
                            lookup.classrooms.any(
                              (room) => room.id == selectedClassroomId,
                            ))
                          DropdownMenuItem<String?>(
                            value: selectedClassroomId,
                            child: Text(
                              '${lookup.roomName(selectedClassroomId)} · ${blockedRooms[selectedClassroomId]}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) {
                        setDialogState(() => selectedClassroomId = value);
                      },
                    ),
                    if (lookup.classrooms.isEmpty) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'No classrooms available. Add a classroom in Class Rooms first.',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // 3. Class Name — text input
                    const Text(
                      'Class Name',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Enter class name (e.g. Class 10)',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (val) {
                        if (codeCtrl.text.isEmpty ||
                            codeCtrl.text.startsWith('CLS-')) {
                          final match = RegExp(r'\d+').firstMatch(val);
                          if (match != null) {
                            codeCtrl.text = 'CLS-${match.group(0)}';
                          }
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 4. Class Code — auto-generated and editable
                    const Text(
                      'Class Code',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. CLS-10',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 5. Class Strength — simple numeric input
                    const Text(
                      'Class Strength',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: strengthCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'e.g. 25',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 6. Status — dropdown with Active and Inactive options
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Active',
                          child: Text('Active'),
                        ),
                        DropdownMenuItem(
                          value: 'Inactive',
                          child: Text('Inactive'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setDialogState(() => status = v);
                      },
                    ),

                    for (final field in fieldDefinitions) ...[
                      const SizedBox(height: 12),
                      Text(
                        field['name'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TextFormField(
                        controller: customFieldControllers[field['id']],
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        ),
                      ),
                    ],
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
                  final finalYear = selectedYear.trim();
                  if (finalYear.isEmpty) {
                    setDialogState(
                      () => formError = 'Academic year is required',
                    );
                    return;
                  }

                  final finalName = nameCtrl.text.trim();
                  if (finalName.isEmpty) {
                    setDialogState(() => formError = 'Class name is required');
                    return;
                  }

                  final strengthVal =
                      int.tryParse(strengthCtrl.text.trim()) ?? 0;
                  if (strengthVal <= 0) {
                    setDialogState(
                      () => formError =
                          'Class strength must be a positive number greater than 0.',
                    );
                    return;
                  }

                  // Auto-derive grade level from class name if available
                  int grade = 1;
                  final digitMatch = RegExp(r'\d+').firstMatch(finalName);
                  if (digitMatch != null) {
                    grade = int.tryParse(digitMatch.group(0)!) ?? 1;
                  } else {
                    grade = existing?.gradeLevel ?? 1;
                  }

                  final finalCode = codeCtrl.text.trim().isNotEmpty
                      ? codeCtrl.text.trim()
                      : 'CLS-$grade';

                  try {
                    final model = ClassModel(
                      id: existing?.id ?? '',
                      name: finalName,
                      code: finalCode,
                      gradeLevel: grade,
                      academicYear: finalYear,
                      status: status,
                      classTeacherId: existing?.classTeacherId,
                      classroomId: existingSection == null
                          ? selectedClassroomId
                          : existing?.classroomId,
                      subject: existing?.subject ?? '',
                      capacity: strengthVal,
                      customFields: {
                        for (final entry in customFieldControllers.entries)
                          entry.key: entry.value.text.trim(),
                      },
                    );
                    await ref
                        .read(classesControllerProvider.notifier)
                        .save(model, isNew: isNew);

                    // If editing a specific section or class has sections, ensure Section A and Section B have different strengths
                    if (existingSection != null) {
                      await ref
                          .read(sectionsControllerProvider.notifier)
                          .save(
                            existingSection.copyWith(
                              capacity: strengthVal,
                              classroomId: selectedClassroomId,
                              clearClassroom: selectedClassroomId == null,
                            ),
                            isNew: false,
                          );
                      // Make sure other sections of the same class do not have the exact same strength
                      final otherSecs = lookup.sections
                          .where(
                            (s) =>
                                s.classId == existing!.id &&
                                s.id != existingSection.id,
                          )
                          .toList();
                      for (int i = 0; i < otherSecs.length; i++) {
                        final os = otherSecs[i];
                        if (os.capacity == strengthVal) {
                          final diff = (i % 2 == 0) ? -2 : 2;
                          final newOtherCap = (strengthVal + diff > 0)
                              ? strengthVal + diff
                              : strengthVal + 2;
                          await ref
                              .read(sectionsControllerProvider.notifier)
                              .save(
                                os.copyWith(capacity: newOtherCap),
                                isNew: false,
                              );
                        }
                      }
                    } else if (existing != null) {
                      final classSecs = lookup.sections
                          .where((s) => s.classId == existing.id)
                          .toList();
                      for (int i = 0; i < classSecs.length; i++) {
                        final s = classSecs[i];
                        final secCap = (i == 0)
                            ? strengthVal
                            : ((s.capacity > 0 && s.capacity != strengthVal)
                                  ? s.capacity
                                  : (strengthVal > 4
                                        ? strengthVal - 2
                                        : strengthVal + 2));
                        await ref
                            .read(sectionsControllerProvider.notifier)
                            .save(s.copyWith(capacity: secCap), isNew: false);
                      }
                    }
                    if (mounted) {
                      setState(() {
                        _currentPage = 1;
                        _searchQuery = '';
                        _searchController.clear();
                        nameCtrl.dispose();
                        codeCtrl.dispose();
                        strengthCtrl.dispose();
                        for (final controller
                            in customFieldControllers.values) {
                          controller.dispose();
                        }
                      });
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      showCompactSnackBar(
                        context,
                        isNew
                            ? 'Class "$finalName" created successfully'
                            : 'Class updated successfully',
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
                child: Text(isNew ? 'Create' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showExportJsonDialog(BuildContext context, WidgetRef ref) {
    final ds = ref.read(classesRepositoryProvider);
    final jsonStr = ds.exportJsonString();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.data_object, color: Color(0xFF109F83)),
            SizedBox(width: 8),
            Text(
              'Global School JSON Data',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 600,
          height: 420,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF109F83).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF109F83).withValues(alpha: 0.3),
                  ),
                ),
                child: const Text(
                  'Academic data is saved in the global school database JSON and shared across related screens. '
                  'Copy the current global JSON below to export or back it up.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      jsonStr,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
            ),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy JSON to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Global school JSON copied to clipboard.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
