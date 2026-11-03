import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../domain/class_model.dart';
import '../widgets/classes_lookup.dart';
import '../widgets/classes_ui.dart';

/// Admin: create (existing == null) or edit a class.
class ClassFormScreen extends ConsumerStatefulWidget {
  final ClassModel? existing;
  const ClassFormScreen({super.key, this.existing});

  @override
  ConsumerState<ClassFormScreen> createState() => _ClassFormScreenState();
}

class _ClassFormScreenState extends ConsumerState<ClassFormScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedYear = '2026-2027';
  String? _selectedClassroomId;
  late final TextEditingController _name;
  late final TextEditingController _code;
  late final TextEditingController _strength;
  String _status = 'Active';
  bool _saving = false;

  static const List<String> _supportedYears = [
    '2026-2027',
    '2027-2028',
    '2028-2029',
  ];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final eYear = e?.academicYear.trim() ?? '';
    _selectedYear = eYear.isNotEmpty ? eYear : '2026-2027';
    _selectedClassroomId = e?.classroomId;
    _name = TextEditingController(text: e?.name ?? '');
    _code = TextEditingController(text: e?.code ?? '');
    _strength = TextEditingController(
      text: (e?.capacity != null && e!.capacity > 0)
          ? e.capacity.toString()
          : '',
    );
    _status = e?.status ?? 'Active';
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    _strength.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final strengthVal = int.tryParse(_strength.text.trim()) ?? 0;

    if (strengthVal <= 0) {
      showCompactSnackBar(
        context,
        'Class strength must be a positive number greater than 0.',
      );
      return;
    }

    setState(() => _saving = true);
    final isNew = widget.existing == null;
    final finalName = _name.text.trim();

    // Auto-derive grade level from class name if available
    int grade = 1;
    final digitMatch = RegExp(r'\d+').firstMatch(finalName);
    if (digitMatch != null) {
      grade = int.tryParse(digitMatch.group(0)!) ?? 1;
    } else {
      grade = widget.existing?.gradeLevel ?? 1;
    }

    final finalCode = _code.text.trim().isNotEmpty
        ? _code.text.trim()
        : 'CLS-$grade';

    final model = ClassModel(
      id: widget.existing?.id ?? '',
      name: finalName,
      code: finalCode,
      gradeLevel: grade,
      academicYear: _selectedYear,
      status: _status,
      classTeacherId: widget.existing?.classTeacherId,
      classroomId: _selectedClassroomId,
      capacity: strengthVal,
      subjectCount: widget.existing?.subjectCount,
      studentCount: widget.existing?.studentCount,
      teacherCount: widget.existing?.teacherCount,
      customFields: widget.existing?.customFields ?? const {},
    );

    final ok = await runClassesAction(
      context,
      () => ref
          .read(classesControllerProvider.notifier)
          .save(model, isNew: isNew),
      success: isNew ? 'Class created' : 'Class updated',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final lookup = ref.watch(classesLookupProvider);
    final isNew = widget.existing == null;
    final blockedRooms = roomsBlockedFor(
      classId: widget.existing?.id,
      classes: lookup.classes,
      sections: lookup.sections,
      classrooms: lookup.classrooms,
    );
    final selectableRooms = lookup.classrooms.where(
      (room) => !blockedRooms.containsKey(room.id),
    );

    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Add New Class' : 'Edit Class')),
      body: AccessGuard(
        allowed: perms.canManageClasses,
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // 1. Academic Year — dropdown
                  DropdownButtonFormField<String>(
                    initialValue: _selectedYear,
                    decoration: const InputDecoration(
                      labelText: 'Academic Year',
                      border: OutlineInputBorder(),
                    ),
                    items:
                        [
                              ..._supportedYears,
                              if (_selectedYear.isNotEmpty &&
                                  !_supportedYears.contains(_selectedYear))
                                _selectedYear,
                            ]
                            .map(
                              (y) => DropdownMenuItem(value: y, child: Text(y)),
                            )
                            .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedYear = v);
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String?>(
                    initialValue: _selectedClassroomId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Classroom / Room Number (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('None (Unassigned)'),
                      ),
                      for (final room in selectableRooms)
                        DropdownMenuItem<String?>(
                          value: room.id,
                          child: Text(
                            '${room.name} · ${room.displayFloor} · Capacity: ${room.capacity}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      if (_selectedClassroomId != null &&
                          !lookup.classrooms.any(
                            (room) => room.id == _selectedClassroomId,
                          ))
                        DropdownMenuItem<String?>(
                          value: _selectedClassroomId,
                          child: Text(
                            'Unavailable room (${lookup.roomName(_selectedClassroomId)})',
                          ),
                        ),
                      if (_selectedClassroomId != null &&
                          blockedRooms.containsKey(_selectedClassroomId) &&
                          lookup.classrooms.any(
                            (room) => room.id == _selectedClassroomId,
                          ))
                        DropdownMenuItem<String?>(
                          value: _selectedClassroomId,
                          child: Text(
                            '${lookup.roomName(_selectedClassroomId)} · ${blockedRooms[_selectedClassroomId]}',
                          ),
                        ),
                    ],
                    onChanged: (value) =>
                        setState(() => _selectedClassroomId = value),
                  ),
                  if (lookup.classrooms.isEmpty) ...[
                    const SizedBox(height: 4),
                    const Text(
                      'No classrooms available. Add a classroom in Class Rooms first.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // 2. Class Name — text input
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Class Name',
                      hintText: 'e.g. Class 10',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Class name is required'
                        : null,
                    onChanged: (val) {
                      if (_code.text.isEmpty || _code.text.startsWith('CLS-')) {
                        final match = RegExp(r'\d+').firstMatch(val);
                        if (match != null) {
                          _code.text = 'CLS-${match.group(0)}';
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // 3. Class Code — text input with auto-generation
                  TextFormField(
                    controller: _code,
                    decoration: const InputDecoration(
                      labelText: 'Class Code',
                      hintText: 'e.g. CLS-10',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Class code is required'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // 4. Class Strength — numeric input
                  TextFormField(
                    controller: _strength,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Class Strength',
                      hintText: 'e.g. 25',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0)
                        return 'Enter a positive number (>0)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // 5. Status — dropdown with Active and Inactive
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Active', child: Text('Active')),
                      DropdownMenuItem(
                        value: 'Inactive',
                        child: Text('Inactive'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _status = v);
                    },
                  ),
                  const SizedBox(height: 24),

                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF109F83),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: _saving ? null : _save,
                    child: Text(
                      _saving
                          ? 'Saving…'
                          : (isNew ? 'Create Class' : 'Save Changes'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
