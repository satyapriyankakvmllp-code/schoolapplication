import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../utils/dynamic_data_client.dart';

// =============================================================================
// ENUMS & CONFIGURATION
// =============================================================================

enum InquirySource {
  walkIn,
  phone,
  website,
  referral;

  String get displayName {
    switch (this) {
      case InquirySource.walkIn:
        return 'Walk-In';
      case InquirySource.phone:
        return 'Phone Call';
      case InquirySource.website:
        return 'Website Lead';
      case InquirySource.referral:
        return 'Parent Referral';
    }
  }

  static InquirySource fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'phone':
        return InquirySource.phone;
      case 'website':
        return InquirySource.website;
      case 'referral':
        return InquirySource.referral;
      case 'walkin':
      default:
        return InquirySource.walkIn;
    }
  }
}

enum InquiryStatus {
  newLead,
  contacted,
  interviewScheduled,
  applicationStarted,
  converted,
  closed,
  dropped; // Backward compatibility alias

  String get displayName {
    switch (this) {
      case InquiryStatus.newLead:
        return 'New Inquiry';
      case InquiryStatus.contacted:
        return 'Contacted';
      case InquiryStatus.interviewScheduled:
        return 'Interview Booked';
      case InquiryStatus.applicationStarted:
        return 'Application Started';
      case InquiryStatus.converted:
        return 'Converted to Application';
      case InquiryStatus.closed:
      case InquiryStatus.dropped:
        return 'Closed / Archived';
    }
  }

  static InquiryStatus fromString(String? val) {
    switch (val) {
      case 'contacted':
        return InquiryStatus.contacted;
      case 'interviewScheduled':
        return InquiryStatus.interviewScheduled;
      case 'applicationStarted':
        return InquiryStatus.applicationStarted;
      case 'converted':
        return InquiryStatus.converted;
      case 'closed':
      case 'dropped':
        return InquiryStatus.closed;
      case 'newLead':
      default:
        return InquiryStatus.newLead;
    }
  }
}

// =============================================================================
// INQUIRY & FOLLOW-UP MODELS
// =============================================================================

class InquiryFollowUp {
  final String id;
  final DateTime timestamp;
  final String actionType;
  final String officerName;
  final String notes;
  final DateTime? reminderDate;

  const InquiryFollowUp({
    required this.id,
    required this.timestamp,
    required this.actionType,
    required this.officerName,
    required this.notes,
    this.reminderDate,
  });

