/// A teacher placed on a class (optionally a section) for a subject in a room.
/// `teacherId` is a Staff Directory id - no teacher details are duplicated here.
class ClassTeacherAssignmentModel {
  final String id;
  final String classId;
  final String? sectionId;
  final String? subjectId;
  final String teacherId;
  final String? classroomId;

  const ClassTeacherAssignmentModel({
    required this.id,
    required this.classId,
    this.sectionId,
    this.subjectId,
    required this.teacherId,
    this.classroomId,
  });

  factory ClassTeacherAssignmentModel.fromJson(Map<String, dynamic> json) => ClassTeacherAssignmentModel(
        id: json['id'] as String? ?? '',
        classId: json['class_id'] as String? ?? '',
        sectionId: json['section_id'] as String?,
        subjectId: json['subject_id'] as String?,
        teacherId: json['teacher_id'] as String? ?? '',
        classroomId: json['classroom_id'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'section_id': sectionId,
        'subject_id': subjectId,
        'teacher_id': teacherId,
        'classroom_id': classroomId,
      };
}
