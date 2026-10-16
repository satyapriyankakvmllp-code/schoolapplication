class DailyLessonModel {
  final String id;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String teacherId;
  final String periodLabel;
  final DateTime date;
  final String title;
  final String notes;
  final String homework;
  final String status;

  const DailyLessonModel({
    required this.id,
    required this.classId,
    this.sectionId = '',
    required this.subjectId,
    required this.teacherId,
    this.periodLabel = '',
    required this.date,
    required this.title,
    this.notes = '',
    this.homework = '',
    this.status = 'Published',
  });

  factory DailyLessonModel.fromJson(Map<String, dynamic> json) => DailyLessonModel(
        id: json['id'] as String? ?? '',
        classId: json['class_id'] as String? ?? '',
        sectionId: json['section_id'] as String? ?? '',
        subjectId: json['subject_id'] as String? ?? '',
        teacherId: json['teacher_id'] as String? ?? '',
        periodLabel: json['period_label'] as String? ?? '',
        date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
        title: json['title'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        homework: json['homework'] as String? ?? '',
        status: json['status'] as String? ?? 'Published',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'section_id': sectionId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'period_label': periodLabel,
        'date': date.toIso8601String().substring(0, 10),
        'title': title,
        'notes': notes,
        'homework': homework,
        'status': status,
      };

  DailyLessonModel copyWith({
    String? classId,
    String? sectionId,
    String? subjectId,
    String? teacherId,
    String? periodLabel,
    DateTime? date,
    String? title,
    String? notes,
    String? homework,
    String? status,
  }) =>
      DailyLessonModel(
        id: id,
        classId: classId ?? this.classId,
        sectionId: sectionId ?? this.sectionId,
        subjectId: subjectId ?? this.subjectId,
        teacherId: teacherId ?? this.teacherId,
        periodLabel: periodLabel ?? this.periodLabel,
        date: date ?? this.date,
        title: title ?? this.title,
        notes: notes ?? this.notes,
        homework: homework ?? this.homework,
        status: status ?? this.status,
      );
}

