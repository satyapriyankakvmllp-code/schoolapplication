import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/examination_providers.dart';
import '../../domain/exam_master_data.dart';
import '../../domain/exam_schedule_model.dart';
import 'exam_ui.dart';

/// Exam dropdown shared by all examination screens. The choice is remembered
/// while moving between screens.
class ExamSelector extends ConsumerWidget {
  /// Only exams matching this test are offered (for example only exams that
  /// are not cancelled).
  final bool Function(ExamSchedule exam)? where;
  final String label;
  final ValueChanged<String?>? onChanged;

  const ExamSelector({super.key, this.where, this.label = 'Exam', this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(allExamsProvider);
    final selected = ref.watch(selectedExamIdProvider);
    return async.when(
      loading: () => const SizedBox(height: 60, child: Center(child: LinearProgressIndicator())),
      error: (e, _) => ExamErrorView(e),
      data: (exams) {
        final list = where == null ? exams : exams.where(where!).toList();
        final value = list.any((e) => e.examScheduleId == selected)
            ? selected
            : (list.isNotEmpty ? list.first.examScheduleId : null);
        if (value != selected) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(selectedExamIdProvider.notifier).state = value;
          });
        }
        return ExamDropdown<String>(
          label: label,
          value: value,
          hint: 'Select an exam',
          options: list
              .map((e) => ExamOption(e.examScheduleId, '${e.examName} (${e.academicYear})'))
              .toList(),
          onChanged: (v) {
            ref.read(selectedExamIdProvider.notifier).state = v;
            onChanged?.call(v);
          },
        );
      },
    );
  }
}

/// Class-section dropdown.
class SectionDropdown extends StatelessWidget {
  final List<ExamSectionInfo> sections;
  final ExamMasterData master;
  final String? value;
  final ValueChanged<String?>? onChanged;
  final String label;

  const SectionDropdown({
    super.key,
    required this.sections,
    required this.master,
    required this.value,
    required this.onChanged,
    this.label = 'Class - Section',
  });

  @override
  Widget build(BuildContext context) {
    return ExamDropdown<String>(
      label: label,
      value: value,
      hint: 'Select class-section',
      options: sections.map((s) => ExamOption(s.id, master.sectionLabel(s.id))).toList(),
      onChanged: onChanged,
    );
  }
}

/// Resolves the exam id to use: the fixed one (inside Exam Details) or the
/// shared selection.
String? resolveExamId(WidgetRef ref, String? fixedExamId) {
  return fixedExamId ?? ref.watch(selectedExamIdProvider);
}
