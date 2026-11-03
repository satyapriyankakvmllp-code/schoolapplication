enum EnrollmentStatus {
  draft,
  pendingVerification,
  enrolled,
  promoted,
  discontinued,
  archived;

  String get displayName {
    switch (this) {
      case EnrollmentStatus.draft:
        return 'Draft';
      case EnrollmentStatus.pendingVerification:
        return 'Pending Verification';
      case EnrollmentStatus.enrolled:
        return 'Enrolled';
      case EnrollmentStatus.promoted:
        return 'Promoted';
      case EnrollmentStatus.discontinued:
        return 'Discontinued';
      case EnrollmentStatus.archived:
        return 'Archived';
    }
  }

  static EnrollmentStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'DRAFT':
        return EnrollmentStatus.draft;
      case 'PENDING_VERIFICATION':
        return EnrollmentStatus.pendingVerification;
      case 'PROMOTED':
        return EnrollmentStatus.promoted;
      case 'DISCONTINUED':
        return EnrollmentStatus.discontinued;
      case 'ARCHIVED':
        return EnrollmentStatus.archived;
      case 'ENROLLED':
      default:
        return EnrollmentStatus.enrolled;
    }
  }
}

class StudentProfileModel {
  final String id;
  final String userId;
  final String admissionNumber;
  final String? rollNumber;
  final String? currentClassId;
  final String? sectionId;
  final String className;
  final String section;
  final DateTime admissionDate;
  final String academicYear;
  final String? category;
  final String? bloodGroup;
  final String? height;
  final String? weight;
  final String emergencyContactPhone;
  final String currentAddress;
  final String residentialAddress;
  final String? permanentAddress;
  final EnrollmentStatus enrollmentStatus;
  final String? dobCertificate;
  final String? transferCertificateId;
  final bool idBadgeIssued;
  final String? mediumOfInstruction;
  final String? houseGroup;
  final String? secondLanguage;

  // Bank & Identification
  final String? bankAccountNumber;
  final String? bankName;
  final String? ifscCode;
  final String? nationalIdNumber;

  // Prior School & Hostel
  final String? previousSchoolName;
  final String? previousSchoolAddress;
  final String? hostelName;
  final String? roomNo;
  final String? additionalDetails;

  const StudentProfileModel({
    required this.id,
    required this.userId,
    required this.admissionNumber,
    this.rollNumber,
    this.currentClassId,
    this.sectionId,
    required this.className,
    required this.section,
    required this.admissionDate,
    required this.academicYear,
    this.category,
    this.bloodGroup,
    this.height,
    this.weight,
    required this.emergencyContactPhone,
    required this.currentAddress,
    required this.residentialAddress,
    this.permanentAddress,
    this.enrollmentStatus = EnrollmentStatus.enrolled,
    this.dobCertificate,
    this.transferCertificateId,
    this.idBadgeIssued = false,
    this.mediumOfInstruction,
    this.houseGroup,
    this.secondLanguage,
    this.bankAccountNumber,
    this.bankName,
    this.ifscCode,
    this.nationalIdNumber,
    this.previousSchoolName,
    this.previousSchoolAddress,
    this.hostelName,
    this.roomNo,
    this.additionalDetails,
  });

