import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}

enum InquiryStatus {
  newLead,
  contacted,
  interviewScheduled,
  converted,
  dropped;

  String get displayName {
    switch (this) {
      case InquiryStatus.newLead:
        return 'New Inquiry';
      case InquiryStatus.contacted:
        return 'Contacted';
      case InquiryStatus.interviewScheduled:
        return 'Interview Booked';
      case InquiryStatus.converted:
        return 'Converted to Application';
      case InquiryStatus.dropped:
        return 'Archived / Dropped';
    }
  }
}

class FrontDeskInquiry {
  final String id;
  final String applicantName;
  final String gradeApplying;
  final String parentName;
  final String parentPhone;
  final String parentEmail;
  final InquirySource source;
  final InquiryStatus status;
  final String notes;
  final DateTime createdAt;

  const FrontDeskInquiry({
    required this.id,
    required this.applicantName,
    required this.gradeApplying,
    required this.parentName,
    required this.parentPhone,
    required this.parentEmail,
    required this.source,
    required this.status,
    required this.notes,
    required this.createdAt,
  });

  FrontDeskInquiry copyWith({
    String? id,
    String? applicantName,
    String? gradeApplying,
    String? parentName,
    String? parentPhone,
    String? parentEmail,
    InquirySource? source,
    InquiryStatus? status,
    String? notes,
    DateTime? createdAt,
  }) {
    return FrontDeskInquiry(
      id: id ?? this.id,
      applicantName: applicantName ?? this.applicantName,
      gradeApplying: gradeApplying ?? this.gradeApplying,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      source: source ?? this.source,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

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
  final DateTime uploadedAt;

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
    required this.uploadedAt,
  });

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
    DateTime? uploadedAt,
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
      uploadedAt: uploadedAt ?? this.uploadedAt,
    );
  }
}

class InterviewSlotItem {
  final String id;
  final String applicantName;
  final String grade;
  final String parentName;
  final String contactPhone;
  final DateTime interviewDateTime;
  final String roomVenue;
  final String interviewerName;
  final String status;
  final String? notes;

  const InterviewSlotItem({
    required this.id,
    required this.applicantName,
    required this.grade,
    required this.parentName,
    required this.contactPhone,
    required this.interviewDateTime,
    required this.roomVenue,
    required this.interviewerName,
    required this.status,
    this.notes,
  });

