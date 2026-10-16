class ClassSubjectAssignment {
  final String grade;
  final String section;
  final String subject;
  final bool isClassTeacher;
  final int periodsPerWeek;

  const ClassSubjectAssignment({
    required this.grade,
    required this.section,
    required this.subject,
    this.isClassTeacher = false,
    this.periodsPerWeek = 5,
  });

  String get displayName => '$grade-$section • $subject';

  ClassSubjectAssignment copyWith({
    String? grade,
    String? section,
    String? subject,
    bool? isClassTeacher,
    int? periodsPerWeek,
  }) {
    return ClassSubjectAssignment(
      grade: grade ?? this.grade,
      section: section ?? this.section,
      subject: subject ?? this.subject,
      isClassTeacher: isClassTeacher ?? this.isClassTeacher,
      periodsPerWeek: periodsPerWeek ?? this.periodsPerWeek,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'grade': grade,
      'section': section,
      'subject': subject,
      'isClassTeacher': isClassTeacher,
      'periodsPerWeek': periodsPerWeek,
    };
  }

  factory ClassSubjectAssignment.fromMap(Map<String, dynamic> map) {
    return ClassSubjectAssignment(
      grade: (map['grade'] ?? '').toString(),
      section: (map['section'] ?? '').toString(),
      subject: (map['subject'] ?? '').toString(),
      isClassTeacher: map['isClassTeacher'] == true,
      periodsPerWeek: (map['periodsPerWeek'] as num?)?.toInt() ?? 5,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClassSubjectAssignment &&
          runtimeType == other.runtimeType &&
          grade == other.grade &&
          section == other.section &&
          subject == other.subject &&
          isClassTeacher == other.isClassTeacher &&
          periodsPerWeek == other.periodsPerWeek;

  @override
  int get hashCode =>
      grade.hashCode ^
      section.hashCode ^
      subject.hashCode ^
      isClassTeacher.hashCode ^
      periodsPerWeek.hashCode;
}
