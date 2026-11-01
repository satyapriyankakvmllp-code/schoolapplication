import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/admissions/application/frontdesk_controller.dart';

void main() {
  group('Front-Desk Admissions Module Unit Tests', () {
    late InquiriesNotifier inquiriesNotifier;
    late InterviewSchedulerNotifier interviewNotifier;
    late DocumentQueueNotifier documentNotifier;

    setUp(() {
      inquiriesNotifier = InquiriesNotifier();
      interviewNotifier = InterviewSchedulerNotifier();
      documentNotifier = DocumentQueueNotifier();
    });

    test('InquiriesNotifier correctly identifies duplicate phone numbers', () {
      final inq = FrontDeskInquiry(
        id: 'INQ-TEST-01',
        applicantName: 'Test Student',
        gradeApplying: 'Class 5',
        parentName: 'Test Parent',
        parentPhone: '+91 98765 43210',
        parentEmail: 'test.parent@gmail.com',
        source: InquirySource.walkIn,
        status: InquiryStatus.newLead,
        notes: 'Initial test note',
        createdAt: DateTime.now(),
      );
      inquiriesNotifier.addInquiry(inq);

      // Same phone with spaces/symbols
      final duplicate = inquiriesNotifier.checkDuplicateLead(
        phone: '9876543210',
        email: 'different@email.com',
      );
      expect(duplicate, isNotNull);
      expect(duplicate!.id, 'INQ-TEST-01');

      // Different phone & email
      final unique = inquiriesNotifier.checkDuplicateLead(
        phone: '+91 99999 11111',
        email: 'unique@email.com',
      );
      expect(unique, isNull);
    });

    test('InquiriesNotifier transitions status across full 6-stage lifecycle', () {
      final inq = FrontDeskInquiry(
        id: 'INQ-TEST-02',
        applicantName: 'Lifecycle Student',
        gradeApplying: 'Class 8',
        parentName: 'Parent Two',
        parentPhone: '+91 98888 22222',
        parentEmail: 'lifecycle@test.com',
        source: InquirySource.phone,
        status: InquiryStatus.newLead,
        notes: '',
        createdAt: DateTime.now(),
      );
      inquiriesNotifier.addInquiry(inq);

      inquiriesNotifier.updateStatus('INQ-TEST-02', InquiryStatus.contacted);
      expect(
        inquiriesNotifier.state.firstWhere((i) => i.id == 'INQ-TEST-02').status,
        InquiryStatus.contacted,
      );

      inquiriesNotifier.updateStatus('INQ-TEST-02', InquiryStatus.interviewScheduled);
      expect(
        inquiriesNotifier.state.firstWhere((i) => i.id == 'INQ-TEST-02').status,
        InquiryStatus.interviewScheduled,
      );

      inquiriesNotifier.updateStatus('INQ-TEST-02', InquiryStatus.converted);
      expect(
        inquiriesNotifier.state.firstWhere((i) => i.id == 'INQ-TEST-02').status,
        InquiryStatus.converted,
      );
    });

    test('InterviewSchedulerNotifier flags room or interviewer collision', () {
      final now = DateTime(2026, 10, 25, 11, 0);

      final slot = InterviewSlotItem(
        id: 'INT-TEST-01',
        applicantName: 'Applicant One',
        grade: 'Class 10',
        parentName: 'Parent One',
        contactPhone: '+91 98765 00001',
        interviewDateTime: now,
        roomVenue: 'Panel Room 101',
        interviewerName: 'Dr. Sarah Jenkins',
        status: 'Scheduled',
      );
      interviewNotifier.addInterview(slot);

      // Booking same room 10 minutes later should trigger conflict
      final conflict = interviewNotifier.checkConflict(
        roomVenue: 'Panel Room 101',
        interviewerName: 'Other Teacher',
        dateTime: now.add(const Duration(minutes: 10)),
      );
      expect(conflict, isNotNull);
      expect(conflict!.applicantName, 'Applicant One');

      // Booking 2 hours later should NOT trigger conflict
      final noConflict = interviewNotifier.checkConflict(
        roomVenue: 'Panel Room 101',
        interviewerName: 'Dr. Sarah Jenkins',
        dateTime: now.add(const Duration(hours: 2)),
      );
      expect(noConflict, isNull);
    });

    test('Interview assessment records rubric scores and average score', () {
      final slot = InterviewSlotItem(
        id: 'INT-TEST-02',
        applicantName: 'Rubric Applicant',
        grade: 'Class 6',
        parentName: 'Parent Two',
        contactPhone: '+91 98765 00002',
        interviewDateTime: DateTime.now(),
        roomVenue: 'Room 202',
        interviewerName: 'Anita Desai',
        status: 'Scheduled',
      );
      interviewNotifier.addInterview(slot);

      final assessment = InterviewAssessment(
        academicScore: 5,
        behavioralScore: 4,
        communicationScore: 5,
        guardianAlignmentScore: 4,
        outcome: 'Recommended',
        evaluatorFeedback: 'Strong candidate for Class 6.',
        evaluatedAt: DateTime(2026, 10, 24, 15, 0),
        evaluatedBy: 'Anita Desai',
      );

      interviewNotifier.recordAssessment('INT-TEST-02', assessment);
      final updated = interviewNotifier.state.firstWhere((s) => s.id == 'INT-TEST-02');
      expect(updated.status, 'Completed');
      expect(updated.assessment, isNotNull);
      expect(updated.assessment!.averageScore, 4.5);
      expect(updated.assessment!.outcome, 'Recommended');
    });

    test('DocumentQueueNotifier approves and rejects documents with reasons', () {
      final doc = ApplicantDocumentItem(
        id: 'DOC-TEST-01',
        applicantId: 'APP-01',
        applicantName: 'Applicant One',
        grade: 'Class 6',
        documentType: 'Birth Certificate',
        fileName: 'birth_cert.pdf',
        fileSize: '1.2 MB',
        status: DocVerifyStatus.pending,
        uploadedAt: DateTime(2026, 10, 24),
      );
      documentNotifier.addDocument(doc);

      documentNotifier.approveDocument('DOC-TEST-01', officerName: 'Officer Radhika');
      var updated = documentNotifier.state.firstWhere((d) => d.id == 'DOC-TEST-01');
      expect(updated.status, DocVerifyStatus.verified);
      expect(updated.reviewedBy, 'Officer Radhika');

      documentNotifier.rejectDocument(
        'DOC-TEST-01',
        'Official seal missing',
        officerName: 'Officer Radhika',
      );
      updated = documentNotifier.state.firstWhere((d) => d.id == 'DOC-TEST-01');
      expect(updated.status, DocVerifyStatus.rejected);
      expect(updated.rejectionReason, 'Official seal missing');
    });

    test('ApplicationPreScreeningChecklist enforces mandatory criteria', () {
      const incomplete = ApplicationPreScreeningChecklist(
        hasCompleteDemographics: true,
        hasVerifiedBirthCertificate: false,
        hasVerifiedTransferCertificate: false,
        hasVerifiedMarksheet: false,
        hasCompletedInterview: true,
        hasClearedApplicationFee: true,
      );
      expect(incomplete.isReadyForAdminDecision, false);

      const complete = ApplicationPreScreeningChecklist(
        hasCompleteDemographics: true,
        hasVerifiedBirthCertificate: true,
        hasVerifiedTransferCertificate: true,
        hasVerifiedMarksheet: true,
        hasCompletedInterview: true,
        hasClearedApplicationFee: true,
      );
      expect(complete.isReadyForAdminDecision, true);

      const overridden = ApplicationPreScreeningChecklist(
        hasCompleteDemographics: true,
        hasVerifiedBirthCertificate: false,
        hasVerifiedTransferCertificate: false,
        hasVerifiedMarksheet: false,
        hasCompletedInterview: false,
        hasClearedApplicationFee: false,
        overrideRemarks: 'Authorized principal provisional waiver for sports quota admission.',
      );
      expect(overridden.isReadyForAdminDecision, true);
    });

    test('ApplicantDocumentItem supports base64 encoding and fileBytes decoding', () {
      final sampleBytes = Uint8List.fromList([10, 20, 30, 40, 50]);
      final base64Sample = base64Encode(sampleBytes);

      final item = ApplicantDocumentItem(
        id: 'DOC-PHOTO-01',
        applicantId: 'APP-01',
        applicantName: 'Aarav Sharma',
        grade: 'Class 1',
        documentType: 'Student Passport Photo',
        fileName: 'aarav_photo.png',
        fileSize: '450 KB',
        status: DocVerifyStatus.pending,
        uploadedAt: DateTime(2026, 10, 24),
        base64Data: base64Sample,
      );

      expect(item.fileBytes, isNotNull);
      expect(item.fileBytes, sampleBytes);

      final json = item.toJson();
      expect(json['base64_data'], base64Sample);

      final fromJson = ApplicantDocumentItem.fromJson(json);
      expect(fromJson.fileBytes, sampleBytes);
      expect(fromJson.documentType, 'Student Passport Photo');
    });
  });
}
