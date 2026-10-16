import 'admission_document_model.dart';
import 'parent_profile_model.dart';
import 'student_admission_model.dart';
import 'student_profile_model.dart';
import '../../authentication/domain/user_model.dart';

enum AdmissionRequestStatus {
  pending,
  approved,
  rejected;

  String get displayName {
    switch (this) {
      case AdmissionRequestStatus.pending:
        return 'Pending';
      case AdmissionRequestStatus.approved:
        return 'Approved';
      case AdmissionRequestStatus.rejected:
        return 'Rejected';
    }
  }

  static AdmissionRequestStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'APPROVED':
        return AdmissionRequestStatus.approved;
      case 'REJECTED':
        return AdmissionRequestStatus.rejected;
      case 'PENDING':
      default:
        return AdmissionRequestStatus.pending;
    }
  }
}

enum AdmissionRequestSource {
  parentPortal,
  frontDesk;

  String get displayName {
    switch (this) {
      case AdmissionRequestSource.parentPortal:
        return 'Parent Portal';
      case AdmissionRequestSource.frontDesk:
        return 'Frontdesk Officer';
    }
  }

  static AdmissionRequestSource fromString(String? source) {
    switch (source?.toUpperCase()) {
      case 'FRONTDESK':
      case 'FRONT_DESK':
      case 'FRONTDESK_OFFICER':
        return AdmissionRequestSource.frontDesk;
      case 'PARENT_PORTAL':
      case 'PARENT':
      default:
        return AdmissionRequestSource.parentPortal;
    }
  }
}

class AdmissionRequestModel {
  final String id;
  final String applicantFirstName;
  final String applicantLastName;
  final String gender;
  final DateTime dateOfBirth;
  final String? bloodGroup;
  final String gradeApplied;
  final String academicYear;
  final AdmissionRequestSource source;
  final AdmissionRequestStatus status;
  final DateTime appliedAt;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String parentFullName;
  final String parentRelationship; // Father, Mother, Guardian
  final String parentPhone;
  final String parentEmail;
  final String? parentOccupation;
  final String currentAddress;
  final String? permanentAddress;
  final String? previousSchoolName;
  final String emergencyContactPhone;
  final List<String> documents;
  final String? notes;

  const AdmissionRequestModel({
    required this.id,
    required this.applicantFirstName,
    required this.applicantLastName,
    required this.gender,
    required this.dateOfBirth,
    this.bloodGroup,
    required this.gradeApplied,
    this.academicYear = '2026-2027',
    this.source = AdmissionRequestSource.parentPortal,
    this.status = AdmissionRequestStatus.pending,
    required this.appliedAt,
    this.reviewedAt,
    this.rejectionReason,
    required this.parentFullName,
    this.parentRelationship = 'Father',
    required this.parentPhone,
    required this.parentEmail,
    this.parentOccupation,
    required this.currentAddress,
    this.permanentAddress,
    this.previousSchoolName,
    required this.emergencyContactPhone,
    this.documents = const [],
    this.notes,
  });

  String get applicantFullName => '$applicantFirstName $applicantLastName'.trim();

