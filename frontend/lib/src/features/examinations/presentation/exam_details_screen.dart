import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../application/exam_controller.dart';
import '../application/examination_access.dart';
import '../domain/exam_schedule_model.dart';
import 'exam_form_screen.dart';
import 'widgets/cancel_exam_dialog.dart';
import 'widgets/delete_exam_dialog.dart';
import 'widgets/exam_status_badge.dart';
import 'widgets/exam_papers_tab.dart';
import 'tabs/hall_tickets_tab.dart';
import 'tabs/attendance_tab.dart';
import 'tabs/marks_entry_tab.dart';
import 'tabs/marks_review_tab.dart';
import 'tabs/results_tab.dart';
import 'tabs/syllabus_pattern_tab.dart';

class ExamDetailsScreen extends ConsumerStatefulWidget {
  final String examId;
  final String initialTab;
  final bool isDialog;
  final VoidCallback? onBack;

  const ExamDetailsScreen({
    super.key,
    required this.examId,
    this.initialTab = 'Overview',
    this.isDialog = false,
    this.onBack,
  });

  static Future<void> showAsDialog(
    BuildContext context, {
    required String examId,
    String initialTab = 'Overview',
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960, maxHeight: 820),
          child: ExamDetailsScreen(
            examId: examId,
            initialTab: initialTab,
            isDialog: true,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<ExamDetailsScreen> createState() => _ExamDetailsScreenState();
}

class _ExamDetailsScreenState extends ConsumerState<ExamDetailsScreen> {
  late String _activeTab;

  @override
  void initState() {
    super.initState();
    _activeTab = widget.initialTab;
  }

  String _formatDate(String dateStr) {
    if (dateStr.isEmpty) return '—';
    try {
      final p = dateStr.split('-').map(int.parse).toList();
      final dt = DateTime(p[0], p[1], p[2]);
      return DateFormat('dd MMMM yyyy').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String isoStr) {
    if (isoStr.isEmpty) return '—';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
    } catch (_) {
      return isoStr;
    }
  }

  int _calculateDays(String startStr, String endStr) {
    try {
      final startParts = startStr.split('-').map(int.parse).toList();
      final endParts = endStr.split('-').map(int.parse).toList();
      final start = DateTime(startParts[0], startParts[1], startParts[2]);
      final end = DateTime(endParts[0], endParts[1], endParts[2]);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _handleEdit(ExamSchedule exam) async {
    final result = await ExamFormScreen.showAsDialog(
      context,
      existingExam: exam,
    );
    if (result != null && mounted) {
      ref.invalidate(examDetailsProvider(widget.examId));
      ref.read(examListControllerProvider.notifier).refreshExams();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Exam updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleCancel(ExamSchedule exam) async {
    final reason = await CancelExamDialog.show(context, exam);
    if (reason != null && mounted) {
      try {
        await ref
            .read(examListControllerProvider.notifier)
            .cancelExam(exam.examScheduleId, reason);
        ref.invalidate(examDetailsProvider(widget.examId));
        ref.read(examListControllerProvider.notifier).refreshExams();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Examination was cancelled successfully.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to cancel: $e'),
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
      if (widget.isDialog) {
        Navigator.of(context).pop();
      } else if (widget.onBack != null) {
        widget.onBack!();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exam "${exam.examName}" and linked records were deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final permissions = ref.watch(examinationPermissionsProvider);
    final setup = ref.watch(globalSetupProvider).valueOrNull;
    final examAsync = ref.watch(examDetailsProvider(widget.examId));

    final content = examAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (err, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Error loading exam: $err'),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: () => ref.invalidate(examDetailsProvider(widget.examId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (exam) {
        if (exam == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('Exam not found or you do not have permission to view it.'),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      if (widget.isDialog) {
                        Navigator.of(context).pop();
                      } else if (widget.onBack != null) {
                        widget.onBack!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          );
        }

        final typeLabel = setup?.resolveExamTypeLabel(exam.examType) ?? exam.examType;
        final createdByName = setup?.resolveUserName(exam.createdBy) ?? exam.createdBy;
        final totalDays = _calculateDays(exam.startDate, exam.endDate);

        final bool canEdit = permissions.canEditExam && exam.canBeEdited;
        final bool canCancel = permissions.canCancelExam && exam.canBeCancelled;
        final bool canDelete = permissions.canDeleteExam && exam.canBeDeleted;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _buildHeaderCard(
                    context,
                    exam: exam,
                    typeLabel: typeLabel,
                    canEdit: canEdit,
                    canCancel: canCancel,
                    canDelete: canDelete,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // Tabs Header
                  _buildTabsHeader(isDark: isDark),
                  const SizedBox(height: 16),

                  // Tab Body
                  if (_activeTab == 'Overview')
                    _buildOverviewTab(
                      exam: exam,
                      typeLabel: typeLabel,
                      createdByName: createdByName,
                      totalDays: totalDays,
                      isDark: isDark,
                    )
                  else if (_activeTab == 'Exam Timetable' || _activeTab == 'Exam Papers')
                    ExamTimetableTab(exam: exam)
                  else if (_activeTab == 'Syllabus')
                    SyllabusTab(exam: exam)
                  else if (_activeTab == 'Exam Pattern')
                    ExamPatternTab(exam: exam)
                  else if (_activeTab == 'Question Paper')
                    QuestionPaperTab(exam: exam)
                  else if (_activeTab == 'Hall Tickets')
                    HallTicketsTab(exam: exam)
                  else if (_activeTab == 'Attendance')
                    ExamAttendanceTab(exam: exam)
                  else if (_activeTab == 'Marks Entry')
                    MarksEntryTab(exam: exam)
                  else if (_activeTab == 'Marks Review')
                    MarksReviewTab(exam: exam)
                  else if (_activeTab == 'Results')
                    ResultsTab(exam: exam)
                  else
                    _buildComingSoonTab(_activeTab, isDark: isDark),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (widget.isDialog) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
              child: Row(
                children: [
                  const Icon(Icons.description_outlined, size: 20, color: Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Exam Details',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: content),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Exam Details', style: TextStyle(fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onBack != null) {
              widget.onBack!();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: content,
    );
  }

  // ---------------------------------------------------------------------------
  // 1. HEADER CARD
  // ---------------------------------------------------------------------------
  Widget _buildHeaderCard(
    BuildContext context, {
    required ExamSchedule exam,
    required String typeLabel,
    required bool canEdit,
    required bool canCancel,
    required bool canDelete,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Navigator (Exam List vs Exam Timetable)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.navigation_outlined, size: 16, color: Color(0xFF109F83)),
                const SizedBox(width: 8),
                const Text(
                  'Module Section:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: (_activeTab == 'Exam Timetable' || _activeTab == 'Exam Papers')
                        ? 'TIMETABLE'
                        : 'LIST',
                    isDense: true,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'LIST',
                        child: Text('1. Exam List (Back to All Exams)'),
                      ),
                      DropdownMenuItem(
                        value: 'TIMETABLE',
                        child: Text('2. Exam Timetable'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == 'LIST') {
                        if (widget.isDialog) {
                          Navigator.of(context).pop();
                        } else if (widget.onBack != null) {
                          widget.onBack!();
                        } else if (Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      } else if (v == 'TIMETABLE') {
                        setState(() => _activeTab = 'Exam Timetable');
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          exam.examName,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        ExamStatusBadge(status: exam.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$typeLabel  •  Academic Year ${exam.academicYear}',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canEdit)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: const Text(
                        'Edit Exam',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onPressed: () => _handleEdit(exam),
                    ),
                  if (canCancel)
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade800,
                        side: BorderSide(color: Colors.orange.shade400),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text(
                        'Cancel Exam',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onPressed: () => _handleCancel(exam),
                    ),
                  if (canDelete)
                    FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      icon: const Icon(Icons.delete_outline, size: 16),
                      label: const Text(
                        'Delete Exam',
                        style: TextStyle(fontSize: 12.5),
                      ),
                      onPressed: () => _handleDelete(exam),
                    ),
                ],
              ),
            ],
          ),
          if (exam.isCancelled && exam.cancelReason != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: Colors.red, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Cancellation Reason: ${exam.cancelReason}',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. TABS HEADER
  // ---------------------------------------------------------------------------
  Widget _buildTabsHeader({required bool isDark}) {
    final p = ref.read(examinationPermissionsProvider);
    final names = <String>[
      'Overview',
      'Exam Timetable',
      if (!p.isStudentOrParent) 'Syllabus',
      if (!p.isStudentOrParent) 'Exam Pattern',
      if (p.isAdminOrPrincipal || p.isTeacher) 'Question Paper',
      if (p.isAdminOrPrincipal) 'Hall Tickets',
      if (!p.isStudentOrParent) 'Attendance',
      if (!p.isStudentOrParent) 'Marks Entry',
      if (p.isAdminOrPrincipal || p.isClassIncharge) 'Marks Review',
      if (p.isAdminOrPrincipal || p.isTeacher || p.isClassIncharge || p.isStudentOrParent) 'Results',
    ];
    final tabs = [for (final n in names) {'name': n, 'enabled': true}];


    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: tabs.map((tab) {
          final title = tab['name'] as String;
          final isEnabled = tab['enabled'] as bool;
          final isSelected = _activeTab == title;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                if (isEnabled) {
                  setState(() => _activeTab = title);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$title module is coming soon!'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                      width: 280,
                    ),
                  );
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF109F83)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF109F83)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isEnabled
                                ? (isDark ? Colors.white70 : const Color(0xFF334155))
                                : (isDark ? Colors.grey.shade600 : Colors.grey.shade400)),
                      ),
                    ),
                    if (!isEnabled) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Coming soon',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. OVERVIEW TAB
  // ---------------------------------------------------------------------------
  Widget _buildOverviewTab({
    required ExamSchedule exam,
    required String typeLabel,
    required String createdByName,
    required int totalDays,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary metrics
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                title: 'Start Date',
                value: _formatDate(exam.startDate),
                icon: Icons.calendar_today,
                color: const Color(0xFF2563EB),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'End Date',
                value: _formatDate(exam.endDate),
                icon: Icons.event,
                color: const Color(0xFF059669),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Schedule Length',
                value: '$totalDays Day${totalDays == 1 ? '' : 's'}',
                icon: Icons.timelapse,
                color: const Color(0xFFD97706),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricTile(
                title: 'Timetable Entries',
                value: '${exam.paperCount} Entries',
                icon: Icons.menu_book,
                color: const Color(0xFF6366F1),
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Information Cards Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            return isMobile
                ? Column(
                    children: [
                      _buildScheduleDetailsCard(exam, typeLabel, isDark),
                      const SizedBox(height: 12),
                      _buildAuditTrailCard(exam, createdByName, isDark),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildScheduleDetailsCard(exam, typeLabel, isDark),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: _buildAuditTrailCard(exam, createdByName, isDark),
                      ),
                    ],
                  );
          },
        ),
      ],
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleDetailsCard(ExamSchedule exam, String typeLabel, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Schedule Specifications',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Exam Name', exam.examName, isDark),
          _buildInfoRow('Exam Type', typeLabel, isDark),
          _buildInfoRow('Academic Year', exam.academicYear, isDark),
          _buildInfoRow('Start Date', _formatDate(exam.startDate), isDark),
          _buildInfoRow('End Date', _formatDate(exam.endDate), isDark),
          _buildInfoRow('Status', exam.status, isDark),
          if (exam.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Description',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (isDark ? Colors.black12 : Colors.grey.shade50),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Text(
                exam.description,
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAuditTrailCard(ExamSchedule exam, String createdByName, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Audit & Record Details',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Schedule ID', exam.examScheduleId, isDark),
          _buildInfoRow('Created By', createdByName, isDark),
          _buildInfoRow('Created On', _formatDateTime(exam.createdAt), isDark),
          _buildInfoRow('Last Updated', _formatDateTime(exam.updatedAt), isDark),
          _buildInfoRow('Timetable Entries', '${exam.paperCount}', isDark),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. PLACEHOLDER / COMING SOON TAB
  // ---------------------------------------------------------------------------
  Widget _buildComingSoonTab(String moduleTitle, {required bool isDark}) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 30),
        padding: const EdgeInsets.all(32),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF109F83).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.rocket_launch_outlined, color: Color(0xFF109F83), size: 36),
            ),
            const SizedBox(height: 16),
            Text(
              '$moduleTitle Module',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'This module is currently under development and will be available in the upcoming phase.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              icon: const Icon(Icons.arrow_back, size: 16),
              label: const Text('Back to Overview'),
              onPressed: () => setState(() => _activeTab = 'Overview'),
            ),
          ],
        ),
      ),
    );
  }
}
