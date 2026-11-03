// Domain models for Screens 3-8 (Hall Tickets, Attendance, Marks, Review, Results, Report Cards).

class StudentRef {
  final String id;
  final String name;
  final String admissionNumber;
  final String rollNumber;
  final String sectionId;
  final String classId;
  final String? photoUrl;

  const StudentRef({
    required this.id,
    required this.name,
    required this.admissionNumber,
    required this.rollNumber,
    required this.sectionId,
    this.classId = '',
    this.photoUrl,
  });
}

class HallTicket {
  final String id;
  final String examScheduleId;
  final String studentId;
  final String number;
  final String token;
  final String issueDate;
  final String status; // ISSUED | REVOKED
  final String? seatNumber;

  const HallTicket({
    required this.id,
    required this.examScheduleId,
    required this.studentId,
    required this.number,
    required this.token,
    required this.issueDate,
    required this.status,
    this.seatNumber,
  });

  factory HallTicket.fromJson(Map<String, dynamic> j) => HallTicket(
        id: '${j['id']}',
        examScheduleId: '${j['exam_schedule_id']}',
        studentId: '${j['student_id']}',
        number: '${j['hall_ticket_number'] ?? j['number']}',
        token: '${j['barcode_or_qr_token'] ?? j['token'] ?? ''}',
        issueDate: '${j['issue_date'] ?? ''}',
        status: '${j['status'] ?? 'ISSUED'}',
        seatNumber: j['seat_number']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_schedule_id': examScheduleId,
        'student_id': studentId,
        'hall_ticket_number': number,
        'barcode_or_qr_token': token,
        'issue_date': issueDate,
        'status': status,
        if (seatNumber != null) 'seat_number': seatNumber,
      };

  HallTicket copyWith({
    String? status,
    String? seatNumber,
  }) {
    return HallTicket(
      id: id,
      examScheduleId: examScheduleId,
      studentId: studentId,
      number: number,
      token: token,
      issueDate: issueDate,
      status: status ?? this.status,
      seatNumber: seatNumber ?? this.seatNumber,
    );
  }
}

class AttendanceRecord {
  final String id;
  final String examPaperId;
  final String studentId;
  final String status; // PRESENT | ABSENT | MALPRACTICE
  final String? markedBy;
  final String? markedAt;
  final String? remarks;

  const AttendanceRecord({
    required this.id,
    required this.examPaperId,
    required this.studentId,
    required this.status,
    this.markedBy,
    this.markedAt,
    this.remarks,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> j) => AttendanceRecord(
        id: '${j['id']}',
        examPaperId: '${j['exam_paper_id'] ?? j['exam_timetable_id']}',
        studentId: '${j['student_id']}',
        status: '${j['status'] ?? 'PRESENT'}',
        markedBy: j['marked_by_teacher_id']?.toString(),
        markedAt: j['marked_at']?.toString(),
        remarks: j['remarks']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_paper_id': examPaperId,
        'student_id': studentId,
        'status': status,
        'marked_by_teacher_id': markedBy,
        'marked_at': markedAt,
        'remarks': remarks,
      };
}

/// Marks statuses: DRAFT -> SUBMITTED -> UNDER_REVIEW -> APPROVED / REJECTED
class StudentMark {
  final String id;
  final String examPaperId;
  final String studentId;
  final String status; // DRAFT | SUBMITTED | UNDER_REVIEW | APPROVED | REJECTED
  final double? marksObtained;
  final String? remarks;
  final String? rejectionReason;
  final String? submittedAt;
  final String? enteredBy;
  final String? reviewerName;
  final String? reviewedBy;
  final String? reviewedAt;

  const StudentMark({
    required this.id,
    required this.examPaperId,
    required this.studentId,
    required this.status,
    this.marksObtained,
    this.remarks,
    this.rejectionReason,
    this.submittedAt,
    this.enteredBy,
    this.reviewerName,
    this.reviewedBy,
    this.reviewedAt,
  });

