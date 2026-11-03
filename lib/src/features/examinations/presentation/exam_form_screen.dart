import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../application/exam_controller.dart';
import '../application/examination_access.dart';
import '../domain/exam_schedule_model.dart';
import 'widgets/exam_status_badge.dart';
import 'widgets/exam_ui.dart';

class ExamFormScreen extends ConsumerStatefulWidget {
  final ExamSchedule? existingExam;
  final bool isDialog;
  final void Function(ExamSchedule savedExam, bool openPapersTab)? onSaved;

  const ExamFormScreen({
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
    return showDialog<ExamSchedule>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
          child: ExamFormScreen(
            existingExam: existingExam,
            isDialog: true,
            onSaved: onSaved,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<ExamFormScreen> createState() => _ExamFormScreenState();
}

class _ExamFormScreenState extends ConsumerState<ExamFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final TextEditingController _startDateController;
  late final TextEditingController _endDateController;

  late String _selectedAcademicYear;
  late String _selectedExamType;
  late String _status;
  bool _statusTouched = false;
  late final TextEditingController _cancelReasonController;

  bool _isSaving = false;
  String? _formErrorMessage;
  ExamSchedule? _overlappingExam;

  bool get _isEditMode => widget.existingExam != null;
  // Rule 4 (Revised): Admin/Principal can Edit in ANY status, all fields editable.
  // Other roles stay read-only.
  bool get _isReadOnly => ref.watch(examinationPermissionsProvider).isReadOnly;

  @override
  void initState() {
    super.initState();
    final exam = widget.existingExam;

    _nameController = TextEditingController(text: exam?.examName ?? '');
    _descController = TextEditingController(text: exam?.description ?? '');
    _startDateController = TextEditingController(text: exam?.startDate ?? '');
    _endDateController = TextEditingController(text: exam?.endDate ?? '');

    _status = exam?.status ?? 'PLANNED';
    _cancelReasonController = TextEditingController(text: exam?.cancelReason ?? '');
    _selectedAcademicYear = exam?.academicYear ?? '2026-2027';
    _selectedExamType = exam?.examType ?? 'UNIT_TEST';

    // Check for overlap on initial load if editing
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkOverlap();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    _cancelReasonController.dispose();
    super.dispose();
  }

  Future<void> _checkOverlap() async {
    final start = _startDateController.text.trim();
    final end = _endDateController.text.trim();

    if (start.isEmpty || end.isEmpty) {
      if (_overlappingExam != null) {
        setState(() => _overlappingExam = null);
      }
      return;
    }

    try {
      final repo = ref.read(examRepositoryProvider);
      final overlap = await repo.checkDateOverlap(
        examType: _selectedExamType,
        academicYear: _selectedAcademicYear,
        startDate: start,
        endDate: end,
        excludeExamId: widget.existingExam?.examScheduleId,
      );
      if (mounted) {
        setState(() => _overlappingExam = overlap);
      }
    } catch (_) {
      // Ignore background overlap check errors
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    if (_isReadOnly) return;

    DateTime initialDate;
    final textVal =
        isStart ? _startDateController.text : _endDateController.text;

    if (textVal.isNotEmpty) {
      try {
        final p = textVal.split('-').map(int.parse).toList();
        initialDate = DateTime(p[0], p[1], p[2]);
      } catch (_) {
        initialDate = DateTime.now();
      }
    } else {
      initialDate = DateTime.now();
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Business rule 5: start date cannot be in past when creating
    final firstDate = (!_isEditMode && isStart)
        ? today
        : DateTime(2024, 1, 1);
    final lastDate = DateTime(2030, 12, 31);

    final effectiveInitial = initialDate.isBefore(firstDate)
        ? firstDate
        : initialDate.isAfter(lastDate)
            ? lastDate
            : initialDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: effectiveInitial,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      final formatted = DateFormat('yyyy-MM-dd').format(picked);
      setState(() {
        if (isStart) {
          _startDateController.text = formatted;
        } else {
          _endDateController.text = formatted;
        }
      });
      _checkOverlap();
    }
  }

  Future<void> _submitForm({required bool openPapersTab}) async {
    if (_isReadOnly) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _formErrorMessage = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final startStr = _startDateController.text.trim();
    final endStr = _endDateController.text.trim();

    // Additional Date Validations
    try {
      final startParts = startStr.split('-').map(int.parse).toList();
      final endParts = endStr.split('-').map(int.parse).toList();
      final start = DateTime(startParts[0], startParts[1], startParts[2]);
      final end = DateTime(endParts[0], endParts[1], endParts[2]);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      if (!_isEditMode && start.isBefore(today)) {
        setState(() => _formErrorMessage = 'Start date cannot be in the past.');
        return;
      }

      if (end.isBefore(start)) {
        setState(() =>
            _formErrorMessage = 'End date must be on or after the start date.');
        return;
      }
    } catch (_) {
      setState(() => _formErrorMessage = 'Invalid date format. Expected yyyy-MM-dd.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final controller = ref.read(examListControllerProvider.notifier);

      ExamSchedule savedExam;
      if (_isEditMode) {
        final current = widget.existingExam!;
        final dateStatus = ExamSchedule.computeStatus(
          rawStatus: 'PLANNED',
          startDate: startStr,
          endDate: endStr,
        );
        final manual = _statusTouched
            ? (_status != 'CANCELLED' && _status != dateStatus)
            : current.manualStatus;
        final updated = current.copyWith(
          examName: _nameController.text.trim(),
          examType: _selectedExamType,
          academicYear: _selectedAcademicYear,
          startDate: startStr,
          endDate: endStr,
          description: _descController.text.trim(),
          status: _status,
          manualStatus: manual,
          cancelReason: _status == 'CANCELLED' ? _cancelReasonController.text.trim() : null,
          clearCancelReason: _status != 'CANCELLED',
        );
        savedExam = await controller.updateExam(updated);
      } else {
        final newDateStatus = ExamSchedule.computeStatus(
          rawStatus: 'PLANNED',
          startDate: startStr,
          endDate: endStr,
        );
        final newSchedule = ExamSchedule(
          examScheduleId: '',
          examName: _nameController.text.trim(),
          examType: _selectedExamType,
          academicYear: _selectedAcademicYear,
          startDate: startStr,
          endDate: endStr,
          description: _descController.text.trim(),
          status: _status,
          manualStatus: _status != 'CANCELLED' && _status != newDateStatus,
          cancelReason: _status == 'CANCELLED' ? _cancelReasonController.text.trim() : null,
          createdBy: ref.read(currentExamActorProvider).userId,
          createdAt: '',
          updatedAt: '',
        );
        savedExam = await controller.createExam(newSchedule);
      }

      if (mounted) {
        if (widget.onSaved != null) {
          widget.onSaved!(savedExam, openPapersTab);
        } else {
          Navigator.of(context).pop(savedExam);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _formErrorMessage = e
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
    final setup = ref.watch(globalSetupProvider).valueOrNull;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final academicYears = setup?.academicYears ?? ['2025-2026', '2026-2027'];
    final examTypes = setup?.examTypes ?? [];

    final formContent = Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        shrinkWrap: widget.isDialog,
        children: [
          // Header / Read-only notice
          if (_isReadOnly) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.shade400),
              ),
              child: const Row(
                children: [
                  Icon(Icons.lock_outline, size: 18, color: Colors.amber),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You have read-only access to this examination.',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Error Message Box
          if (_formErrorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade300),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, size: 18, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formErrorMessage!,
                      style: const TextStyle(fontSize: 12.5, color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // Non-blocking Overlap Warning Box
          if (_overlappingExam != null) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade400),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Warning: Dates overlap with existing exam "${_overlappingExam!.examName}" (${_overlappingExam!.startDate} to ${_overlappingExam!.endDate}) of the same exam type.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFFFDBA74) : const Color(0xFFC2410C),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // 1. Exam status (dropdown)
          const Text(
            'Exam Status *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            key: ValueKey('exam-status-$_status'),
            initialValue: _status,
            isExpanded: true,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            decoration: examInputDecoration(context, enabled: !_isReadOnly),
            items: const [
              DropdownMenuItem(value: 'PLANNED', child: Text('Planned')),
              DropdownMenuItem(value: 'ONGOING', child: Text('Ongoing')),
              DropdownMenuItem(value: 'COMPLETED', child: Text('Completed')),
              DropdownMenuItem(value: 'CANCELLED', child: Text('Cancelled')),
            ],
            onChanged: _isReadOnly
                ? null
                : (val) {
                    if (val != null) {
                      setState(() {
                        _status = val;
                        _statusTouched = true;
                      });
                    }
                  },
          ),
          const SizedBox(height: 4),
          Text(
            'Follows the exam dates automatically unless you pick a status here.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
          if (_status == 'CANCELLED') ...[
            const SizedBox(height: 12),
            const Text(
              'Reason for cancelling *',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _cancelReasonController,
              enabled: !_isReadOnly,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: examInputDecoration(
                context,
                hint: 'e.g. Postponed due to holidays',
                enabled: !_isReadOnly,
              ),
              validator: (val) {
                if (_status == 'CANCELLED' && (val == null || val.trim().isEmpty)) {
                  return 'A cancellation reason is required.';
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 14),

          // 2. Exam Name
          const Text(
            'Exam Name *',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            enabled: !_isReadOnly,
            maxLength: 100,
            style: const TextStyle(fontSize: 13),
            decoration: examInputDecoration(context, hint: 'e.g. Unit Test 1, Mid-Term Examination', enabled: !_isReadOnly),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'This field is required.';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // 3. Exam Type & Academic Year Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Exam Type
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Exam Type *',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedExamType,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: examInputDecoration(context, enabled: !_isReadOnly),
                      items: examTypes.map((t) {
                        return DropdownMenuItem<String>(
                          value: t.code,
                          child: Text(t.label, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _isReadOnly
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedExamType = val);
                                _checkOverlap();
                              }
                            },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Academic Year
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Academic Year *',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAcademicYear,
                      isExpanded: true,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      decoration: examInputDecoration(context, enabled: !_isReadOnly),
                      items: academicYears.map((y) {
                        return DropdownMenuItem<String>(
                          value: y,
                          child: Text(y, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: _isReadOnly
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedAcademicYear = val);
                                _checkOverlap();
                              }
                            },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 4. Start Date & End Date Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Start Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Start Date *',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      enabled: !_isReadOnly,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: examInputDecoration(context, hint: 'yyyy-MM-dd', enabled: !_isReadOnly, suffixIcon: const Icon(Icons.calendar_today, size: 16)),
                      onTap: () => _pickDate(isStart: true),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // End Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'End Date *',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      enabled: !_isReadOnly,
                      style: const TextStyle(fontSize: 12.5),
                      decoration: examInputDecoration(context, hint: 'yyyy-MM-dd', enabled: !_isReadOnly, suffixIcon: const Icon(Icons.calendar_today, size: 16)),
                      onTap: () => _pickDate(isStart: false),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'This field is required.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 5. Description
          const Text(
            'Description',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descController,
            enabled: !_isReadOnly,
            maxLines: 3,
            style: const TextStyle(fontSize: 13),
            decoration: examInputDecoration(context, hint: 'Provide details, scope, or guidelines for this exam schedule...', enabled: !_isReadOnly),
          ),
        ],
      ),
    );

    final actionButtons = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          OutlinedButton(
            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          if (!_isReadOnly) ...[
            FilledButton.tonal(
              onPressed: _isSaving ? null : () => _submitForm(openPapersTab: false),
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditMode ? 'Save Changes' : 'Save Exam'),
            ),
            FilledButton(
              onPressed: _isSaving ? null : () => _submitForm(openPapersTab: true),
              child: const Text('Save & Add Papers'),
            ),
          ],
        ],
      ),
    );

    if (widget.isDialog) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dialog Title Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
            child: Row(
              children: [
                Icon(
                  _isEditMode ? Icons.edit_calendar : Icons.add_circle_outline,
                  color: const Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _isEditMode ? 'Edit Examination' : 'Create Examination',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
          Flexible(child: formContent),
          const Divider(height: 1),
          actionButtons,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Examination' : 'Create Examination'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: formContent),
            const Divider(height: 1),
            actionButtons,
          ],
        ),
      ),
    );
  }
}
