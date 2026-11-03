import 'package:flutter/material.dart';
import '../panels/marks_entry_panel.dart';

class TeacherExamMarksEntryScreen extends StatelessWidget {
  final String? initialExamScheduleId;

  const TeacherExamMarksEntryScreen({
    super.key,
    this.initialExamScheduleId,
  });

  @override
  Widget build(BuildContext context) {
    return MarksEntryPanel(examId: initialExamScheduleId);
  }
}
