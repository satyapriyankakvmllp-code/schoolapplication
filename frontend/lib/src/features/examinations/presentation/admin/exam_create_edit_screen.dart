import 'package:flutter/material.dart';
import '../../domain/exam_schedule_model.dart';
import '../exam_form_screen.dart';

/// Admin Exam Create / Edit Screen
/// Single unified screen supporting both Create Exam and Edit Exam modes.
/// If [existingExam] is null, opens in Create mode.
/// If [existingExam] is provided, opens in Edit mode with prefilled fields.
class ExamCreateEditScreen extends StatelessWidget {
  final ExamSchedule? existingExam;
  final bool isDialog;
  final void Function(ExamSchedule savedExam, bool openPapersTab)? onSaved;

  const ExamCreateEditScreen({
    super.key,
    this.existingExam,
    this.isDialog = false,
    this.onSaved,
  });

  static Future<ExamSchedule?> showAsDialog(
    BuildContext context, {
    ExamSchedule? existingExam,
    void Function(ExamSchedule savedExam, bool openPapersTab)? onSaved,
  }) {
    return ExamFormScreen.showAsDialog(
      context,
      existingExam: existingExam,
      onSaved: onSaved,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExamFormScreen(
      existingExam: existingExam,
      isDialog: isDialog,
      onSaved: onSaved,
    );
  }
}

