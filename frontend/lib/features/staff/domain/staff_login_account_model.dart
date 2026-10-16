class StaffLoginAccountModel {
  final bool isEnabled;
  final String institutionalEmail;
  final String? temporaryPassword;
  final String systemRole; // 'teacher', 'admin', 'frontDesk'
  final bool isFirstLoginPasswordChangeRequired;

  const StaffLoginAccountModel({
    this.isEnabled = true,
    required this.institutionalEmail,
    this.temporaryPassword,
    this.systemRole = 'teacher',
    this.isFirstLoginPasswordChangeRequired = true,
  });

  StaffLoginAccountModel copyWith({
    bool? isEnabled,
    String? institutionalEmail,
    String? temporaryPassword,
    String? systemRole,
    bool? isFirstLoginPasswordChangeRequired,
  }) {
    return StaffLoginAccountModel(
      isEnabled: isEnabled ?? this.isEnabled,
      institutionalEmail: institutionalEmail ?? this.institutionalEmail,
      temporaryPassword: temporaryPassword ?? this.temporaryPassword,
      systemRole: systemRole ?? this.systemRole,
      isFirstLoginPasswordChangeRequired:
          isFirstLoginPasswordChangeRequired ?? this.isFirstLoginPasswordChangeRequired,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'institutionalEmail': institutionalEmail,
      'temporaryPassword': temporaryPassword,
      'systemRole': systemRole,
      'isFirstLoginPasswordChangeRequired': isFirstLoginPasswordChangeRequired,
    };
  }

  factory StaffLoginAccountModel.fromMap(Map<String, dynamic> map) {
    return StaffLoginAccountModel(
      isEnabled: map['isEnabled'] ?? true,
      institutionalEmail: (map['institutionalEmail'] ?? '').toString(),
      temporaryPassword: map['temporaryPassword']?.toString(),
      systemRole: (map['systemRole'] ?? 'teacher').toString(),
      isFirstLoginPasswordChangeRequired:
          map['isFirstLoginPasswordChangeRequired'] ?? true,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffLoginAccountModel &&
          runtimeType == other.runtimeType &&
          isEnabled == other.isEnabled &&
          institutionalEmail == other.institutionalEmail &&
          temporaryPassword == other.temporaryPassword &&
          systemRole == other.systemRole &&
          isFirstLoginPasswordChangeRequired ==
              other.isFirstLoginPasswordChangeRequired;

  @override
  int get hashCode =>
      isEnabled.hashCode ^
      institutionalEmail.hashCode ^
      temporaryPassword.hashCode ^
      systemRole.hashCode ^
      isFirstLoginPasswordChangeRequired.hashCode;
}
