import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/daily_lessons_controller.dart';
import '../../domain/daily_lesson_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

const List<String> kStandardPeriods = [
  'P1 (08:00 - 08:45)',
  'P2 (08:45 - 09:30)',
  'P3 (09:30 - 10:15)',
  'P4 (10:30 - 11:15)',
  'P5 (11:15 - 12:00)',
  'P6 (12:40 - 01:25)',
  'P7 (01:25 - 02:10)',
];

/// Daily Teaching Log & Monitoring Screen:
/// Admin Monitoring Grid vs Student Feed tabs, KPI cards,
/// centered smaller search bar, full-width responsive layout,
/// Period, Class, Section, Teacher, Today's Topic, Status, and working Publish/Delete actions.
class DailyLessonsScreen extends ConsumerStatefulWidget {
  const DailyLessonsScreen({super.key});

  @override
  ConsumerState<DailyLessonsScreen> createState() => _DailyLessonsScreenState();
}

class _DailyLessonsScreenState extends ConsumerState<DailyLessonsScreen> {
  int _activeTabIndex = 0; // 0 = Admin Monitoring Grid, 1 = Student Feed
  String _selectedClassFilter = 'All';
  String _selectedSubjectFilter = 'All';
  String _selectedStatusFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    final lessonsAsync = ref.watch(dailyLessonsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AccessGuard(
      allowed: perms.canAccessClasses,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final screenWidth = constraints.maxWidth;
          final isMobile = screenWidth < 768;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 12 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Bar: Title + Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Lessons',
                            style: TextStyle(
                              fontSize: isMobile ? 18 : 22,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Daily teaching log, topics taught, homework & student publication',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (perms.canWriteLessons)
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF109F83),
                          padding: EdgeInsets.symmetric(
                            horizontal: isMobile ? 12 : 16,
                            vertical: isMobile ? 8 : 10,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(
                          '+ Record Lesson Log',
                          style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w600),
                        ),
                        onPressed: () => _openLessonModal(context, ref, lookup),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tab Selector: Admin Monitoring Grid vs Student Feed
                Row(
                  children: [
                    _buildTabButton(
                      title: 'Admin Monitoring Grid',
                      isSelected: _activeTabIndex == 0,
                      onTap: () => setState(() => _activeTabIndex = 0),
                      isDark: isDark,
                    ),
                    const SizedBox(width: 8),
                    _buildTabButton(
                      title: 'Student "What Did I Learn Today?" Feed',
                      isSelected: _activeTabIndex == 1,
                      onTap: () => setState(() => _activeTabIndex = 1),
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // 4 Compact Metric Cards
                lessonsAsync.maybeWhen(
                  data: (lessons) {
                    final totalExpected = 7;
                    final submitted = lessons.length;
                    final published = lessons.where((l) => l.status == 'Published' || l.notes.isNotEmpty).length;
                    final pending = (submitted - published).clamp(0, totalExpected);

                    final cardWidth = (screenWidth - (isMobile ? 24 : 64) - (isMobile ? 8 : 24)) / (isMobile ? 2 : 4);
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildKpiCard(
                          count: '$totalExpected',
                          label: 'Lessons Expected Today',
                          icon: Icons.access_time_rounded,
                          iconColor: const Color(0xFF3B82F6),
                          bgColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          count: '$submitted',
                          label: 'Lessons Submitted',
                          icon: Icons.post_add_outlined,
                          iconColor: const Color(0xFF14B8A6),
                          bgColor: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          count: '$published',
                          label: 'Published to Students',
                          icon: Icons.check_circle_outline,
                          iconColor: const Color(0xFF10B981),
                          bgColor: const Color(0xFF10B981).withValues(alpha: 0.1),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                        _buildKpiCard(
                          count: '$pending',
                          label: 'Pending Review / Draft',
                          icon: Icons.assignment_late_outlined,
                          iconColor: const Color(0xFFF59E0B),
                          bgColor: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                          width: cardWidth,
                          isDark: isDark,
                        ),
                      ],
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Main Card Container with Controls + Table / Feed
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
                      // Filter Dropdowns Row with centered smaller search bar
                      _buildFilterAndSearchRow(lookup, isDark, isMobile),
                      const Divider(height: 24),

                      // Content based on active tab
                      lessonsAsync.when(
                        data: (items) {
                          if (_activeTabIndex == 0) {
                            return _buildLessonsTable(items, lookup, isDark, isMobile, screenWidth);
                          } else {
                            return _buildStudentFeedView(items, lookup, isDark, isMobile);
                          }
                        },
                        loading: () => const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (err, _) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF109F83)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF109F83)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String count,
    required String label,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required double width,
    required bool isDark,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterAndSearchRow(ClassesLookup lookup, bool isDark, bool isMobile) {
    final searchWidget = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 200),
      child: SizedBox(
        height: 32,
        child: TextField(
          controller: _searchController,
          style: const TextStyle(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'Search topic / notes...',
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
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
          ),
        ),
      ),
    );

    if (isMobile) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _buildDropdownContainer(
            label: 'Class',
            value: _selectedClassFilter,
            items: ['All', ...lookup.classes.map((c) => c.name)],
            onChanged: (v) {
              if (v != null) setState(() => _selectedClassFilter = v);
            },
            isDark: isDark,
          ),
          _buildDropdownContainer(
            label: 'Subject',
            value: _selectedSubjectFilter,
            items: ['All', ...lookup.subjects.map((s) => s.name).toSet()],
            onChanged: (v) {
              if (v != null) setState(() => _selectedSubjectFilter = v);
            },
            isDark: isDark,
          ),
          _buildDropdownContainer(
            label: 'Status',
            value: _selectedStatusFilter,
            items: const ['All', 'Published', 'Pending Review'],
            onChanged: (v) {
              if (v != null) setState(() => _selectedStatusFilter = v);
            },
            isDark: isDark,
          ),
          Center(child: searchWidget),
        ],
      );
    }

    return Row(
      children: [
        // Left filters
        Wrap(
          spacing: 8,
          children: [
            _buildDropdownContainer(
              label: 'Class',
              value: _selectedClassFilter,
              items: ['All', ...lookup.classes.map((c) => c.name)],
              onChanged: (v) {
                if (v != null) setState(() => _selectedClassFilter = v);
              },
              isDark: isDark,
            ),
            _buildDropdownContainer(
              label: 'Subject',
              value: _selectedSubjectFilter,
              items: ['All', ...lookup.subjects.map((s) => s.name).toSet()],
              onChanged: (v) {
                if (v != null) setState(() => _selectedSubjectFilter = v);
              },
              isDark: isDark,
            ),
            _buildDropdownContainer(
              label: 'Status',
              value: _selectedStatusFilter,
              items: const ['All', 'Published', 'Pending Review'],
              onChanged: (v) {
                if (v != null) setState(() => _selectedStatusFilter = v);
              },
              isDark: isDark,
            ),
          ],
        ),
        // Center: Smaller search bar
        Expanded(
          child: Center(
            child: searchWidget,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownContainer({
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
          Text('$label: ', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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

  Widget _buildLessonsTable(
    List<DailyLessonModel> items,
    ClassesLookup lookup,
    bool isDark,
    bool isMobile,
    double screenWidth,
  ) {
    final perms = ref.watch(classesPermissionsProvider);

    final filtered = items.where((l) {
      final className = lookup.className(l.classId);
      final subName = lookup.subjectName(l.subjectId);
      final isPublished = l.status == 'Published' || l.notes.isNotEmpty;

      if (_selectedClassFilter != 'All' && className != _selectedClassFilter) return false;
      if (_selectedSubjectFilter != 'All' && subName != _selectedSubjectFilter) return false;
      if (_selectedStatusFilter == 'Published' && !isPublished) return false;
      if (_selectedStatusFilter == 'Pending Review' && isPublished) return false;

      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery;
        final teacher = lookup.teacherName(l.teacherId).toLowerCase();
        final topic = l.title.toLowerCase();
        final notes = l.notes.toLowerCase();
        final hw = l.homework.toLowerCase();
        return topic.contains(q) || notes.contains(q) || hw.contains(q) || teacher.contains(q) || subName.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: const Text('No lessons match the selected filters.', style: TextStyle(color: Colors.grey)),
      );
    }

    final tableMinWidth = (screenWidth - (isMobile ? 48 : 80)).clamp(850.0, 2400.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableMinWidth),
            child: DataTable(
              showCheckboxColumn: false,
              horizontalMargin: 14,
              columnSpacing: 18,
              headingRowHeight: 40,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 68,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              columns: const [
                DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Class', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Section', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Teacher', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text("Today's Topic", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
              ],
              rows: filtered.map((l) {
                final isPublished = l.status == 'Published';
                final periodLabel = l.periodLabel.isNotEmpty
                    ? l.periodLabel
                    : (filtered.indexOf(l) < kStandardPeriods.length
                        ? kStandardPeriods[filtered.indexOf(l)]
                        : 'P${filtered.indexOf(l) + 1} (08:00 - 08:45)');

                final sectionName = l.sectionId.isNotEmpty
                    ? lookup.sectionName(l.sectionId)
                    : 'A';

                return DataRow(
                  cells: [
                    // Period
                    DataCell(
                      Text(
                        periodLabel,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                      ),
                    ),
                    // Class
                    DataCell(
                      Text(
                        lookup.className(l.classId),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    // Section
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          sectionName,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
                        ),
                      ),
                    ),
                    // Teacher
                    DataCell(
                      Text(
                        lookup.teacherName(l.teacherId),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                    // Today's Topic
                    DataCell(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 240),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              l.title,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (l.notes.isNotEmpty || l.homework.isNotEmpty)
                              Text(
                                l.notes.isNotEmpty ? l.notes : l.homework,
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Status Badge
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isPublished
                              ? const Color(0xFF10B981).withValues(alpha: 0.12)
                              : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isPublished ? 'Published' : 'Draft / Pending',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isPublished ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ),
                    // Actions: Publish & Delete clearly provided and working
                    DataCell(
                      perms.canWriteLessons
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Publish / Unpublish button
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                    foregroundColor: isPublished ? const Color(0xFF64748B) : const Color(0xFF109F83),
                                  ),
                                  icon: Icon(
                                    isPublished ? Icons.unpublished_outlined : Icons.publish_rounded,
                                    size: 15,
                                  ),
                                  label: Text(
                                    isPublished ? 'Unpublish' : 'Publish',
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () async {
                                    final newStatus = isPublished ? 'Draft' : 'Published';
                                    await runClassesAction(
                                      context,
                                      () => ref.read(dailyLessonsControllerProvider.notifier).save(
                                            l.copyWith(status: newStatus),
                                            isNew: false,
                                          ),
                                      success: isPublished ? 'Lesson unpublished' : 'Lesson published successfully',
                                    );
                                  },
                                ),
                                const SizedBox(width: 4),
                                // Edit
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  tooltip: 'Edit Log',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => _openLessonModal(context, ref, lookup, existing: l),
                                ),
                                // Delete
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  tooltip: 'Delete Log',
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () async {
                                    if (await confirmDelete(context, l.title)) {
                                      if (!mounted) return;
                                      await runClassesAction(
                                        context,
                                        () => ref.read(dailyLessonsControllerProvider.notifier).delete(l.id),
                                        success: 'Lesson deleted successfully',
                                      );
                                    }
                                  },
                                ),
                              ],
                            )
                          : const Text('—', style: TextStyle(color: Colors.grey)),
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

  Widget _buildStudentFeedView(
    List<DailyLessonModel> items,
    ClassesLookup lookup,
    bool isDark,
    bool isMobile,
  ) {
    final published = items.where((l) => l.status == 'Published' || l.notes.isNotEmpty).toList();

    if (published.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(40),
        alignment: Alignment.center,
        child: const Text('No published lessons available today.', style: TextStyle(color: Colors.grey)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: published.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final l = published[i];
        final period = l.periodLabel.isNotEmpty ? l.periodLabel : (i < kStandardPeriods.length ? kStandardPeriods[i] : 'P${i + 1}');

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      period,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${lookup.className(l.classId)} - ${l.sectionId.isNotEmpty ? lookup.sectionName(l.sectionId) : 'A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${lookup.subjectName(l.subjectId)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const Spacer(),
                  Text(
                    'Teacher: ${lookup.teacherName(l.teacherId)}',
                    style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                l.title,
                style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
              ),
              if (l.notes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  'Topics covered: ${l.notes}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ],
              if (l.homework.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Homework: ${l.homework}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: Color(0xFFB45309)),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Inline modal form to record lesson log directly on page without route navigation
  Future<void> _openLessonModal(
    BuildContext context,
    WidgetRef ref,
    ClassesLookup lookup, {
    DailyLessonModel? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final notesCtrl = TextEditingController(text: existing?.notes ?? '');
    final homeworkCtrl = TextEditingController(text: existing?.homework ?? '');
    var classId = existing?.classId ?? (lookup.classes.isNotEmpty ? lookup.classes.first.id : '');
    var sectionId = existing?.sectionId ?? (lookup.sections.where((s) => s.classId == classId).isNotEmpty
        ? lookup.sections.where((s) => s.classId == classId).first.id
        : (lookup.sections.isNotEmpty ? lookup.sections.first.id : ''));
    var subjectId = existing?.subjectId ?? (lookup.subjects.where((s) => s.classId == classId).isNotEmpty
        ? lookup.subjects.where((s) => s.classId == classId).first.id
        : (lookup.subjects.isNotEmpty ? lookup.subjects.first.id : ''));
    var periodLabel = existing?.periodLabel.isNotEmpty == true
        ? existing!.periodLabel
        : kStandardPeriods.first;
    String? teacherId = existing?.teacherId ?? (lookup.teachers.isNotEmpty ? lookup.teachers.first.id : null);
    var isPublished = existing?.status == 'Published' || existing == null;
    String? formError;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final sectionsForClass = lookup.sections.where((s) => s.classId == classId).toList();
          final subjectsForClass = lookup.subjects.where((s) => s.classId == classId).toList();

          return AlertDialog(
            title: Row(
              children: [
                Icon(
                  existing == null ? Icons.post_add_rounded : Icons.edit_outlined,
                  color: const Color(0xFF109F83),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  existing == null ? 'Record Daily Lesson Log' : 'Edit Lesson Log',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SizedBox(
              width: 480,
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

                    // Class and Section Row
                    Row(
                      children: [
                        // Class
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Class', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: lookup.classes.any((c) => c.id == classId) ? classId : null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: lookup.classes.map((c) {
                                  return DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() {
                                      classId = v;
                                      final secs = lookup.sections.where((s) => s.classId == v).toList();
                                      if (secs.isNotEmpty) sectionId = secs.first.id;
                                      final subs = lookup.subjects.where((s) => s.classId == v).toList();
                                      if (subs.isNotEmpty) {
                                        subjectId = subs.first.id;
                                        if (subs.first.teacherId != null && subs.first.teacherId!.isNotEmpty) {
                                          teacherId = subs.first.teacherId;
                                        }
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Section
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Section', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: sectionsForClass.any((s) => s.id == sectionId)
                                    ? sectionId
                                    : (sectionsForClass.isNotEmpty ? sectionsForClass.first.id : null),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: (sectionsForClass.isNotEmpty ? sectionsForClass : lookup.sections).map((s) {
                                  return DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => sectionId = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Subject and Period Row
                    Row(
                      children: [
                        // Subject
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Subject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: subjectsForClass.any((s) => s.id == subjectId)
                                    ? subjectId
                                    : (subjectsForClass.isNotEmpty
                                        ? subjectsForClass.first.id
                                        : (lookup.subjects.isNotEmpty ? lookup.subjects.first.id : null)),
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: (subjectsForClass.isNotEmpty ? subjectsForClass : lookup.subjects).map((s) {
                                  return DropdownMenuItem(
                                    value: s.id,
                                    child: Text(s.name, style: const TextStyle(fontSize: 13)),
                                  );
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) {
                                    setDialogState(() {
                                      subjectId = v;
                                      final matchedSub = lookup.subjects.where((s) => s.id == v).firstOrNull;
                                      if (matchedSub?.teacherId != null && matchedSub!.teacherId!.isNotEmpty) {
                                        teacherId = matchedSub.teacherId;
                                      }
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Period
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Period', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<String>(
                                value: kStandardPeriods.contains(periodLabel) ? periodLabel : kStandardPeriods.first,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                ),
                                items: kStandardPeriods.map((p) {
                                  return DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 12)));
                                }).toList(),
                                onChanged: (v) {
                                  if (v != null) setDialogState(() => periodLabel = v);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Teacher
                    const Text('Assigned Teacher', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: lookup.teachers.any((t) => t.id == teacherId)
                          ? teacherId
                          : (lookup.teachers.isNotEmpty ? lookup.teachers.first.id : null),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: lookup.teachers.map((t) {
                        return DropdownMenuItem(value: t.id, child: Text(t.name, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => teacherId = v);
                      },
                    ),
                    const SizedBox(height: 12),

                    // Topic Taught Today
                    const Text("Today's Topic", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: titleCtrl,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Elimination Method & Linear Systems',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes / Summary
                    const Text('Topics Covered / Summary Notes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: notesCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Solved 4 comprehensive examples of elimination method',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Homework
                    const Text('Homework / Assignment', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    TextFormField(
                      controller: homeworkCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Complete NCERT Ex 3.3, Questions 1 through 6 in notebook',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Publish Toggle
                    Row(
                      children: [
                        Checkbox(
                          value: isPublished,
                          activeColor: const Color(0xFF109F83),
                          onChanged: (v) => setDialogState(() => isPublished = v ?? false),
                        ),
                        const Text(
                          'Publish to students immediately',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ],
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
                    setDialogState(() => formError = "Today's topic is required");
                    return;
                  }

                  try {
                    final actor = ref.read(classesActorProvider);
                    final model = DailyLessonModel(
                      id: existing?.id ?? '',
                      classId: classId,
                      sectionId: sectionId,
                      subjectId: subjectId,
                      teacherId: (teacherId != null && teacherId!.isNotEmpty) ? teacherId! : (existing?.teacherId ?? actor.userId),
                      periodLabel: periodLabel,
                      date: existing?.date ?? DateTime.now(),
                      title: title,
                      notes: notesCtrl.text.trim(),
                      homework: homeworkCtrl.text.trim(),
                      status: isPublished ? 'Published' : 'Draft',
                    );
                    await ref.read(dailyLessonsControllerProvider.notifier).save(
                          model,
                          isNew: existing == null,
                        );
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(existing == null ? 'Lesson log submitted successfully' : 'Lesson log updated successfully'),
                          backgroundColor: const Color(0xFF10B981),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  } catch (e) {
                    setDialogState(() {
                      formError = e.toString().replaceAll('Exception:', '').trim();
                    });
                  }
                },
                child: Text(existing == null ? 'Submit Log' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
