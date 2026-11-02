import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/exam_controller.dart';
import '../../application/examination_access.dart';
import '../../domain/exam_schedule_model.dart';
import '../widgets/cancel_exam_dialog.dart';
import '../widgets/delete_exam_dialog.dart';
import '../widgets/exam_card_item.dart';
import '../widgets/exam_filter_bar.dart';
import '../widgets/exam_status_badge.dart';
import '../widgets/exam_summary_cards.dart';
import 'exam_create_edit_screen.dart';
import 'exam_details_screen.dart';

/// Admin Exam List Screen
/// Manages the primary examination schedule roster:
/// - List examinations with search, academic year, and status filters
/// - Add Exam (via shared ExamCreateEditScreen)
/// - Edit Exam (via shared ExamCreateEditScreen)
/// - Delete Exam (via confirmation dialog)
/// - View Exam Details
class ExamListScreen extends ConsumerStatefulWidget {
  final void Function(String examId)? onViewExam;
  final VoidCallback? onExamCreated;

  const ExamListScreen({
    super.key,
    this.onViewExam,
    this.onExamCreated,
  });

  @override
  ConsumerState<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends ConsumerState<ExamListScreen> {
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

  void _handleViewExam(String examId) {
    if (widget.onViewExam != null) {
      widget.onViewExam!(examId);
    } else {
      ExamDetailsScreen.showAsDialog(
        context,
        examId: examId,
        initialTab: 'Overview',
      );
    }
  }

  Future<void> _openCreateDialog() async {
    await ExamCreateEditScreen.showAsDialog(
      context,
      onSaved: (savedExam, openPapersTab) {
        Navigator.of(context).pop();
        widget.onExamCreated?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exam "${savedExam.examName}" created successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _openEditDialog(ExamSchedule exam) async {
    await ExamCreateEditScreen.showAsDialog(
      context,
      existingExam: exam,
      onSaved: (savedExam, openPapersTab) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exam "${savedExam.examName}" updated successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  Future<void> _openCancelDialog(ExamSchedule exam) async {
    final reason = await CancelExamDialog.show(context, exam);
    if (reason != null && mounted) {
      await ref.read(examListControllerProvider.notifier).cancelExam(exam.examScheduleId, reason);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exam "${exam.examName}" was cancelled.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openDeleteDialog(ExamSchedule exam) async {
    final counts = await ref.read(examListControllerProvider.notifier).getLinkedDataCounts(exam.examScheduleId);
    if (!mounted) return;
    final confirmed = await DeleteExamDialog.show(
      context,
      exam: exam,
      counts: counts,
      onConfirmDelete: () async {
        await ref.read(examListControllerProvider.notifier).deleteExam(exam.examScheduleId);
      },
    );
    if (confirmed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Exam "${exam.examName}" deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final examsAsync = ref.watch(examListControllerProvider);
    final actor = ref.watch(currentExamActorProvider);
    final perms = actor.permissions;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 12 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action Bar: Header + Add Exam Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Examinations Master List',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Schedule, monitor, and coordinate institutional exam terms.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                  ),
                ],
              ),
              if (perms.canCreateExam)
                ElevatedButton.icon(
                  onPressed: _openCreateDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF109F83),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Exam', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Summary Metrics Cards
          const ExamSummaryCards(),
          const SizedBox(height: 16),

          // Filters & Search Bar
          const ExamFilterBar(),
          const SizedBox(height: 16),

          // Main Exam Roster Table & Cards
          examsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
            error: (err, _) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text('Error: $err', style: const TextStyle(color: Colors.red)),
              ),
            ),
            data: (exams) {
              if (exams.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Column(
                      children: [
                        Icon(Icons.event_busy, size: 48, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        const Text('No examinations found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 6),
                        const Text(
                          'Try adjusting your search criteria or create a new examination term.',
                          style: TextStyle(color: Colors.grey, fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Responsive layout: Cards on mobile, Table on Desktop
              if (isMobile) {
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: exams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final exam = exams[index];
                    return ExamCardItem(
                      exam: exam,
                      examTypeLabel: exam.examType.replaceAll('_', ' ').toUpperCase(),
                      permissions: perms,
                      onTap: () => _handleViewExam(exam.examScheduleId),
                      onEdit: perms.canEditExam && exam.canBeEdited ? () => _openEditDialog(exam) : null,
                      onCancel: perms.canCancelExam && exam.canBeCancelled ? () => _openCancelDialog(exam) : null,
                      onDelete: perms.canDeleteExam && exam.canBeDeleted ? () => _openDeleteDialog(exam) : null,
                    );
                  },
                );
              }

              return Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Examination', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Expanded(flex: 2, child: Text('Term Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Expanded(flex: 2, child: Text('Academic Year', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Expanded(flex: 3, child: Text('Duration Window', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                          Expanded(flex: 2, child: Text('Actions', textAlign: TextAlign.end, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5))),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: exams.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                      itemBuilder: (context, index) {
                        final exam = exams[index];
                        final canEdit = perms.canEditExam && exam.canBeEdited;
                        final canCancel = perms.canCancelExam && exam.canBeCancelled;
                        final canDelete = perms.canDeleteExam && exam.canBeDeleted;

                        return InkWell(
                          onTap: () => _handleViewExam(exam.examScheduleId),
                          hoverColor: const Color(0xFF109F83).withValues(alpha: 0.04),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        exam.examName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                      if (exam.description.isNotEmpty)
                                        Text(
                                          exam.description,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                                        ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    exam.examType.replaceAll('_', ' ').toUpperCase(),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    exam.academicYear,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    _formatDateRange(exam.startDate, exam.endDate),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: ExamStatusBadge(status: exam.status),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.visibility_outlined, size: 18),
                                        tooltip: 'View Exam Details',
                                        onPressed: () => _handleViewExam(exam.examScheduleId),
                                      ),
                                      if (canEdit)
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          tooltip: 'Edit Examination',
                                          onPressed: () => _openEditDialog(exam),
                                        ),
                                      if (canCancel)
                                        IconButton(
                                          icon: const Icon(Icons.cancel_outlined, size: 18, color: Colors.orange),
                                          tooltip: 'Cancel Examination',
                                          onPressed: () => _openCancelDialog(exam),
                                        ),
                                      if (canDelete)
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                          tooltip: 'Delete Examination',
                                          onPressed: () => _openDeleteDialog(exam),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

