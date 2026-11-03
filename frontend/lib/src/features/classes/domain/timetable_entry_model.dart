class TimetableEntryModel {
  final String id;
  final String classId;
  final String sectionId;
  final String subjectId;
  final String teacherId;
  final String? classroomId;
  final bool isBreak;
  final String? title;

  /// 1 = Monday ... 7 = Sunday (matches [DateTime.weekday]).
  final int dayOfWeek;
  final String startTime; // HH:mm
  final String endTime; // HH:mm
  final String? month;
  final String? subjectType;

  const TimetableEntryModel({
    required this.id,
    required this.classId,
    required this.sectionId,
    required this.subjectId,
    required this.teacherId,
    this.classroomId,
    this.isBreak = false,
    this.title,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.month,
    this.subjectType,
  });

  bool get isPractical => subjectType?.toLowerCase() == 'practical';

  factory TimetableEntryModel.fromJson(Map<String, dynamic> json) =>
      TimetableEntryModel(
        id: json['id'] as String? ?? '',
        classId: json['class_id'] as String? ?? '',
        sectionId: json['section_id'] as String? ?? '',
        subjectId: json['subject_id'] as String? ?? '',
        teacherId: json['teacher_id'] as String? ?? '',
        classroomId: json['classroom_id'] as String?,
        isBreak: json['is_break'] as bool? ?? false,
        title: json['title'] as String?,
        dayOfWeek: (json['day_of_week'] as num?)?.toInt() ?? 1,
        startTime: json['start_time'] as String? ?? '09:00',
        endTime: json['end_time'] as String? ?? '09:45',
        month: json['month'] as String?,
        subjectType: json['subject_type'] as String? ?? (json['subjectType'] as String?),
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'class_id': classId,
    'section_id': sectionId,
    'subject_id': subjectId,
    'teacher_id': teacherId,
    if (classroomId != null) 'classroom_id': classroomId,
    'is_break': isBreak,
    if (title != null) 'title': title,
    'day_of_week': dayOfWeek,
    'start_time': startTime,
    'end_time': endTime,
    if (month != null) 'month': month,
    if (subjectType != null) 'subject_type': subjectType,
  };

  TimetableEntryModel copyWith({
    String? subjectId,
    String? teacherId,
    String? classroomId,
    bool? isBreak,
    String? title,
    int? dayOfWeek,
    String? startTime,
    String? endTime,
    String? month,
    String? subjectType,
    bool clearClassroom = false,
  }) => TimetableEntryModel(
    id: id,
    classId: classId,
    sectionId: sectionId,
    subjectId: subjectId ?? this.subjectId,
    teacherId: teacherId ?? this.teacherId,
    classroomId: clearClassroom ? null : (classroomId ?? this.classroomId),
    isBreak: isBreak ?? this.isBreak,
    title: title ?? this.title,
    dayOfWeek: dayOfWeek ?? this.dayOfWeek,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    month: month ?? this.month,
    subjectType: subjectType ?? this.subjectType,
  );
}
