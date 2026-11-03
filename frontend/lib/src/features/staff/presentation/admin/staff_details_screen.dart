import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/staff_controller.dart';
import '../../domain/staff_member_model.dart';
import '../widgets/staff_id_badge_view.dart';
import 'tabs/staff_profile_tab.dart';
import 'tabs/staff_class_routine_tab.dart';
import 'tabs/staff_attendance_tab.dart';
import 'tabs/staff_leave_tab.dart';
import 'tabs/staff_payroll_tab.dart';
import 'tabs/staff_library_tab.dart';

class StaffDetailsScreen extends ConsumerStatefulWidget {
  final String? staffId;
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final ValueChanged<StaffMemberModel>? onEditStaff;

  const StaffDetailsScreen({
    super.key,
    this.staffId,
    required this.isDark,
    this.onToggleTheme,
    this.onNavigate,
    this.onEditStaff,
  });

  @override
  ConsumerState<StaffDetailsScreen> createState() => _StaffDetailsScreenState();
}

class _StaffDetailsScreenState extends ConsumerState<StaffDetailsScreen> {
  int _activeTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final staffListAsync = ref.watch(staffListProvider);
    final activeStaffId = widget.staffId ?? ref.watch(selectedStaffIdProvider);
    final staff = ref.watch(staffDetailsProvider(activeStaffId));
    final allStaff = staffListAsync.valueOrNull ?? [];

    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    Widget bodyContent;
    if (staffListAsync.isLoading) {
      bodyContent = const Center(
        child: CircularProgressIndicator(color: Color(0xFF109F83)),
      );
    } else if (staff == null) {
      bodyContent = _buildNoStaffSelected(allStaff, isDark, textColor, subColor);
    } else {
      final isTeaching = staff.category == StaffCategory.teaching;
      final tabLabels = [
        isTeaching ? 'Teacher Details' : 'Staff Details',
        isTeaching ? 'Class Routine' : 'Duty Schedule',
        'Attendance',
        'Leave',
        'Payroll',
        'Library',
      ];

      bodyContent = SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Bar: Back Button & Quick Directory Switcher
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final titleRow = Row(
                  children: [
                    IconButton(
                      onPressed: () => widget.onNavigate?.call(EdupluseNavPage.staffList),
                      icon: const Icon(Icons.arrow_back),
                      tooltip: 'Back to Directory',
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Staff 360° Profile Dossier',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                  ],
                );

                final switcher = SizedBox(
                  width: isNarrow ? double.infinity : 240,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: borderColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: staff.id,
                        isDense: true,
                        isExpanded: true,
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        dropdownColor: cardBg,
                        style: TextStyle(fontSize: 12, color: textColor),
                        items: allStaff.map((s) {
                          return DropdownMenuItem(
                            value: s.id,
                            child: Text(s.fullName, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (newId) {
                          if (newId != null) {
                            ref.read(selectedStaffIdProvider.notifier).state = newId;
                          }
                        },
                      ),
                    ),
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleRow,
                      const SizedBox(height: 8),
                      switcher,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: titleRow),
                    const SizedBox(width: 12),
                    switcher,
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

            // Hero Banner Card
            _buildHeroBanner(staff, isDark, cardBg, borderColor, textColor, subColor),

            const SizedBox(height: 20),

            // Tab Navigation (Matching Screenshots with horizontal scroll on mobile)
            _buildCategorySubTabs(tabLabels, cardBg, borderColor, textColor, subColor),

            const SizedBox(height: 20),

            // Active Tab Content
            _buildTabContent(staff, isDark),
          ],
        ),
      );
    }

    return EdupluseScaffold(
      activePage: EdupluseNavPage.staffDetails,
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      onNavigate: widget.onNavigate,
      body: Container(
        color: bgColor,
        child: bodyContent,
      ),
    );
  }

  Widget _buildCategorySubTabs(
    List<String> tabs,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              key: ValueKey('staff_details_subtab_$index'),
              onTap: () => setState(() => _activeTabIndex = index),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTabIcon(index),
                      size: 16,
                      color: isSelected ? const Color(0xFF8B5CF6) : subColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      tabs[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? const Color(0xFF8B5CF6) : subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  IconData _getTabIcon(int index) {
    switch (index) {
      case 0:
        return Icons.person_outline;
      case 1:
        return Icons.calendar_today_outlined;
      case 2:
        return Icons.event_available_outlined;
      case 3:
        return Icons.flight_takeoff_outlined;
      case 4:
        return Icons.account_balance_wallet_outlined;
      case 5:
        return Icons.local_library_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildTabContent(StaffMemberModel staff, bool isDark) {
    switch (_activeTabIndex) {
      case 0:
        return StaffProfileTab(staff: staff, isDark: isDark);
      case 1:
        return StaffClassRoutineTab(staff: staff, isDark: isDark);
      case 2:
        return StaffAttendanceTab(staff: staff, isDark: isDark);
      case 3:
        return StaffLeaveTab(staff: staff, isDark: isDark);
      case 4:
        return StaffPayrollTab(staff: staff, isDark: isDark);
      case 5:
        return StaffLibraryTab(staff: staff, isDark: isDark);
      default:
        return StaffProfileTab(staff: staff, isDark: isDark);
    }
  }

  Widget _buildHeroBanner(
    StaffMemberModel staff,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    Color catColor = const Color(0xFF109F83);
    if (staff.category == StaffCategory.administrative) catColor = const Color(0xFF3B82F6);
    if (staff.category == StaffCategory.support) catColor = const Color(0xFFF59E0B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 650;

          final avatarAndBio = Row(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [catColor.withValues(alpha: 0.8), catColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  staff.initials,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            staff.fullName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            staff.status.label,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      staff.designation,
                      style: TextStyle(fontSize: 14, color: subColor, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      children: [
                        Text(
                          'ID: ${staff.id}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: catColor,
                            fontFamily: 'monospace',
                          ),
                        ),
                        Text('•', style: TextStyle(color: subColor)),
                        Text(staff.department, style: TextStyle(fontSize: 12, color: subColor)),
                        Text('•', style: TextStyle(color: subColor)),
                        Text(staff.employmentType.label, style: TextStyle(fontSize: 12, color: subColor)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );

          final actionButtons = Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  if (widget.onEditStaff != null) {
                    widget.onEditStaff!(staff);
                  } else {
                    widget.onNavigate?.call(EdupluseNavPage.editStaff);
                  }
                },
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit Profile'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showIdBadgeDialog(context, staff, isDark),
                icon: const Icon(Icons.badge_outlined, size: 16),
                label: const Text('ID Badge'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF109F83),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                avatarAndBio,
                const SizedBox(height: 16),
                actionButtons,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: avatarAndBio),
              const SizedBox(width: 16),
              actionButtons,
            ],
          );
        },
      ),
    );
  }

  void _showIdBadgeDialog(BuildContext context, StaffMemberModel staff, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.badge_outlined, color: Color(0xFF109F83)),
                        SizedBox(width: 8),
                        Text(
                          'Staff Official ID Badge',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StaffIdBadgeView(staff: staff, isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoStaffSelected(
    List<StaffMemberModel> allStaff,
    bool isDark,
    Color textColor,
    Color subColor,
  ) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.badge_outlined, size: 64, color: subColor),
            const SizedBox(height: 16),
            Text(
              'No Staff Member Selected',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Select an employee from the directory to review their comprehensive 360° dossier.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: subColor),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => widget.onNavigate?.call(EdupluseNavPage.staffList),
              icon: const Icon(Icons.people_outline, size: 16),
              label: const Text('Open Staff Directory'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF109F83),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