  factory StudentProfileModel.fromJson(Map<String, dynamic> json) {
    String? classId = json['current_class_id'] as String?;
    String? secId = json['section_id'] as String?;
    // Safe legacy migration: Map composite cls-10a/cls-10b to class cls-10 and sections sec-10a/sec-10b
    if (classId == 'cls-10a') {
      classId = 'cls-10';
      secId ??= 'sec-10a';
    } else if (classId == 'cls-10b') {
      classId = 'cls-10';
      secId ??= 'sec-10b';
    }

    return StudentProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      admissionNumber: json['admission_number'] as String? ?? '',
      rollNumber: json['roll_number'] as String?,
      currentClassId: classId,
      sectionId: secId,
      className: json['class_name'] as String? ?? 'Grade 10',
      section: json['section'] as String? ?? 'A',
      admissionDate: json['admission_date'] != null
          ? DateTime.tryParse(json['admission_date'] as String) ?? DateTime.now()
          : DateTime.now(),
      academicYear: json['academic_year'] as String? ?? '2026-2027',
      category: json['category'] as String?,
      bloodGroup: json['blood_group'] as String?,
      height: json['height'] as String?,
      weight: json['weight'] as String?,
      emergencyContactPhone: json['emergency_contact_phone'] as String? ?? '',
      currentAddress: json['current_address'] as String? ?? '',
      residentialAddress: json['residential_address'] as String? ??
          json['current_address'] as String? ?? '',
      permanentAddress: json['permanent_address'] as String?,
      enrollmentStatus: EnrollmentStatus.fromString(json['enrollment_status'] as String?),
      dobCertificate: json['dob_certificate'] as String?,
      transferCertificateId: json['transfer_certificate_id'] as String?,
      idBadgeIssued: json['id_badge_issued'] as bool? ?? false,
      mediumOfInstruction: json['medium_of_instruction'] as String?,
      houseGroup: json['house_group'] as String?,
      secondLanguage: json['second_language'] as String?,
      bankAccountNumber: json['bank_account_number'] as String?,
      bankName: json['bank_name'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      nationalIdNumber: json['national_id_number'] as String?,
      previousSchoolName: json['previous_school_name'] as String?,
      previousSchoolAddress: json['previous_school_address'] as String?,
      hostelName: json['hostel_name'] as String?,
      roomNo: json['room_no'] as String?,
      additionalDetails: json['additional_details'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'admission_number': admissionNumber,
      'roll_number': rollNumber,
      'current_class_id': currentClassId,
      'section_id': sectionId,
      'class_name': className,
      'section': section,
      'admission_date': admissionDate.toIso8601String().split('T').first,
      'academic_year': academicYear,
      'category': category,
      'blood_group': bloodGroup,
      'height': height,
      'weight': weight,
      'emergency_contact_phone': emergencyContactPhone,
      'current_address': currentAddress,
      'residential_address': residentialAddress,
      'permanent_address': permanentAddress,
      'enrollment_status': enrollmentStatus.name.toUpperCase(),
      'dob_certificate': dobCertificate,
      'transfer_certificate_id': transferCertificateId,
      'id_badge_issued': idBadgeIssued,
      'medium_of_instruction': mediumOfInstruction,
      'house_group': houseGroup,
      'second_language': secondLanguage,
      'bank_account_number': bankAccountNumber,
      'bank_name': bankName,
      'ifsc_code': ifscCode,
      'national_id_number': nationalIdNumber,
      'previous_school_name': previousSchoolName,
      'previous_school_address': previousSchoolAddress,
      'hostel_name': hostelName,
      'room_no': roomNo,
      'additional_details': additionalDetails,
    };
  }

  StudentProfileModel copyWith({
    String? id,
    String? userId,
    String? admissionNumber,
    String? rollNumber,
    String? currentClassId,
    String? sectionId,
    String? className,
    String? section,
    DateTime? admissionDate,
    String? academicYear,
    String? category,
    String? bloodGroup,
    String? height,
    String? weight,
    String? emergencyContactPhone,
    String? currentAddress,
    String? residentialAddress,
    String? permanentAddress,
    EnrollmentStatus? enrollmentStatus,
    String? dobCertificate,
    String? transferCertificateId,
    bool? idBadgeIssued,
    String? mediumOfInstruction,
    String? houseGroup,
    String? secondLanguage,
    String? bankAccountNumber,
    String? bankName,
    String? ifscCode,
    String? nationalIdNumber,
    String? previousSchoolName,
    String? previousSchoolAddress,
    String? hostelName,
    String? roomNo,
    String? additionalDetails,
  }) {
    return StudentProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      admissionNumber: admissionNumber ?? this.admissionNumber,
      rollNumber: rollNumber ?? this.rollNumber,
      currentClassId: currentClassId ?? this.currentClassId,
      sectionId: sectionId ?? this.sectionId,
      className: className ?? this.className,
      section: section ?? this.section,
      admissionDate: admissionDate ?? this.admissionDate,
      academicYear: academicYear ?? this.academicYear,
      category: category ?? this.category,
      bloodGroup: bloodGroup ?? this.bloodGroup,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      currentAddress: currentAddress ?? this.currentAddress,
      residentialAddress: residentialAddress ?? this.residentialAddress,
      permanentAddress: permanentAddress ?? this.permanentAddress,
      enrollmentStatus: enrollmentStatus ?? this.enrollmentStatus,
      dobCertificate: dobCertificate ?? this.dobCertificate,
      transferCertificateId: transferCertificateId ?? this.transferCertificateId,
      idBadgeIssued: idBadgeIssued ?? this.idBadgeIssued,
      mediumOfInstruction: mediumOfInstruction ?? this.mediumOfInstruction,
      houseGroup: houseGroup ?? this.houseGroup,
      secondLanguage: secondLanguage ?? this.secondLanguage,
      bankAccountNumber: bankAccountNumber ?? this.bankAccountNumber,
      bankName: bankName ?? this.bankName,
      ifscCode: ifscCode ?? this.ifscCode,
      nationalIdNumber: nationalIdNumber ?? this.nationalIdNumber,
      previousSchoolName: previousSchoolName ?? this.previousSchoolName,
      previousSchoolAddress: previousSchoolAddress ?? this.previousSchoolAddress,
      hostelName: hostelName ?? this.hostelName,
      roomNo: roomNo ?? this.roomNo,
      additionalDetails: additionalDetails ?? this.additionalDetails,
    );
  }
}
