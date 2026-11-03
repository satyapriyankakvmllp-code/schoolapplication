import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../commonwidgets/edupluse_scaffold.dart';
import '../../../commonwidgets/empty_state_view.dart';
import '../../../commonwidgets/error_state_view.dart';
import '../../../commonwidgets/loading_indicator.dart';
import '../../classes/presentation/widgets/classes_ui.dart';
import '../application/fees_access.dart';
import '../application/fees_controller.dart';
import '../data/fees_repository.dart';
import '../domain/fee_structure.dart';
import '../domain/money.dart';
import 'fee_structure_form_panel.dart';
import 'widgets/fees_stat_card.dart';

class FeeStructureListScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onExitToGateway;

  const FeeStructureListScreen({
    super.key,
    required this.isDark,
    this.onToggleTheme,
    this.onNavigate,
    this.onExitToGateway,
  });

  @override
  ConsumerState<FeeStructureListScreen> createState() =>
      _FeeStructureListScreenState();
}

class _FeeStructureListScreenState
    extends ConsumerState<FeeStructureListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSort(String column) {
    final current = ref.read(feeStructureFilterProvider);
    if (current.sortColumn == column) {
      ref.read(feeStructureFilterProvider.notifier).state = current.copyWith(
        sortAscending: !current.sortAscending,
      );
    } else {
      ref.read(feeStructureFilterProvider.notifier).state = current.copyWith(
        sortColumn: column,
        sortAscending: true,
      );
    }
  }

  void _setSort(String column, bool ascending) {
    final current = ref.read(feeStructureFilterProvider);
    ref.read(feeStructureFilterProvider.notifier).state = current.copyWith(
      sortColumn: column,
      sortAscending: ascending,
    );
  }

  Future<void> _handleToggleActive(FeeStructure structure) async {
    final newActiveState = !structure.isActive;
    try {
      await ref
          .read(feeStructuresControllerProvider.notifier)
          .toggleActive(structure.id, newActiveState);
      if (mounted) {
        showCompactSnackBar(
          context,
          newActiveState
              ? 'Fee structure for ${structure.className} activated.'
              : 'Fee structure for ${structure.className} deactivated.',
        );
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e
            .toString()
            .replaceAll('Exception:', '')
            .replaceAll('FeesValidationException:', '')
            .trim();
        showCompactSnackBar(
          context,
          cleanMsg,
          backgroundColor: Colors.red.shade700,
          icon: Icons.error_outline,
        );
      }
    }
  }

  Future<void> _handleDelete(FeeStructure structure) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.red),
            const SizedBox(width: 8),
            Text('Delete ${structure.className} Structure?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete the fee structure for ${structure.className} (${structure.termName}, ${structure.academicYear})?\n\n'
          'Note: Structures linked to existing student invoices cannot be deleted and must be deactivated instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(feeStructuresControllerProvider.notifier)
          .delete(structure.id);
      if (mounted) {
        showCompactSnackBar(context, 'Fee structure deleted successfully.');
      }
    } catch (e) {
      if (mounted) {
        final cleanMsg = e
            .toString()
            .replaceAll('Exception:', '')
            .replaceAll('FeesReferenceException:', '')
            .trim();
        showCompactSnackBar(
          context,
          cleanMsg,
          backgroundColor: Colors.red.shade700,
          icon: Icons.error_outline,
          duration: const Duration(seconds: 4),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasAccess = ref.watch(feesAccessProvider);

    return EdupluseScaffold(
      activePage: EdupluseNavPage.fees,
      isDark: widget.isDark,
      onToggleTheme: widget.onToggleTheme,
      onNavigate: widget.onNavigate,
      onExitToGateway: widget.onExitToGateway,
      body: AccessGuard(
        allowed: hasAccess,
        child: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final asyncStructures = ref.watch(feeStructuresControllerProvider);
    final asyncFiltered = ref.watch(filteredFeeStructuresProvider);
    final filter = ref.watch(feeStructureFilterProvider);

    return asyncStructures.when(
      loading: () => const Center(child: LoadingIndicator()),
      error: (e, _) => Center(
        child: ErrorStateView(
          message: e.toString(),
          onRetry: () => ref.read(feeStructuresControllerProvider.notifier).refresh(),
        ),
      ),
      data: (allStructures) {
        final activeCount = allStructures.where((s) => s.isActive).length;
        final inactiveCount = allStructures.where((s) => !s.isActive).length;
        final totalValue = allStructures.fold<double>(
          0.0,
          (sum, s) => sum + s.totalFee,
        );

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 12 : 24,
            vertical: 16,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Page Header & Add Action
                  _buildPageHeader(context, isMobile, isDark),
                  const SizedBox(height: 16),

                  // KPI Summary Stat Cards
                  _buildStatCards(
                    allCount: allStructures.length,
                    activeCount: activeCount,
                    inactiveCount: inactiveCount,
                    totalValue: totalValue,
                    isMobile: isMobile,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 20),

                  // Filter & Search Controls Bar
                  _buildFilterBar(context, filter, isMobile, isDark),
                  const SizedBox(height: 16),

                  // Content Area: Filtered results
                  asyncFiltered.when(
                    loading: () => const Center(child: LoadingIndicator()),
                    error: (e, _) => ErrorStateView(
                      message: e.toString(),
                      onRetry: () => ref.read(feeStructuresControllerProvider.notifier).refresh(),
                    ),
                    data: (items) {
                      if (items.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: EmptyStateView(
                            title: 'No Fee Structures Found',
                            subtitle: filter.searchQuery.isNotEmpty ||
                                    filter.academicYear != 'All' ||
                                    filter.className != 'All' ||
                                    filter.termName != 'All' ||
                                    filter.status != 'All'
                                ? 'No structures matched the selected filter criteria. Try resetting filters.'
                                : 'Get started by creating the first fee structure for an academic class.',
                            action: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF109F83),
                              ),
                              onPressed: () => showFeeStructurePanel(
                                context: context,
                                onRefresh: () => ref
                                    .read(feeStructuresControllerProvider.notifier)
                                    .refresh(),
                              ),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Fee Structure'),
                            ),
                          ),
                        );
                      }

                      return isMobile
                          ? _buildMobileCardList(items, isDark)
                          : _buildDesktopTable(items, filter, isDark);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPageHeader(BuildContext context, bool isMobile, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Fee Structure',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Configure class-wise fee breakdowns, term due dates, and active structures',
                style: TextStyle(
                  fontSize: isMobile ? 11.5 : 13,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF109F83),
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 18,
              vertical: isMobile ? 10 : 14,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => showFeeStructurePanel(
            context: context,
            onRefresh: () =>
                ref.read(feeStructuresControllerProvider.notifier).refresh(),
          ),
          icon: const Icon(Icons.add, size: 18),
          label: Text(
            isMobile ? 'Add' : 'Add Fee Structure',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCards({
    required int allCount,
    required int activeCount,
    required int inactiveCount,
    required double totalValue,
    required bool isMobile,
    required bool isDark,
  }) {
    final cards = [
      FeesStatCard(
        label: 'Total Structures',
        value: '$allCount',
        icon: Icons.layers_outlined,
        color: const Color(0xFF3B82F6),
        subtitle: 'Configured class tiers',
      ),
      FeesStatCard(
        label: 'Active Structures',
        value: '$activeCount',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF109F83),
        subtitle: 'Current billing plans',
      ),
      FeesStatCard(
        label: 'Inactive / Draft',
        value: '$inactiveCount',
        icon: Icons.pause_circle_outline,
        color: const Color(0xFFF59E0B),
        subtitle: 'Archived structures',
      ),
      FeesStatCard(
        label: 'Sum of Term Fees',
        value: Money.formatRupees(totalValue),
        icon: Icons.currency_rupee,
        color: const Color(0xFF8B5CF6),
        subtitle: 'Aggregated structure value',
      ),
    ];

    if (isMobile) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: cards,
      );
    }

    return Row(
      children: cards
          .map((c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: c,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildFilterBar(
    BuildContext context,
    FeeStructureFilterState filter,
    bool isMobile,
    bool isDark,
  ) {
    final academicYearsAsync = ref.watch(feeAcademicYearsProvider);
    final availableClassesAsync = ref.watch(feeAvailableClassesProvider);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
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
          // Row 1: Search Box + Quick Filter Dropdowns
          Wrap(
            spacing: 12,
            runSpacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Search Box
              SizedBox(
                width: isMobile ? double.infinity : 280,
                height: 42,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search class, term, year...',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(feeStructureFilterProvider.notifier).state =
                                  filter.copyWith(searchQuery: '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                      ),
                    ),
                  ),
                  onChanged: (val) {
                    ref.read(feeStructureFilterProvider.notifier).state =
                        filter.copyWith(searchQuery: val.trim());
                  },
                ),
              ),

              // Academic Year Filter
              academicYearsAsync.when(
                data: (years) {
                  final items = ['All', ...years];
                  return SizedBox(
                    width: isMobile ? (MediaQuery.sizeOf(context).width - 36) / 2 : 160,
                    height: 42,
                    child: DropdownButtonFormField<String>(
                      value: items.contains(filter.academicYear) ? filter.academicYear : 'All',
                      decoration: _filterInputDecoration('Academic Year', isDark),
                      items: items
                          .map((y) => DropdownMenuItem(
                                value: y,
                                child: Text(y == 'All' ? 'All Years' : y,
                                    style: const TextStyle(fontSize: 12.5)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(feeStructureFilterProvider.notifier).state =
                              filter.copyWith(academicYear: val);
                        }
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Class Filter
              availableClassesAsync.when(
                data: (classes) {
                  final items = ['All', ...classes];
                  return SizedBox(
                    width: isMobile ? (MediaQuery.sizeOf(context).width - 36) / 2 : 160,
                    height: 42,
                    child: DropdownButtonFormField<String>(
                      value: items.contains(filter.className) ? filter.className : 'All',
                      decoration: _filterInputDecoration('Class', isDark),
                      items: items
                          .map((c) => DropdownMenuItem(
                                value: c,
                                child: Text(c == 'All' ? 'All Classes' : c,
                                    style: const TextStyle(fontSize: 12.5)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          ref.read(feeStructureFilterProvider.notifier).state =
                              filter.copyWith(className: val);
                        }
                      },
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              // Term Filter
              SizedBox(
                width: isMobile ? (MediaQuery.sizeOf(context).width - 36) / 2 : 140,
                height: 42,
                child: DropdownButtonFormField<String>(
                  value: filter.termName,
                  decoration: _filterInputDecoration('Term', isDark),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Terms', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Term 1', child: Text('Term 1', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Term 2', child: Text('Term 2', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Term 3', child: Text('Term 3', style: TextStyle(fontSize: 12.5))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(feeStructureFilterProvider.notifier).state =
                          filter.copyWith(termName: val);
                    }
                  },
                ),
              ),

              // Status Filter
              SizedBox(
                width: isMobile ? (MediaQuery.sizeOf(context).width - 36) / 2 : 140,
                height: 42,
                child: DropdownButtonFormField<String>(
                  value: filter.status,
                  decoration: _filterInputDecoration('Status', isDark),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Status', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Active', child: Text('Active Only', style: TextStyle(fontSize: 12.5))),
                    DropdownMenuItem(value: 'Inactive', child: Text('Inactive Only', style: TextStyle(fontSize: 12.5))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(feeStructureFilterProvider.notifier).state =
                          filter.copyWith(status: val);
                    }
                  },
                ),
              ),

              // Reset Filter Button
              if (filter.searchQuery.isNotEmpty ||
                  filter.academicYear != 'All' ||
                  filter.className != 'All' ||
                  filter.termName != 'All' ||
                  filter.status != 'All') ...[
                TextButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    ref.read(feeStructureFilterProvider.notifier).state =
                        const FeeStructureFilterState();
                  },
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Reset', style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _filterInputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(fontSize: 12),
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
    List<FeeStructure> items,
    FeeStructureFilterState filter,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 1050),
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              horizontalMargin: 16,
              columnSpacing: 20,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 56,
              columns: [
                DataColumn(
                  label: SortableHeader(
                    title: 'Class',
                    isSorted: filter.sortColumn == 'class',
                    ascending: filter.sortAscending,
                    onToggle: () => _onSort('class'),
                    onAscending: () => _setSort('class', true),
                    onDescending: () => _setSort('class', false),
                  ),
                ),
                DataColumn(
                  label: SortableHeader(
                    title: 'Term',
                    isSorted: filter.sortColumn == 'term',
                    ascending: filter.sortAscending,
                    onToggle: () => _onSort('term'),
                    onAscending: () => _setSort('term', true),
                    onDescending: () => _setSort('term', false),
                  ),
                ),
                DataColumn(
                  label: SortableHeader(
                    title: 'Academic Year',
                    isSorted: filter.sortColumn == 'year',
                    ascending: filter.sortAscending,
                    onToggle: () => _onSort('year'),
                    onAscending: () => _setSort('year', true),
                    onDescending: () => _setSort('year', false),
                  ),
                ),
                DataColumn(
                  label: SortableHeader(
                    title: 'Tuition Fee',
                    isSorted: filter.sortColumn == 'tuition',
                    ascending: filter.sortAscending,
                    onToggle: () => _onSort('tuition'),
                    onAscending: () => _setSort('tuition', true),
                    onDescending: () => _setSort('tuition', false),
                  ),
                ),
                const DataColumn(
                  label: Text('Lab/Comp.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                const DataColumn(
                  label: Text('Dev. Fee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                const DataColumn(
                  label: Text('Other Fee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                DataColumn(
                  label: SortableHeader(
                    title: 'Total Fee',
                    isSorted: filter.sortColumn == 'total',
                    ascending: filter.sortAscending,
                    onToggle: () => _onSort('total'),
                    onAscending: () => _setSort('total', true),
                    onDescending: () => _setSort('total', false),
                  ),
                ),
                DataColumn(
                  label: SortableHeader(
                    title: 'Due Date',
                    isSorted: filter.sortColumn == 'due_date',
                    ascending: filter.sortAscending,
                    onToggle: () => _onSort('due_date'),
                    onAscending: () => _setSort('due_date', true),
                    onDescending: () => _setSort('due_date', false),
                  ),
                ),
                const DataColumn(
                  label: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
                const DataColumn(
                  label: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                ),
              ],
              rows: items.map((structure) {
                return DataRow(
                  cells: [
                    // Class
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF109F83).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              structure.className,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF109F83),
                                fontSize: 12.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Term
                    DataCell(
                      Text(structure.termName, style: const TextStyle(fontSize: 12.5)),
                    ),
                    // Academic Year
                    DataCell(
                      Text(structure.academicYear, style: const TextStyle(fontSize: 12.5)),
                    ),
                    // Tuition Fee
                    DataCell(
                      Text(Money.formatRupees(structure.tuitionFee),
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5)),
                    ),
                    // Lab / Computer
                    DataCell(
                      Text(Money.formatRupees(structure.labComputerFee),
                          style: const TextStyle(fontSize: 12.5)),
                    ),
                    // Development Fee
                    DataCell(
                      Text(Money.formatRupees(structure.developmentFee),
                          style: const TextStyle(fontSize: 12.5)),
                    ),
                    // Other Fee
                    DataCell(
                      Text(Money.formatRupees(structure.otherFee),
                          style: const TextStyle(fontSize: 12.5)),
                    ),
                    // Total Fee
                    DataCell(
                      Text(
                        Money.formatRupees(structure.totalFee),
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: Color(0xFF109F83),
                        ),
                      ),
                    ),
                    // Due Date
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 13,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                          const SizedBox(width: 5),
                          Text(structure.dueDate, style: const TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),
                    // Status Badge
                    DataCell(
                      _buildStatusBadge(structure.isActive),
                    ),
                    // Actions
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // View
                          IconButton(
                            icon: const Icon(Icons.visibility_outlined, size: 18),
                            tooltip: 'View details',
                            onPressed: () => showFeeStructurePanel(
                              context: context,
                              existing: structure,
                              isViewOnly: true,
                            ),
                          ),
                          // Edit
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit structure',
                            onPressed: () => showFeeStructurePanel(
                              context: context,
                              existing: structure,
                              isViewOnly: false,
                              onRefresh: () => ref
                                  .read(feeStructuresControllerProvider.notifier)
                                  .refresh(),
                            ),
                          ),
                          // Deactivate / Activate
                          IconButton(
                            icon: Icon(
                              structure.isActive
                                  ? Icons.pause_circle_outline
                                  : Icons.play_circle_outline,
                              size: 18,
                              color: structure.isActive ? Colors.orange : const Color(0xFF109F83),
                            ),
                            tooltip: structure.isActive ? 'Deactivate structure' : 'Activate structure',
                            onPressed: () => _handleToggleActive(structure),
                          ),
                          // Delete
                          IconButton(
                            icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                            tooltip: 'Delete structure',
                            onPressed: () => _handleDelete(structure),
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
  }

  Widget _buildMobileCardList(List<FeeStructure> items, bool isDark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final s = items[index];
        return Container(
          padding: const EdgeInsets.all(14),
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
              // Top Row: Class + Term + Status Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF109F83).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          s.className,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF109F83),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${s.termName} • ${s.academicYear}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  _buildStatusBadge(s.isActive),
                ],
              ),
              const SizedBox(height: 12),

              // Fee Breakdown Grid
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _buildMobileFeeRow('Tuition Fee', Money.formatRupees(s.tuitionFee), isDark),
                    const SizedBox(height: 4),
                    _buildMobileFeeRow('Lab & Computer', Money.formatRupees(s.labComputerFee), isDark),
                    const SizedBox(height: 4),
                    _buildMobileFeeRow('Development', Money.formatRupees(s.developmentFee), isDark),
                    const SizedBox(height: 4),
                    _buildMobileFeeRow('Other Charges', Money.formatRupees(s.otherFee), isDark),
                    const Divider(height: 14),
                    _buildMobileFeeRow(
                      'Total Fee',
                      Money.formatRupees(s.totalFee),
                      isDark,
                      isTotal: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Due Date Row
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Due: ${s.dueDate}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => showFeeStructurePanel(
                      context: context,
                      existing: s,
                      isViewOnly: true,
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 16),
                    label: const Text('View', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    onPressed: () => showFeeStructurePanel(
                      context: context,
                      existing: s,
                      isViewOnly: false,
                      onRefresh: () =>
                          ref.read(feeStructuresControllerProvider.notifier).refresh(),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit', style: TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(
                      s.isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                      size: 18,
                      color: s.isActive ? Colors.orange : const Color(0xFF109F83),
                    ),
                    tooltip: s.isActive ? 'Deactivate' : 'Activate',
                    onPressed: () => _handleToggleActive(s),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                    tooltip: 'Delete',
                    onPressed: () => _handleDelete(s),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileFeeRow(String title, String amount, bool isDark, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.normal,
            color: isTotal
                ? (isDark ? Colors.white : const Color(0xFF0F172A))
                : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700),
          ),
        ),
        Text(
          amount,
          style: TextStyle(
            fontSize: isTotal ? 13 : 11.5,
            fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
            color: isTotal ? const Color(0xFF109F83) : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    final color = isActive ? const Color(0xFF109F83) : Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

