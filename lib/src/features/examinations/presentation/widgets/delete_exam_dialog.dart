import 'package:flutter/material.dart';
import '../../domain/exam_schedule_model.dart';
import 'exam_ui.dart';

class DeleteExamDialog extends StatefulWidget {
  final ExamSchedule exam;
  final ExamLinkedDataCounts counts;
  final Future<void> Function() onConfirmDelete;

  const DeleteExamDialog({
    super.key,
    required this.exam,
    required this.counts,
    required this.onConfirmDelete,
  });

  static Future<bool?> show(
    BuildContext context, {
    required ExamSchedule exam,
    required ExamLinkedDataCounts counts,
    required Future<void> Function() onConfirmDelete,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeleteExamDialog(
        exam: exam,
        counts: counts,
        onConfirmDelete: onConfirmDelete,
      ),
    );
  }

  @override
  State<DeleteExamDialog> createState() => _DeleteExamDialogState();
}

class _DeleteExamDialogState extends State<DeleteExamDialog> {
  final _inputController = TextEditingController();
  bool _isDeleting = false;
  String? _errorMessage;

  bool get _hasLinkedData => widget.counts.hasLinkedData;

  bool get _isConfirmationValid {
    if (!_hasLinkedData) return true;
    return _inputController.text.trim() == widget.exam.examName.trim();
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _handleDelete() async {
    if (!_isConfirmationValid) return;

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      await widget.onConfirmDelete();
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _errorMessage = e
              .toString()
              .replaceAll('Exception:', '')
              .replaceAll('ExamValidationException:', '')
              .replaceAll('ExamPermissionException:', '')
              .trim();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.delete_forever, color: Colors.red, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Delete Exam: ${widget.exam.examName}',
              style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner if any
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, size: 16, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Linked Data Warning Box (if linked data exists)
              if (_hasLinkedData) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF451A1A) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFCA5A5),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          widget.counts.formatSummary(),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    ),
                    children: [
                      const TextSpan(text: 'To confirm, please type '),
                      TextSpan(
                        text: widget.exam.examName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const TextSpan(text: ' in the field below:'),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                TextField(
                  controller: _inputController,
                  enabled: !_isDeleting,
                  style: const TextStyle(fontSize: 13),
                  decoration: examInputDecoration(
                    context,
                    hint: 'Type exam name to confirm...',
                    enabled: !_isDeleting,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ] else ...[
                Text(
                  'Are you sure you want to permanently delete "${widget.exam.examName}"? This action cannot be undone.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: _isConfirmationValid ? Colors.red.shade700 : Colors.grey.shade400,
            foregroundColor: Colors.white,
          ),
          onPressed: (_isDeleting || !_isConfirmationValid) ? null : _handleDelete,
          child: _isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Delete Exam'),
        ),
      ],
    );
  }
}

