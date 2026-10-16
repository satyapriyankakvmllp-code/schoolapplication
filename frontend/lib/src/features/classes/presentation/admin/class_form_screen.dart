import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/classes_access.dart';
import '../../application/classes_controller.dart';
import '../../application/classroom_controller.dart';
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
  late final TextEditingController _name;
  late final TextEditingController _grade;
  late final TextEditingController _year;
  String? _teacherId;
  String? _roomId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _grade = TextEditingController(text: e == null ? '' : e.gradeLevel.toString());
    _year = TextEditingController(text: e?.academicYear ?? '');
    _teacherId = e?.classTeacherId;
    _roomId = e?.classroomId;
  }

  @override
  void dispose() {
    _name.dispose();
    _grade.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final isNew = widget.existing == null;
    final model = ClassModel(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      gradeLevel: int.parse(_grade.text.trim()),
      academicYear: _year.text.trim(),
      classTeacherId: _teacherId,
      classroomId: _roomId,
    );
    final ok = await runClassesAction(
      context,
      () => ref.read(classesControllerProvider.notifier).save(model, isNew: isNew),
      success: isNew ? 'Class created' : 'Class updated',
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(classesPermissionsProvider);
    final teachers = ref.watch(classesTeachersProvider);
    final rooms = ref.watch(classroomControllerProvider).valueOrNull ?? const [];
    final isNew = widget.existing == null;
    return Scaffold(
      appBar: AppBar(title: Text(isNew ? 'Create Class' : 'Edit Class')),
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
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Class name'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _grade,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Grade level'),
                    validator: (v) => int.tryParse(v?.trim() ?? '') == null ? 'Enter a number' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _year,
                    decoration: const InputDecoration(labelText: 'Academic year (e.g. 2026-27)'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  IdDropdown(
                    label: 'Class teacher',
                    value: _teacherId,
                    options: {for (final t in teachers) t.id: t.name},
                    onChanged: (v) => setState(() => _teacherId = v),
                  ),
                  const SizedBox(height: 12),
                  IdDropdown(
                    label: 'Classroom',
                    value: _roomId,
                    options: {for (final r in rooms) r.id: r.name},
                    onChanged: (v) => setState(() => _roomId = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: Text(_saving ? 'Saving…' : 'Save'),
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
