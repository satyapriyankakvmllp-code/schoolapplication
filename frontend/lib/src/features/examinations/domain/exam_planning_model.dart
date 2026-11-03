// Phase 2 models: syllabus pattern, question bank, question papers.

double _n(dynamic v, [double f = 0]) =>
    (v is num) ? v.toDouble() : (double.tryParse(v?.toString() ?? '') ?? f);
int _i(dynamic v, [int f = 0]) =>
    (v is num) ? v.toInt() : (int.tryParse(v?.toString() ?? '') ?? f);
String _s(dynamic v, [String f = '']) {
  final s = v?.toString();
  return (s == null || s == 'null') ? f : s;
}

const List<String> kQuestionTypes = [
  'MCQ',
  'TRUE_FALSE',
  'FILL_BLANK',
  'SHORT',
  'LONG',
  'PROBLEM',
];

String questionTypeLabel(String t) {
  switch (t) {
    case 'MCQ':
      return 'MCQ';
    case 'TRUE_FALSE':
      return 'True / False';
    case 'FILL_BLANK':
      return 'Fill in the blank';
    case 'SHORT':
      return 'Short answer';
    case 'LONG':
      return 'Long answer';
    case 'PROBLEM':
      return 'Problem solving';
    default:
      return t;
  }
}

const List<String> kDifficultyLevels = ['EASY', 'MEDIUM', 'HARD'];

// ---------------------------------------------------------------------------
// PATTERN
// ---------------------------------------------------------------------------
class PatternSection {
  final String id;
  final String patternId;
  final String sectionName;
  final String questionType;
  final int noOfQuestions;
  final double marksEach;

  /// How many questions the student attempts (0 = all of them).
  final int choiceCount;

  const PatternSection({
    required this.id,
    required this.patternId,
    required this.sectionName,
    required this.questionType,
    required this.noOfQuestions,
    required this.marksEach,
    this.choiceCount = 0,
  });

  int get attemptCount =>
      (choiceCount > 0 && choiceCount < noOfQuestions) ? choiceCount : noOfQuestions;
  double get totalMarks => attemptCount * marksEach;

  factory PatternSection.fromJson(Map<String, dynamic> j) => PatternSection(
        id: _s(j['pattern_section_id'] ?? j['id']),
        patternId: _s(j['pattern_id']),
        sectionName: _s(j['section_name']),
        questionType: _s(j['question_type'], 'MCQ'),
        noOfQuestions: _i(j['no_of_questions']),
        marksEach: _n(j['marks_each'], 1),
        choiceCount: _i(j['choice_count']),
      );

  Map<String, dynamic> toJson() => {
        'pattern_section_id': id,
        'pattern_id': patternId,
        'section_name': sectionName,
        'question_type': questionType,
        'no_of_questions': noOfQuestions,
        'marks_each': marksEach,
        'choice_count': choiceCount,
      };
}

class PatternTopic {
  final String id;
  final String patternId;
  final String topicId; // curriculum chapter id
  final String topicTitle;
  final double weightagePercent;

  const PatternTopic({
    required this.id,
    required this.patternId,
    required this.topicId,
    required this.topicTitle,
    required this.weightagePercent,
  });

  factory PatternTopic.fromJson(Map<String, dynamic> j) => PatternTopic(
        id: _s(j['pattern_topic_id'] ?? j['id']),
        patternId: _s(j['pattern_id']),
        topicId: _s(j['topic_id']),
        topicTitle: _s(j['topic_title']),
        weightagePercent: _n(j['weightage_percent']),
      );

  Map<String, dynamic> toJson() => {
        'pattern_topic_id': id,
        'pattern_id': patternId,
        'topic_id': topicId,
        'topic_title': topicTitle,
        'weightage_percent': weightagePercent,
      };
}

class ExamPattern {
  final String id;
  final String examScheduleId;
  final String classSectionId;
  final String subjectId;
  final String patternName;
  final double maxMarks;
  final int examDuration; // minutes
  final String syllabusDetails;
  final String status; // DRAFT | ACTIVE
  final String createdAt;
  final String updatedAt;
  final List<PatternSection> sections;
  final List<PatternTopic> topics;

