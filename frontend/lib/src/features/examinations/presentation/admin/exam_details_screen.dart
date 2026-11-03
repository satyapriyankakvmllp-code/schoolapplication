import 'package:flutter/material.dart';
import '../exam_details_screen.dart' as legacy;

/// Admin Exam Details Screen
/// Displays full examination details, statistics, and configuration views.
class ExamDetailsScreen extends StatelessWidget {
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
    return legacy.ExamDetailsScreen.showAsDialog(
      context,
      examId: examId,
      initialTab: initialTab,
    );
  }

  @override
  Widget build(BuildContext context) {
    return legacy.ExamDetailsScreen(
      examId: examId,
      initialTab: initialTab,
      isDialog: isDialog,
      onBack: onBack,
    );
  }
}

