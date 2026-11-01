import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/admissions/application/admissions_controller.dart';
import 'package:frontend/src/features/admissions/domain/admission_request_model.dart';
import 'package:frontend/src/features/admissions/presentation/admin/add_student_form_screen.dart';

void main() {
  group('Approve and Pre-fill Student Application Tests', () {
    test('toStudentAdmissionDraft maps photo, documents, and parent info properly', () {
      final req = AdmissionRequestModel(
        id: 'req-201',
        applicantFirstName: 'Reyansh',
        applicantLastName: 'Sharma',
        gender: 'MALE',
        dateOfBirth: DateTime(2019, 5, 14),
        bloodGroup: 'B+',
        gradeApplied: 'Class 1',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.parentPortal,
        status: AdmissionRequestStatus.pendingReview,
        appliedAt: DateTime.now().subtract(const Duration(days: 2)),
        parentFullName: 'Vikram Sharma',
        parentRelationship: 'Father',
        parentPhone: '+91 98765 43210',
        parentEmail: 'vikram.sharma@example.com',
        parentOccupation: 'Senior Architect',
        emergencyContactPhone: '+91 98765 43210',
        currentAddress: 'Flat 402, Palm Heights, Indiranagar, Bengaluru',
        previousSchoolName: 'Little Millennium Preschool',
        studentPhotoUrl: 'reyansh_photo.jpg',
        documents: const [
          'Reyansh_Birth_Certificate.pdf',
          'Reyansh_Immunization_Card.pdf',
          'Parent_Aadhaar_Card.pdf',
        ],
      );

      final draft = req.toStudentAdmissionDraft(newAdmissionNumber: 'ADM-2026-1001');

      expect(draft.user.firstName, 'Reyansh');
      expect(draft.user.lastName, 'Sharma');
      expect(draft.user.profilePhotoUrl, 'reyansh_photo.jpg');
      expect(draft.student.className, 'Class 1');
      expect(draft.student.previousSchoolName, 'Little Millennium Preschool');
      expect(draft.father?.fullName, 'Vikram Sharma');
      expect(draft.father?.occupation, 'Senior Architect');
      expect(draft.documents.length, 3);
      expect(draft.documents.first.fileName, 'Reyansh_Birth_Certificate.pdf');
      expect(draft.documents.first.title, 'Birth Certificate');
      expect(draft.documents[1].fileName, 'Reyansh_Immunization_Card.pdf');
      expect(draft.documents[1].title, 'Medical / Immunization Record');
    });

    testWidgets('AddStudentFormScreen displays prefilled dossier banner and imports all data responsively on 390x844 mobile screen', (tester) async {
      final req = AdmissionRequestModel(
        id: 'req-201',
        applicantFirstName: 'Reyansh',
        applicantLastName: 'Sharma',
        gender: 'MALE',
        dateOfBirth: DateTime(2019, 5, 14),
        bloodGroup: 'B+',
        gradeApplied: 'Class 1',
        academicYear: '2026-2027',
        source: AdmissionRequestSource.parentPortal,
        status: AdmissionRequestStatus.pendingReview,
        appliedAt: DateTime.now().subtract(const Duration(days: 2)),
        parentFullName: 'Vikram Sharma',
        parentRelationship: 'Father',
        parentPhone: '+91 98765 43210',
        parentEmail: 'vikram.sharma@example.com',
        parentOccupation: 'Senior Architect',
        emergencyContactPhone: '+91 98765 43210',
        currentAddress: 'Flat 402, Palm Heights, Indiranagar, Bengaluru',
        previousSchoolName: 'Little Millennium Preschool',
        studentPhotoUrl: 'reyansh_photo.jpg',
        documents: const [
          'Reyansh_Birth_Certificate.pdf',
          'Reyansh_Immunization_Card.pdf',
          'Parent_Aadhaar_Card.pdf',
        ],
      );

      final draft = req.toStudentAdmissionDraft(newAdmissionNumber: 'ADM-2026-1001');

      // Set physical size to standard mobile screen 390x844
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefilledAdmissionDraftProvider.overrideWith((ref) => draft),
            originatingRequestIdProvider.overrideWith((ref) => req.id),
          ],
          child: MaterialApp(
            home: AddStudentFormScreen(
              admissionToEdit: draft,
              isEditMode: false,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 1));

      // Check pre-filled dossier banner exists
      expect(find.text('Pre-filled from Application Dossier'), findsOneWidget);
      expect(find.text('REQ: req-201'), findsOneWidget);

      // Check student personal demographics are pre-populated
      expect(find.text('Reyansh'), findsWidgets);
      expect(find.text('Sharma'), findsWidgets);

      // Check photo attached indicator
      expect(find.text('Photo Attached'), findsWidgets);
      expect(find.text('reyansh_photo.jpg'), findsWidgets);

      await tester.pump(const Duration(seconds: 1));
    });
  });
}
