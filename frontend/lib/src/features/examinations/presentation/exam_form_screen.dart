import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../application/exam_controller.dart';
import '../application/examination_access.dart';
import '../domain/exam_schedule_model.dart';

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
  final TextEditingController _cancelReasonController = TextEditingController();

  bool _isSaving = false;
  String? _formErrorMessage;
  ExamSchedule? _overlappingExam;

  bool get _isEditMode => widget.existingExam != null;

  /// Create: only PLANNED. Edit (not yet cancelled/completed): current status or CANCELLED.
  List<String> get _statusOptions {
    final cur = widget.existingExam?.status ?? 'PLANNED';
    if (!_isEditMode) return const ['PLANNED'];
    if (cur == 'CANCELLED') return const ['CANCELLED'];
    if (cur == 'COMPLETED') return const ['COMPLETED'];
    return [cur, 'CANCELLED'];
  }

  bool get _canChangeStatus => !_isReadOnly && _statusOptions.length > 1;

  String _statusLabel(String st) =>
      st[0] + st.substring(1).toLowerCase();
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
    _cancelReasonController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
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
        final updated = current.copyWith(
          examName: _nameController.text.trim(),
          examType: _selectedExamType,
          academicYear: _selectedAcademicYear,
          startDate: startStr,
          endDate: endStr,
          description: _descController.text.trim(),
        );
        savedExam = await controller.updateExam(updated);
        if (_status == 'CANCELLED' && !current.isCancelled) {
          savedExam = await controller.cancelExam(
            savedExam.examScheduleId,
            _cancelReasonController.text.trim(),
          );
        }
      } else {
        final newSchedule = ExamSchedule(
          examScheduleId: '',
          examName: _nameController.text.trim(),
          examType: _selectedExamType,
          academicYear: _selectedAcademicYear,
          startDate: startStr,
          endDate: endStr,
          description: _descController.text.trim(),
          status: 'PLANNED',
          createdBy: 'u1',
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

          // 1. Status dropdown
          const Text(
            'Exam Status',
            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            value: _statusOptions.contains(_status) ? _status : _statusOptions.first,
            isExpanded: true,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: _canChangeStatus
                  ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                  : (isDark ? Colors.black26 : Colors.grey.shade200),
              helperText: _isEditMode
                  ? 'Status follows the exam dates automatically. Choose Cancelled to cancel (reason required).'
                  : 'New exams always start as Planned.',
              helperMaxLines: 2,
            ),
            items: [
              for (final st in _statusOptions)
                DropdownMenuItem(value: st, child: Text(_statusLabel(st))),
            ],
            onChanged: _canChangeStatus
                ? (v) => setState(() => _status = v ?? _status)
                : null,
          ),
          if (_status == 'CANCELLED' && !(widget.existingExam?.isCancelled ?? false)) ...[
            const SizedBox(height: 10),
            TextFormField(
              controller: _cancelReasonController,
              maxLines: 2,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                labelText: 'Cancel Reason *',
                border: const OutlineInputBorder(),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              ),
              validator: (v) => (_status == 'CANCELLED' && (v == null || v.trim().isEmpty))
                  ? 'This field is required.'
                  : null,
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
            decoration: InputDecoration(
              hintText: 'e.g. Unit Test 1, Mid-Term Examination',
              hintStyle: const TextStyle(fontSize: 12.5),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF109F83), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              filled: true,
              fillColor: _isReadOnly
                  ? (isDark ? Colors.black26 : Colors.grey.shade200)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
            ),
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
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF109F83), width: 2),
              ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: _isReadOnly
                  ? (isDark ? Colors.black26 : Colors.grey.shade200)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      ),
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
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF109F83), width: 2),
              ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        filled: true,
                        fillColor: _isReadOnly
                  ? (isDark ? Colors.black26 : Colors.grey.shade200)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      ),
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
                      decoration: InputDecoration(
                        hintText: 'yyyy-MM-dd',
                        border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF109F83), width: 2),
              ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        suffixIcon: const Icon(Icons.calendar_today, size: 16),
                        filled: true,
                        fillColor: _isReadOnly
                  ? (isDark ? Colors.black26 : Colors.grey.shade200)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      ),
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
                      decoration: InputDecoration(
                        hintText: 'yyyy-MM-dd',
                        border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF109F83), width: 2),
              ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        suffixIcon: const Icon(Icons.calendar_today, size: 16),
                        filled: true,
                        fillColor: _isReadOnly
                  ? (isDark ? Colors.black26 : Colors.grey.shade200)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      ),
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
            decoration: InputDecoration(
              hintText: 'Provide details, scope, or guidelines for this exam schedule...',
              hintStyle: const TextStyle(fontSize: 12.5),
              border: const OutlineInputBorder(),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: isDark ? Colors.white38 : Colors.grey.shade600),
              ),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF109F83), width: 2),
              ),
              contentPadding: const EdgeInsets.all(12),
              filled: true,
              fillColor: _isReadOnly
                  ? (isDark ? Colors.black26 : Colors.grey.shade200)
                  : (isDark ? const Color(0xFF1E293B) : Colors.white),
            ),
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
              child: const Text('Save & Add Timetable'),
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
