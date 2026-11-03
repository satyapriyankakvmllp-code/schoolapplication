import 'class_subject_assignment.dart';
import 'staff_compensation_model.dart';
import 'staff_login_account_model.dart';

enum StaffCategory {
  teaching,
  administrative,
  support;

  String get label {
    switch (this) {
      case StaffCategory.teaching:
        return 'Teaching Faculty';
      case StaffCategory.administrative:
        return 'Administrative Staff';
      case StaffCategory.support:
        return 'Operational Support';
    }
  }

  static StaffCategory fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'teaching':
      case 'teaching faculty':
      case 'teacher':
        return StaffCategory.teaching;
      case 'administrative':
      case 'admin':
      case 'administrative staff':
        return StaffCategory.administrative;
      case 'support':
      case 'operational support':
        return StaffCategory.support;
      default:
        return StaffCategory.teaching;
    }
  }
}

enum EmploymentType {
  permanent,
  probationary,
  contractual,
  partTime;

  String get label {
    switch (this) {
      case EmploymentType.permanent:
        return 'Full-Time Permanent';
      case EmploymentType.probationary:
        return 'Probationary';
      case EmploymentType.contractual:
        return 'Contractual';
      case EmploymentType.partTime:
        return 'Visiting / Part-Time';
    }
  }

  static EmploymentType fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'permanent':
      case 'full-time permanent':
      case 'full time permanent':
        return EmploymentType.permanent;
      case 'probationary':
      case 'probation':
        return EmploymentType.probationary;
      case 'contractual':
      case 'contract':
        return EmploymentType.contractual;
      case 'parttime':
      case 'part-time':
      case 'visiting':
      case 'visiting / part-time':
        return EmploymentType.partTime;
      default:
        return EmploymentType.permanent;
    }
  }
}

enum StaffStatus {
  active,
  onLeave,
  inactive;

  String get label {
    switch (this) {
      case StaffStatus.active:
        return 'Active';
      case StaffStatus.onLeave:
        return 'On Leave';
      case StaffStatus.inactive:
        return 'Inactive';
    }
  }

  static StaffStatus fromString(String? val) {
    switch (val?.toLowerCase().trim()) {
      case 'active':
        return StaffStatus.active;
      case 'onleave':
      case 'on leave':
      case 'leave':
        return StaffStatus.onLeave;
      case 'inactive':
      case 'relieved':
      case 'suspended':
        return StaffStatus.inactive;
      default:
        return StaffStatus.active;
    }
  }
}

class StaffMemberModel {
  // 1. Staff ID
  final String id;
  // 2. Full Name
  final String fullName;
  // 3. Profile Photo
  final String? photoUrl;
  // 4. Staff Category
  final StaffCategory category;
  // 5. Designation / Job Title
  final String designation;
  // 6. Department
  final String department;
  // 7. Qualification
  final String qualification;
  // 8. Specialization (Teaching Category Only)
  final String? specialization;
  // 9. Contact Info
  final String phone;
  final String email;
  final String currentAddress;
  final String permanentAddress;
  // 10. Date of Joining
  final DateTime joiningDate;
  // 11. Employment Type
  final EmploymentType employmentType;
  // 12. Assigned Classes & Subjects (Teaching Category Only)
  final List<ClassSubjectAssignment> assignedClasses;
  // 13. Salary Details (Admin/HR Protected)
  final StaffCompensationModel compensation;
  // 14. Login Account & Role
  final StaffLoginAccountModel? loginAccount;
  // 15. Active / Inactive Status
  final StaffStatus status;

  // Additional Demographics & Metadata
  final String? gender;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final String? emergencyContact;
  final String? fatherName;
  final String? motherName;
  final String? maritalStatus;
  final int? experienceYears;
  final String? previousSchool;
  final String? currentSchool;
  final String? bankBranch;
  final String? height;
  final String? weight;
  final List<Map<String, dynamic>>? documents;
  final Map<String, dynamic>? socialMedia;

