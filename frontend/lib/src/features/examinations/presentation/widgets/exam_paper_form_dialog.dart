import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/exam_paper_controller.dart';
import '../../domain/exam_timetable_model.dart';
import '../../domain/exam_reference_model.dart';
import '../../domain/exam_schedule_model.dart';
import '../tabs/flow_ui.dart';

/// Screen 2B: Add / Edit Exam Timetable Entry dialog.
/// All fields have visible bordered boxes. Class dropdown resets section & subject.
class ExamTimetableFormDialog extends ConsumerStatefulWidget {
  final ExamSchedule exam;
  final ExamTimetableEntry? entry;
  final ExamReferenceData refData;

  const ExamTimetableFormDialog({
    super.key,
    required this.exam,
    this.entry,
    required this.refData,
  });

  @override
  ConsumerState<ExamTimetableFormDialog> createState() => _ExamTimetableFormDialogState();
}

class _ExamTimetableFormDialogState extends ConsumerState<ExamTimetableFormDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _classId;
  String? _sectionId;
  String? _subjectId;
  String? _invigilatorId;
  String? _roomId;
  String _status = 'SCHEDULED';

  late final TextEditingController _dateCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;
  late final TextEditingController _maxCtrl;
  late final TextEditingController _passCtrl;

  String? _error;
  bool _saving = false;

  bool get _isEdit => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _sectionId = e?.classSectionId;
    _classId = e?.classId ?? widget.refData.classIdForSection(_sectionId);
    _subjectId = e?.subjectId;
    _invigilatorId = e?.invigilatorId;
    _roomId = e?.roomId;
    _status = e?.status ?? 'SCHEDULED';

    _dateCtrl = TextEditingController(text: e?.examDate ?? widget.exam.startDate);
    _startCtrl = TextEditingController(text: e?.startTime ?? '09:30');
    _endCtrl = TextEditingController(text: e?.endTime ?? '12:30');
    _maxCtrl = TextEditingController(text: (e?.maxMarks ?? 100).toStringAsFixed(0));
    _passCtrl = TextEditingController(text: (e?.passingMarks ?? 35).toStringAsFixed(0));
  }

  @override
  void dispose() {
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _maxCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String _calculateDuration() {
    try {
      final s = _startCtrl.text.split(':').map(int.parse).toList();
      final e = _endCtrl.text.split(':').map(int.parse).toList();
      final sm = s[0] * 60 + s[1];
      final em = e[0] * 60 + e[1];
      if (em <= sm) return '0 min (End time must be after start time)';
      final diff = em - sm;
      final hrs = diff ~/ 60;
      final mins = diff % 60;
      if (hrs == 0) return '$mins mins';
      if (mins == 0) return '$hrs hours';
      return '$hrs hrs $mins mins';
    } catch (_) {
      return '—';
    }
  }

  Future<void> _pickDate() async {
    final start = DateTime.parse(widget.exam.startDate);
    final end = DateTime.parse(widget.exam.endDate);
    final cur = DateTime.tryParse(_dateCtrl.text) ?? start;
    final picked = await showDatePicker(
      context: context,
      initialDate: cur.isBefore(start) || cur.isAfter(end) ? start : cur,
      firstDate: start,
      lastDate: end,
    );
    if (picked != null) {
      setState(() {
        _dateCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final parts = ctrl.text.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.tryParse(parts.first) ?? 9,
        minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      ),
    );
    if (picked != null) {
      setState(() {
        ctrl.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'This field is required.' : null;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final draft = ExamTimetableEntry(
      id: widget.entry?.id ?? '',
      examScheduleId: widget.exam.examScheduleId,
      classId: _classId,
      classSectionId: _sectionId,
      subjectId: _subjectId,
      examDate: _dateCtrl.text.trim(),
      startTime: _startCtrl.text.trim(),
      endTime: _endCtrl.text.trim(),
      maxMarks: double.tryParse(_maxCtrl.text) ?? 100.0,
      passingMarks: double.tryParse(_passCtrl.text) ?? 35.0,
      invigilatorId: _invigilatorId,
      roomId: _roomId,
      status: _status,
      createdAt: widget.entry?.createdAt ?? '',
    );

    try {
      final actions = ref.read(examTimetableActionsProvider);
      if (_isEdit) {
        await actions.update(draft, widget.exam);
      } else {
        await actions.add(draft, widget.exam);
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = flowError(e);
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.refData;
    final availableSections = r.sectionsForClass(_classId);
    final availableSubjects = r.subjectsForClass(_classId);

    return AlertDialog(
      title: Text(_isEdit ? 'Edit Exam Timetable Entry' : 'Add Exam Timetable Entry'),
      content: SizedBox(
        width: 540,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade400, width: 1.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: TextStyle(
                              color: Colors.red.shade900,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // 1. Examination (Read-only banner)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF109F83).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF109F83).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_note, color: Color(0xFF109F83), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Examination: ${widget.exam.examName} (${widget.exam.startDate} to ${widget.exam.endDate})',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F766E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Class Dropdown
                DropdownButtonFormField<String>(
                  value: r.classes.any((c) => c.id == _classId) ? _classId : null,
                  isExpanded: true,
                  decoration: flowDecoration(context, 'Class *'),
                  items: [
                    for (final c in {for (final x in r.classes) x.id: x}.values)
                      DropdownMenuItem(value: c.id, child: Text(c.label)),
                  ],
                  validator: _req,
                  onChanged: (v) {
                    setState(() {
                      _classId = v;
                      // Reset section and subject when class changes
                      _sectionId = null;
                      _subjectId = null;
                      _invigilatorId = null;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 3. Section Dropdown (Filtered by selected Class)
                DropdownButtonFormField<String>(
                  value: availableSections.any((s) => s.id == _sectionId) ? _sectionId : null,
                  isExpanded: true,
                  decoration: flowDecoration(context, 'Section *',
                      hint: _classId == null ? 'Select Class first' : null),
                  items: [
                    for (final s in {for (final x in availableSections) x.id: x}.values)
                      DropdownMenuItem(value: s.id, child: Text(s.label)),
                  ],
                  validator: _req,
                  onChanged: (v) => setState(() => _sectionId = v),
                ),
                const SizedBox(height: 12),

                // 4. Subject Dropdown (Filtered by selected Class)
                DropdownButtonFormField<String>(
                  value: availableSubjects.any((s) => s.id == _subjectId) ? _subjectId : null,
                  isExpanded: true,
                  decoration: flowDecoration(context, 'Subject *',
                      hint: _classId == null ? 'Select Class first' : null),
                  items: [
                    for (final s in {for (final x in availableSubjects) x.id: x}.values)
                      DropdownMenuItem(
                        value: s.id,
                        child: Text('${s.label}${s.code.isNotEmpty ? " (${s.code})" : ""}'),
                      ),
                  ],
                  validator: _req,
                  onChanged: (v) {
                    setState(() {
                      _subjectId = v;
                      // Pre-fill max and pass marks if available
                      final sub = availableSubjects.where((s) => s.id == v).firstOrNull;
                      if (sub != null && !_isEdit) {
                        _maxCtrl.text = sub.maxMarks.toStringAsFixed(0);
                        _passCtrl.text = sub.passMarks.toStringAsFixed(0);
                      }
                      // Default invigilator to subject teacher if valid
                      final suggestedTeacher = r.defaultTeacherFor(_sectionId, v);
                      if (suggestedTeacher != null && r.teachers.any((t) => t.id == suggestedTeacher)) {
                        _invigilatorId = suggestedTeacher;
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),

                // 5. Exam Date
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: flowDecoration(
                    context,
                    'Exam Date *',
                    hint: '${widget.exam.startDate} to ${widget.exam.endDate}',
                    suffix: const Icon(Icons.calendar_today, size: 18),
                  ),
                  validator: _req,
                ),
                const SizedBox(height: 12),

                // 6. Start Time & End Time
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startCtrl,
                        readOnly: true,
                        onTap: () => _pickTime(_startCtrl),
                        decoration: flowDecoration(
                          context,
                          'Start Time *',
                          suffix: const Icon(Icons.access_time, size: 18),
                        ),
                        validator: _req,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _endCtrl,
                        readOnly: true,
                        onTap: () => _pickTime(_endCtrl),
                        decoration: flowDecoration(
                          context,
                          'End Time *',
                          suffix: const Icon(Icons.access_time, size: 18),
                        ),
                        validator: _req,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                // Auto-calculated Duration Display
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    children: [
                      const Icon(Icons.timelapse, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        'Duration: ${_calculateDuration()}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // 7. Max Marks & Passing Marks
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: flowDecoration(context, 'Max Marks *'),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0) return 'Must be > 0';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _passCtrl,
                        keyboardType: TextInputType.number,
                        decoration: flowDecoration(context, 'Passing Marks *'),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          final m = double.tryParse(_maxCtrl.text) ?? 0;
                          if (n == null || n < 0) return 'Invalid number';
                          if (n > m) return 'Cannot exceed max';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 8. Room (Classroom module)
                Builder(
                  builder: (context) {
                    final validRooms = <RoomRef>[];
                    final seenR = <String>{};
                    for (final rm in r.rooms) {
                      if (rm.id.isNotEmpty && seenR.add(rm.id)) {
                        validRooms.add(rm);
                      }
                    }
                    final isValueValid = validRooms.any((rm) => rm.id == _roomId);
                    final safeVal = isValueValid ? _roomId : null;

                    return DropdownButtonFormField<String?>(
                      value: safeVal,
                      isExpanded: true,
                      decoration: flowDecoration(context, 'Room'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('No Room assigned')),
                        for (final rm in validRooms)
                          DropdownMenuItem<String?>(value: rm.id, child: Text(rm.label)),
                      ],
                      onChanged: (v) => setState(() => _roomId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 9. Invigilator (Teacher module)
                Builder(
                  builder: (context) {
                    final validTeachers = <TeacherRef>[];
                    final seenT = <String>{};
                    for (final t in r.teachers) {
                      if (t.id.isNotEmpty && seenT.add(t.id)) {
                        validTeachers.add(t);
                      }
                    }
                    final isValueValid = validTeachers.any((t) => t.id == _invigilatorId);
                    final safeVal = isValueValid ? _invigilatorId : null;

                    return DropdownButtonFormField<String?>(
                      value: safeVal,
                      isExpanded: true,
                      decoration: flowDecoration(context, 'Invigilator'),
                      items: [
                        const DropdownMenuItem<String?>(value: null, child: Text('No Invigilator assigned')),
                        for (final t in validTeachers)
                          DropdownMenuItem<String?>(value: t.id, child: Text(t.label)),
                      ],
                      onChanged: (v) => setState(() => _invigilatorId = v),
                    );
                  },
                ),
                const SizedBox(height: 12),

                // 10. Status
                DropdownButtonFormField<String>(
                  value: _status,
                  isExpanded: true,
                  decoration: flowDecoration(context, 'Status *'),
                  items: const [
                    DropdownMenuItem(value: 'SCHEDULED', child: Text('SCHEDULED')),
                    DropdownMenuItem(value: 'COMPLETED', child: Text('COMPLETED')),
                    DropdownMenuItem(value: 'CANCELLED', child: Text('CANCELLED')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'SCHEDULED'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF109F83)),
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving...' : 'Save Exam Timetable Entry'),
        ),
      ],
    );
  }
}

/// Backwards compatibility alias
typedef ExamPaperFormDialog = ExamTimetableFormDialog;
