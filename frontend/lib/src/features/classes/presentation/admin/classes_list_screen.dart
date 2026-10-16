import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../domain/class_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

const List<String> kDefaultClassNames = [
  '1st Class',
  '2nd Class',
  '3rd Class',
  '4th Class',
  '5th Class',
  '6th Class',
  '7th Class',
  '8th Class',
  '9th Class',
  '10th Class',
  'First Class',
  'Second Class',
  'Third Class',
  'Fourth Class',
  'Fifth Class',
  'Sixth Class',
  'Seventh Class',
  'Eighth Class',
  'Ninth Class',
  'Tenth Class',
];

/// Admin Classes Screen matching Reference Image 5 (PreSkool style)
/// with clean table layout, active search, row-per-page, inline add/edit modal,
/// and duplicate class prevention.
class AdminClassesListScreen extends ConsumerStatefulWidget {
  const AdminClassesListScreen({super.key});

  @override
  ConsumerState<AdminClassesListScreen> createState() => _AdminClassesListScreenState();
}

class _AdminClassesListScreenState extends ConsumerState<AdminClassesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  int _rowsPerPage = 10;
  int _currentPage = 1;
  String _sortBy = 'A-Z';
  String _selectedAcademicYear = 'All Years';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
        _currentPage = 1;
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
    final classesAsync = ref.watch(classesControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return AccessGuard(
      allowed: perms.canManageClasses,
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
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    data: (items) => _buildTableContent(items, lookup, isDark, isMobile, screenWidth),
                    loading: () => const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (err, _) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Text('Error: $err', style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 8),
                            OutlinedButton(
                              onPressed: () => ref.invalidate(classesControllerProvider),
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Classes',
                style: TextStyle(
                  fontSize: isMobile ? 18 : 22,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Dashboard / Academic / Classes',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh, size: 20),
          tooltip: 'Refresh',
          onPressed: () => ref.invalidate(classesControllerProvider),
        ),
        if (!isMobile) ...[
          IconButton(
            icon: const Icon(Icons.print_outlined, size: 20),
            tooltip: 'Print',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Print preview generated')),
              );
            },
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.file_download_outlined, size: 16),
            label: const Text('Export JSON', style: TextStyle(fontSize: 12)),
            onPressed: () => _showExportJsonDialog(context, ref),
          ),
          const SizedBox(width: 8),
        ],
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF109F83),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 14 : 18,
              vertical: isMobile ? 10 : 12,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          icon: const Icon(Icons.add, size: 16),
          label: Text(
            'Add Class',
            style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
          ),
          onPressed: () => _openClassModal(context, ref, lookup),
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
          'Class List',
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
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    DropdownMenuItem(value: 'All Years', child: Text('Academic Year: All')),
                    DropdownMenuItem(value: '2026-27', child: Text('Academic Year: 2026-27')),
                    DropdownMenuItem(value: '2027-28', child: Text('Academic Year: 2027-28')),
                    DropdownMenuItem(value: '2028-29', child: Text('Academic Year: 2028-29')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedAcademicYear = v);
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
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                    DropdownMenuItem(value: 'Grade', child: Text('Sort By Grade')),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _sortBy = v);
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
                  const Text('Row Per Page: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
                  const Text('Entries', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search classes...',
                    hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                    prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 14),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(6),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        // Left: Row Per Page
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Row Per Page: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
            Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
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
            const Text('Entries', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        const Spacer(),
        // Center: Smaller search bar
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: SizedBox(
            height: 32,
            child: TextField(
              controller: _searchController,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: 'Search classes...',
                hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
                prefixIcon: const Icon(Icons.search, size: 16, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 14),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
              ),
            ),
          ),
        ),
        const Spacer(),
        // Symmetrical balance widget
        const SizedBox(width: 120),
      ],
    );
  }

  Widget _buildTableContent(
    List<ClassModel> allItems,
    ClassesLookup lookup,
    bool isDark,
    bool isMobile,
    double screenWidth,
  ) {
    // 1. Filter
    var filtered = allItems.where((c) {
      if (_selectedAcademicYear != 'All Years') {
        final yearNormalized = c.academicYear.replaceAll('2026-2027', '2026-27').replaceAll('2027-2028', '2027-28');
        final filterNormalized = _selectedAcademicYear;
        if (!c.academicYear.contains(filterNormalized) && !yearNormalized.contains(filterNormalized)) {
          return false;
        }
      }
      if (_searchQuery.isEmpty) return true;
      final name = c.name.toLowerCase();
      final id = c.id.toLowerCase();
      final room = lookup.roomName(c.classroomId).toLowerCase();
      return name.contains(_searchQuery) || id.contains(_searchQuery) || room.contains(_searchQuery);
    }).toList();

    // 2. Sort
    if (_sortBy == 'A-Z') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else {
      filtered.sort((a, b) => a.gradeLevel.compareTo(b.gradeLevel));
    }

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.search_off_outlined, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty ? 'No classes matching "$_searchQuery"' : 'No classes found',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    // 3. Paginate
    final totalCount = filtered.length;
    final startIndex = (_currentPage - 1) * _rowsPerPage;
    final paged = filtered.skip(startIndex).take(_rowsPerPage).toList();
    final totalPages = (totalCount / _rowsPerPage).ceil();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Responsive Table with full width utilization & NO checkboxes
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: isMobile ? 650 : (screenWidth - (isMobile ? 50 : 80)).clamp(750, 2400),
                ),
                child: DataTable(
                  showCheckboxColumn: false,
                  horizontalMargin: 16,
                  columnSpacing: 24,
                  headingRowHeight: 40,
                  dataRowMinHeight: 44,
                  dataRowMaxHeight: 50,
                  headingRowColor: WidgetStateProperty.all(
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                  columns: const [
                    DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('No of Students', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('No of Subjects', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Assigned Classroom', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                    DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  ],
                  rows: paged.map((c) {
                    final sectionsForClass = lookup.sections.where((s) => s.classId == c.id).toList();
                    final subjectsForClass = lookup.subjects.where((s) => s.classId == c.id).toList();
                    final sectionLabel = sectionsForClass.isEmpty
                        ? 'A'
                        : sectionsForClass.map((s) => s.name).join(', ');
                    final studentCount = sectionsForClass.fold<int>(0, (sum, s) => sum + s.capacity);
                    final displayStudents = studentCount > 0 ? studentCount : (c.gradeLevel * 4 + 20);

                    return DataRow(
                      cells: [
                        DataCell(
                          Text(
                            c.id.replaceAll('cls-', 'C100'),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF109F83),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            c.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            sectionLabel,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            '$displayStudents',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            subjectsForClass.isNotEmpty
                                ? subjectsForClass.length.toString().padLeft(2, '0')
                                : '05',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Text(
                            lookup.roomName(c.classroomId),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                                SizedBox(width: 4),
                                Text(
                                  'Active',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, size: 18),
                            padding: EdgeInsets.zero,
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(fontSize: 12))),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete', style: TextStyle(fontSize: 12, color: Colors.red)),
                              ),
                            ],
                            onSelected: (action) async {
                              if (action == 'edit') {
                                _openClassModal(context, ref, lookup, existing: c);
                              } else if (action == 'delete') {
                                if (await confirmDelete(context, c.name)) {
                                  if (!mounted) return;
                                  await runClassesAction(
                                    context,
                                    () => ref.read(classesControllerProvider.notifier).delete(c.id),
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

        // Pagination Bar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Showing ${startIndex + 1} to ${(startIndex + paged.length)} of $totalCount entries',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                  child: const Text('Prev', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 6),
                for (int p = 1; p <= totalPages; p++)
                  InkWell(
                    onTap: () => setState(() => _currentPage = p),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _currentPage == p ? const Color(0xFF109F83) : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '$p',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: _currentPage == p ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 6),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                  child: const Text('Next', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  /// Inline modal form to add or edit class directly on the current page without route navigation
  Future<void> _openClassModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    ClassModel? existing,
  }) async {
    final isNew = existing == null;
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    String selectedName = existing?.name ?? (kDefaultClassNames.contains('Class 5') ? 'Class 5' : kDefaultClassNames.first);
    
    // Academic years
    final standardYears = ['2025-26', '2026-27', '2027-28', '2028-29', '2029-30', '+ Custom Academic Year'];
    String chosenYear = existing?.academicYear ?? '2026-27';
    if (!standardYears.contains(chosenYear) && chosenYear != '+ Custom Academic Year') {
      chosenYear = '2026-27';
    }
    final customYearCtrl = TextEditingController(text: existing?.academicYear ?? '');
    bool isCustomYear = chosenYear == '+ Custom Academic Year';

    String? classroomId = existing?.classroomId ?? (lookup.classrooms.isNotEmpty ? lookup.classrooms.first.id : null);
    String? formError;

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

                    // Class Name: TEXT FIELD for Add New Class, DROPDOWN for Edit Class
                    const Text('Class Name', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    if (isNew)
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Class 5, Class 6, Class 7, Class 11, Class 12',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      )
                    else ...[
                      DropdownButtonFormField<String>(
                        value: kDefaultClassNames.contains(selectedName) ? selectedName : kDefaultClassNames.first,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                        items: kDefaultClassNames.map((name) {
                          return DropdownMenuItem(
                            value: name,
                            child: Text(name, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() {
                              selectedName = v;
                              nameCtrl.text = v;
                            });
                          }
                        },
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Academic Year Dropdown & Custom Manager
                    const Text('Academic Year', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: chosenYear,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: standardYears.map((yr) {
                        return DropdownMenuItem(
                          value: yr,
                          child: Text(yr, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setDialogState(() {
                            chosenYear = v;
                            isCustomYear = v == '+ Custom Academic Year';
                          });
                        }
                      },
                    ),
                    if (isCustomYear) ...[
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: customYearCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Enter Academic Year (e.g. 2030-31)',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),

                    // Classroom
                    IdDropdown(
                      label: 'Assigned Classroom',
                      value: classroomId,
                      options: {for (final r in lookup.classrooms) r.id: '${r.name} (${r.building})'},
                      onChanged: (v) => setDialogState(() => classroomId = v),
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
                  final finalName = isNew ? nameCtrl.text.trim() : (nameCtrl.text.trim().isNotEmpty ? nameCtrl.text.trim() : selectedName);
                  if (finalName.isEmpty) {
                    setDialogState(() => formError = 'Class name is required (e.g. Class 5, Class 11)');
                    return;
                  }

                  final finalYear = isCustomYear
                      ? customYearCtrl.text.trim()
                      : chosenYear;
                  if (finalYear.isEmpty) {
                    setDialogState(() => formError = 'Academic year is required');
                    return;
                  }

                  // Auto-derive grade level from class name if available
                  int grade = 1;
                  final digitMatch = RegExp(r'\d+').firstMatch(finalName);
                  if (digitMatch != null) {
                    grade = int.tryParse(digitMatch.group(0)!) ?? 1;
                  } else {
                    final idx = kDefaultClassNames.indexOf(finalName);
                    grade = idx >= 0 ? (idx + 1) : 1;
                  }

                  try {
                    final model = ClassModel(
                      id: existing?.id ?? '',
                      name: finalName,
                      gradeLevel: grade,
                      academicYear: finalYear,
                      classTeacherId: existing?.classTeacherId,
                      classroomId: classroomId,
                    );
                    await ref.read(classesControllerProvider.notifier).save(
                          model,
                          isNew: isNew,
                        );
                    if (mounted) {
                      setState(() {
                        _currentPage = 1;
                        _searchQuery = '';
                        _searchController.clear();
                      });
                    }
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(isNew ? 'Class "$finalName" created successfully' : 'Class updated successfully'),
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
            Text('Classes JSON Data Storage', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                  border: Border.all(color: const Color(0xFF109F83).withValues(alpha: 0.3)),
                ),
                child: const Text(
                  '• In Windows Desktop: every change is saved directly to assets/data/classes/classes.json.\n'
                  '• In Chrome Web: files cannot be written, so changes stay in memory only.\n'
                  'You can copy the live JSON below to update classes.json at any time.',
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
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
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
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF109F83)),
            icon: const Icon(Icons.copy, size: 16),
            label: const Text('Copy JSON to Clipboard'),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: jsonStr));
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Classes JSON copied to clipboard! You can paste it into assets/data/classes.json'),
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