  const StaffMemberModel({
    required this.id,
    required this.fullName,
    this.photoUrl,
    required this.category,
    required this.designation,
    required this.department,
    required this.qualification,
    this.specialization,
    required this.phone,
    required this.email,
    required this.currentAddress,
    required this.permanentAddress,
    required this.joiningDate,
    required this.employmentType,
    this.assignedClasses = const [],
    required this.compensation,
    this.loginAccount,
    this.status = StaffStatus.active,
    this.gender,
    this.dateOfBirth,
    this.bloodGroup,
    this.emergencyContact,
    this.fatherName,
    this.motherName,
    this.maritalStatus,
    this.experienceYears,
    this.previousSchool,
    this.currentSchool,
    this.bankBranch,
    this.height,
    this.weight,
    this.documents,
    this.socialMedia,
  });

  /// True if staff member is currently designated as a primary class teacher
  bool get isClassTeacher => assignedClasses.any((a) => a.isClassTeacher);

  /// First designated class teacher assignment, if any
  ClassSubjectAssignment? get primaryClassAssignment {
    try {
      return assignedClasses.firstWhere((a) => a.isClassTeacher);
    } catch (_) {
      return null;
    }
  }

  /// List of all distinct class teacher assignments
  List<ClassSubjectAssignment> get classTeacherAssignments {
    final seen = <String>{};
    final list = <ClassSubjectAssignment>[];
    for (final a in assignedClasses.where((e) => e.isClassTeacher)) {
      final key = '${a.grade}-${a.section}';
      if (seen.add(key)) {
        list.add(a);
      }
    }
    return list;
  }

  /// Human-readable summary of class teacher assignments (e.g. "Class Teacher (10-A, 9-B)")
  String get classTeacherSummary {
    final distinct = classTeacherAssignments;
    if (distinct.isEmpty) return '';
    if (distinct.length == 1) {
      final a = distinct.first;
      final cleanGrade = a.grade.replaceFirst(RegExp(r'^(Class\s+|Grade\s+)', caseSensitive: false), '');
      return 'Class Teacher ($cleanGrade-${a.section})';
    }
    if (distinct.length <= 3) {
      final codes = distinct
          .map((a) => '${a.grade.replaceFirst(RegExp(r'^(Class\s+|Grade\s+)', caseSensitive: false), '')}-${a.section}')
          .join(', ');
      return 'Class Teacher ($codes)';
    }
    return 'Class Teacher (${distinct.length} Classes)';
  }

