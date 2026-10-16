import 'package:flutter/material.dart';
import '../../domain/class_subject_assignment.dart';

class ClassPairingBox extends StatefulWidget {
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
  State<ClassPairingBox> createState() => _ClassPairingBoxState();
}

class _ClassPairingBoxState extends State<ClassPairingBox> {
  late List<ClassSubjectAssignment> _assignments;

  String _selectedGrade = 'Class 10';
  String _selectedSection = 'A';
  String _selectedSubject = 'Mathematics';
  bool _isClassTeacher = false;
  final int _periodsPerWeek = 5;

  static const List<String> _gradeOptions = [
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
  ];

  static const List<String> _sectionOptions = ['A', 'B', 'C', 'D'];

  static const List<String> _commonSubjects = [
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
    final exists = _assignments.any((a) =>
        a.grade == _selectedGrade &&
        a.section == _selectedSection &&
        a.subject == _selectedSubject);

    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This class-section and subject pairing is already assigned.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // If marked as class teacher, unmark others if necessary
    List<ClassSubjectAssignment> updated = _assignments.map((a) {
      if (_isClassTeacher && a.isClassTeacher) {
        return a.copyWith(isClassTeacher: false);
      }
      return a;
    }).toList();

    updated.add(ClassSubjectAssignment(
      grade: _selectedGrade,
      section: _selectedSection,
      subject: _selectedSubject,
      isClassTeacher: _isClassTeacher,
      periodsPerWeek: _periodsPerWeek,
    ));

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
      final current = _assignments[index].isClassTeacher;
      _assignments = _assignments.asMap().entries.map((entry) {
        if (entry.key == index) {
          return entry.value.copyWith(isClassTeacher: !current);
        } else if (!current) {
          // If turning this one ON, turn others OFF
          return entry.value.copyWith(isClassTeacher: false);
        }
        return entry.value;
      }).toList();
    });
    widget.onChanged(_assignments);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

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
              const Icon(Icons.class_outlined, size: 18, color: Color(0xFF109F83)),
              const SizedBox(width: 8),
              Text(
                'Class & Subject Pairing Matrix',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF109F83).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_assignments.length} Assigned',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF109F83),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Assign teaching classes and designate primary class teacher duties for institutional report cards.',
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
                        Expanded(child: _buildGradeDropdown()),
                        const SizedBox(width: 8),
                        Expanded(child: _buildSectionDropdown()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildSubjectDropdown(),
                    const SizedBox(height: 8),
                    _buildTeacherToggleAndAddButton(),
                  ],
                );
              }

              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(flex: 2, child: _buildGradeDropdown()),
                      const SizedBox(width: 8),
                      Expanded(flex: 1, child: _buildSectionDropdown()),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: _buildSubjectDropdown()),
                    ],
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: a.isClassTeacher
                          ? const Color(0xFF8B5CF6)
                          : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF109F83).withValues(alpha: 0.12),
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
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: a.isClassTeacher
                                ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: a.isClassTeacher
                                  ? const Color(0xFF8B5CF6)
                                  : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                a.isClassTeacher ? Icons.star_rounded : Icons.star_outline_rounded,
                                size: 14,
                                color: a.isClassTeacher
                                    ? const Color(0xFF8B5CF6)
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                a.isClassTeacher ? 'Class Teacher' : 'Set as CT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: a.isClassTeacher
                                      ? const Color(0xFF8B5CF6)
                                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
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

  Widget _buildGradeDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedGrade,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Grade',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: _gradeOptions
          .map((g) => DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 12))))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedGrade = val);
      },
    );
  }

  Widget _buildSectionDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSection,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Section',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: _sectionOptions
          .map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12))))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedSection = val);
      },
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedSubject,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Subject',
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(),
      ),
      items: _commonSubjects
          .map((subj) => DropdownMenuItem(value: subj, child: Text(subj, style: const TextStyle(fontSize: 12))))
          .toList(),
      onChanged: (val) {
        if (val != null) setState(() => _selectedSubject = val);
      },
    );
  }

  Widget _buildTeacherToggleAndAddButton() {
    return Row(
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
              'Primary Class Teacher',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _addPairing,
          icon: const Icon(Icons.add, size: 16),
          label: const Text('Add Pairing', style: TextStyle(fontSize: 12)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF109F83),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }
}
