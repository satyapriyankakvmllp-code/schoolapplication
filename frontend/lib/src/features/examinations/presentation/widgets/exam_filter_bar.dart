import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_controller.dart';
import '../../application/examination_access.dart';

class ExamFilterBar extends ConsumerStatefulWidget {
  const ExamFilterBar({super.key});

  @override
  ConsumerState<ExamFilterBar> createState() => _ExamFilterBarState();
}

class _ExamFilterBarState extends ConsumerState<ExamFilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final filter = ref.read(examFilterProvider);
    _searchController = TextEditingController(text: filter.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final setup = ref.watch(globalSetupProvider).valueOrNull;
    final filter = ref.watch(examFilterProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final academicYears = setup?.academicYears ?? ['2025-2026', '2026-2027'];
    final examTypes = setup?.examTypes ?? [];

    return Container(
      padding: const EdgeInsets.all(12),
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
          // Search box
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 200, maxWidth: 320),
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _searchController,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search exams by name...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8),
                  ),
                  prefixIcon: const Icon(Icons.search, size: 18),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 16),
                          onPressed: () {
                            _searchController.clear();
                            ref.read(examFilterProvider.notifier).state =
                                filter.copyWith(searchQuery: '');
                          },
                        )
                      : null,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                onChanged: (val) {
                  setState(() {});
                  ref.read(examFilterProvider.notifier).state =
                      filter.copyWith(searchQuery: val);
                },
              ),
            ),
          ),

          // Academic Year Dropdown
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 180),
            child: SizedBox(
              height: 38,
              child: DropdownButtonFormField<String>(
                initialValue: filter.academicYear ?? setup?.currentAcademicYear ?? '2026-2027',
                isExpanded: true,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Academic Year',
                  labelStyle: const TextStyle(fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'All Years',
                    child: Text('All Years', style: TextStyle(fontSize: 12.5)),
                  ),
                  ...academicYears.map(
                    (y) => DropdownMenuItem(
                      value: y,
                      child: Text(y, style: const TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(examFilterProvider.notifier).state =
                        filter.copyWith(academicYear: val == 'All Years' ? 'All' : val);
                  }
                },
              ),
            ),
          ),

          // Exam Type Dropdown
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
            child: SizedBox(
              height: 38,
              child: DropdownButtonFormField<String>(
                initialValue: filter.examType ?? 'All',
                isExpanded: true,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Exam Type',
                  labelStyle: const TextStyle(fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: 'All',
                    child: Text('All Types', style: TextStyle(fontSize: 12.5)),
                  ),
                  ...examTypes.map(
                    (t) => DropdownMenuItem(
                      value: t.code,
                      child: Text(t.label, style: const TextStyle(fontSize: 12.5)),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(examFilterProvider.notifier).state =
                        filter.copyWith(examType: val);
                  }
                },
              ),
            ),
          ),

          // Status Dropdown
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 130, maxWidth: 160),
            child: SizedBox(
              height: 38,
              child: DropdownButtonFormField<String>(
                initialValue: filter.status ?? 'All',
                isExpanded: true,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  labelText: 'Status',
                  labelStyle: const TextStyle(fontSize: 11),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Statuses', style: TextStyle(fontSize: 12.5))),
                  DropdownMenuItem(value: 'PLANNED', child: Text('Planned', style: TextStyle(fontSize: 12.5))),
                  DropdownMenuItem(value: 'ONGOING', child: Text('Ongoing', style: TextStyle(fontSize: 12.5))),
                  DropdownMenuItem(value: 'COMPLETED', child: Text('Completed', style: TextStyle(fontSize: 12.5))),
                  DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled', style: TextStyle(fontSize: 12.5))),
                ],
                onChanged: (val) {
                  if (val != null) {
                    ref.read(examFilterProvider.notifier).state =
                        filter.copyWith(status: val);
                  }
                },
              ),
            ),
          ),

          // Reset button if filters active
          if (filter.searchQuery.isNotEmpty ||
              filter.examType != null && filter.examType != 'All' ||
              filter.status != null && filter.status != 'All' ||
              (filter.academicYear != (setup?.currentAcademicYear ?? '2026-2027'))) ...[
            TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.refresh, size: 14),
              label: const Text('Reset', style: TextStyle(fontSize: 12)),
              onPressed: () {
                _searchController.clear();
                ref.read(examFilterProvider.notifier).state = ExamFilterState(
                  academicYear: setup?.currentAcademicYear ?? '2026-2027',
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
