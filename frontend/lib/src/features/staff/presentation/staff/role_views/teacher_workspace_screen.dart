import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/commonwidgets/responsive_layout.dart';
import 'package:frontend/src/themes/app_colors.dart';
import '../../../application/staff_auth_controller.dart';
import '../../../domain/staff_member_model.dart';

class TeacherWorkspaceScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const TeacherWorkspaceScreen({
    super.key,
    this.isDark = false,
  });

  @override
  ConsumerState<TeacherWorkspaceScreen> createState() => _TeacherWorkspaceScreenState();
}

class _TeacherWorkspaceScreenState extends ConsumerState<TeacherWorkspaceScreen> {
  // Class Teacher: Section Attendance State
  final Map<String, String> _studentAttendanceStatus = {
    'STU-01': 'Present',
    'STU-02': 'Present',
    'STU-03': 'Absent',
    'STU-04': 'Present',
    'STU-05': 'Late',
    'STU-06': 'Present',
    'STU-07': 'Present',
    'STU-08': 'Present',
  };

  final List<Map<String, dynamic>> _sectionStudents = [
    {'id': 'STU-01', 'roll': '01', 'name': 'Aarav Sharma', 'gender': 'Male', 'blood': 'O+', 'parentPhone': '+91 98765 43210'},
    {'id': 'STU-02', 'roll': '02', 'name': 'Diya Patel', 'gender': 'Female', 'blood': 'B+', 'parentPhone': '+91 98220 11223'},
    {'id': 'STU-03', 'roll': '03', 'name': 'Rohan Verma', 'gender': 'Male', 'blood': 'A+', 'parentPhone': '+91 98110 33445'},
    {'id': 'STU-04', 'roll': '04', 'name': 'Sneha Iyer', 'gender': 'Female', 'blood': 'AB+', 'parentPhone': '+91 97400 55667'},
    {'id': 'STU-05', 'roll': '05', 'name': 'Kabir Mehta', 'gender': 'Male', 'blood': 'O-', 'parentPhone': '+91 98860 77889'},
    {'id': 'STU-06', 'roll': '06', 'name': 'Ananya Sen', 'gender': 'Female', 'blood': 'A-', 'parentPhone': '+91 97110 99001'},
    {'id': 'STU-07', 'roll': '07', 'name': 'Ishan Deshmukh', 'gender': 'Male', 'blood': 'B+', 'parentPhone': '+91 94220 22334'},
    {'id': 'STU-08', 'roll': '08', 'name': 'Tanvi Bhat', 'gender': 'Female', 'blood': 'O+', 'parentPhone': '+91 93410 44556'},
  ];

  // Subject Teacher: Homework Dispatch State
  final _hwTitleCtrl = TextEditingController(text: 'Chapter 4: Quadratic Equations Problem Set');
  final _hwInstructionsCtrl = TextEditingController(text: 'Complete Exercise 4.2 (Questions 1 to 12) in class notebook.');
  String _selectedClassForHw = 'Class 10-A';
  bool _isDispatchingHw = false;

  // Subject Teacher: Marks Entry State
  final Map<String, TextEditingController> _marksControllers = {};

  @override
  void initState() {
    super.initState();
    for (final s in _sectionStudents) {
      _marksControllers[s['id'] as String] = TextEditingController(text: '${38 + int.parse(s['roll'] as String)}');
    }
  }

