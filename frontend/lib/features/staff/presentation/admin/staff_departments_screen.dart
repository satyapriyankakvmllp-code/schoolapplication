import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/staff_controller.dart';
import '../../domain/staff_member_model.dart';

class StaffDepartmentsScreen extends ConsumerWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final ValueChanged<String>? onSelectStaff;

  const StaffDepartmentsScreen({
    super.key,
    required this.isDark,
    this.onToggleTheme,
    this.onNavigate,
    this.onSelectStaff,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffListProvider);

    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return EdupluseScaffold(
      activePage: EdupluseNavPage.staffDepartments,
      isDark: isDark,
      onToggleTheme: onToggleTheme,
      onNavigate: onNavigate,
      body: Container(
        color: bgColor,
        child: staffAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Color(0xFF109F83)),
          ),
          error: (err, _) => Center(
            child: Text('Error loading departments: $err', style: TextStyle(color: textColor)),
          ),
          data: (staffList) {
            // Group staff by department
            final Map<String, List<StaffMemberModel>> deptMap = {};
            for (final staff in staffList) {
              deptMap.putIfAbsent(staff.department, () => []).add(staff);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final isNarrow = constraints.maxWidth < 600;
                      final headerText = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Departments & Faculty Roster',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Institutional headcount breakdown and designation matrix across departments.',
                            style: TextStyle(fontSize: 13, color: subColor),
                          ),
                        ],
                      );

                      final addBtn = ElevatedButton.icon(
                        onPressed: () => onNavigate?.call(EdupluseNavPage.addNewStaff),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Staff'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF109F83),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      );

                      if (isNarrow) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            headerText,
                            const SizedBox(height: 12),
                            addBtn,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: headerText),
                          const SizedBox(width: 16),
                          addBtn,
                        ],
                      );
                    },
                  ),

              const SizedBox(height: 20),

              // Department Grid
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  int cols = 1;
                  if (width >= 700 && width < 1100) cols = 2;
                  if (width >= 1100) cols = 3;

                  final itemWidth = (width - ((cols - 1) * 16)) / cols;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: deptMap.entries.map((entry) {
                      final deptName = entry.key;
                      final members = entry.value;

                      // Find HOD or lead
                      StaffMemberModel? hod;
                      try {
                        hod = members.firstWhere((m) =>
                            m.designation.toLowerCase().contains('hod') ||
                            m.designation.toLowerCase().contains('head') ||
                            m.designation.toLowerCase().contains('chief'));
                      } catch (_) {
                        hod = members.isNotEmpty ? members.first : null;
                      }

                      return SizedBox(
                        width: itemWidth,
                        child: Container(
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Department Header
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF109F83).withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(Icons.apartment_outlined, color: Color(0xFF109F83), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          deptName,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: textColor,
                                          ),
                                        ),
                                        Text(
                                          '${members.length} Member(s)',
                                          style: TextStyle(fontSize: 12, color: subColor),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 14),

                              // HOD / Lead Card
                              if (hod != null)
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star, size: 14, color: Color(0xFFF59E0B)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'Lead: ${hod.fullName}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),

                              // Staff List in Dept
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: members.take(4).length,
                                separatorBuilder: (_, _) => const SizedBox(height: 8),
                                itemBuilder: (context, idx) {
                                  final m = members[idx];
                                  return InkWell(
                                    onTap: () {
                                      ref.read(selectedStaffIdProvider.notifier).state = m.id;
                                      onSelectStaff?.call(m.id);
                                      onNavigate?.call(EdupluseNavPage.staffDetails);
                                    },
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 12,
                                          backgroundColor: const Color(0xFF109F83).withValues(alpha: 0.15),
                                          child: Text(
                                            m.initials,
                                            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            m.fullName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(fontSize: 12, color: textColor),
                                          ),
                                        ),
                                        const Icon(Icons.chevron_right, size: 14, color: Colors.grey),
                                      ],
                                    ),
                                  );
                                },
                              ),

                              if (members.length > 4) ...[
                                const SizedBox(height: 8),
                                Center(
                                  child: Text(
                                    '+${members.length - 4} more personnel',
                                    style: TextStyle(fontSize: 11, color: subColor, fontStyle: FontStyle.italic),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    ),
  ),
);
}
}
