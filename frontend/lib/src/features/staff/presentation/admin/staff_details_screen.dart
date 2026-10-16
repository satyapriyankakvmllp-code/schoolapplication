import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/staff_controller.dart';
import '../../domain/staff_member_model.dart';
import '../widgets/staff_id_badge_view.dart';

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

class _StaffDetailsScreenState extends ConsumerState<StaffDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSalaryRevealed = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
                          width: isNarrow ? double.infinity : 220,
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

                    // Tab Navigation
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: const Color(0xFF109F83),
                        unselectedLabelColor: subColor,
                        indicatorColor: const Color(0xFF109F83),
                        indicatorWeight: 3,
                        tabs: const [
                          Tab(icon: Icon(Icons.badge_outlined, size: 18), text: 'Overview'),
                          Tab(icon: Icon(Icons.school_outlined, size: 18), text: 'Academic Workload'),
                          Tab(icon: Icon(Icons.currency_rupee_outlined, size: 18), text: 'Compensation'),
                          Tab(icon: Icon(Icons.credit_card_outlined, size: 18), text: 'ID Card Studio'),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Tab Views
                    SizedBox(
                      height: 520,
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(staff, isDark, cardBg, borderColor, textColor, subColor),
                          _buildAcademicWorkloadTab(staff, isDark, cardBg, borderColor, textColor, subColor),
                          _buildCompensationTab(staff, isDark, cardBg, borderColor, textColor, subColor),
                          _buildIdBadgeTab(staff, isDark, cardBg, borderColor),
                        ],
                      ),
                    ),
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
                onPressed: () {
                  _tabController.animateTo(3);
                },
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

  Widget _buildOverviewTab(
    StaffMemberModel staff,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Personal & Contact Credentials', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 14),
            _buildDetailRow('Official Email', staff.email, Icons.email_outlined),
            _buildDetailRow('Mobile Phone', staff.phone, Icons.phone_outlined),
            _buildDetailRow('Emergency Contact', staff.emergencyContact ?? 'Not provided', Icons.contact_emergency_outlined),
            _buildDetailRow('Residential Address', staff.currentAddress, Icons.home_outlined),
            _buildDetailRow('Permanent Address', staff.permanentAddress, Icons.location_on_outlined),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 14),
            Text('Institutional Placement', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 14),
            _buildDetailRow('Staff Category', staff.category.label, Icons.category_outlined),
            _buildDetailRow('Department', staff.department, Icons.apartment_outlined),
            _buildDetailRow('Qualification', staff.qualification, Icons.school_outlined),
            _buildDetailRow('Date of Joining', '${staff.joiningDate.day}/${staff.joiningDate.month}/${staff.joiningDate.year}', Icons.calendar_today_outlined),
            _buildDetailRow('Employment Type', staff.employmentType.label, Icons.work_outline),
            if (staff.specialization != null)
              _buildDetailRow('Specialization', staff.specialization!, Icons.psychology_outlined),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicWorkloadTab(
    StaffMemberModel staff,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    if (staff.category != StaffCategory.teaching) {
      return Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info_outline, size: 40, color: subColor),
            const SizedBox(height: 10),
            Text(
              'No Academic Workload',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
            ),
            const SizedBox(height: 4),
            Text(
              'Academic classes and subject duties are applicable only to Teaching faculty.',
              style: TextStyle(fontSize: 12, color: subColor),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Text('Assigned Class Timetables', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              if (staff.isClassTeacher)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFF8B5CF6)),
                      const SizedBox(width: 4),
                      Text(
                        'Primary Class Teacher (${staff.primaryClassAssignment?.grade}-${staff.primaryClassAssignment?.section})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.separated(
              itemCount: staff.assignedClasses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final a = staff.assignedClasses[index];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: a.isClassTeacher
                          ? const Color(0xFF8B5CF6)
                          : borderColor,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF109F83).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${a.grade} - ${a.section}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF109F83)),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.subject, style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 14)),
                            Text('${a.periodsPerWeek} instructional periods per academic week', style: TextStyle(fontSize: 11, color: subColor)),
                          ],
                        ),
                      ),
                      if (a.isClassTeacher)
                        const Chip(
                          label: Text('Class Teacher', style: TextStyle(fontSize: 10, color: Colors.white)),
                          backgroundColor: Color(0xFF8B5CF6),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompensationTab(
    StaffMemberModel staff,
    bool isDark,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
  ) {
    final comp = staff.compensation;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security, size: 18, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Text(
                      'Sensitive HR & Financial Dossier',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _isSalaryRevealed = !_isSalaryRevealed);
                  },
                  icon: Icon(_isSalaryRevealed ? Icons.visibility_off : Icons.visibility, size: 16),
                  label: Text(_isSalaryRevealed ? 'Mask Sensitive Data' : 'Reveal Data'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Basic Monthly Salary',
              _isSalaryRevealed ? '₹ ${comp.basicSalary.toStringAsFixed(0)} / month' : '₹ ••••••• / month',
              Icons.currency_rupee,
            ),
            _buildDetailRow('Pay Frequency', comp.payFrequency, Icons.schedule),
            _buildDetailRow('Bank Name', comp.bankName, Icons.account_balance),
            _buildDetailRow(
              'Account Number',
              _isSalaryRevealed ? comp.accountNumber : comp.maskedAccountNumber,
              Icons.credit_card,
            ),
            _buildDetailRow('IFSC Code', comp.ifscCode, Icons.numbers),
            _buildDetailRow(
              'PAN Card Number',
              _isSalaryRevealed ? comp.panNumber : comp.maskedPanNumber,
              Icons.badge,
            ),
            if (comp.epfUan != null)
              _buildDetailRow(
                'EPF UAN',
                _isSalaryRevealed ? comp.epfUan! : '••••••••••••',
                Icons.fingerprint,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdBadgeTab(
    StaffMemberModel staff,
    bool isDark,
    Color cardBg,
    Color borderColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(20),
      child: Center(
        child: SingleChildScrollView(
          child: StaffIdBadgeView(staff: staff, isDark: isDark),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFF109F83)),
          const SizedBox(width: 10),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
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
