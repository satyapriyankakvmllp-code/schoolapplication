import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/admissions_controller.dart';
import '../../data/admissions_repository.dart';
import '../../domain/student_admission_model.dart';
import '../../domain/student_profile_model.dart';
import 'tabs/student_attendance_tab.dart';
import 'tabs/student_leave_tab.dart';
import 'tabs/student_fees_tab.dart';
import 'tabs/student_exam_tab.dart';
import 'tabs/student_library_tab.dart';

class StudentDetailsScreen extends ConsumerStatefulWidget {
  final String? studentId;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onEdit;
  final ValueChanged<StudentAdmissionModel>? onEditStudent;
  final ValueChanged<String>? onSelectStudent;
  final VoidCallback? onToggleTheme;
  final bool isDark;
  final VoidCallback? onExitToGateway;
  final bool isEmbedded;

  const StudentDetailsScreen({
    super.key,
    this.studentId,
    this.onNavigate,
    this.onEdit,
    this.onEditStudent,
    this.onSelectStudent,
    this.onToggleTheme,
    this.isDark = false,
    this.onExitToGateway,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends ConsumerState<StudentDetailsScreen> {
  int _activeTabIndex = 0;

  final List<String> _tabs = [
    'Student Details',
    'Attendance',
    'Leave',
    'Fees',
    'Exam',
    'Library',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final current = ref.read(selectedStudentIdProvider);
        if (current == null && widget.studentId != null) {
          ref.read(selectedStudentIdProvider.notifier).state = widget.studentId;
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant StudentDetailsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.studentId != oldWidget.studentId && widget.studentId != null) {
      ref.read(selectedStudentIdProvider.notifier).state = widget.studentId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedId = ref.watch(selectedStudentIdProvider);
    final effectiveStudentId = selectedId ?? widget.studentId;
    final allStudents = ref.watch(admissionsListProvider).valueOrNull ?? MockAdmissionsRepository.defaultAdmissions;
    final admission = effectiveStudentId != null
        ? (ref.watch(studentDetailsProvider(effectiveStudentId)).valueOrNull ??
            allStudents.where((s) => s.student.id == effectiveStudentId).firstOrNull)
        : null;

    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    return EdupluseScaffold(
      activePage: EdupluseNavPage.studentDetails,
      onNavigate: widget.onNavigate,
      onToggleTheme: widget.onToggleTheme,
      onExitToGateway: widget.onExitToGateway,
      isDark: widget.isDark,
      isEmbedded: widget.isEmbedded,
      body: admission == null
          ? _buildEmptyStudentDetailsState(allStudents, isDark)
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBreadcrumbAndHeader(admission, allStudents, effectiveStudentId!),
                  const SizedBox(height: 20),
                  _buildTopProfileCard(admission),
                  const SizedBox(height: 24),
                  _buildSubTabs(),
                  const SizedBox(height: 20),
                  _buildTabContent(admission, isDark),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyStudentDetailsState(List<StudentAdmissionModel> allStudents, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row with Title and All Admissions Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student Details',
                          style: TextStyle(
                            fontSize: isMobile ? 20 : 22,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Dashboard / Student / Select Student',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAllAdmissionsSheet(context, allStudents, ''),
                    icon: const Icon(Icons.people_alt_outlined, size: 16),
                    label: Text(
                      isMobile ? 'Admissions (${allStudents.length})' : 'All Admissions (${allStudents.length})',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109F83),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: isMobile ? 9 : 11),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Empty selection hero container
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: isMobile ? 18 : 36, vertical: isMobile ? 28 : 42),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  boxShadow: const [
                    BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF109F83), width: 2),
                      ),
                      child: const Icon(Icons.person_search_outlined, size: 38, color: Color(0xFF109F83)),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'No Student Selected',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 480),
                      child: Text(
                        'Select a student from the admissions list below or search to view their complete academic, attendance, and guardian details.',
                        style: TextStyle(
                          fontSize: 13.5,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 22),
                    // Dropdown to pick student
                    Container(
                      constraints: const BoxConstraints(maxWidth: 380),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF109F83), width: 1.5),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          hint: Row(
                            children: const [
                              Icon(Icons.touch_app, size: 16, color: Color(0xFF109F83)),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Choose student from directory...',
                                  style: TextStyle(fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: allStudents.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.student.id,
                              child: Text(
                                '${s.user.fullName} (${s.student.admissionNumber} - ${s.student.className})',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: (id) {
                            if (id != null) {
                              ref.read(selectedStudentIdProvider.notifier).state = id;
                              widget.onSelectStudent?.call(id);
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Quick select chips
                    if (allStudents.isNotEmpty) ...[
                      Text(
                        'Quick Select:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: allStudents.take(6).map((s) {
                          return ActionChip(
                            avatar: const Icon(Icons.person, size: 15, color: Color(0xFF109F83)),
                            label: Text(
                              '${s.user.fullName} (${s.student.className})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : const Color(0xFF1E293B),
                              ),
                            ),
                            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                            side: BorderSide(
                              color: isDark ? const Color(0xFF475569) : Colors.grey.shade300,
                            ),
                            onPressed: () {
                              ref.read(selectedStudentIdProvider.notifier).state = s.student.id;
                              widget.onSelectStudent?.call(s.student.id);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBreadcrumbAndHeader(
    StudentAdmissionModel admission,
    List<StudentAdmissionModel> allStudents,
    String currentId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;
        final title = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => widget.onNavigate?.call(EdupluseNavPage.studentList),
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back to Student Directory',
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Student Details',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      letterSpacing: -0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Padding(
              padding: EdgeInsets.only(left: isMobile ? 0 : 48),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  InkWell(
                    onTap: () => widget.onNavigate?.call(EdupluseNavPage.studentList),
                    child: Text(
                      'Student List / ',
                      style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    ),
                  ),
                  Text(
                    '${admission.user.fullName} (${admission.student.admissionNumber})',
                    style: const TextStyle(
                      color: Color(0xFF109F83),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );

        final studentSwitcher = Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF109F83), width: 1.2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              isExpanded: isMobile,
              value: allStudents.any((s) => s.student.id == currentId)
                  ? currentId
                  : (allStudents.isNotEmpty ? allStudents.first.student.id : null),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF109F83)),
              items: allStudents.map((s) {
                return DropdownMenuItem<String>(
                  value: s.student.id,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.person_pin, size: 16, color: Color(0xFF109F83)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${s.user.fullName} (${s.student.admissionNumber})',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 12.5,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              onChanged: (newId) {
                if (newId != null) {
                  ref.read(selectedStudentIdProvider.notifier).state = newId;
                }
              },
            ),
          ),
        );

        final viewAllButton = ElevatedButton.icon(
          onPressed: () => _showAllAdmissionsSheet(context, allStudents, currentId),
          icon: const Icon(Icons.people_alt_outlined, size: 16),
          label: Text(
            isMobile ? 'Admissions (${allStudents.length})' : 'All Admissions (${allStudents.length})',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF109F83),
            foregroundColor: Colors.white,
            elevation: 0,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 12 : 16,
              vertical: isMobile ? 9 : 11,
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );

        final actionsRow = Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            viewAllButton,
            studentSwitcher,
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              title,
              const SizedBox(height: 12),
              actionsRow,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: title),
            const SizedBox(width: 16),
            actionsRow,
          ],
        );
      },
    );
  }

  Widget _buildTopProfileCard(StudentAdmissionModel admission) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final student = admission.student;
    final user = admission.user;
    final isEnrolled = student.enrollmentStatus == EnrollmentStatus.enrolled;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 850;

          final profileLeft = Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                  border: Border.all(color: const Color(0xFF109F83), width: 2.5),
                  boxShadow: const [
                    BoxShadow(color: Color(0x10109F83), blurRadius: 8, offset: Offset(0, 4)),
                  ],
                ),
                child: const Center(
                  child: Icon(Icons.face_retouching_natural, size: 56, color: Color(0xFF109F83)),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.fullName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text('Admission No: ', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                  Text(
                    student.admissionNumber,
                    style: const TextStyle(
                      color: Color(0xFF0284C7),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Text(
                'Roll No: ${student.rollNumber ?? '10'}',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 10,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: () => _confirmSuspend(admission),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isEnrolled ? const Color(0xFFEF4444) : const Color(0xFF109F83),
                      side: BorderSide(
                        color: isEnrolled ? const Color(0xFFFCA5A5) : const Color(0xFF109F83),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    child: Text(isEnrolled ? 'Suspend' : 'Activate', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      if (widget.onEditStudent != null) {
                        widget.onEditStudent!(admission);
                      } else if (widget.onEdit != null) {
                        widget.onEdit!();
                      } else {
                        widget.onNavigate?.call(EdupluseNavPage.editStudent);
                      }
                    },
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF109F83),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          );

          final profileRight = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Personal Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isEnrolled ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isEnrolled ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isEnrolled ? 'Active' : 'Suspended',
                          style: TextStyle(
                            color: isEnrolled ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              Wrap(
                spacing: 36,
                runSpacing: 14,
                children: [
                  _buildMetaItem('Class', student.className, isDark),
                  _buildMetaItem('Section', student.section, isDark),
                  _buildMetaItem('Roll No', student.rollNumber ?? '10', isDark),
                  _buildMetaItem('Gender', user.gender?.displayName ?? 'Male', isDark),
                  _buildMetaItem(
                    'Date Of Birth',
                    user.dateOfBirth != null
                        ? DateFormat('d MMM yyyy').format(user.dateOfBirth!)
                        : '10 Nov 2006',
                    isDark,
                  ),
                  _buildMetaItem('Category', student.category ?? 'General', isDark),
                  _buildMetaItem('Academic Year', student.academicYear, isDark),
                  _buildMetaItem('Phone Number', user.phoneNumber, isDark),
                  _buildMetaItem('Email', user.email, isDark),
                ],
              ),
            ],
          );

          if (isNarrow) {
            return Column(
              children: [
                profileLeft,
                const SizedBox(height: 24),
                Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                const SizedBox(height: 16),
                profileRight,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 240, child: profileLeft),
              const SizedBox(width: 32),
              Container(width: 1, height: 260, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              const SizedBox(width: 32),
              Expanded(child: profileRight),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetaItem(String label, String value, bool isDark) {
    return SizedBox(
      width: 190,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 95,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(': ', style: TextStyle(color: isDark ? const Color(0xFF64748B) : Colors.grey)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabs() {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _activeTabIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _activeTabIndex = index),
              borderRadius: BorderRadius.circular(6),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF109F83) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getTabIcon(index),
                      size: 16,
                      color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _tabs[index],
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
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
        return Icons.school_outlined;
      case 1:
        return Icons.calendar_month_outlined;
      case 2:
        return Icons.logout_outlined;
      case 3:
        return Icons.credit_card_outlined;
      case 4:
        return Icons.assignment_outlined;
      case 5:
        return Icons.local_library_outlined;
      default:
        return Icons.info_outline;
    }
  }

  Widget _buildStudentDetailsTab(StudentAdmissionModel admission) {
    final student = admission.student;

    return Column(
      children: [
        // Parent Guardian Detail Section
        _buildSectionCard(
          title: 'Parent Guardian Detail',
          child: Column(
            children: [
              _buildParentRow(
                name: admission.father?.fullName ?? 'Rajesh Sharma',
                relation: 'Father',
                phone: admission.father?.phoneNumber ?? '+91 98112 34567',
                email: admission.father?.email ?? 'rajesh.sharma@example.com',
                avatarColor: const Color(0xFFFDE68A),
              ),
              const Divider(height: 24),
              _buildParentRow(
                name: admission.mother?.fullName ?? 'Sunita Sharma',
                relation: 'Mother',
                phone: admission.mother?.phoneNumber ?? '+91 98112 34568',
                email: admission.mother?.email ?? 'sunita.sharma@example.com',
                avatarColor: const Color(0xFFE9D5FF),
              ),
              const Divider(height: 24),
              _buildParentRow(
                name: admission.guardian?.fullName ?? 'Rajesh Sharma',
                relation: 'Guardian (Father)',
                phone: admission.guardian?.phoneNumber ?? '+91 98112 34567',
                email: admission.guardian?.email ?? 'rajesh.sharma@example.com',
                avatarColor: const Color(0xFFBAE6FD),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Responsive 2-Column or 1-Column Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 900;
            final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

            final leftColumn = Column(
              children: [
                _buildSectionCard(
                  title: 'Previous School Details',
                  child: Column(
                    children: [
                      _buildDetailRow('Previous School Name', student.previousSchoolName ?? 'Delhi Public School (DPS), R.K. Puram'),
                      const SizedBox(height: 12),
                      _buildDetailRow('Current School Name', student.previousSchoolAddress ?? 'National Public School (NPS), Indiranagar'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Bank Details',
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      if (boxConstraints.maxWidth < 450) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(width: 140, child: _buildColumnInfo('Bank Name', student.bankName ?? 'State Bank of India (SBI)')),
                            SizedBox(width: 140, child: _buildColumnInfo('Branch', 'Bengaluru Main')),
                            SizedBox(width: 140, child: _buildColumnInfo('IFSC Code', student.ifscCode ?? 'SBIN0004521')),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildColumnInfo('Bank Name', student.bankName ?? 'State Bank of India (SBI)')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildColumnInfo('Branch', 'Bengaluru Main')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildColumnInfo('IFSC Code', student.ifscCode ?? 'SBIN0004521')),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Documents',
                  child: admission.documents.isEmpty
                      ? Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B), size: 18),
                              const SizedBox(width: 8),
                              Text('No documents uploaded yet', style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600, fontSize: 13)),
                            ],
                          ),
                        )
                      : Column(
                          children: admission.documents.map((doc) {
                            final isPdf = doc.fileType.toLowerCase() == 'pdf' || doc.fileName.toLowerCase().endsWith('.pdf');
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      isPdf ? Icons.picture_as_pdf : Icons.image_outlined,
                                      color: isPdf ? const Color(0xFFEF4444) : const Color(0xFF109F83),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            doc.title,
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          Text(
                                            '${doc.fileName} • ${doc.fileSize}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Fulfilled',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.file_download_outlined, color: Color(0xFF109F83)),
                                      onPressed: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('Downloading ${doc.fileName}...'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                ),
              ],
            );

            final rightColumn = Column(
              children: [
                _buildSectionCard(
                  title: 'Address',
                  child: Column(
                    children: [
                      _buildDetailRow('Current Address', student.currentAddress),
                      const SizedBox(height: 12),
                      _buildDetailRow('Permanent Address', student.permanentAddress ?? student.residentialAddress),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Medical Details',
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      if (boxConstraints.maxWidth < 450) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(width: 110, child: _buildColumnInfo('Blood Group', student.bloodGroup ?? 'B+')),
                            SizedBox(width: 110, child: _buildColumnInfo('Height', student.height ?? '5.4')),
                            SizedBox(width: 110, child: _buildColumnInfo('Weight', student.weight ?? '56kg')),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildColumnInfo('Blood Group', student.bloodGroup ?? 'B+')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildColumnInfo('Height', student.height ?? '5.4')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildColumnInfo('Weight', student.weight ?? '56kg')),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _buildSectionCard(
                  title: 'Hostel',
                  child: LayoutBuilder(
                    builder: (context, boxConstraints) {
                      if (boxConstraints.maxWidth < 450) {
                        return Wrap(
                          spacing: 16,
                          runSpacing: 12,
                          children: [
                            SizedBox(width: 140, child: _buildColumnInfo('Hostel', student.hostelName ?? 'Vivekananda Boys Hostel')),
                            SizedBox(width: 140, child: _buildColumnInfo('Room No.', student.roomNo ?? 'Room No. 204')),
                            SizedBox(width: 140, child: _buildColumnInfo('Room Type', 'Two Bed')),
                          ],
                        );
                      }
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildColumnInfo('Hostel', student.hostelName ?? 'Vivekananda Boys Hostel')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildColumnInfo('Room No.', student.roomNo ?? 'Room No. 204')),
                          const SizedBox(width: 8),
                          Expanded(child: _buildColumnInfo('Room Type', 'Two Bed')),
                        ],
                      );
                    },
                  ),
                ),
              ],
            );

            if (isNarrow) {
              return Column(
                children: [
                  leftColumn,
                  const SizedBox(height: 20),
                  rightColumn,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: leftColumn),
                const SizedBox(width: 20),
                Expanded(child: rightColumn),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        // Full-width Description Card
        _buildSectionCard(
          title: 'Description',
          child: Text(
            student.additionalDetails ??
                'Known for their punctuality and positive attitude, he consistently demonstrates a strong commitment to academic excellence and co-curricular participation. He maintains good behavior, shows respect toward teachers and peers, and actively engages in classroom discussions.',
            style: TextStyle(
              fontSize: 13.5,
              color: (Theme.of(context).brightness == Brightness.dark || widget.isDark)
                  ? const Color(0xFFCBD5E1)
                  : Colors.grey.shade700,
              height: 1.6,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParentRow({
    required String name,
    required String relation,
    required String phone,
    required String email,
    required Color avatarColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        final avatarAndName = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: avatarColor,
              child: const Icon(Icons.person, color: Color(0xFF334155), size: 22),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 140,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(relation, style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        );

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatarAndName,
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Email', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            avatarAndName,
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Phone', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Email', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildColumnInfo(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildTabContent(StudentAdmissionModel admission, bool isDark) {
    switch (_activeTabIndex) {
      case 0:
        return _buildStudentDetailsTab(admission);
      case 1:
        return StudentAttendanceTab(admission: admission, isDark: isDark);
      case 2:
        return StudentLeaveTab(admission: admission, isDark: isDark);
      case 3:
        return StudentFeesTab(admission: admission, isDark: isDark);
      case 4:
        return StudentExamTab(admission: admission, isDark: isDark);
      case 5:
        return StudentLibraryTab(admission: admission, isDark: isDark);
      default:
        return _buildPlaceholderTab(_tabs[_activeTabIndex]);
    }
  }

  Widget _buildPlaceholderTab(String tabName) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.dashboard_customize_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '$tabName Module',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed $tabName records for this student will appear here in Phase 3.',
              style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmSuspend(StudentAdmissionModel admission) {
    final isEnrolled = admission.student.enrollmentStatus == EnrollmentStatus.enrolled;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(isEnrolled ? 'Suspend Student?' : 'Reactivate Student?'),
        content: Text(
          isEnrolled
              ? 'Are you sure you want to suspend ${admission.user.fullName}? They will not be able to log in.'
              : 'Reactivate enrollment for ${admission.user.fullName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isEnrolled ? const Color(0xFFEF4444) : const Color(0xFF109F83),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(admissionsListProvider.notifier).suspendStudent(admission.student.id);
            },
            child: Text(isEnrolled ? 'Confirm Suspend' : 'Confirm Activate'),
          ),
        ],
      ),
    );
  }

  void _showAllAdmissionsSheet(
    BuildContext context,
    List<StudentAdmissionModel> allStudents,
    String currentId,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 680;

    if (isMobile) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _AdmissionsDirectorySheet(
          allStudents: allStudents,
          currentId: currentId,
          isDark: isDark,
          isMobile: true,
          onSelectStudent: (selectedId) {
            ref.read(selectedStudentIdProvider.notifier).state = selectedId;
            widget.onSelectStudent?.call(selectedId);
            Navigator.pop(ctx);
          },
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680, maxHeight: 720),
            child: _AdmissionsDirectorySheet(
              allStudents: allStudents,
              currentId: currentId,
              isDark: isDark,
              isMobile: false,
              onSelectStudent: (selectedId) {
                ref.read(selectedStudentIdProvider.notifier).state = selectedId;
                widget.onSelectStudent?.call(selectedId);
                Navigator.pop(ctx);
              },
            ),
          ),
        ),
      );
    }
  }
}

class _AdmissionsDirectorySheet extends StatefulWidget {
  final List<StudentAdmissionModel> allStudents;
  final String currentId;
  final bool isDark;
  final bool isMobile;
  final ValueChanged<String> onSelectStudent;

  const _AdmissionsDirectorySheet({
    required this.allStudents,
    required this.currentId,
    required this.isDark,
    required this.isMobile,
    required this.onSelectStudent,
  });

  @override
  State<_AdmissionsDirectorySheet> createState() => _AdmissionsDirectorySheetState();
}

class _AdmissionsDirectorySheetState extends State<_AdmissionsDirectorySheet> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedClassFilter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final uniqueClasses = <String>{'All'};
    for (final s in widget.allStudents) {
      if (s.student.className.isNotEmpty) {
        uniqueClasses.add(s.student.className);
      }
    }
    final classList = uniqueClasses.toList();

    final filteredStudents = widget.allStudents.where((s) {
      if (_selectedClassFilter != 'All' && s.student.className != _selectedClassFilter) {
        return false;
      }
      if (_searchQuery.trim().isEmpty) return true;
      final q = _searchQuery.toLowerCase().trim();
      final name = s.user.fullName.toLowerCase();
      final adm = s.student.admissionNumber.toLowerCase();
      final roll = (s.student.rollNumber ?? '').toLowerCase();
      final cls = s.student.className.toLowerCase();
      return name.contains(q) || adm.contains(q) || roll.contains(q) || cls.contains(q);
    }).toList();

    final sheetHeight = widget.isMobile
        ? MediaQuery.of(context).size.height * 0.85
        : 680.0;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(widget.isMobile ? 20 : 16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          if (widget.isMobile) ...[
            const SizedBox(height: 10),
            Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ],

          // Modal Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(Icons.groups_rounded, size: 20, color: Color(0xFF109F83)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'All Admissions Directory',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select any student to view their details & profile',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Close',
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),

          // Search Box & Filter Chips
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  style: TextStyle(fontSize: 13.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Search by student name, admission number, roll no...',
                    hintStyle: TextStyle(
                      fontSize: 13,
                      color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF109F83)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF109F83), width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Class filter chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: classList.map((cls) {
                      final isSelected = _selectedClassFilter == cls;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(cls),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedClassFilter = cls);
                            }
                          },
                          labelStyle: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                          ),
                          selectedColor: const Color(0xFF109F83),
                          backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          side: BorderSide(
                            color: isSelected
                                ? const Color(0xFF109F83)
                                : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Count Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${filteredStudents.length} of ${widget.allStudents.length} students',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                if (_searchQuery.isNotEmpty || _selectedClassFilter != 'All')
                  InkWell(
                    onTap: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _selectedClassFilter = 'All';
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'Reset Filters',
                        style: TextStyle(fontSize: 11.5, color: Color(0xFF0284C7), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // List of Students
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person_search_outlined, size: 48, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'No admissions match your search',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your search query or filter chips.',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 16),
                    itemCount: filteredStudents.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final item = filteredStudents[index];
                      final isCurrent = item.student.id == widget.currentId;
                      final isEnrolled = item.student.enrollmentStatus == EnrollmentStatus.enrolled;

                      return InkWell(
                        onTap: () => widget.onSelectStudent(item.student.id),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.35) : const Color(0xFFF0FDF4))
                                : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isCurrent
                                  ? const Color(0xFF109F83)
                                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              width: isCurrent ? 1.6 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                                  border: Border.all(
                                    color: isCurrent ? const Color(0xFF109F83) : const Color(0xFFCBD5E1),
                                    width: 1.5,
                                  ),
                                ),
                                child: ClipOval(
                                  child: item.user.profilePhotoUrl != null &&
                                          item.user.profilePhotoUrl!.startsWith('http')
                                      ? Image.network(
                                          item.user.profilePhotoUrl!,
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(
                                            Icons.person,
                                            size: 24,
                                            color: Color(0xFF109F83),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 24,
                                          color: Color(0xFF109F83),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            item.user.fullName,
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (isCurrent) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF109F83),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.check, size: 10, color: Colors.white),
                                                SizedBox(width: 2),
                                                Text(
                                                  'Viewing',
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 2,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      children: [
                                        Text(
                                          item.student.admissionNumber,
                                          style: const TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                        Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                        Text(
                                          '${item.student.className} (${item.student.section})',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                        Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
                                        Text(
                                          'Roll: ${item.student.rollNumber ?? 'N/A'}',
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Status badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: isEnrolled
                                      ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                                      : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2)),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isEnrolled ? 'Active' : 'Suspended',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isEnrolled ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