  /// Initial monogram (e.g., "RS" for "Rajeshwari Swaminathan")
  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'ST';
    if (parts.length == 1) return parts.first.substring(0, parts.first.length.clamp(1, 2)).toUpperCase();
    // Ignore titles like Dr., Mr., Mrs. for initials if more names exist
    int start = 0;
    if (['dr.', 'mr.', 'mrs.', 'ms.', 'prof.'].contains(parts.first.toLowerCase()) && parts.length > 2) {
      start = 1;
    }
    final firstChar = parts[start].isNotEmpty ? parts[start][0] : '';
    final lastChar = parts.last.isNotEmpty ? parts.last[0] : '';
    return '$firstChar$lastChar'.toUpperCase();
  }

  StaffMemberModel copyWith({
    String? id,
    String? fullName,
    String? photoUrl,
    StaffCategory? category,
    String? designation,
    String? department,
    String? qualification,
    String? specialization,
    String? phone,
    String? email,
    String? currentAddress,
    String? permanentAddress,
    DateTime? joiningDate,
    EmploymentType? employmentType,
    List<ClassSubjectAssignment>? assignedClasses,
    StaffCompensationModel? compensation,
    StaffLoginAccountModel? loginAccount,
    StaffStatus? status,
    String? gender,
    DateTime? dateOfBirth,
    String? bloodGroup,
    String? emergencyContact,
    String? fatherName,
    String? motherName,
    String? maritalStatus,
    int? experienceYears,
    String? previousSchool,
    String? currentSchool,
    String? bankBranch,
    String? height,
    String? weight,
    List<Map<String, dynamic>>? documents,
    Map<String, dynamic>? socialMedia,
  }) {
    return StaffMemberModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      photoUrl: photoUrl ?? this.photoUrl,
      category: category ?? this.category,
      designation: designation ?? this.designation,
      department: department ?? this.department,
      qualification: qualification ?? this.qualification,
      specialization: specialization ?? this.specialization,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currentAddress: currentAddress ?? this.currentAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      joiningDate: joiningDate ?? this.joiningDate,
      employmentType: employmentType ?? this.employmentType,
      assignedClasses: assignedClasses ?? this.assignedClasses,
      compensation: compensation ?? this.compensation,
      loginAccount: loginAccount ?? this.loginAccount,
      status: status ?? this.status,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      maritalStatus: maritalStatus ?? this.maritalStatus,
      experienceYears: experienceYears ?? this.experienceYears,
      previousSchool: previousSchool ?? this.previousSchool,
      currentSchool: currentSchool ?? this.currentSchool,
      bankBranch: bankBranch ?? this.bankBranch,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      documents: documents ?? this.documents,
      socialMedia: socialMedia ?? this.socialMedia,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'photoUrl': photoUrl,
      'category': category.name,
      'designation': designation,
      'department': department,
      'qualification': qualification,
      'specialization': specialization,
      'phone': phone,
      'email': email,
      'currentAddress': currentAddress,
      'permanentAddress': permanentAddress,
      'joiningDate': joiningDate.toIso8601String(),
      'employmentType': employmentType.name,
      'assignedClasses': assignedClasses.map((a) => a.toMap()).toList(),
      'compensation': compensation.toMap(),
      'loginAccount': loginAccount?.toMap(),
      'status': status.name,
      'gender': gender,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'bloodGroup': bloodGroup,
      'emergencyContact': emergencyContact,
      'fatherName': fatherName,
      'motherName': motherName,
      'maritalStatus': maritalStatus,
      'experienceYears': experienceYears,
      'previousSchool': previousSchool,
      'currentSchool': currentSchool,
      'bankBranch': bankBranch,
      'height': height,
      'weight': weight,
      'documents': documents,
      'socialMedia': socialMedia,
    };
  }

  factory StaffMemberModel.fromMap(Map<String, dynamic> map) {
    return StaffMemberModel(
      id: (map['id'] ?? '').toString(),
      fullName: (map['fullName'] ?? '').toString(),
      photoUrl: map['photoUrl']?.toString(),
      category: StaffCategory.fromString(map['category']?.toString()),
      designation: (map['designation'] ?? '').toString(),
      department: (map['department'] ?? '').toString(),
      qualification: (map['qualification'] ?? '').toString(),
      specialization: map['specialization']?.toString(),
      phone: (map['phone'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      currentAddress: (map['currentAddress'] ?? '').toString(),
      permanentAddress: (map['permanentAddress'] ?? '').toString(),
      joiningDate: map['joiningDate'] != null
          ? DateTime.tryParse(map['joiningDate'].toString()) ?? DateTime(2024, 6, 1)
          : DateTime(2024, 6, 1),
      employmentType: EmploymentType.fromString(map['employmentType']?.toString()),
      assignedClasses: (map['assignedClasses'] as List<dynamic>?)
              ?.map((e) => ClassSubjectAssignment.fromMap(e as Map<String, dynamic>))
              .toList() ??
          const [],
      compensation: map['compensation'] != null
          ? StaffCompensationModel.fromMap(map['compensation'] as Map<String, dynamic>)
          : const StaffCompensationModel(
              basicSalary: 45000,
              bankName: 'State Bank of India',
              accountNumber: '1029384756',
              ifscCode: 'SBIN0001234',
              panNumber: 'ABCDE1234F',
            ),
      loginAccount: map['loginAccount'] != null
          ? StaffLoginAccountModel.fromMap(map['loginAccount'] as Map<String, dynamic>)
          : null,
      status: StaffStatus.fromString(map['status']?.toString()),
      gender: map['gender']?.toString(),
      dateOfBirth: map['dateOfBirth'] != null
          ? DateTime.tryParse(map['dateOfBirth'].toString())
          : null,
      bloodGroup: map['bloodGroup']?.toString(),
      emergencyContact: map['emergencyContact']?.toString(),
      fatherName: map['fatherName']?.toString(),
      motherName: map['motherName']?.toString(),
      maritalStatus: map['maritalStatus']?.toString(),
      experienceYears: map['experienceYears'] != null
          ? int.tryParse(map['experienceYears'].toString())
          : null,
      previousSchool: map['previousSchool']?.toString(),
      currentSchool: map['currentSchool']?.toString(),
      bankBranch: map['bankBranch']?.toString(),
      height: map['height']?.toString(),
      weight: map['weight']?.toString(),
      documents: (map['documents'] as List<dynamic>?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      socialMedia: map['socialMedia'] != null
          ? Map<String, dynamic>.from(map['socialMedia'] as Map)
          : null,
    );
  }
}
