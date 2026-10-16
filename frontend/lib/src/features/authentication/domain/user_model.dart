enum UserRole {
  admin,
  teacher,
  student,
  parent,
  admissions,
  finance;

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.teacher:
        return 'Teacher';
      case UserRole.student:
        return 'Student';
      case UserRole.parent:
        return 'Parent';
      case UserRole.admissions:
        return 'Admissions';
      case UserRole.finance:
        return 'Finance';
    }
  }

  static UserRole fromString(String? role) {
    switch (role?.toUpperCase()) {
      case 'ADMIN':
        return UserRole.admin;
      case 'TEACHER':
        return UserRole.teacher;
      case 'STUDENT':
        return UserRole.student;
      case 'PARENT':
        return UserRole.parent;
      case 'ADMISSIONS':
        return UserRole.admissions;
      case 'FINANCE':
        return UserRole.finance;
      default:
        return UserRole.student;
    }
  }
}

enum Gender {
  male,
  female,
  other;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }

  static Gender? fromString(String? gender) {
    if (gender == null) return null;
    switch (gender.toUpperCase()) {
      case 'MALE':
        return Gender.male;
      case 'FEMALE':
        return Gender.female;
      case 'OTHER':
        return Gender.other;
      default:
        return null;
    }
  }
}

enum AccountStatus {
  active,
  inactive,
  suspended,
  archived;

  String get displayName {
    switch (this) {
      case AccountStatus.active:
        return 'Active';
      case AccountStatus.inactive:
        return 'Inactive';
      case AccountStatus.suspended:
        return 'Suspended';
      case AccountStatus.archived:
        return 'Archived';
    }
  }

  static AccountStatus fromString(String? status) {
    switch (status?.toUpperCase()) {
      case 'INACTIVE':
        return AccountStatus.inactive;
      case 'SUSPENDED':
        return AccountStatus.suspended;
      case 'ARCHIVED':
        return AccountStatus.archived;
      case 'ACTIVE':
      default:
        return AccountStatus.active;
    }
  }
}

class UserModel {
  final String id;
  final String email;
  final String phoneNumber;
  final String? passwordHash;
  final UserRole userRole;
  final String firstName;
  final String lastName;
  final String? profilePhotoUrl;
  final Gender? gender;
  final DateTime? dateOfBirth;
  final AccountStatus status;
  final DateTime? lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.phoneNumber,
    this.passwordHash,
    required this.userRole,
    required this.firstName,
    required this.lastName,
    this.profilePhotoUrl,
    this.gender,
    this.dateOfBirth,
    this.status = AccountStatus.active,
    this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String? ?? '',
      phoneNumber: json['phone_number'] as String? ?? '',
      passwordHash: json['password_hash'] as String?,
      userRole: UserRole.fromString(json['user_role'] as String?),
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      profilePhotoUrl: json['profile_photo_url'] as String?,
      gender: Gender.fromString(json['gender'] as String?),
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'] as String)
          : null,
      status: AccountStatus.fromString(json['status'] as String?),
      lastLoginAt: json['last_login_at'] != null
          ? DateTime.tryParse(json['last_login_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone_number': phoneNumber,
      'password_hash': passwordHash,
      'user_role': userRole.name.toUpperCase(),
      'first_name': firstName,
      'last_name': lastName,
      'profile_photo_url': profilePhotoUrl,
      'gender': gender?.name.toUpperCase(),
      'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
      'status': status.name.toUpperCase(),
      'last_login_at': lastLoginAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? phoneNumber,
    String? passwordHash,
    UserRole? userRole,
    String? firstName,
    String? lastName,
    String? profilePhotoUrl,
    Gender? gender,
    DateTime? dateOfBirth,
    AccountStatus? status,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      passwordHash: passwordHash ?? this.passwordHash,
      userRole: userRole ?? this.userRole,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profilePhotoUrl: profilePhotoUrl ?? this.profilePhotoUrl,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      status: status ?? this.status,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
