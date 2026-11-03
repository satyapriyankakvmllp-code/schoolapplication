import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../commonwidgets/edupluse_scaffold.dart';
import '../application/exam_controller.dart';
import '../application/examination_access.dart';
import '../domain/exam_schedule_model.dart';
import '../domain/examination_actor.dart';
import '../domain/global_setup_model.dart';
import 'exam_details_screen.dart';
import 'exam_form_screen.dart';
import 'widgets/cancel_exam_dialog.dart';
import 'widgets/delete_exam_dialog.dart';
import 'widgets/exam_card_item.dart';
import 'widgets/exam_filter_bar.dart';
import 'widgets/exam_status_badge.dart';
import 'widgets/exam_summary_cards.dart';
import 'panels/attendance_panel.dart';
import 'panels/exam_papers_panel.dart';
import 'panels/hall_tickets_panel.dart';
import 'panels/marks_entry_panel.dart';
import 'panels/marks_review_panel.dart';
import 'panels/my_exams_panel.dart';
import 'panels/pattern_panel.dart';
import 'panels/question_bank_panel.dart';
import 'panels/question_paper_panel.dart';
import 'panels/results_panel.dart';

class ExamListScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onExitToGateway;

  const ExamListScreen({
    super.key,
    this.isDark = false,
    this.onToggleTheme,
    this.onNavigate,
    this.onExitToGateway,
  });

  @override
  ConsumerState<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends ConsumerState<ExamListScreen> {
  /// Which examination screen is open ('Exams' is the exam list).
  String _section = 'Exams';

  /// Screens each role can open (one entry per screen of the module).
  List<({String key, String label, IconData icon})> _sectionsFor(ExaminationPermissions p) {
    final all = <({String key, String label, IconData icon})>[
      (key: 'Exams', label: 'Exams', icon: Icons.event_note_outlined),
      if (p.isAdminOrPrincipal || p.isTeacher || p.isClassIncharge)
        (key: 'Exam Papers', label: 'Exam Papers', icon: Icons.calendar_month_outlined),
      if (p.isAdminOrPrincipal || p.isClassIncharge)
        (key: 'Hall Tickets', label: 'Hall Tickets', icon: Icons.badge_outlined),
      if (p.isAdminOrPrincipal || p.isTeacher)
        (key: 'Attendance', label: 'Attendance', icon: Icons.fact_check_outlined),
      if (p.isAdminOrPrincipal || p.isTeacher)
        (key: 'Marks Entry', label: 'Marks Entry', icon: Icons.edit_note),
      if (p.isAdminOrPrincipal || p.isClassIncharge)
        (key: 'Marks Review', label: 'Marks Review', icon: Icons.rate_review_outlined),
      if (p.isAdminOrPrincipal || p.isClassIncharge)
        (key: 'Results', label: 'Results & Report Cards', icon: Icons.assessment_outlined),
      if (p.isStudentOrParent)
        (key: 'My Exams', label: 'My Exams', icon: Icons.school_outlined),
      (key: 'Syllabus & Pattern', label: 'Syllabus & Pattern', icon: Icons.rule_folder_outlined),
      if (p.isAdminOrPrincipal || p.isTeacher)
        (key: 'Question Bank', label: 'Question Bank', icon: Icons.quiz_outlined),
      if (p.isAdminOrPrincipal || p.isTeacher)
        (key: 'Question Papers', label: 'Question Papers', icon: Icons.description_outlined),
    ];
    return all;
  }

  Widget _buildSectionNav(List<({String key, String label, IconData icon})> sections, String active, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: sections.map((s) {
          final selected = s.key == active;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              avatar: Icon(s.icon, size: 16, color: selected ? Colors.white : null),
              label: Text(s.label),
              selected: selected,
              showCheckmark: false,
              selectedColor: const Color(0xFF109F83),
              labelStyle: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
              ),
              onSelected: (_) => setState(() => _section = s.key),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSectionPanel(String key) {
    switch (key) {
      case 'Exam Papers':
        return const ExamPapersPanel();
      case 'Hall Tickets':
        return const HallTicketsPanel();
      case 'Attendance':
        return const AttendancePanel();
      case 'Marks Entry':
        return const MarksEntryPanel();
      case 'Marks Review':
        return const MarksReviewPanel();
      case 'Results':
        return const ResultsPanel();
      case 'My Exams':
        return const MyExamsPanel();
      case 'Syllabus & Pattern':
        return const PatternPanel();
      case 'Question Bank':
        return const QuestionBankPanel();
      case 'Question Papers':
        return const QuestionPaperPanel();
      default:
        return const SizedBox.shrink();
    }
  }

  String _formatDateRange(String startStr, String endStr) {
    try {
      final startParts = startStr.split('-').map(int.parse).toList();
      final endParts = endStr.split('-').map(int.parse).toList();
      final start = DateTime(startParts[0], startParts[1], startParts[2]);
      final end = DateTime(endParts[0], endParts[1], endParts[2]);

      final startFmt = DateFormat('d MMM').format(start);
      final endFmt = DateFormat('d MMM yyyy').format(end);
      return '$startFmt to $endFmt';
    } catch (_) {
      return '$startStr to $endStr';
    }
  }

  void _openDetails(String examId, {String initialTab = 'Overview'}) {
    ExamDetailsScreen.showAsDialog(
      context,
      examId: examId,
      initialTab: initialTab,
    );
  }

  Future<void> _openCreateDialog() async {
    await ExamFormScreen.showAsDialog(
      context,
      onSaved: (savedExam, openPapersTab) {
        Navigator.of(context).pop();
        if (openPapersTab) {
          _openDetails(savedExam.examScheduleId, initialTab: 'Exam Papers');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exam "${savedExam.examName}" created successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _openEditDialog(ExamSchedule exam) async {
    await ExamFormScreen.showAsDialog(
      context,
      existingExam: exam,
      onSaved: (savedExam, openPapersTab) {
        Navigator.of(context).pop();
        if (openPapersTab) {
          _openDetails(savedExam.examScheduleId, initialTab: 'Exam Papers');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Exam "${savedExam.examName}" updated successfully!'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }

  Future<void> _handleCancel(ExamSchedule exam) async {
    final reason = await CancelExamDialog.show(context, exam);
    if (reason != null && mounted) {
      try {
        await ref
            .read(examListControllerProvider.notifier)
            .cancelExam(exam.examScheduleId, reason);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Examination "${exam.examName}" was cancelled.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel exam: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDelete(ExamSchedule exam) async {
    final counts = await ref
        .read(examListControllerProvider.notifier)
        .getLinkedDataCounts(exam.examScheduleId);
    if (!mounted) return;

    final confirmed = await DeleteExamDialog.show(
      context,
      exam: exam,
      counts: counts,
      onConfirmDelete: () async {
        await ref
            .read(examListControllerProvider.notifier)
            .deleteExam(exam.examScheduleId);
      },
    );

    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exam "${exam.examName}" and linked records were deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleResetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Demo Data?'),
        content: const Text(
          'This will restore examination schedules and global user configuration back to the initial sample data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset Data'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(examListControllerProvider.notifier).resetDemoData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Demo data has been reset to seed values.'),
              backgroundColor: Color(0xFF109F83),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Reset failed: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = widget.isDark || theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final setup = ref.watch(globalSetupProvider).valueOrNull;
    final actor = ref.watch(currentExamActorProvider);
    final permissions = actor.permissions;
    final filter = ref.watch(examFilterProvider);
    final examsAsync = ref.watch(examListControllerProvider);

    final isStudentOrParent = permissions.isStudentOrParent;
    final showTable = !isMobile && !isStudentOrParent;
    final sections = _sectionsFor(permissions);
    final activeSection = sections.any((x) => x.key == _section) ? _section : 'Exams';

    return EdupluseScaffold(
      activePage: EdupluseNavPage.examinations,
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      onNavigate: widget.onNavigate,
      onExitToGateway: widget.onExitToGateway,
      body: Container(
        color: isDark ? const Color(0xFF0B1120) : const Color(0xFFF1F5F9),
        child: Column(
          children: [
            // Top App Bar / Module Subheader with Role Switcher & Reset Demo Data
            _buildTopBar(context, setup, actor, isDark),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 24,
                  vertical: 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Examination screens (role based)
                        _buildSectionNav(sections, activeSection, isDark),
                        const SizedBox(height: 16),
                        if (activeSection != 'Exams') _buildSectionPanel(activeSection),

                        if (activeSection == 'Exams') ...[
                        // Page Title & Primary Actions
                        _buildPageTitleRow(permissions, isDark),
                        const SizedBox(height: 16),

                        // Summary Statistics Cards
                        const ExamSummaryCards(),
                        const SizedBox(height: 16),

                        // Search and Filter Controls
                        const ExamFilterBar(),
                        const SizedBox(height: 16),

                        // Exam List Body: Loading, Error, Empty, or Data (Table / Cards)
                        examsAsync.when(
                          loading: () => const Center(
                            child: Padding(
                              padding: EdgeInsets.all(40),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                          error: (err, _) => _buildErrorView(err.toString(), isDark),
                          data: (exams) {
                            if (exams.isEmpty) {
                              return _buildEmptyView(filter.academicYear ?? 'selected period', permissions, isDark);
                            }

                            if (showTable) {
                              return _buildDataTable(exams, setup, permissions, isDark);
                            } else {
                              return _buildCardList(exams, setup, permissions);
                            }
                          },
                        ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. TOP BAR WITH DEBUG ROLE SWITCHER & RESET DEMO DATA
  // ---------------------------------------------------------------------------
  Widget _buildTopBar(
    BuildContext context,
    GlobalSetup? setup,
    ExaminationActor actor,
    bool isDark,
  ) {
    final users = setup?.users ?? [];

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          // Sub-Module Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF109F83).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz_outlined, color: Color(0xFF109F83), size: 16),
                SizedBox(width: 6),
                Text(
                  'Examination Management',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF109F83),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),

          // Debug Role Switcher Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.tune, size: 14, color: Color(0xFF6366F1)),
                const SizedBox(width: 6),
                const Text(
                  'Switch Role: ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: actor.userId,
                    isDense: true,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    items: users.map((u) {
                      return DropdownMenuItem<String>(
                        value: u.id,
                        child: Text('${u.name} (${u.role})'),
                      );
                    }).toList(),
                    onChanged: (newUserId) {
                      if (newUserId != null) {
                        ref.read(globalSetupProvider.notifier).switchUser(newUserId);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Reset Demo Data Action
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.restore, size: 16),
            label: const Text('Reset demo data', style: TextStyle(fontSize: 11.5)),
            onPressed: _handleResetDemoData,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. PAGE TITLE AND ACTION ROW
  // ---------------------------------------------------------------------------
  Widget _buildPageTitleRow(ExaminationPermissions permissions, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Examinations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Manage institutional exam schedules, evaluation terms, and calendar dates.',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),

        // "+ Create Exam" button (Admin / Principal only)
        if (permissions.canCreateExam)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text(
              '+ Create Exam',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
            onPressed: _openCreateDialog,
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. DATA TABLE VIEW (Wide Screens, Admin / Teacher)
  // ---------------------------------------------------------------------------
  Widget _buildDataTable(
    List<ExamSchedule> exams,
    GlobalSetup? setup,
    ExaminationPermissions permissions,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 950),
            child: DataTable(
              headingRowHeight: 44,
              dataRowMinHeight: 52,
              dataRowMaxHeight: 56,
              headingRowColor: WidgetStateProperty.all(
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ),
              columns: const [
                DataColumn(
                  label: Text('Exam Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                DataColumn(
                  label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                DataColumn(
                  label: Text('Academic Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                DataColumn(
                  label: Text('Start to End Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                DataColumn(
                  label: Text('Papers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                DataColumn(
                  label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
                DataColumn(
                  label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                ),
              ],
              rows: exams.map((exam) {
                final typeLabel = setup?.resolveExamTypeLabel(exam.examType) ?? exam.examType;
                final dateRangeStr = _formatDateRange(exam.startDate, exam.endDate);

                final bool canEdit = permissions.canEditExam && exam.canBeEdited;
                final bool canCancel = permissions.canCancelExam && exam.canBeCancelled;
                final bool canDelete = permissions.canDeleteExam && exam.canBeDeleted;

                return DataRow(
                  cells: [
                    // Exam Name (Tappable)
                    DataCell(
                      InkWell(
                        onTap: () => _openDetails(exam.examScheduleId),
                        child: Text(
                          exam.examName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),

                    // Type
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(typeLabel, style: const TextStyle(fontSize: 12)),
                      ),
                    ),

                    // Academic Year
                    DataCell(Text(exam.academicYear, style: const TextStyle(fontSize: 12.5))),

                    // Start to End Date
                    DataCell(
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today, size: 13, color: isDark ? Colors.white60 : Colors.black54),
                          const SizedBox(width: 6),
                          Text(dateRangeStr, style: const TextStyle(fontSize: 12.5)),
                        ],
                      ),
                    ),

                    // Papers Count
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${exam.paperCount}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    // Status
                    DataCell(ExamStatusBadge(status: exam.status, isCompact: true)),

                    // Actions
                    DataCell(
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        tooltip: 'Actions',
                        onSelected: (action) {
                          if (action == 'view') {
                            _openDetails(exam.examScheduleId);
                          } else if (action == 'edit') {
                            _openEditDialog(exam);
                          } else if (action == 'cancel') {
                            _handleCancel(exam);
                          } else if (action == 'delete') {
                            _handleDelete(exam);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility_outlined, size: 16),
                                SizedBox(width: 8),
                                Text('View Details', style: TextStyle(fontSize: 12.5)),
                              ],
                            ),
                          ),
                          if (canEdit)
                            PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_outlined, size: 16),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Edit Exam',
                                    style: TextStyle(fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          if (canCancel)
                            const PopupMenuItem(
                              value: 'cancel',
                              child: Row(
                                children: [
                                  Icon(Icons.cancel_outlined, size: 16, color: Colors.orange),
                                  SizedBox(width: 8),
                                  Text(
                                    'Cancel Exam',
                                    style: TextStyle(fontSize: 12.5, color: Colors.orange),
                                  ),
                                ],
                              ),
                            ),
                          if (canDelete)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text(
                                    'Delete Exam',
                                    style: TextStyle(fontSize: 12.5, color: Colors.red),
                                  ),
                                ],
                              ),
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

  // ---------------------------------------------------------------------------
  // 4. CARD LIST VIEW (Mobile Screens & Student / Parent Roles)
  // ---------------------------------------------------------------------------
  Widget _buildCardList(
    List<ExamSchedule> exams,
    GlobalSetup? setup,
    ExaminationPermissions permissions,
  ) {
    return Column(
      children: exams.map((exam) {
        final typeLabel = setup?.resolveExamTypeLabel(exam.examType) ?? exam.examType;

        return ExamCardItem(
          exam: exam,
          examTypeLabel: typeLabel,
          permissions: permissions,
          onTap: () => _openDetails(exam.examScheduleId),
          onEdit: () => _openEditDialog(exam),
          onCancel: () => _handleCancel(exam),
          onDelete: () => _handleDelete(exam),
        );
      }).toList(),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. EMPTY STATE
  // ---------------------------------------------------------------------------
  Widget _buildEmptyView(String year, ExaminationPermissions permissions, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz_outlined, size: 40, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            'No exams created for $year.',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Create your first exam schedule to begin managing terms and tests.',
            style: TextStyle(fontSize: 12.5, color: Colors.grey),
          ),
          if (permissions.canCreateExam) ...[
            const SizedBox(height: 20),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF109F83),
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Create Exam'),
              onPressed: _openCreateDialog,
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. ERROR STATE
  // ---------------------------------------------------------------------------
  Widget _buildErrorView(String message, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 36, color: Colors.red),
          const SizedBox(height: 12),
          Text(
            'Failed to load examinations',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.red.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            onPressed: () => ref.read(examListControllerProvider.notifier).refreshExams(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
