class TeacherWorkModel {
  final String id;
  final String title;
  final String classId;
  final String? sectionId;
  final String subjectId;
  final String teacherId;
  final String workType; // 'Homework', 'Project', 'Worksheet', 'Lab Report', 'Reading'
  final DateTime dueDate;
  final String status; // 'Assigned', 'In Progress', 'Submitted', 'Reviewed'
  final String instructions;
  final String submissionGuidelines;
  final String academicYear;

  const TeacherWorkModel({
    required this.id,
    required this.title,
    required this.classId,
    this.sectionId,
    required this.subjectId,
    required this.teacherId,
    this.workType = 'Homework',
    required this.dueDate,
    this.status = 'Assigned',
    this.instructions = '',
    this.submissionGuidelines = '',
    this.academicYear = '2026-2027',
  });

  factory TeacherWorkModel.fromJson(Map<String, dynamic> json) {
    return TeacherWorkModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      sectionId: json['section_id'] as String?,
      subjectId: json['subject_id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      workType: json['work_type'] as String? ?? 'Homework',
      dueDate: json['due_date'] != null
          ? DateTime.tryParse(json['due_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? 'Assigned',
      instructions: json['instructions'] as String? ?? '',
      submissionGuidelines: json['submission_guidelines'] as String? ?? '',
      academicYear: json['academic_year'] as String? ?? '2026-2027',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'class_id': classId,
      if (sectionId != null) 'section_id': sectionId,
      'subject_id': subjectId,
      'teacher_id': teacherId,
      'work_type': workType,
      'due_date': dueDate.toIso8601String().split('T').first,
      'status': status,
      'instructions': instructions,
      'submission_guidelines': submissionGuidelines,
      'academic_year': academicYear,
    };
  }

  TeacherWorkModel copyWith({
    String? id,
    String? title,
    String? classId,
    String? sectionId,
    String? subjectId,
    String? teacherId,
    String? workType,
    DateTime? dueDate,
    String? status,
    String? instructions,
    String? submissionGuidelines,
    String? academicYear,
  }) {
    return TeacherWorkModel(
      id: id ?? this.id,
      title: title ?? this.title,
      classId: classId ?? this.classId,
      sectionId: sectionId ?? this.sectionId,
      subjectId: subjectId ?? this.subjectId,
      teacherId: teacherId ?? this.teacherId,
      workType: workType ?? this.workType,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
      submissionGuidelines: submissionGuidelines ?? this.submissionGuidelines,
      academicYear: academicYear ?? this.academicYear,
    );
  }
}