  @override
  void dispose() {
    _hwTitleCtrl.dispose();
    _hwInstructionsCtrl.dispose();
    for (final c in _marksControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _markAllPresent() {
    setState(() {
      for (final s in _sectionStudents) {
        _studentAttendanceStatus[s['id'] as String] = 'Present';
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All section scholars marked as Present.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submitSectionAttendance(String sectionSummary) {
    int present = _studentAttendanceStatus.values.where((v) => v == 'Present').length;
    int absent = _studentAttendanceStatus.values.where((v) => v == 'Absent').length;
    int lateCount = _studentAttendanceStatus.values.where((v) => v == 'Late').length;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Attendance for $sectionSummary recorded! Present: $present, Absent: $absent, Late: $lateCount'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _dispatchHomework() {
    if (_hwTitleCtrl.text.isEmpty) return;
    setState(() => _isDispatchingHw = true);

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() => _isDispatchingHw = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Homework "${_hwTitleCtrl.text}" dispatched to $_selectedClassForHw!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(currentLoggedInStaffProvider);
    final dark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    final cardBg = dark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderColor = dark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final isMobile = ResponsiveLayout.isMobile(context);

    final isClassTeacher = staff?.isClassTeacher ?? true;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Teacher Hero Banner
          Container(
            padding: EdgeInsets.all(isMobile ? 16 : 22),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (isClassTeacher ? AppColors.secondary : AppColors.primary)
                      .withValues(alpha: dark ? 0.25 : 0.12),
                  cardBg,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (isClassTeacher ? AppColors.secondary : AppColors.primary)
                    .withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: isMobile ? 24 : 32,
                  backgroundColor: isClassTeacher ? AppColors.secondary : AppColors.primary,
                  child: Icon(
                    isClassTeacher ? Icons.stars_rounded : Icons.school_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: isMobile ? 12 : 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isClassTeacher
                                  ? (staff?.classTeacherSummary.isNotEmpty == true
                                      ? staff!.classTeacherSummary
                                      : 'Primary Class Teacher Workspace')
                                  : 'Subject Faculty Instruction Workspace',
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: (isClassTeacher ? AppColors.secondary : AppColors.primary)
                                  .withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isClassTeacher ? 'CLASS TEACHER' : 'SUBJECT FACULTY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isClassTeacher ? AppColors.secondary : AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Faculty: ${staff?.fullName ?? 'Faculty Member'} • ${staff?.designation ?? 'Educator'}',
                        style: TextStyle(fontSize: 12, color: subColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Render View based on isClassTeacher flag
          if (isClassTeacher)
            _buildClassTeacherView(staff, cardBg, borderColor, textColor, subColor, isMobile)
          else
            _buildSubjectTeacherView(staff, cardBg, borderColor, textColor, subColor, isMobile),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 1. CLASS TEACHER VIEW
  // -------------------------------------------------------------------------
  Widget _buildClassTeacherView(
    StaffMemberModel? staff,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    final sectionStr = staff?.primaryClassAssignment?.displayName ?? 'Class 10-A';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Attendance Desk
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.how_to_reg, color: AppColors.secondary, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Daily Section Roll-Call Attendance ($sectionStr)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                        ),
                        Text('Recorded for today • Instant SMS alert dispatched to parents on absence', style: TextStyle(fontSize: 11, color: subColor)),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _markAllPresent,
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark All Present'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.secondary,
                      side: const BorderSide(color: AppColors.secondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Student Roll-Call List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sectionStudents.length,
                separatorBuilder: (_, _) => Divider(color: borderColor.withValues(alpha: 0.5)),
                itemBuilder: (context, index) {
                  final s = _sectionStudents[index];
                  final sid = s['id'] as String;
                  final currentStatus = _studentAttendanceStatus[sid] ?? 'Present';

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            s['roll'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s['name'] as String,
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor),
                              ),
                              Text(
                                'Blood: ${s['blood']} • Guardian: ${s['parentPhone']}',
                                style: TextStyle(fontSize: 11, color: subColor),
                              ),
                            ],
                          ),
                        ),
                        // Segmented attendance status buttons
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Present', label: Text('P', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'Late', label: Text('L', style: TextStyle(fontSize: 11))),
                            ButtonSegment(value: 'Absent', label: Text('A', style: TextStyle(fontSize: 11))),
                          ],
                          selected: {currentStatus},
                          onSelectionChanged: (set) {
                            setState(() {
                              _studentAttendanceStatus[sid] = set.first;
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: () => _submitSectionAttendance(sectionStr),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                  label: Text('Save & Submit $sectionStr Morning Attendance'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Class Teacher Administrative Actions
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Teacher Administration Desk',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Term report card compilation studio launched.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.assessment_outlined, size: 16),
                    label: const Text('Compile Section Report Cards'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('SMS broadcast composer opened for section parents.'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.sms_outlined, size: 16),
                    label: const Text('Broadcast Section Circular to Parents'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // 2. SUBJECT TEACHER VIEW
  // -------------------------------------------------------------------------
  Widget _buildSubjectTeacherView(
    StaffMemberModel? staff,
    Color cardBg,
    Color borderColor,
    Color textColor,
    Color subColor,
    bool isMobile,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Homework Dispatch Studio
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.assignment, color: AppColors.primary, size: 22),
                  const SizedBox(width: 10),
                  Text(
                    'Homework & Coursework Dispatch Studio',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedClassForHw,
                decoration: const InputDecoration(labelText: 'Target Section', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'Class 10-A', child: Text('Class 10-A (Mathematics)')),
                  DropdownMenuItem(value: 'Class 12-A', child: Text('Class 12-A (Advanced Math)')),
                  DropdownMenuItem(value: 'Class 9-B', child: Text('Class 9-B (Mathematics)')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedClassForHw = val);
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hwTitleCtrl,
                decoration: const InputDecoration(labelText: 'Assignment Title', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hwInstructionsCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Homework Instructions & Syllabus Reference', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _isDispatchingHw ? null : _dispatchHomework,
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isDispatchingHw ? 'Publishing Assignment...' : 'Publish & Notify Enrolled Students'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Marks Entry Table
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mid-Term Assessment Marks Entry (Class 10-A Mathematics)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  const Text('Max Score: 50', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.secondary)),
                ],
              ),
              const SizedBox(height: 14),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _sectionStudents.length,
                separatorBuilder: (_, _) => Divider(color: borderColor.withValues(alpha: 0.5)),
                itemBuilder: (context, index) {
                  final s = _sectionStudents[index];
                  final sid = s['id'] as String;
                  final ctrl = _marksControllers[sid]!;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Text(s['roll'] as String, style: TextStyle(fontWeight: FontWeight.bold, color: subColor)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(s['name'] as String, style: TextStyle(fontWeight: FontWeight.w600, color: textColor)),
                        ),
                        SizedBox(
                          width: 80,
                          child: TextFormField(
                            controller: ctrl,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text('/ 50', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Test marks successfully committed to gradebook!'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.save_outlined, size: 16),
                  label: const Text('Save Marks to Gradebook'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
