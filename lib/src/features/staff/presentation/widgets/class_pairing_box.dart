import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../classes/application/classes_controller.dart';
import '../../../classes/application/sections_controller.dart';
import '../../../classes/application/subjects_controller.dart';
import '../../../classes/domain/class_model.dart';
import '../../../classes/domain/subject_model.dart';
import '../../../classes/presentation/widgets/classes_ui.dart';
import '../../domain/class_subject_assignment.dart';

class ClassPairingBox extends ConsumerStatefulWidget {
  final List<ClassSubjectAssignment> initialAssignments;
  final ValueChanged<List<ClassSubjectAssignment>> onChanged;
  final bool isDark;

  const ClassPairingBox({
    super.key,
    required this.initialAssignments,
    required this.onChanged,
    required this.isDark,
  });

  @override
  ConsumerState<ClassPairingBox> createState() => _ClassPairingBoxState();
}

class _ClassPairingBoxState extends ConsumerState<ClassPairingBox> {
  late List<ClassSubjectAssignment> _assignments;

  String _selectedGrade = '10th Class';
  String _selectedSection = 'A';
  String _selectedSubject = 'Mathematics';
  bool _isClassTeacher = false;
  final int _periodsPerWeek = 5;
  final Map<String, List<String>> _createdSubjectsByClass = {};

  static const List<String> _fallbackGradeOptions = [
    '1st Class',
    '2nd Class',
    '3rd Class',
    '4th Class',
    '5th Class',
    '6th Class',
    '7th Class',
    '8th Class',
    '9th Class',
    '10th Class',
    '11th Class',
    '12th Class',
  ];

  static const List<String> _fallbackSectionOptions = ['A', 'B', 'C', 'D'];

  static const List<String> _fallbackCommonSubjects = [
    'Mathematics',
    'Advanced Mathematics',
    'Science',
    'Physics',
    'Chemistry',
    'Biology',
    'English Language',
    'English Literature',
    'Social Science',
    'History & Civics',
    'Geography',
    'Computer Science',
    'Information Technology',
    'Hindi',
    'Sanskrit',
    'Physical & Health Education',
    'Art & Craft',
  ];

  @override
  void initState() {
    super.initState();
    _assignments = List.from(widget.initialAssignments);
  }

  void _addPairing() {
    // Check if pairing already exists
    final exists = _assignments.any(
      (a) =>
          a.grade == _selectedGrade &&
          a.section == _selectedSection &&
          a.subject == _selectedSubject,
    );

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This class-section and subject pairing is already assigned.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Synchronize by Class & Section:
    // If this class & section is already marked as Class Teacher, or if _isClassTeacher is checked,
    // mark all pairings for this class & section as Class Teacher, while preserving other classes!
    final isAlreadyClassTeacherForThisClass = _assignments.any(
      (a) =>
          a.grade == _selectedGrade &&
          a.section == _selectedSection &&
          a.isClassTeacher,
    );
    final shouldBeClassTeacher =
        _isClassTeacher || isAlreadyClassTeacherForThisClass;

    List<ClassSubjectAssignment> updated = _assignments.map((a) {
      if (shouldBeClassTeacher &&
          a.grade == _selectedGrade &&
          a.section == _selectedSection) {
        return a.copyWith(isClassTeacher: true);
      }
      return a;
    }).toList();

    updated.add(
      ClassSubjectAssignment(
        grade: _selectedGrade,
        section: _selectedSection,
        subject: _selectedSubject,
        isClassTeacher: shouldBeClassTeacher,
        periodsPerWeek: _periodsPerWeek,
      ),
    );

    setState(() {
      _assignments = updated;
      _isClassTeacher = false;
    });

    widget.onChanged(_assignments);
  }

  void _removePairing(int index) {
    setState(() {
      _assignments.removeAt(index);
    });
    widget.onChanged(_assignments);
  }