  factory InquiryFollowUp.fromJson(Map<String, dynamic> json) {
    return InquiryFollowUp(
      id: json['id']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      actionType: json['action_type']?.toString() ?? 'Note',
      officerName: json['officer_name']?.toString() ?? 'Admissions Staff',
      notes: json['notes']?.toString() ?? '',
      reminderDate: json['reminder_date'] != null
          ? DateTime.tryParse(json['reminder_date'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'action_type': actionType,
      'officer_name': officerName,
      'notes': notes,
      'reminder_date': reminderDate?.toIso8601String(),
    };
  }
}

class FrontDeskInquiry {
  final String id;
  final String applicantName;
  final String gradeApplying;
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final String residentialArea;
  final InquirySource source;
  final InquiryStatus status;
  final String notes;
  final DateTime createdAt;
  final List<InquiryFollowUp> followUps;

  const FrontDeskInquiry({
    required this.id,
    required this.applicantName,
    required this.gradeApplying,
    required this.parentName,
    required this.parentPhone,
    required this.parentEmail,
    this.residentialArea = '',
    required this.source,
    required this.status,
    required this.notes,
    required this.createdAt,
    this.followUps = const [],
  });

  factory FrontDeskInquiry.fromJson(Map<String, dynamic> json) {
    return FrontDeskInquiry(
      id: json['id']?.toString() ?? '',
      applicantName: json['applicant_name']?.toString() ?? '',
      gradeApplying: json['grade_applying']?.toString() ?? '',
      parentName: json['parent_name']?.toString() ?? '',
      parentPhone: json['parent_phone']?.toString() ?? '',
      parentEmail: json['parent_email']?.toString() ?? '',
      residentialArea: json['residential_area']?.toString() ?? '',
      source: InquirySource.fromString(json['source']?.toString()),
      status: InquiryStatus.fromString(json['status']?.toString()),
      notes: json['notes']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      followUps: (json['follow_ups'] as List<dynamic>?)
              ?.map((item) => InquiryFollowUp.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicant_name': applicantName,
      'grade_applying': gradeApplying,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_email': parentEmail,
      'residential_area': residentialArea,
      'source': source.name,
      'status': status.name,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'follow_ups': followUps.map((fu) => fu.toJson()).toList(),
    };
  }

  FrontDeskInquiry copyWith({
    String? id,
    String? applicantName,
    String? gradeApplying,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    String? residentialArea,
    InquirySource? source,
    InquiryStatus? status,
    String? notes,
    DateTime? createdAt,
    List<InquiryFollowUp>? followUps,
  }) {
    return FrontDeskInquiry(
      id: id ?? this.id,
      applicantName: applicantName ?? this.applicantName,
      gradeApplying: gradeApplying ?? this.gradeApplying,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      residentialArea: residentialArea ?? this.residentialArea,
      source: source ?? this.source,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      followUps: followUps ?? this.followUps,
    );
  }
}

// =============================================================================
// DOCUMENT VERIFICATION MODELS
// =============================================================================

enum DocVerifyStatus {
  pending,
  verified,
  rejected;

  String get displayName {
    switch (this) {
      case DocVerifyStatus.pending:
        return 'Pending Verification';
      case DocVerifyStatus.verified:
        return 'Verified & Approved';
      case DocVerifyStatus.rejected:
        return 'Rejected (Re-upload Req.)';
    }
  }

  static DocVerifyStatus fromString(String? val) {
    switch (val?.toLowerCase()) {
      case 'verified':
        return DocVerifyStatus.verified;
      case 'rejected':
        return DocVerifyStatus.rejected;
      case 'pending':
      default:
        return DocVerifyStatus.pending;
    }
  }
}

class ApplicantDocumentItem {
  final String id;
  final String applicantId;
  final String applicantName;
  final String grade;
  final String documentType;
  final String fileName;
  final String fileSize;
  final DocVerifyStatus status;
  final String? rejectionReason;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime uploadedAt;
  final String? base64Data;
  final DateTime? dateOfBirth;
  final String? gender;
  final String? parentFullName;
  final String? parentRelationship;
  final String? currentAddress;
  final String? bloodGroup;

  const ApplicantDocumentItem({
    required this.id,
    required this.applicantId,
    required this.applicantName,
    required this.grade,
    required this.documentType,
    required this.fileName,
    required this.fileSize,
    required this.status,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
    required this.uploadedAt,
    this.base64Data,
    this.dateOfBirth,
    this.gender,
    this.parentFullName,
    this.parentRelationship,
    this.currentAddress,
    this.bloodGroup,
  });

  Uint8List? get fileBytes {
    if (base64Data != null && base64Data!.isNotEmpty) {
      try {
        return base64Decode(base64Data!);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  factory ApplicantDocumentItem.fromJson(Map<String, dynamic> json) {
    return ApplicantDocumentItem(
      id: json['id']?.toString() ?? '',
      applicantId: json['applicant_id']?.toString() ?? '',
      applicantName: json['applicant_name']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      documentType: json['document_type']?.toString() ?? '',
      fileName: json['file_name']?.toString() ?? '',
      fileSize: json['file_size']?.toString() ?? '',
      status: DocVerifyStatus.fromString(json['status']?.toString()),
      rejectionReason: json['rejection_reason']?.toString(),
      reviewedBy: json['reviewed_by']?.toString(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'].toString())
          : null,
      uploadedAt: DateTime.tryParse(json['uploaded_at']?.toString() ?? '') ?? DateTime.now(),
      base64Data: json['base64_data']?.toString(),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'].toString())
          : null,
      gender: json['gender']?.toString(),
      parentFullName: json['parent_full_name']?.toString(),
      parentRelationship: json['parent_relationship']?.toString(),
      currentAddress: json['current_address']?.toString(),
      bloodGroup: json['blood_group']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'grade': grade,
      'document_type': documentType,
      'file_name': fileName,
      'file_size': fileSize,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'uploaded_at': uploadedAt.toIso8601String(),
      'base64_data': base64Data,
      'date_of_birth': dateOfBirth?.toIso8601String(),
      'gender': gender,
      'parent_full_name': parentFullName,
      'parent_relationship': parentRelationship,
      'current_address': currentAddress,
      'blood_group': bloodGroup,
    };
  }

  ApplicantDocumentItem copyWith({
    String? id,
    String? applicantId,
    String? applicantName,
    String? grade,
    String? documentType,
    String? fileName,
    String? fileSize,
    DocVerifyStatus? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? uploadedAt,
    String? base64Data,
    DateTime? dateOfBirth,
    String? gender,
    String? parentFullName,
    String? parentRelationship,
    String? currentAddress,
    String? bloodGroup,
  }) {
    return ApplicantDocumentItem(
      id: id ?? this.id,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      grade: grade ?? this.grade,
      documentType: documentType ?? this.documentType,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      uploadedAt: uploadedAt ?? this.uploadedAt,
      base64Data: base64Data ?? this.base64Data,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      parentFullName: parentFullName ?? this.parentFullName,
      parentRelationship: parentRelationship ?? this.parentRelationship,
      currentAddress: currentAddress ?? this.currentAddress,
      bloodGroup: bloodGroup ?? this.bloodGroup,
    );
  }
}

// =============================================================================
// INTERVIEW SCHEDULING & ASSESSMENT MODELS
// =============================================================================

class InterviewAssessment {
  final int academicScore; // 1-5 scale
  final int behavioralScore; // 1-5 scale
  final int communicationScore; // 1-5 scale
  final int guardianAlignmentScore; // 1-5 scale
  final String outcome; // Recommended, Conditional, Waitlist, Not Recommended
  final String evaluatorFeedback;
  final DateTime evaluatedAt;
  final String evaluatedBy;

  const InterviewAssessment({
    required this.academicScore,
    required this.behavioralScore,
    required this.communicationScore,
    required this.guardianAlignmentScore,
    required this.outcome,
    required this.evaluatorFeedback,
    required this.evaluatedAt,
    required this.evaluatedBy,
  });

  double get averageScore =>
      (academicScore + behavioralScore + communicationScore + guardianAlignmentScore) / 4.0;

  factory InterviewAssessment.fromJson(Map<String, dynamic> json) {
    return InterviewAssessment(
      academicScore: int.tryParse(json['academic_score']?.toString() ?? '0') ?? 0,
      behavioralScore: int.tryParse(json['behavioral_score']?.toString() ?? '0') ?? 0,
      communicationScore: int.tryParse(json['communication_score']?.toString() ?? '0') ?? 0,
      guardianAlignmentScore: int.tryParse(json['guardian_alignment_score']?.toString() ?? '0') ?? 0,
      outcome: json['outcome']?.toString() ?? 'Recommended',
      evaluatorFeedback: json['evaluator_feedback']?.toString() ?? '',
      evaluatedAt: DateTime.tryParse(json['evaluated_at']?.toString() ?? '') ?? DateTime.now(),
      evaluatedBy: json['evaluated_by']?.toString() ?? 'Evaluator',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'academic_score': academicScore,
      'behavioral_score': behavioralScore,
      'communication_score': communicationScore,
      'guardian_alignment_score': guardianAlignmentScore,
      'outcome': outcome,
      'evaluator_feedback': evaluatorFeedback,
      'evaluated_at': evaluatedAt.toIso8601String(),
      'evaluated_by': evaluatedBy,
    };
  }
}

class InterviewSlotItem {
  final String id;
  final String applicantId;
  final String applicantName;
  final String grade;
  final String parentName;
  final String contactPhone;
  final DateTime interviewDateTime;
  final String roomVenue;
  final String interviewerName;
  final String status;
  final String? notes;
  final InterviewAssessment? assessment;

  const InterviewSlotItem({
    required this.id,
    this.applicantId = '',
    required this.applicantName,
    required this.grade,
    required this.parentName,
    required this.contactPhone,
    required this.interviewDateTime,
    required this.roomVenue,
    required this.interviewerName,
    required this.status,
    this.notes,
    this.assessment,
  });

  factory InterviewSlotItem.fromJson(Map<String, dynamic> json) {
    return InterviewSlotItem(
      id: json['id']?.toString() ?? '',
      applicantId: json['applicant_id']?.toString() ?? '',
      applicantName: json['applicant_name']?.toString() ?? '',
      grade: json['grade']?.toString() ?? '',
      parentName: json['parent_name']?.toString() ?? '',
      contactPhone: json['contact_phone']?.toString() ?? '',
      interviewDateTime: DateTime.tryParse(json['interview_date_time']?.toString() ?? '') ??
          DateTime.now().add(const Duration(hours: 2)),
      roomVenue: json['room_venue']?.toString() ?? 'Admissions Panel Room',
      interviewerName: json['interviewer_name']?.toString() ?? 'Faculty Panel',
      status: json['status']?.toString() ?? 'Scheduled',
      notes: json['notes']?.toString(),
      assessment: json['assessment'] != null
          ? InterviewAssessment.fromJson(Map<String, dynamic>.from(json['assessment'] as Map))
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicant_id': applicantId,
      'applicant_name': applicantName,
      'grade': grade,
      'parent_name': parentName,
      'contact_phone': contactPhone,
      'interview_date_time': interviewDateTime.toIso8601String(),
      'room_venue': roomVenue,
      'interviewer_name': interviewerName,
      'status': status,
      'notes': notes,
      'assessment': assessment?.toJson(),
    };
  }

  InterviewSlotItem copyWith({
    String? id,
    String? applicantId,
    String? applicantName,
    String? grade,
    String? parentName,
    String? contactPhone,
    DateTime? interviewDateTime,
    String? roomVenue,
    String? interviewerName,
    String? status,
    String? notes,
    InterviewAssessment? assessment,
  }) {
    return InterviewSlotItem(
      id: id ?? this.id,
      applicantId: applicantId ?? this.applicantId,
      applicantName: applicantName ?? this.applicantName,
      grade: grade ?? this.grade,
      parentName: parentName ?? this.parentName,
      contactPhone: contactPhone ?? this.contactPhone,
      interviewDateTime: interviewDateTime ?? this.interviewDateTime,
      roomVenue: roomVenue ?? this.roomVenue,
      interviewerName: interviewerName ?? this.interviewerName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      assessment: assessment ?? this.assessment,
    );
  }
}

// =============================================================================
// PRE-SCREENING APPLICATION CHECKLIST MODEL
// =============================================================================

class ApplicationPreScreeningChecklist {
  final bool hasCompleteDemographics;
  final bool hasVerifiedBirthCertificate;
  final bool hasVerifiedTransferCertificate;
  final bool hasVerifiedMarksheet;
  final bool hasCompletedInterview;
  final bool hasClearedApplicationFee;
  final String? overrideRemarks;

  const ApplicationPreScreeningChecklist({
    required this.hasCompleteDemographics,
    required this.hasVerifiedBirthCertificate,
    required this.hasVerifiedTransferCertificate,
    required this.hasVerifiedMarksheet,
    required this.hasCompletedInterview,
    required this.hasClearedApplicationFee,
    this.overrideRemarks,
  });

  bool get isReadyForAdminDecision =>
      (hasCompleteDemographics &&
          hasVerifiedBirthCertificate &&
          hasCompletedInterview &&
          hasClearedApplicationFee) ||
      (overrideRemarks != null && overrideRemarks!.trim().length >= 10);
}

// =============================================================================
// DYNAMIC REPOSITORIES & STATENOTIFIERS
// =============================================================================

class InquiriesNotifier extends StateNotifier<List<FrontDeskInquiry>> {
  final DynamicDataClient _client;
  static const String assetPath = 'assets/data/admissions/inquiries.json';
  static const String storageKey = 'edupulse_saved_frontdesk_inquiries';

  InquiriesNotifier({DynamicDataClient? client})
      : _client = client ?? DynamicDataClient.instance,
        super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _client.getAll(
        assetPath: assetPath,
        storageKey: storageKey,
      );
      if (raw.isNotEmpty) {
        state = raw.map((json) => FrontDeskInquiry.fromJson(json)).toList();
        return;
      }
    } catch (_) {}

    // Fallback seed
    state = [
      FrontDeskInquiry(
        id: 'INQ-2026-0101',
        applicantName: 'Kabir Rajesh Sharma',
        gradeApplying: 'Class 6',
        parentName: 'Rajesh Sharma',
        parentPhone: '+91 98765 43210',
        parentEmail: 'parent.rajesh@gmail.com',
        residentialArea: 'Whitefield, Bengaluru',
        source: InquirySource.walkIn,
        status: InquiryStatus.newLead,
        notes: 'Brother of Aarav Sharma (Class 10-A). Inquiring about CBSE curriculum & transport facilities.',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
    ];
  }

  Future<void> _sync() async {
    try {
      final rawList = state.map((inq) => inq.toJson()).toList();
      await _client.syncAll(
        assetPath: assetPath,
        storageKey: storageKey,
        items: rawList,
      );
    } catch (_) {}
  }

  /// Duplicate Detection: checks if an inquiry with matching phone or email already exists
  FrontDeskInquiry? checkDuplicateLead({
    required String phone,
    required String email,
    String? excludeId,
  }) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final cleanEmail = email.trim().toLowerCase();

    for (final inq in state) {
      if (excludeId != null && inq.id == excludeId) continue;
      final inqPhone = inq.parentPhone.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanPhone.length >= 8 && inqPhone.contains(cleanPhone)) {
        return inq;
      }
      if (cleanEmail.isNotEmpty && inq.parentEmail.trim().toLowerCase() == cleanEmail) {
        return inq;
      }
    }
    return null;
  }

  void addInquiry(FrontDeskInquiry inquiry) {
    state = [inquiry, ...state];
    _sync();
  }

  void updateStatus(String id, InquiryStatus newStatus) {
    state = [
      for (final inq in state)
        if (inq.id == id) inq.copyWith(status: newStatus) else inq,
    ];
    _sync();
  }

  void addFollowUp(String inquiryId, InquiryFollowUp followUp) {
    state = [
      for (final inq in state)
        if (inq.id == inquiryId)
          inq.copyWith(followUps: [followUp, ...inq.followUps])
        else
          inq,
    ];
    _sync();
  }
}

final frontDeskInquiriesProvider =
    StateNotifierProvider<InquiriesNotifier, List<FrontDeskInquiry>>(
  (ref) => InquiriesNotifier(),
);

// -----------------------------------------------------------------------------
// Document Verification StateNotifier
// -----------------------------------------------------------------------------
class DocumentQueueNotifier extends StateNotifier<List<ApplicantDocumentItem>> {
  final DynamicDataClient _client;
  static const String assetPath = 'assets/data/admissions/applicant_documents.json';
  static const String storageKey = 'edupulse_saved_frontdesk_documents';

  DocumentQueueNotifier({DynamicDataClient? client})
      : _client = client ?? DynamicDataClient.instance,
        super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _client.getAll(
        assetPath: assetPath,
        storageKey: storageKey,
      );
      if (raw.isNotEmpty) {
        state = raw.map((json) => ApplicantDocumentItem.fromJson(json)).toList();
        return;
      }
    } catch (_) {}
  }

  Future<void> _sync() async {
    try {
      final rawList = state.map((doc) => doc.toJson()).toList();
      await _client.syncAll(
        assetPath: assetPath,
        storageKey: storageKey,
        items: rawList,
      );
    } catch (_) {}
  }

  void approveDocument(String id, {String officerName = 'Front-Desk Officer'}) {
    state = [
      for (final doc in state)
        if (doc.id == id)
          doc.copyWith(
            status: DocVerifyStatus.verified,
            rejectionReason: null,
            reviewedBy: officerName,
            reviewedAt: DateTime.now(),
          )
        else
          doc,
    ];
    _sync();
  }

  void rejectDocument(String id, String reason, {String officerName = 'Front-Desk Officer'}) {
    state = [
      for (final doc in state)
        if (doc.id == id)
          doc.copyWith(
            status: DocVerifyStatus.rejected,
            rejectionReason: reason,
            reviewedBy: officerName,
            reviewedAt: DateTime.now(),
          )
        else
          doc,
    ];
    _sync();
  }

  void addDocument(ApplicantDocumentItem item) {
    state = [item, ...state];
    _sync();
  }

  void updateDocumentFile(
    String id, {
    required String fileName,
    required Uint8List bytes,
    required String fileSize,
  }) {
    state = [
      for (final doc in state)
        if (doc.id == id)
          doc.copyWith(
            fileName: fileName,
            fileSize: fileSize,
            base64Data: base64Encode(bytes),
          )
        else
          doc,
    ];
    _sync();
  }
}

final documentQueueProvider =
    StateNotifierProvider<DocumentQueueNotifier, List<ApplicantDocumentItem>>(
  (ref) => DocumentQueueNotifier(),
);

// -----------------------------------------------------------------------------
// Interview Scheduler StateNotifier
// -----------------------------------------------------------------------------
class InterviewSchedulerNotifier extends StateNotifier<List<InterviewSlotItem>> {
  final DynamicDataClient _client;
  static const String assetPath = 'assets/data/admissions/interview_slots.json';
  static const String storageKey = 'edupulse_saved_frontdesk_interviews';

  InterviewSchedulerNotifier({DynamicDataClient? client})
      : _client = client ?? DynamicDataClient.instance,
        super([]) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    try {
      final raw = await _client.getAll(
        assetPath: assetPath,
        storageKey: storageKey,
      );
      if (raw.isNotEmpty) {
        state = raw.map((json) => InterviewSlotItem.fromJson(json)).toList();
        return;
      }
    } catch (_) {}
  }

  Future<void> _sync() async {
    try {
      final rawList = state.map((item) => item.toJson()).toList();
      await _client.syncAll(
        assetPath: assetPath,
        storageKey: storageKey,
        items: rawList,
      );
    } catch (_) {}
  }

  /// Conflict check: prevents booking the same room or teacher within 30 mins
  InterviewSlotItem? checkConflict({
    required String roomVenue,
    required String interviewerName,
    required DateTime dateTime,
    String? excludeId,
  }) {
    for (final slot in state) {
      if (excludeId != null && slot.id == excludeId) continue;
      final diff = slot.interviewDateTime.difference(dateTime).inMinutes.abs();
      if (diff < 30) {
        if (slot.roomVenue.trim().toLowerCase() == roomVenue.trim().toLowerCase() ||
            slot.interviewerName.trim().toLowerCase() == interviewerName.trim().toLowerCase()) {
          return slot;
        }
      }
    }
    return null;
  }

  void addInterview(InterviewSlotItem item) {
    state = [item, ...state];
    _sync();
  }

  void recordAssessment(String slotId, InterviewAssessment assessment) {
    state = [
      for (final slot in state)
        if (slot.id == slotId)
          slot.copyWith(
            status: 'Completed',
            assessment: assessment,
          )
        else
          slot,
    ];
    _sync();
  }
}

final interviewSlotsProvider =
    StateNotifierProvider<InterviewSchedulerNotifier, List<InterviewSlotItem>>(
  (ref) => InterviewSchedulerNotifier(),
);

// Navigation page enum for Front Desk
enum FrontDeskPage {
  dashboard,
  inquiries,
  draftIntake,
  applicationsTracker,
  documentQueue,
  interviewScheduler,
  idBadgeStudio,
  studentLookup;
}

final frontDeskActivePageProvider = StateProvider<FrontDeskPage>((ref) => FrontDeskPage.dashboard);

final frontDeskDraftInquiryProvider = StateProvider<FrontDeskInquiry?>((ref) => null);

final frontDeskSelectedStudentBadgeProvider = StateProvider<String?>((ref) => null);
