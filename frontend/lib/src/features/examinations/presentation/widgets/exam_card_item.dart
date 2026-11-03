import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/exam_schedule_model.dart';
import '../../domain/examination_actor.dart';
import 'exam_status_badge.dart';

class ExamCardItem extends StatelessWidget {
  final ExamSchedule exam;
  final String examTypeLabel;
  final ExaminationPermissions permissions;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCancel;
  final VoidCallback? onDelete;

  const ExamCardItem({
    super.key,
    required this.exam,
    required this.examTypeLabel,
    required this.permissions,
    required this.onTap,
    this.onEdit,
    this.onCancel,
    this.onDelete,
  });

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateRangeStr = _formatDateRange(exam.startDate, exam.endDate);

    final bool canEdit = permissions.canEditExam && exam.canBeEdited;
    final bool canCancel = permissions.canCancelExam && exam.canBeCancelled;
    final bool canDelete = permissions.canDeleteExam && exam.canBeDeleted;

    final isSimpleCard = permissions.isStudentOrParent;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Title + Status + Action Menu
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.examName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                examTypeLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              exam.academicYear,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? const Color(0xFF64748B) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ExamStatusBadge(status: exam.status, isCompact: true),
                  if (!isSimpleCard && (canEdit || canCancel || canDelete)) ...[
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 18),
                      padding: EdgeInsets.zero,
                      tooltip: 'Actions',
                      onSelected: (val) {
                        if (val == 'view') onTap();
                        if (val == 'edit') onEdit?.call();
                        if (val == 'cancel') onCancel?.call();
                        if (val == 'delete') onDelete?.call();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.visibility_outlined, size: 16),
                              SizedBox(width: 8),
                              Text('View Details', style: TextStyle(fontSize: 13)),
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
                                  style: TextStyle(fontSize: 13),
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
                                  style: TextStyle(fontSize: 13, color: Colors.orange),
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
                                  style: TextStyle(fontSize: 13, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Divider(
                height: 1,
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              ),
              const SizedBox(height: 10),

              // Bottom details row: Date range + Papers Count
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        dateRangeStr,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.menu_book_outlined,
                          size: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${exam.paperCount} Timetable entries',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (exam.isCancelled && exam.cancelReason != null) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Cancelled: ${exam.cancelReason}',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Colors.red.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