  void _toggleClassTeacher(int index) {
    setState(() {
      final target = _assignments[index];
      final newStatus = !target.isClassTeacher;
      // Synchronize all pairings for the same class & section,
      // allowing multiple distinct classes to be assigned as Class Teacher!
      _assignments = _assignments.map((a) {
        if (a.grade == target.grade && a.section == target.section) {
          return a.copyWith(isClassTeacher: newStatus);
        }
        return a;
      }).toList();
    });
    widget.onChanged(_assignments);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark
        ? const Color(0xFF334155)
        : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Dynamic data from central JSON repositories via Riverpod
    final classesAsync = ref.watch(classesControllerProvider);
    final sectionsAsync = ref.watch(sectionsControllerProvider);
    final subjectsAsync = ref.watch(subjectsControllerProvider);

    final rawClasses = classesAsync.value ?? [];
    final rawSections = sectionsAsync.value ?? [];
    final rawSubjects = subjectsAsync.value ?? [];

    // 1. Dynamic Class / Grade Options
    final dynamicGradeOptions = rawClasses.isNotEmpty
        ? rawClasses
              .map((c) => c.name)
              .where((n) => n.trim().isNotEmpty)
              .toSet()
              .toList()
        : _fallbackGradeOptions;

    final effectiveGradeOptions = dynamicGradeOptions.isNotEmpty
        ? dynamicGradeOptions
        : _fallbackGradeOptions;
    if (!effectiveGradeOptions.contains(_selectedGrade) &&
        effectiveGradeOptions.isNotEmpty) {
      _selectedGrade = effectiveGradeOptions.first;
    }

    // 2. Cascading Section Options for the chosen Class
    ClassModel? matchedClass;
    for (final c in rawClasses) {
      if (c.name == _selectedGrade) {
        matchedClass = c;
        break;
      }
    }

    final dynamicSections = matchedClass != null
        ? rawSections
              .where((s) => s.classId == matchedClass!.id)
              .map((s) => s.name)
              .where((n) => n.trim().isNotEmpty)
              .toSet()
              .toList()
        : <String>[];

    final effectiveSectionOptions = dynamicSections.isNotEmpty
        ? dynamicSections
        : _fallbackSectionOptions;
    if (!effectiveSectionOptions.contains(_selectedSection) &&
        effectiveSectionOptions.isNotEmpty) {
      _selectedSection = effectiveSectionOptions.first;
    }

    // 3. Cascading Subject Options for the chosen Class
    final classSpecificSubjects = matchedClass != null
        ? rawSubjects
              .where((s) => s.classId == matchedClass!.id)
              .map((s) => s.name)
              .where((n) => n.trim().isNotEmpty)
              .toSet()
              .toList()
        : <String>[];

    final allDynamicSubjects = rawSubjects
        .map((s) => s.name)
        .where((n) => n.trim().isNotEmpty)
        .toSet()
        .toList();

    final effectiveSubjectOptions = <String>{
      ...(classSpecificSubjects.isNotEmpty
          ? classSpecificSubjects
          : allDynamicSubjects),
      ...(_createdSubjectsByClass[matchedClass?.id] ?? const <String>[]),
    }.toList();

    if (effectiveSubjectOptions.isEmpty) {
      effectiveSubjectOptions.addAll(_fallbackCommonSubjects);
    }
    if (!effectiveSubjectOptions.contains(_selectedSubject) &&
        effectiveSubjectOptions.isNotEmpty) {
      _selectedSubject = effectiveSubjectOptions.first;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.class_outlined,
                size: 18,
                color: Color(0xFF109F83),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Class & Subject Pairing Matrix',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF109F83).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF109F83).withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF109F83),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      classesAsync.isLoading ? 'Syncing...' : 'Dynamic JSON',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF109F83),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_assignments.length} Assigned',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B5CF6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Assign teaching classes and designate class teacher duties. Options sync live from the Academics module.',
            style: TextStyle(fontSize: 12, color: subColor),
          ),
          const SizedBox(height: 16),

          // Input Selector Controls
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmall = constraints.maxWidth < 500;
              if (isSmall) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildGradeDropdown(effectiveGradeOptions),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildSectionDropdown(effectiveSectionOptions),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSubjectSelector(
                      effectiveSubjectOptions,
                      matchedClass,
                    ),
                    const SizedBox(height: 8),
                    _buildTeacherToggleAndAddButton(),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildGradeDropdown(effectiveGradeOptions),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: _buildSectionDropdown(effectiveSectionOptions),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: _buildSubjectDropdown(effectiveSubjectOptions),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: _buildAddSubjectButton(matchedClass),
                  ),
                  const SizedBox(height: 12),
                  _buildTeacherToggleAndAddButton(),
                ],
              );
            },
          ),

          const SizedBox(height: 16),

          // Active Assignments Roster
          if (_assignments.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(
                  color: borderColor,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Icon(Icons.assignment_outlined, size: 28, color: subColor),
                  const SizedBox(height: 6),
                  Text(
                    'No classes or subjects assigned yet.',
                    style: TextStyle(fontSize: 12, color: subColor),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _assignments.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final a = _assignments[index];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: a.isClassTeacher
                          ? const Color(0xFF8B5CF6)
                          : (isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF109F83,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${a.grade}-${a.section}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF109F83),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.subject,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '${a.periodsPerWeek} periods/week',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                          ],
                        ),
                      ),
                      // Class Teacher Toggle Badge
                      InkWell(
                        onTap: () => _toggleClassTeacher(index),
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: a.isClassTeacher
                                ? const Color(
                                    0xFF8B5CF6,
                                  ).withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: a.isClassTeacher
                                  ? const Color(0xFF8B5CF6)
                                  : (isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                a.isClassTeacher
                                    ? Icons.star_rounded
                                    : Icons.star_outline_rounded,
                                size: 14,
                                color: a.isClassTeacher
                                    ? const Color(0xFF8B5CF6)
                                    : (isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                a.isClassTeacher
                                    ? 'Class Teacher'
                                    : 'Set as CT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: a.isClassTeacher
                                      ? const Color(0xFF8B5CF6)
                                      : (isDark
                                            ? const Color(0xFF94A3B8)
                                            : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => _removePairing(index),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        color: Colors.redAccent,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildGradeDropdown(List<String> options) {
    final effectiveVal = options.contains(_selectedGrade)
        ? _selectedGrade
        : (options.isNotEmpty ? options.first : null);
    return DropdownButtonFormField<String>(
      key: ValueKey('grade_${options.length}_$effectiveVal'),
      initialValue: effectiveVal,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Class / Grade',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (g) => DropdownMenuItem(
              value: g,
              child: Text(
                g,
                style: const TextStyle(fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedGrade = val;
          });
        }
      },
    );
  }

  Widget _buildSectionDropdown(List<String> options) {
    final effectiveVal = options.contains(_selectedSection)
        ? _selectedSection
        : (options.isNotEmpty ? options.first : null);
    return DropdownButtonFormField<String>(
      key: ValueKey('section_${options.length}_$effectiveVal'),
      initialValue: effectiveVal,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Section',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: options
          .map(
            (s) => DropdownMenuItem(
              value: s,
              child: Text(s, style: const TextStyle(fontSize: 12)),
            ),
          )
          .toList(),
      onChanged: (val) {
        if (val != null) {
          setState(() {
            _selectedSection = val;
          });
        }
      },
    );
  }

  Widget _buildSubjectDropdown(List<String> options) {
    return SearchableIdDropdown(
      key: ValueKey('subject_${options.length}_$_selectedSubject'),
      label: 'Subject',
      value: _selectedSubject,
      options: {for (final subject in options) subject: subject},
      allowNone: false,
      onChanged: (value) {
        if (value != null) {
          setState(() => _selectedSubject = value);
        }
      },
    );
  }

  Widget _buildSubjectSelector(List<String> options, ClassModel? matchedClass) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSubjectDropdown(options),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: _buildAddSubjectButton(matchedClass),
        ),
      ],
    );
  }

  Widget _buildAddSubjectButton(ClassModel? matchedClass) {
    return TextButton.icon(
      onPressed: matchedClass == null ? null : () => _addSubject(matchedClass),
      icon: const Icon(Icons.add, size: 16),
      label: const Text('Add New Subject'),
    );
  }

  Future<void> _addSubject(ClassModel matchedClass) async {
    final nameController = TextEditingController();
    final subjectName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add New Subject'),
        content: TextField(
          controller: nameController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Subject name',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(nameController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (subjectName == null || subjectName.trim().isEmpty) return;

    final normalizedName = subjectName.trim();
    final duplicate =
        ref
            .read(subjectsControllerProvider)
            .valueOrNull
            ?.where((subject) => subject.classId == matchedClass.id)
            .any(
              (subject) =>
                  subject.name.trim().toLowerCase() ==
                  normalizedName.toLowerCase(),
            ) ??
        false;
    if (duplicate) {
      setState(() => _selectedSubject = normalizedName);
      return;
    }

    final subjectCode = normalizedName
        .toUpperCase()
        .replaceAll(RegExp(r'[^A-Z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
    try {
      final created = await ref
          .read(subjectsControllerProvider.notifier)
          .save(
            SubjectModel(
              id: '',
              classId: matchedClass.id,
              name: normalizedName,
              code: subjectCode.isEmpty
                  ? 'SUB'
                  : subjectCode.substring(
                      0,
                      subjectCode.length > 12 ? 12 : subjectCode.length,
                    ),
            ),
            isNew: true,
          );
      if (!mounted) return;
      setState(() {
        _createdSubjectsByClass
            .putIfAbsent(matchedClass.id, () => [])
            .add(created.name);
        _selectedSubject = created.name;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subject created and selected.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not create subject: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  Widget _buildTeacherToggleAndAddButton() {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: _isClassTeacher,
              activeColor: const Color(0xFF8B5CF6),
              onChanged: (val) {
                setState(() => _isClassTeacher = val ?? false);
              },
            ),
            const Text(
              'Designate as Class Teacher',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: _addPairing,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Pairing', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF109F83),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}