  bool get isLocked => status == 'SUBMITTED' || status == 'UNDER_REVIEW' || status == 'APPROVED';
  bool get isApproved => status == 'APPROVED';
  bool get isEditable => status == 'DRAFT' || status == 'REJECTED';

  factory StudentMark.fromJson(Map<String, dynamic> j) => StudentMark(
        id: '${j['id']}',
        examPaperId: '${j['exam_paper_id'] ?? j['exam_timetable_id']}',
        studentId: '${j['student_id']}',
        status: '${j['status'] ?? 'DRAFT'}'.toUpperCase(),
        marksObtained: (j['marks_obtained'] as num?)?.toDouble(),
        remarks: j['remarks']?.toString(),
        rejectionReason: j['rejection_reason']?.toString(),
        submittedAt: j['submitted_at']?.toString(),
        enteredBy: j['entered_by_teacher_id']?.toString(),
        reviewerName: j['reviewer_name']?.toString(),
        reviewedBy: j['reviewed_by']?.toString(),
        reviewedAt: j['reviewed_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_paper_id': examPaperId,
        'student_id': studentId,
        'marks_obtained': marksObtained,
        'status': status,
        'submitted_at': submittedAt,
        'entered_by_teacher_id': enteredBy,
        if (reviewerName != null) 'reviewer_name': reviewerName,
        'reviewed_by': reviewedBy,
        'reviewed_at': reviewedAt,
        'remarks': remarks,
        if (rejectionReason != null) 'rejection_reason': rejectionReason,
      };

  StudentMark copyWith({
    String? status,
    double? marksObtained,
    String? remarks,
    String? rejectionReason,
    String? submittedAt,
    String? enteredBy,
    String? reviewerName,
    String? reviewedBy,
    String? reviewedAt,
  }) {
    return StudentMark(
      id: id,
      examPaperId: examPaperId,
      studentId: studentId,
      status: status ?? this.status,
      marksObtained: marksObtained ?? this.marksObtained,
      remarks: remarks ?? this.remarks,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      submittedAt: submittedAt ?? this.submittedAt,
      enteredBy: enteredBy ?? this.enteredBy,
      reviewerName: reviewerName ?? this.reviewerName,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }
}

/// Report card status: DRAFT -> PENDING_APPROVAL -> APPROVED -> PUBLISHED
class ReportCard {
  final String id;
  final String examScheduleId;
  final String studentId;
  final String classSectionId;
  final String grade;
  final String status;
  final double totalMarks;
  final double totalMaxMarks;
  final double percentage;
  final double gpa;
  final String performance;
  final int rank;
  final bool passed;
  final String? inchargeRemarks;
  final String? principalRemarks;
  final String? approvedBy;
  final String? approvedAt;
  final String? publishedAt;
  final String? generatedAt;

  const ReportCard({
    required this.id,
    required this.examScheduleId,
    required this.studentId,
    required this.classSectionId,
    required this.grade,
    required this.status,
    required this.totalMarks,
    required this.totalMaxMarks,
    required this.percentage,
    this.gpa = 0.0,
    this.performance = 'Good',
    required this.rank,
    required this.passed,
    this.inchargeRemarks,
    this.principalRemarks,
    this.approvedBy,
    this.approvedAt,
    this.publishedAt,
    this.generatedAt,
  });

  bool get isPublished => status == 'PUBLISHED';
  bool get isApproved => status == 'APPROVED' || status == 'PUBLISHED';
  String get finalResult => passed ? 'PASS' : 'FAIL';
  String get overallGrade => grade;
  double get maxMarks => totalMaxMarks;

  factory ReportCard.fromJson(Map<String, dynamic> j) => ReportCard(
        id: '${j['id']}',
        examScheduleId: '${j['exam_schedule_id']}',
        studentId: '${j['student_id']}',
        classSectionId: '${j['class_section_id']}',
        grade: '${j['grade']}',
        status: '${j['status'] ?? 'PENDING_APPROVAL'}',
        totalMarks: (j['total_marks'] as num?)?.toDouble() ?? 0,
        totalMaxMarks: (j['total_max_marks'] as num?)?.toDouble() ?? 0,
        percentage: (j['percentage'] as num?)?.toDouble() ?? 0,
        gpa: (j['gpa'] as num?)?.toDouble() ?? 0,
        performance: j['performance']?.toString() ?? 'Good',
        rank: (j['class_rank'] as num?)?.toInt() ?? 0,
        passed: j['passed'] == true,
        inchargeRemarks: j['class_incharge_remarks']?.toString(),
        principalRemarks: j['principal_remarks']?.toString(),
        approvedBy: j['approved_by_id']?.toString(),
        approvedAt: j['approved_at']?.toString(),
        publishedAt: j['published_at']?.toString(),
        generatedAt: j['generated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_schedule_id': examScheduleId,
        'student_id': studentId,
        'class_section_id': classSectionId,
        'total_marks': totalMarks,
        'total_max_marks': totalMaxMarks,
        'percentage': percentage,
        'gpa': gpa,
        'performance': performance,
        'grade': grade,
        'class_rank': rank,
        'passed': passed,
        'status': status,
        'class_incharge_remarks': inchargeRemarks,
        if (principalRemarks != null) 'principal_remarks': principalRemarks,
        'generated_at': generatedAt,
        'approved_by_id': approvedBy,
        'approved_at': approvedAt,
        'is_published': isPublished,
        'published_at': publishedAt,
      };
}

class SyllabusChapter {
  final String id;
  final String classId;
  final String? classSectionId;
  final String subjectId;
  final int chapterNumber;
  final String title;
  final String description;
  final List<String> topics;
  final int weightage;
  final String status; // Completed | In Progress | Planned
  final String? createdAt;
  final String? updatedAt;

  const SyllabusChapter({
    required this.id,
    required this.classId,
    this.classSectionId,
    required this.subjectId,
    this.chapterNumber = 1,
    required this.title,
    this.description = '',
    this.topics = const [],
    this.weightage = 0,
    this.status = 'Planned',
    this.createdAt,
    this.updatedAt,
  });

  factory SyllabusChapter.fromJson(Map<String, dynamic> j) => SyllabusChapter(
        id: (j['id'] ?? '').toString(),
        classId: (j['class_id'] ?? '').toString(),
        classSectionId: j['class_section_id']?.toString() ?? j['section_id']?.toString(),
        subjectId: (j['subject_id'] ?? '').toString(),
        chapterNumber: (j['chapter_number'] as num?)?.toInt() ?? 1,
        title: (j['title'] ?? '').toString(),
        description: (j['description'] ?? '').toString(),
        topics: (j['topics'] as List<dynamic>? ?? []).map((t) => t.toString()).toList(),
        weightage: (j['weightage'] as num?)?.toInt() ?? 0,
        status: (j['status'] ?? 'Planned').toString(),
        createdAt: j['created_at']?.toString(),
        updatedAt: j['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_id': classId,
        if (classSectionId != null && classSectionId!.isNotEmpty) 'class_section_id': classSectionId,
        'subject_id': subjectId,
        'chapter_number': chapterNumber,
        'title': title,
        'description': description,
        'topics': topics,
        'weightage': weightage,
        'status': status,
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  SyllabusChapter copyWith({
    String? id,
    String? classId,
    String? classSectionId,
    String? subjectId,
    int? chapterNumber,
    String? title,
    String? description,
    List<String>? topics,
    int? weightage,
    String? status,
  }) {
    return SyllabusChapter(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      classSectionId: classSectionId ?? this.classSectionId,
      subjectId: subjectId ?? this.subjectId,
      chapterNumber: chapterNumber ?? this.chapterNumber,
      title: title ?? this.title,
      description: description ?? this.description,
      topics: topics ?? this.topics,
      weightage: weightage ?? this.weightage,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}

class PatternSection {
  final String name; // e.g. "Section A: Objective & MCQs"
  final String type; // MCQ, Short Answer, Long Answer, Case Study, Practical
  final int questionCount;
  final double marksPerQuestion;

  const PatternSection({
    required this.name,
    required this.type,
    required this.questionCount,
    required this.marksPerQuestion,
  });

  double get totalMarks => questionCount * marksPerQuestion;

  factory PatternSection.fromJson(Map<String, dynamic> j) => PatternSection(
        name: (j['name'] ?? j['section_name'] ?? 'Section').toString(),
        type: (j['type'] ?? 'Short Answer').toString(),
        questionCount: (j['question_count'] as num?)?.toInt() ?? 1,
        marksPerQuestion: (j['marks_per_question'] as num?)?.toDouble() ?? 1.0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type,
        'question_count': questionCount,
        'marks_per_question': marksPerQuestion,
      };

  PatternSection copyWith({
    String? name,
    String? type,
    int? questionCount,
    double? marksPerQuestion,
  }) {
    return PatternSection(
      name: name ?? this.name,
      type: type ?? this.type,
      questionCount: questionCount ?? this.questionCount,
      marksPerQuestion: marksPerQuestion ?? this.marksPerQuestion,
    );
  }
}

class ExamPattern {
  final String id;
  final String examScheduleId;
  final String? classId;
  final String? subjectId;
  final String title;
  final double totalMarks;
  final double internalAssessmentMarks;
  final int durationMinutes;
  final String status;
  final String instructions;
  final List<PatternSection> sections;
  final String? createdAt;
  final String? updatedAt;

  const ExamPattern({
    required this.id,
    required this.examScheduleId,
    this.classId,
    this.subjectId,
    required this.title,
    this.totalMarks = 100.0,
    this.internalAssessmentMarks = 0.0,
    this.durationMinutes = 180,
    this.status = 'ACTIVE',
    this.instructions = '',
    this.sections = const [],
    this.createdAt,
    this.updatedAt,
  });

  double get sectionsTotalMarks => sections.fold(0.0, (sum, s) => sum + s.totalMarks);
  double get grandTotalMarks => sectionsTotalMarks + internalAssessmentMarks;
  bool get isValidTotal => (grandTotalMarks - totalMarks).abs() < 0.01;

  factory ExamPattern.fromJson(Map<String, dynamic> j) => ExamPattern(
        id: (j['id'] ?? '').toString(),
        examScheduleId: (j['exam_schedule_id'] ?? '').toString(),
        classId: j['class_id']?.toString(),
        subjectId: j['subject_id']?.toString(),
        title: (j['title'] ?? 'Exam Pattern').toString(),
        totalMarks: (j['total_marks'] as num?)?.toDouble() ?? 100.0,
        internalAssessmentMarks: (j['internal_assessment_marks'] as num?)?.toDouble() ?? 0.0,
        durationMinutes: (j['duration_minutes'] as num?)?.toInt() ?? 180,
        status: (j['status'] ?? 'ACTIVE').toString(),
        instructions: (j['instructions'] ?? '').toString(),
        sections: (j['sections'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(PatternSection.fromJson)
            .toList(),
        createdAt: j['created_at']?.toString(),
        updatedAt: j['updated_at']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_schedule_id': examScheduleId,
        if (classId != null && classId!.isNotEmpty) 'class_id': classId,
        if (subjectId != null && subjectId!.isNotEmpty) 'subject_id': subjectId,
        'title': title,
        'total_marks': totalMarks,
        'internal_assessment_marks': internalAssessmentMarks,
        'duration_minutes': durationMinutes,
        'status': status,
        'instructions': instructions,
        'sections': sections.map((s) => s.toJson()).toList(),
        if (createdAt != null) 'created_at': createdAt,
        if (updatedAt != null) 'updated_at': updatedAt,
      };

  ExamPattern copyWith({
    String? id,
    String? examScheduleId,
    String? classId,
    String? subjectId,
    String? title,
    double? totalMarks,
    double? internalAssessmentMarks,
    int? durationMinutes,
    String? status,
    String? instructions,
    List<PatternSection>? sections,
  }) {
    return ExamPattern(
      id: id ?? this.id,
      examScheduleId: examScheduleId ?? this.examScheduleId,
      classId: classId ?? this.classId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      totalMarks: totalMarks ?? this.totalMarks,
      internalAssessmentMarks: internalAssessmentMarks ?? this.internalAssessmentMarks,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
      sections: sections ?? this.sections,
      createdAt: createdAt,
      updatedAt: DateTime.now().toIso8601String(),
    );
  }
}

class UploadedQuestionPaper {
  final String id;
  final String examScheduleId;
  final String classId;
  final String classSectionId;
  final String subjectId;
  final String title;
  final String uploadedByTeacherId;
  final String uploadedByTeacherName;
  final String fileName;
  final String fileType; // PDF Document | Image Document
  final String fileUrl;
  final String status; // UPLOADED | UNDER_REVIEW | APPROVED
  final String instructions;
  final String uploadedAt;
  final String? reviewRemarks;

  const UploadedQuestionPaper({
    required this.id,
    required this.examScheduleId,
    required this.classId,
    required this.classSectionId,
    required this.subjectId,
    required this.title,
    required this.uploadedByTeacherId,
    required this.uploadedByTeacherName,
    required this.fileName,
    this.fileType = 'PDF Document',
    this.fileUrl = '',
    this.status = 'UPLOADED',
    this.instructions = '',
    required this.uploadedAt,
    this.reviewRemarks,
  });

  factory UploadedQuestionPaper.fromJson(Map<String, dynamic> j) => UploadedQuestionPaper(
        id: (j['id'] ?? '').toString(),
        examScheduleId: (j['exam_schedule_id'] ?? '').toString(),
        classId: (j['class_id'] ?? '').toString(),
        classSectionId: (j['class_section_id'] ?? '').toString(),
        subjectId: (j['subject_id'] ?? '').toString(),
        title: (j['title'] ?? '').toString(),
        uploadedByTeacherId: (j['uploaded_by_teacher_id'] ?? '').toString(),
        uploadedByTeacherName: (j['uploaded_by_teacher_name'] ?? 'Faculty Teacher').toString(),
        fileName: (j['file_name'] ?? 'Question_Paper.pdf').toString(),
        fileType: (j['file_type'] ?? 'PDF Document').toString(),
        fileUrl: (j['file_url'] ?? '').toString(),
        status: (j['status'] ?? 'UPLOADED').toString(),
        instructions: (j['instructions'] ?? '').toString(),
        uploadedAt: (j['uploaded_at'] ?? '').toString(),
        reviewRemarks: j['review_remarks']?.toString(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'exam_schedule_id': examScheduleId,
        'class_id': classId,
        'class_section_id': classSectionId,
        'subject_id': subjectId,
        'title': title,
        'uploaded_by_teacher_id': uploadedByTeacherId,
        'uploaded_by_teacher_name': uploadedByTeacherName,
        'file_name': fileName,
        'file_type': fileType,
        'file_url': fileUrl,
        'status': status,
        'instructions': instructions,
        'uploaded_at': uploadedAt,
        if (reviewRemarks != null) 'review_remarks': reviewRemarks,
      };

  UploadedQuestionPaper copyWith({
    String? status,
    String? reviewRemarks,
    String? instructions,
  }) {
    return UploadedQuestionPaper(
      id: id,
      examScheduleId: examScheduleId,
      classId: classId,
      classSectionId: classSectionId,
      subjectId: subjectId,
      title: title,
      uploadedByTeacherId: uploadedByTeacherId,
      uploadedByTeacherName: uploadedByTeacherName,
      fileName: fileName,
      fileType: fileType,
      fileUrl: fileUrl,
      status: status ?? this.status,
      instructions: instructions ?? this.instructions,
      uploadedAt: uploadedAt,
      reviewRemarks: reviewRemarks ?? this.reviewRemarks,
    );
  }
}