  const ExamPattern({
    required this.id,
    required this.examScheduleId,
    required this.classSectionId,
    required this.subjectId,
    required this.patternName,
    required this.maxMarks,
    required this.examDuration,
    this.syllabusDetails = '',
    this.status = 'DRAFT',
    this.createdAt = '',
    this.updatedAt = '',
    this.sections = const [],
    this.topics = const [],
  });

  double get sectionsTotal => sections.fold<double>(0, (a, s) => a + s.totalMarks);
  double get weightageTotal => topics.fold<double>(0, (a, t) => a + t.weightagePercent);
  bool get isActive => status == 'ACTIVE';

  /// Problems that stop the pattern from being activated.
  List<String> activationProblems() {
    final out = <String>[];
    if (sections.isEmpty) out.add('Add at least one section.');
    if ((sectionsTotal - maxMarks).abs() > 0.001) {
      out.add(
        'Sections add up to ${_fmt(sectionsTotal)} marks but the paper is for ${_fmt(maxMarks)}.',
      );
    }
    if (topics.isNotEmpty && (weightageTotal - 100).abs() > 0.01) {
      out.add('Chapter weightage adds up to ${_fmt(weightageTotal)}%, it must be 100%.');
    }
    return out;
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  factory ExamPattern.fromJson(
    Map<String, dynamic> j, {
    List<PatternSection> sections = const [],
    List<PatternTopic> topics = const [],
  }) =>
      ExamPattern(
        id: _s(j['pattern_id'] ?? j['id']),
        examScheduleId: _s(j['exam_schedule_id']),
        classSectionId: _s(j['class_section_id']),
        subjectId: _s(j['subject_id']),
        patternName: _s(j['pattern_name']),
        maxMarks: _n(j['max_marks'], 100),
        examDuration: _i(j['exam_duration'], 120),
        syllabusDetails: _s(j['syllabus_details']),
        status: _s(j['status'], 'DRAFT').toUpperCase(),
        createdAt: _s(j['created_at']),
        updatedAt: _s(j['updated_at']),
        sections: sections,
        topics: topics,
      );

  Map<String, dynamic> toJson() => {
        'pattern_id': id,
        'exam_schedule_id': examScheduleId,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
        'pattern_name': patternName,
        'max_marks': maxMarks,
        'exam_duration': examDuration,
        'syllabus_details': syllabusDetails,
        'status': status,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

// ---------------------------------------------------------------------------
// QUESTION BANK
// ---------------------------------------------------------------------------
class QuestionOption {
  final String id;
  final String questionId;
  final String text;
  final bool isCorrect;
  const QuestionOption({
    required this.id,
    required this.questionId,
    required this.text,
    this.isCorrect = false,
  });

  factory QuestionOption.fromJson(Map<String, dynamic> j) => QuestionOption(
        id: _s(j['option_id'] ?? j['id']),
        questionId: _s(j['question_id']),
        text: _s(j['option_text']),
        isCorrect: j['is_correct'] == true,
      );

  Map<String, dynamic> toJson() => {
        'option_id': id,
        'question_id': questionId,
        'option_text': text,
        'is_correct': isCorrect,
      };
}

class Question {
  final String id;
  final String subjectId;
  final String? topicId;
  final String text;
  final String type;
  final double marks;
  final String difficulty;
  final String answerKey;
  final String status; // DRAFT | APPROVED
  final String createdBy;
  final String createdAt;
  final String updatedAt;
  final List<QuestionOption> options;

  const Question({
    required this.id,
    required this.subjectId,
    this.topicId,
    required this.text,
    required this.type,
    required this.marks,
    this.difficulty = 'MEDIUM',
    this.answerKey = '',
    this.status = 'DRAFT',
    this.createdBy = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.options = const [],
  });

  bool get isApproved => status == 'APPROVED';

  factory Question.fromJson(
    Map<String, dynamic> j, {
    List<QuestionOption> options = const [],
  }) =>
      Question(
        id: _s(j['question_id'] ?? j['id']),
        subjectId: _s(j['subject_id']),
        topicId: (j['syllabus_topic_id'] ?? j['topic_id'])?.toString(),
        text: _s(j['question_text']),
        type: _s(j['question_type'], 'SHORT'),
        marks: _n(j['marks'], 1),
        difficulty: _s(j['difficulty_level'], 'MEDIUM').toUpperCase(),
        answerKey: _s(j['answer_key']),
        status: _s(j['status'], 'DRAFT').toUpperCase(),
        createdBy: _s(j['created_by_teacher_id']),
        createdAt: _s(j['created_at']),
        updatedAt: _s(j['updated_at']),
        options: options,
      );

  Map<String, dynamic> toJson() => {
        'question_id': id,
        'subject_id': subjectId,
        'syllabus_topic_id': topicId,
        'question_text': text,
        'question_type': type,
        'marks': marks,
        'difficulty_level': difficulty,
        'answer_key': answerKey,
        'status': status,
        'created_by_teacher_id': createdBy,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

// ---------------------------------------------------------------------------
// QUESTION PAPER
// ---------------------------------------------------------------------------
class QuestionPaperItem {
  final String id;
  final String questionPaperId;
  final String questionId;
  final String sectionName;
  final int questionNumber;
  final double marks;

  const QuestionPaperItem({
    required this.id,
    required this.questionPaperId,
    required this.questionId,
    required this.sectionName,
    required this.questionNumber,
    required this.marks,
  });

  factory QuestionPaperItem.fromJson(Map<String, dynamic> j) => QuestionPaperItem(
        id: _s(j['question_paper_item_id'] ?? j['id']),
        questionPaperId: _s(j['question_paper_id']),
        questionId: _s(j['question_id']),
        sectionName: _s(j['section_name']),
        questionNumber: _i(j['question_number']),
        marks: _n(j['marks'], 1),
      );

  Map<String, dynamic> toJson() => {
        'question_paper_item_id': id,
        'question_paper_id': questionPaperId,
        'question_id': questionId,
        'section_name': sectionName,
        'question_number': questionNumber,
        'marks': marks,
      };
}

class QuestionPaper {
  final String id;
  final String examPaperId;
  final String patternId;
  final int version;
  final String paperCode;
  final String status; // DRAFT | SUBMITTED | UNDER_REVIEW | CORRECTION_REQUIRED | APPROVED | LOCKED
  final String createdBy;
  final String approvedById;
  final String approvedAt;
  final String reviewComment;
  final String createdAt;
  final String updatedAt;
  final List<QuestionPaperItem> items;

  const QuestionPaper({
    required this.id,
    required this.examPaperId,
    required this.patternId,
    this.version = 1,
    this.paperCode = '',
    this.status = 'DRAFT',
    this.createdBy = '',
    this.approvedById = '',
    this.approvedAt = '',
    this.reviewComment = '',
    this.createdAt = '',
    this.updatedAt = '',
    this.items = const [],
  });

  bool get isLocked => status == 'LOCKED';

  factory QuestionPaper.fromJson(
    Map<String, dynamic> j, {
    List<QuestionPaperItem> items = const [],
  }) =>
      QuestionPaper(
        id: _s(j['question_paper_id'] ?? j['id']),
        examPaperId: _s(j['exam_paper_id']),
        patternId: _s(j['pattern_id']),
        version: _i(j['version'], 1),
        paperCode: _s(j['paper_code']),
        status: _s(j['status'], 'DRAFT').toUpperCase(),
        createdBy: _s(j['created_by_teacher_id']),
        approvedById: _s(j['approved_by_id']),
        approvedAt: _s(j['approved_at']),
        reviewComment: _s(j['review_comment']),
        createdAt: _s(j['created_at']),
        updatedAt: _s(j['updated_at']),
        items: items,
      );

  Map<String, dynamic> toJson() => {
        'question_paper_id': id,
        'exam_paper_id': examPaperId,
        'pattern_id': patternId,
        'version': version,
        'paper_code': paperCode,
        'status': status,
        'created_by_teacher_id': createdBy,
        'approved_by_id': approvedById,
        'approved_at': approvedAt,
        'review_comment': reviewComment,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };
}

/// Result of checking a question paper against its pattern.
class PaperPatternCheck {
  final List<String> blockers; // stop submission
  final List<String> warnings; // informational
  final Map<String, int> selectedPerSection;
  final double totalMarks;
  const PaperPatternCheck({
    this.blockers = const [],
    this.warnings = const [],
    this.selectedPerSection = const {},
    this.totalMarks = 0,
  });
  bool get ok => blockers.isEmpty;
}