  InterviewSlotItem copyWith({
    String? id,
    String? applicantName,
    String? grade,
    String? parentName,
    String? contactPhone,
    DateTime? interviewDateTime,
    String? roomVenue,
    String? interviewerName,
    String? status,
    String? notes,
  }) {
    return InterviewSlotItem(
      id: id ?? this.id,
      applicantName: applicantName ?? this.applicantName,
      grade: grade ?? this.grade,
      parentName: parentName ?? this.parentName,
      contactPhone: contactPhone ?? this.contactPhone,
      interviewDateTime: interviewDateTime ?? this.interviewDateTime,
      roomVenue: roomVenue ?? this.roomVenue,
      interviewerName: interviewerName ?? this.interviewerName,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

// -----------------------------------------------------------------------------
// Inquiries StateNotifier
// -----------------------------------------------------------------------------
class InquiriesNotifier extends StateNotifier<List<FrontDeskInquiry>> {
  InquiriesNotifier()
      : super([
          FrontDeskInquiry(
            id: 'INQ-2026-0101',
            applicantName: 'Kabir Rajesh Sharma',
            gradeApplying: 'Class 6',
            parentName: 'Rajesh Sharma',
            parentPhone: '+91 98765 43210',
            parentEmail: 'parent.rajesh@gmail.com',
            source: InquirySource.walkIn,
            status: InquiryStatus.newLead,
            notes: 'Brother of Aarav Sharma (Class 10-A). Inquiring about CBSE curriculum & transport facilities.',
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
          FrontDeskInquiry(
            id: 'INQ-2026-0102',
            applicantName: 'Meera Iyer',
            gradeApplying: 'Class 9',
            parentName: 'Kalyan Iyer',
            parentPhone: '+91 98222 33445',
            parentEmail: 'kalyan.iyer@gmail.com',
            source: InquirySource.phone,
            status: InquiryStatus.contacted,
            notes: 'Relocating from Bangalore. Requested syllabus comparison and sports coaching info.',
            createdAt: DateTime.now().subtract(const Duration(hours: 5)),
          ),
          FrontDeskInquiry(
            id: 'INQ-2026-0103',
            applicantName: 'Rohan Gupta',
            gradeApplying: 'Class 11 - Science',
            parentName: 'Anil Gupta',
            parentPhone: '+91 98111 55667',
            parentEmail: 'anil.gupta@corp.in',
            source: InquirySource.website,
            status: InquiryStatus.interviewScheduled,
            notes: 'Opting for Physics, Chemistry, Math & Computer Science stream. Prior school 92% GPA.',
            createdAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          FrontDeskInquiry(
            id: 'INQ-2026-0104',
            applicantName: 'Sanya Malhotra',
            gradeApplying: 'Class 4',
            parentName: 'Pooja Malhotra',
            parentPhone: '+91 97665 11223',
            parentEmail: 'pooja.m@yahoo.com',
            source: InquirySource.referral,
            status: InquiryStatus.converted,
            notes: 'Formally filled draft admission intake. Documents handed in at reception.',
            createdAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]);

  void addInquiry(FrontDeskInquiry inquiry) {
    state = [inquiry, ...state];
  }

  void updateStatus(String id, InquiryStatus newStatus) {
    state = [
      for (final inq in state)
        if (inq.id == id) inq.copyWith(status: newStatus) else inq,
    ];
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
  DocumentQueueNotifier()
      : super([
          ApplicantDocumentItem(
            id: 'DOC-001',
            applicantId: 'APP-2026-0101',
            applicantName: 'Kabir Sharma',
            grade: 'Class 6',
            documentType: 'Birth Certificate',
            fileName: 'kabir_birth_cert_scan.pdf',
            fileSize: '1.4 MB',
            status: DocVerifyStatus.pending,
            uploadedAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          ApplicantDocumentItem(
            id: 'DOC-002',
            applicantId: 'APP-2026-0101',
            applicantName: 'Kabir Sharma',
            grade: 'Class 6',
            documentType: 'Transfer Certificate (TC)',
            fileName: 'tc_prior_school_stamped.pdf',
            fileSize: '2.1 MB',
            status: DocVerifyStatus.pending,
            uploadedAt: DateTime.now().subtract(const Duration(hours: 3)),
          ),
          ApplicantDocumentItem(
            id: 'DOC-003',
            applicantId: 'APP-2026-0098',
            applicantName: 'Ananya Deshmukh',
            grade: 'Class 8',
            documentType: 'Prior Report Card',
            fileName: 'grade7_final_marksheet.jpg',
            fileSize: '840 KB',
            status: DocVerifyStatus.verified,
            uploadedAt: DateTime.now().subtract(const Duration(days: 1)),
          ),
          ApplicantDocumentItem(
            id: 'DOC-004',
            applicantId: 'APP-2026-0095',
            applicantName: 'Dev Patel',
            grade: 'Class 11',
            documentType: 'Residential Address Proof',
            fileName: 'electricity_bill_blurry.png',
            fileSize: '620 KB',
            status: DocVerifyStatus.rejected,
            rejectionReason: 'Scan is blurry; address line and seal are illegible. Please upload a clear PDF.',
            uploadedAt: DateTime.now().subtract(const Duration(days: 2)),
          ),
        ]);

  void approveDocument(String id) {
    state = [
      for (final doc in state)
        if (doc.id == id)
          doc.copyWith(status: DocVerifyStatus.verified, rejectionReason: null)
        else
          doc,
    ];
  }

  void rejectDocument(String id, String reason) {
    state = [
      for (final doc in state)
        if (doc.id == id)
          doc.copyWith(status: DocVerifyStatus.rejected, rejectionReason: reason)
        else
          doc,
    ];
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
  InterviewSchedulerNotifier()
      : super([
          InterviewSlotItem(
            id: 'INT-01',
            applicantName: 'Rohan Gupta',
            grade: 'Class 11 - Science',
            parentName: 'Anil Gupta',
            contactPhone: '+91 98111 55667',
            interviewDateTime: DateTime.now().add(const Duration(hours: 4)),
            roomVenue: 'Admissions Panel Room 102',
            interviewerName: 'Dr. Sarah Jenkins & Anita Desai',
            status: 'Scheduled Today',
            notes: 'Science aptitude evaluation & subject elective selection',
          ),
          InterviewSlotItem(
            id: 'INT-02',
            applicantName: 'Meera Iyer',
            grade: 'Class 9',
            parentName: 'Kalyan Iyer',
            contactPhone: '+91 98222 33445',
            interviewDateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
            roomVenue: 'Conference Hall A',
            interviewerName: 'Priya Verma',
            status: 'Confirmed Slot',
            notes: 'General admission & language preference assessment',
          ),
          InterviewSlotItem(
            id: 'INT-03',
            applicantName: 'Kabir Rajesh Sharma',
            grade: 'Class 6',
            parentName: 'Rajesh Sharma',
            contactPhone: '+91 98765 43210',
            interviewDateTime: DateTime.now().add(const Duration(days: 2, hours: 5)),
            roomVenue: 'Admissions Panel Room 101',
            interviewerName: 'Anita Desai',
            status: 'Requested by Parent',
            notes: 'Sibling intake interview & campus tour',
          ),
        ]);

  void addInterview(InterviewSlotItem item) {
    state = [item, ...state];
  }
}

final interviewSlotsProvider =
    StateNotifierProvider<InterviewSchedulerNotifier, List<InterviewSlotItem>>(
  (ref) => InterviewSchedulerNotifier(),
);

// Navigation page enum extension for Front Desk
enum FrontDeskPage {
  dashboard,
  inquiries,
  draftIntake,
  documentQueue,
  interviewScheduler,
  idBadgeStudio,
  studentLookup;
}

final frontDeskActivePageProvider = StateProvider<FrontDeskPage>((ref) => FrontDeskPage.dashboard);

final frontDeskDraftInquiryProvider = StateProvider<FrontDeskInquiry?>((ref) => null);

final frontDeskSelectedStudentBadgeProvider = StateProvider<String?>((ref) => null);
