import 'package:flutter/material.dart';
import '../../domain/exam_schedule_model.dart';
import 'exam_ui.dart';

class CancelExamDialog extends StatefulWidget {
  final ExamSchedule exam;

  const CancelExamDialog({super.key, required this.exam});

  static Future<String?> show(BuildContext context, ExamSchedule exam) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => CancelExamDialog(exam: exam),
    );
  }

  @override
  State<CancelExamDialog> createState() => _CancelExamDialogState();
}

class _CancelExamDialogState extends State<CancelExamDialog> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Cancel Exam: ${widget.exam.examName}',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notice banner
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
                    const Icon(Icons.info_outline, color: Colors.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Cancelling will cancel all papers in this exam. This cannot be undone.',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFFFECACA) : const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Cancellation Reason *',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: _reasonController,
                maxLines: 3,
                style: const TextStyle(fontSize: 13),
                decoration: examInputDecoration(
                  context,
                  hint: 'Enter specific reason for cancelling this examination...',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'This field is required. Please provide a reason.';
                  }
                  if (value.trim().length < 5) {
                    return 'Reason must be at least 5 characters.';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Keep Exam'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop(_reasonController.text.trim());
            }
          },
          child: const Text('Confirm Cancellation'),
        ),
      ],
    );
  }
}

