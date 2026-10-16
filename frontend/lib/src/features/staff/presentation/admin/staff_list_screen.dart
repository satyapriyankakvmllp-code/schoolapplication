import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/staff_controller.dart';
import '../../domain/staff_member_model.dart';
import '../widgets/staff_card.dart';
import '../widgets/staff_id_badge_view.dart';

class StaffListScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final ValueChanged<String>? onSelectStaff;
  final ValueChanged<StaffMemberModel>? onEditStaff;

  const StaffListScreen({
    super.key,
    required this.isDark,
    this.onToggleTheme,
    this.onNavigate,
    this.onSelectStaff,
    this.onEditStaff,
  });

  @override
  ConsumerState<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends ConsumerState<StaffListScreen> {
  bool _isGridView = true;
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _departments = [
    'All Departments',
    'Mathematics',
    'Science',
    'Humanities',
    'Computer Science',
    'Accounts & Finance',
    'Admissions & Reception',
    'Library',
    'Physical Education',
    'Campus Operations',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showIdBadgeModal(StaffMemberModel staff) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.badge_outlined, color: Color(0xFF109F83)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Physical ID Badge — ${staff.fullName}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, size: 20),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: StaffIdBadgeView(staff: staff, isDark: widget.isDark),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffListProvider);
    final filteredStaff = ref.watch(filteredStaffListProvider);
    final counts = ref.watch(staffCountsProvider);
    final selectedCategory = ref.watch(staffCategoryFilterProvider);
    final selectedDepartment = ref.watch(staffDepartmentFilterProvider);
    final selectedStatus = ref.watch(staffStatusFilterProvider);

    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return EdupluseScaffold(
      activePage: EdupluseNavPage.staffList,
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      onNavigate: widget.onNavigate,
      body: Container(
        color: bgColor,
        child: staffAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF109F83)),
          ),
          error: (err, stack) => Center(
            child: Text('Error loading staff roster: $err', style: TextStyle(color: textColor)),
          ),
          data: (_) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header & Quick Add Button
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isMobile = constraints.maxWidth < 600;
                      return isMobile
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Staff & Faculty Directory',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Unified directory of teaching faculty, administrative officers, and operational personnel.',
                                  style: TextStyle(fontSize: 13, color: subColor),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: () => widget.onNavigate?.call(EdupluseNavPage.addNewStaff),
                                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 16),
                                  label: const Text('Add New Staff'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF109F83),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Staff & Faculty Directory',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Unified directory of teaching faculty, administrative officers, and operational personnel.',
                                        style: TextStyle(fontSize: 13, color: subColor),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton.icon(
                                  onPressed: () => widget.onNavigate?.call(EdupluseNavPage.addNewStaff),
                                  icon: const Icon(Icons.person_add_alt_1_outlined, size: 18),
                                  label: const Text('Add New Staff'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF109F83),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ],
                            );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Top KPI Cards
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      final isPhone = width < 600;
                      final isTablet = width >= 600 && width < 1000;

                      final kpiTotal = _buildKpiCard(
                        title: 'Total Personnel',
                        count: counts.total,
                        icon: Icons.people_outline,
                        color: const Color(0xFF0F172A),
                        accentColor: const Color(0xFF109F83),
                        isDark: isDark,
                      );
                      final kpiTeaching = _buildKpiCard(
                        title: 'Teaching Faculty',
                        count: counts.teaching,
                        icon: Icons.school_outlined,
                        color: const Color(0xFF109F83),
                        accentColor: const Color(0xFF109F83),
                        isDark: isDark,
                      );
                      final kpiAdmin = _buildKpiCard(
                        title: 'Administrative',
                        count: counts.administrative,
                        icon: Icons.admin_panel_settings_outlined,
                        color: const Color(0xFF3B82F6),
                        accentColor: const Color(0xFF3B82F6),
                        isDark: isDark,
                      );
                      final kpiLeave = _buildKpiCard(
                        title: 'On Leave Today',
                        count: counts.onLeave,
                        icon: Icons.beach_access_outlined,
                        color: const Color(0xFFF59E0B),
                        accentColor: const Color(0xFFF59E0B),
                        isDark: isDark,
                      );

                      if (isPhone) {
                        return Column(
                          children: [
                            Row(children: [Expanded(child: kpiTotal), const SizedBox(width: 10), Expanded(child: kpiTeaching)]),
                            const SizedBox(height: 10),
                            Row(children: [Expanded(child: kpiAdmin), const SizedBox(width: 10), Expanded(child: kpiLeave)]),
                          ],
                        );
                      }

                      if (isTablet) {
                        return Row(
                          children: [
                            Expanded(child: kpiTotal),
                            const SizedBox(width: 12),
                            Expanded(child: kpiTeaching),
                            const SizedBox(width: 12),
                            Expanded(child: kpiAdmin),
                            const SizedBox(width: 12),
                            Expanded(child: kpiLeave),
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: kpiTotal),
                          const SizedBox(width: 16),
                          Expanded(child: kpiTeaching),
                          const SizedBox(width: 16),
                          Expanded(child: kpiAdmin),
                          const SizedBox(width: 16),
                          Expanded(child: kpiLeave),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Search & Multi-facet Filter Container
                  Container(
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        // Search bar + View Toggle
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (val) {
                                  ref.read(staffSearchQueryProvider.notifier).state = val;
                                },
                                decoration: InputDecoration(
                                  hintText: 'Search staff by name, ID, phone, designation...',
                                  hintStyle: TextStyle(fontSize: 13, color: subColor),
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 16),
                                          onPressed: () {
                                            _searchController.clear();
                                            ref.read(staffSearchQueryProvider.notifier).state = '';
                                          },
                                        )
                                      : null,
                                  isDense: true,
                                  filled: true,
                                  fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            // View Switcher (Grid vs Table)
                            Container(
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.grid_view_rounded, size: 18),
                                    color: _isGridView ? const Color(0xFF109F83) : subColor,
                                    tooltip: 'Card Grid View',
                                    onPressed: () => setState(() => _isGridView = true),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.table_rows_rounded, size: 18),
                                    color: !_isGridView ? const Color(0xFF109F83) : subColor,
                                    tooltip: 'Table List View',
                                    onPressed: () => setState(() => _isGridView = false),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Filter Pills & Dropdowns Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isNarrow = constraints.maxWidth < 650;
                            final categoryPills = SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCategoryFilterChip(
                                    label: 'All Staff',
                                    isSelected: selectedCategory == null,
                                    onSelected: () => ref.read(staffCategoryFilterProvider.notifier).state = null,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCategoryFilterChip(
                                    label: 'Teaching Faculty',
                                    isSelected: selectedCategory == StaffCategory.teaching,
                                    onSelected: () => ref.read(staffCategoryFilterProvider.notifier).state = StaffCategory.teaching,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCategoryFilterChip(
                                    label: 'Administrative',
                                    isSelected: selectedCategory == StaffCategory.administrative,
                                    onSelected: () => ref.read(staffCategoryFilterProvider.notifier).state = StaffCategory.administrative,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCategoryFilterChip(
                                    label: 'Support',
                                    isSelected: selectedCategory == StaffCategory.support,
                                    onSelected: () => ref.read(staffCategoryFilterProvider.notifier).state = StaffCategory.support,
                                  ),
                                ],
                              ),
                            );

                            final dropdowns = Row(
                              mainAxisSize: isNarrow ? MainAxisSize.max : MainAxisSize.min,
                              children: [
                                // Department filter
                                Expanded(
                                  flex: isNarrow ? 1 : 0,
                                  child: SizedBox(
                                    width: isNarrow ? null : 170,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: selectedDepartment ?? 'All Departments',
                                          isExpanded: true,
                                          isDense: true,
                                          style: TextStyle(fontSize: 12, color: textColor),
                                          items: _departments
                                              .map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontSize: 12))))
                                              .toList(),
                                          onChanged: (val) {
                                            ref.read(staffDepartmentFilterProvider.notifier).state =
                                                (val == 'All Departments') ? null : val;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Status filter
                                Expanded(
                                  flex: isNarrow ? 1 : 0,
                                  child: SizedBox(
                                    width: isNarrow ? null : 130,
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<StaffStatus?>(
                                          value: selectedStatus,
                                          isExpanded: true,
                                          isDense: true,
                                          style: TextStyle(fontSize: 12, color: textColor),
                                          items: [
                                            const DropdownMenuItem(value: null, child: Text('All Status', style: TextStyle(fontSize: 12))),
                                            ...StaffStatus.values.map(
                                              (s) => DropdownMenuItem(value: s, child: Text(s.label, style: const TextStyle(fontSize: 12))),
                                            ),
                                          ],
                                          onChanged: (val) {
                                            ref.read(staffStatusFilterProvider.notifier).state = val;
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );

                            if (isNarrow) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  categoryPills,
                                  const SizedBox(height: 10),
                                  dropdowns,
                                ],
                              );
                            }

                            return Row(
                              children: [
                                Expanded(child: categoryPills),
                                const SizedBox(width: 12),
                                dropdowns,
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Results Count
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Showing ${filteredStaff.length} of ${counts.total} staff members',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                          ),
                        ),
                      ),
                      if (selectedCategory != null || selectedDepartment != null || selectedStatus != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () {
                            ref.read(staffCategoryFilterProvider.notifier).state = null;
                            ref.read(staffDepartmentFilterProvider.notifier).state = null;
                            ref.read(staffStatusFilterProvider.notifier).state = null;
                            _searchController.clear();
                            ref.read(staffSearchQueryProvider.notifier).state = '';
                          },
                          child: const Text('Reset Filters', style: TextStyle(fontSize: 12, color: Color(0xFF109F83))),
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Content: Grid or Table
                  if (filteredStaff.isEmpty)
                    _buildEmptyState(isDark)
                  else if (_isGridView)
                    _buildCardGrid(filteredStaff, isDark)
                  else
                    _buildTableView(filteredStaff, isDark),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
    required Color accentColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: const Color(0xFF109F83).withValues(alpha: 0.18),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF109F83) : (widget.isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildCardGrid(List<StaffMemberModel> staffList, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int columns = 1;
        if (width >= 680 && width < 1100) {
          columns = 2;
        } else if (width >= 1100) {
          columns = 3;
        }

        final itemWidth = (width - ((columns - 1) * 16)) / columns;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: staffList.map((staff) {
            return SizedBox(
              width: itemWidth,
              child: StaffCard(
                staff: staff,
                isDark: isDark,
                onViewProfile: () {
                  ref.read(selectedStaffIdProvider.notifier).state = staff.id;
                  widget.onSelectStaff?.call(staff.id);
                  widget.onNavigate?.call(EdupluseNavPage.staffDetails);
                },
                onEdit: () {
                  ref.read(selectedStaffIdProvider.notifier).state = staff.id;
                  if (widget.onEditStaff != null) {
                    widget.onEditStaff!(staff);
                  } else {
                    widget.onNavigate?.call(EdupluseNavPage.editStaff);
                  }
                },
                onPrintBadge: () => _showIdBadgeModal(staff),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildTableView(List<StaffMemberModel> staffList, bool isDark) {
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          ),
          columns: const [
            DataColumn(label: Text('Staff Member', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Staff ID', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Category & Dept', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Contact', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Role / Classes', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: staffList.map((staff) {
            return DataRow(
              cells: [
                // Name & Monogram
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                        child: Text(
                          staff.initials,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(staff.fullName, style: TextStyle(fontWeight: FontWeight.w600, color: textColor, fontSize: 13)),
                          Text(staff.designation, style: TextStyle(fontSize: 11, color: subColor)),
                        ],
                      ),
                    ],
                  ),
                ),
                // ID
                DataCell(
                  Text(staff.id, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600, fontSize: 12)),
                ),
                // Dept
                DataCell(
                  Text('${staff.department} (${staff.category.name})', style: const TextStyle(fontSize: 12)),
                ),
                // Contact
                DataCell(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(staff.phone, style: TextStyle(fontSize: 11, color: textColor)),
                      Text(staff.email, style: TextStyle(fontSize: 10, color: subColor)),
                    ],
                  ),
                ),
                // Classes
                DataCell(
                  staff.isClassTeacher
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Class Teacher (${staff.primaryClassAssignment?.grade}-${staff.primaryClassAssignment?.section})',
                            style: const TextStyle(fontSize: 10, color: Color(0xFF8B5CF6), fontWeight: FontWeight.bold),
                          ),
                        )
                      : Text(
                          staff.assignedClasses.isNotEmpty
                              ? '${staff.assignedClasses.length} class(es)'
                              : staff.category.label,
                          style: TextStyle(fontSize: 11, color: subColor),
                        ),
                ),
                // Status
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (staff.status == StaffStatus.active
                              ? const Color(0xFF10B981)
                              : staff.status == StaffStatus.onLeave
                                  ? const Color(0xFFF59E0B)
                                  : const Color(0xFF94A3B8))
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      staff.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: staff.status == StaffStatus.active
                            ? const Color(0xFF10B981)
                            : staff.status == StaffStatus.onLeave
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF94A3B8),
                      ),
                    ),
                  ),
                ),
                // Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        tooltip: 'View Profile',
                        onPressed: () {
                          ref.read(selectedStaffIdProvider.notifier).state = staff.id;
                          widget.onSelectStaff?.call(staff.id);
                          widget.onNavigate?.call(EdupluseNavPage.staffDetails);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.badge_outlined, size: 16),
                        tooltip: 'Print ID Badge',
                        color: const Color(0xFF109F83),
                        onPressed: () => _showIdBadgeModal(staff),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        tooltip: 'Edit Record',
                        color: const Color(0xFF3B82F6),
                        onPressed: () {
                          ref.read(selectedStaffIdProvider.notifier).state = staff.id;
                          if (widget.onEditStaff != null) {
                            widget.onEditStaff!(staff);
                          } else {
                            widget.onNavigate?.call(EdupluseNavPage.editStaff);
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
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'No matching staff members found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search criteria or resetting the category filters.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