  factory AdmissionRequestModel.fromJson(Map<String, dynamic> json) {
    return AdmissionRequestModel(
      id: json['id'] as String,
      applicantFirstName: json['applicant_first_name'] as String,
      applicantLastName: json['applicant_last_name'] as String? ?? '',
      gender: (json['gender'] as String? ?? 'MALE').toUpperCase(),
      dateOfBirth: DateTime.tryParse(json['date_of_birth'] as String? ?? '') ??
          DateTime(2012, 1, 1),
      bloodGroup: json['blood_group'] as String?,
      gradeApplied: json['grade_applied'] as String? ?? 'Class 1',
      academicYear: json['academic_year'] as String? ?? '2026-2027',
      source: AdmissionRequestSource.fromString(json['source'] as String?),
      status: AdmissionRequestStatus.fromString(json['status'] as String?),
      appliedAt: DateTime.tryParse(json['applied_at'] as String? ?? '') ??
          DateTime.now(),
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      rejectionReason: json['rejection_reason'] as String?,
      parentFullName: json['parent_full_name'] as String? ?? 'Parent',
      parentRelationship: json['parent_relationship'] as String? ?? 'Father',
      parentPhone: json['parent_phone'] as String? ?? '',
      parentEmail: json['parent_email'] as String? ?? '',
      parentOccupation: json['parent_occupation'] as String?,
      currentAddress: json['current_address'] as String? ?? '',
      permanentAddress: json['permanent_address'] as String?,
      previousSchoolName: json['previous_school_name'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String? ??
          json['parent_phone'] as String? ??
          '',
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'applicant_first_name': applicantFirstName,
      'applicant_last_name': applicantLastName,
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'blood_group': bloodGroup,
      'grade_applied': gradeApplied,
      'academic_year': academicYear,
      'source': source.name,
      'status': status.name,
      'applied_at': appliedAt.toIso8601String(),
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'parent_full_name': parentFullName,
      'parent_relationship': parentRelationship,
      'parent_phone': parentPhone,
      'parent_email': parentEmail,
      'parent_occupation': parentOccupation,
      'current_address': currentAddress,
      'permanent_address': permanentAddress,
      'previous_school_name': previousSchoolName,
      'emergency_contact_phone': emergencyContactPhone,
      'documents': documents,
      'notes': notes,
    };
  }

  AdmissionRequestModel copyWith({
    String? id,
    String? applicantFirstName,
    String? applicantLastName,
    String? gender,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? gradeApplied,
    String? academicYear,
    AdmissionRequestSource? source,
    AdmissionRequestStatus? status,
    DateTime? appliedAt,
    DateTime? reviewedAt,
    String? rejectionReason,
    String? parentFullName,
    String? parentRelationship,
    String? parentPhone,
    String? parentEmail,
    String? parentOccupation,
    String? currentAddress,
    String? permanentAddress,
    String? previousSchoolName,
    String? emergencyContactPhone,
    List<String>? documents,
    String? notes,
  }) {
    return AdmissionRequestModel(
      id: id ?? this.id,
      applicantFirstName: applicantFirstName ?? this.applicantFirstName,
      applicantLastName: applicantLastName ?? this.applicantLastName,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      gradeApplied: gradeApplied ?? this.gradeApplied,
      academicYear: academicYear ?? this.academicYear,
      source: source ?? this.source,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      parentFullName: parentFullName ?? this.parentFullName,
      parentRelationship: parentRelationship ?? this.parentRelationship,
      parentPhone: parentPhone ?? this.parentPhone,
      parentEmail: parentEmail ?? this.parentEmail,
      parentOccupation: parentOccupation ?? this.parentOccupation,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      previousSchoolName: previousSchoolName ?? this.previousSchoolName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      documents: documents ?? this.documents,
      notes: notes ?? this.notes,
    );
  }

  /// Converts this incoming application request into a pre-filled StudentAdmissionModel
  /// so that the Admin's Add New Student form wizard is automatically populated with
  /// all existing submitted data, ready for final Class, Section & Roll No assignment.
  StudentAdmissionModel toStudentAdmissionDraft({
    required String newAdmissionNumber,
    String assignedSection = 'A',
  }) {
    final digits = id.replaceAll(RegExp(r'[^0-9]'), '');
    final idSuffix = digits.isNotEmpty ? digits : '${DateTime.now().millisecondsSinceEpoch % 10000}';
    final generatedUserId = 'usr-$idSuffix';
    final generatedStudentId = 'std-$idSuffix';
    final parentId = 'par-$idSuffix';

    final user = UserModel(
      id: generatedUserId,
      email: parentEmail.isNotEmpty
          ? '${applicantFirstName.toLowerCase()}.${applicantLastName.toLowerCase()}@student.edu'
          : '',
      phoneNumber: emergencyContactPhone,
      userRole: UserRole.student,
      firstName: applicantFirstName,
      lastName: applicantLastName,
      gender: Gender.fromString(gender),
      dateOfBirth: dateOfBirth,
      status: AccountStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    String? dobCert;
    for (final doc in documents) {
      if (doc.toLowerCase().contains('birth')) {
        dobCert = doc;
        break;
      }
    }

    final student = StudentProfileModel(
      id: generatedStudentId,
      userId: generatedUserId,
      admissionNumber: newAdmissionNumber,
      rollNumber: null, // Left for Admin to assign
      currentClassId: 'cls-${gradeApplied.toLowerCase().replaceAll(' ', '')}',
      className: gradeApplied,
      section: assignedSection,
      admissionDate: DateTime.now(),
      academicYear: academicYear,
      category: 'General',
      bloodGroup: bloodGroup,
      emergencyContactPhone: emergencyContactPhone,
      currentAddress: currentAddress,
      residentialAddress: currentAddress,
      permanentAddress: permanentAddress ?? currentAddress,
      enrollmentStatus: EnrollmentStatus.enrolled,
      previousSchoolName: previousSchoolName,
      dobCertificate: dobCert,
      additionalDetails: notes ?? 'Admission submitted via ${source.displayName}.',
    );

    ParentProfileModel? father;
    ParentProfileModel? mother;
    ParentProfileModel? guardian;

    if (parentRelationship.toLowerCase() == 'mother') {
      mother = ParentProfileModel(
        id: parentId,
        userId: generatedUserId,
        fullName: parentFullName,
        relationship: 'Mother',
        phoneNumber: parentPhone,
        email: parentEmail,
        occupation: parentOccupation ?? 'Professional',
        residentialAddress: currentAddress,
      );
    } else if (parentRelationship.toLowerCase() == 'guardian' ||
        parentRelationship.toLowerCase() == 'others') {
      guardian = ParentProfileModel(
        id: parentId,
        userId: generatedUserId,
        fullName: parentFullName,
        relationship: parentRelationship,
        phoneNumber: parentPhone,
        email: parentEmail,
        occupation: parentOccupation ?? 'Guardian',
        residentialAddress: currentAddress,
      );
    } else {
      father = ParentProfileModel(
        id: parentId,
        userId: generatedUserId,
        fullName: parentFullName,
        relationship: 'Father',
        phoneNumber: parentPhone,
        email: parentEmail,
        occupation: parentOccupation ?? 'Service / Business',
        residentialAddress: currentAddress,
      );
    }

    final docModels = documents.asMap().entries.map((entry) {
      final idx = entry.key;
      final docName = entry.value;
      final dLower = docName.toLowerCase();
      String title = 'Document';
      if (dLower.contains('birth')) {
        title = 'Birth Certificate';
      } else if (dLower.contains('transfer') || dLower.contains('tc') || dLower.contains('report') || dLower.contains('marks')) {
        title = 'Previous Academic Record';
      } else if (dLower.contains('govt') || dLower.contains('id') || dLower.contains('aadhaar') || dLower.contains('parent')) {
        title = 'Government ID';
      } else if (dLower.contains('immun') || dLower.contains('medical') || dLower.contains('vaccin')) {
        title = 'Medical / Immunization Record';
      }
      return AdmissionDocumentModel(
        id: 'doc-${DateTime.now().millisecondsSinceEpoch}-$idx',
        title: title,
        fileName: docName,
        fileUrl: docName,
        fileSize: '1.2 MB',
        fileType: docName.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
        isVerified: true,
        uploadedAt: appliedAt,
      );
    }).toList();

    return StudentAdmissionModel(
      user: user,
      student: student,
      father: father,
      mother: mother,
      guardian: guardian,
      selectedGuardianType: parentRelationship.isNotEmpty ? parentRelationship : 'Father',
      documents: docModels,
      loginEmail: '${applicantFirstName.toLowerCase()}.${applicantLastName.toLowerCase()}@student.edu',
    );
  }
}
