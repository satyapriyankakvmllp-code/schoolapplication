class CurriculumModel {
  final String id;
  final String classId;
  final String subjectId;
  final String title;
  final String description;
  final List<String> topics;
  final int completedTopics;

  const CurriculumModel({
    required this.id,
    required this.classId,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.topics,
    this.completedTopics = 0,
  });

  double get progress => topics.isEmpty ? 0 : completedTopics / topics.length;

  factory CurriculumModel.fromJson(Map<String, dynamic> json) => CurriculumModel(
        id: json['id'] as String,
        classId: json['class_id'] as String? ?? '',
        subjectId: json['subject_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        topics: (json['topics'] as List<dynamic>? ?? const []).map((e) => e.toString()).toList(),
        completedTopics: (json['completed_topics'] as num?)?.toInt() ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        'subject_id': subjectId,
        'title': title,
        'description': description,
        'topics': topics,
        'completed_topics': completedTopics,
      };

  CurriculumModel copyWith({
    String? title,
    String? description,
    List<String>? topics,
    int? completedTopics,
  }) {
    final nextTopics = topics ?? this.topics;
    final nextDone = (completedTopics ?? this.completedTopics).clamp(0, nextTopics.length);
    return CurriculumModel(
      id: id,
      classId: classId,
      subjectId: subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      topics: nextTopics,
      completedTopics: nextDone,
    );
  }
}
