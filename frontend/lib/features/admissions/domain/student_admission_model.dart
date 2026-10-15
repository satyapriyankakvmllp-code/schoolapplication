import 'admission_document_model.dart';
import 'parent_profile_model.dart';
import 'student_profile_model.dart';
import '../../authentication/domain/user_model.dart';

/// Complete aggregate admission model linking User, StudentProfile,
/// ParentProfiles, and Documents for form submission and details display.
class StudentAdmissionModel {
  final UserModel user;
  final StudentProfileModel student;
  final ParentProfileModel? father;
  final ParentProfileModel? mother;
  final ParentProfileModel? guardian;
  final String selectedGuardianType; // 'Father', 'Mother', 'Others'
  final List<AdmissionDocumentModel> documents;
  final String? loginEmail;
  final String? loginPassword;

  const StudentAdmissionModel({
    required this.user,
    required this.student,
    this.father,
    this.mother,
    this.guardian,
    this.selectedGuardianType = 'Father',
    this.documents = const [],
    this.loginEmail,
    this.loginPassword,
  });

  factory StudentAdmissionModel.fromJson(Map<String, dynamic> json) {
    return StudentAdmissionModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      student: StudentProfileModel.fromJson(json['student'] as Map<String, dynamic>),
      father: json['father'] != null
          ? ParentProfileModel.fromJson(json['father'] as Map<String, dynamic>)
          : null,
      mother: json['mother'] != null
          ? ParentProfileModel.fromJson(json['mother'] as Map<String, dynamic>)
          : null,
      guardian: json['guardian'] != null
          ? ParentProfileModel.fromJson(json['guardian'] as Map<String, dynamic>)
          : null,
      selectedGuardianType: json['selected_guardian_type'] as String? ?? 'Father',
      documents: (json['documents'] as List<dynamic>?)
              ?.map((e) => AdmissionDocumentModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      loginEmail: json['login_email'] as String?,
      loginPassword: json['login_password'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'student': student.toJson(),
      'father': father?.toJson(),
      'mother': mother?.toJson(),
      'guardian': guardian?.toJson(),
      'selected_guardian_type': selectedGuardianType,
      'documents': documents.map((e) => e.toJson()).toList(),
      'login_email': loginEmail,
      'login_password': loginPassword,
    };
  }

  StudentAdmissionModel copyWith({
    UserModel? user,
    StudentProfileModel? student,
    ParentProfileModel? father,
    ParentProfileModel? mother,
    ParentProfileModel? guardian,
    String? selectedGuardianType,
    List<AdmissionDocumentModel>? documents,
    String? loginEmail,
    String? loginPassword,
  }) {
    return StudentAdmissionModel(
      user: user ?? this.user,
      student: student ?? this.student,
      father: father ?? this.father,
      mother: mother ?? this.mother,
      guardian: guardian ?? this.guardian,
      selectedGuardianType: selectedGuardianType ?? this.selectedGuardianType,
      documents: documents ?? this.documents,
      loginEmail: loginEmail ?? this.loginEmail,
      loginPassword: loginPassword ?? this.loginPassword,
    );
  }
}
