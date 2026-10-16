class StaffCompensationModel {
  final double basicSalary;
  final String payFrequency;
  final String bankName;
  final String accountNumber;
  final String ifscCode;
  final String panNumber;
  final String? epfUan;

  const StaffCompensationModel({
    required this.basicSalary,
    this.payFrequency = 'Monthly',
    required this.bankName,
    required this.accountNumber,
    required this.ifscCode,
    required this.panNumber,
    this.epfUan,
  });

  /// Returns masked account number showing only last 4 digits (e.g. •••• •••• 4512)
  String get maskedAccountNumber {
    if (accountNumber.length <= 4) return accountNumber;
    final last4 = accountNumber.substring(accountNumber.length - 4);
    final maskedPrefix = '•••• ' * ((accountNumber.length - 4) ~/ 4).clamp(1, 3);
    return '$maskedPrefix$last4';
  }

  /// Returns masked PAN number showing only first 2 and last 2 characters (e.g. AB••••••1F)
  String get maskedPanNumber {
    if (panNumber.length <= 4) return panNumber;
    final prefix = panNumber.substring(0, 2);
    final suffix = panNumber.substring(panNumber.length - 2);
    return '$prefix••••••$suffix';
  }

  StaffCompensationModel copyWith({
    double? basicSalary,
    String? payFrequency,
    String? bankName,
    String? accountNumber,
    String? ifscCode,
    String? panNumber,
    String? epfUan,
  }) {
    return StaffCompensationModel(
      basicSalary: basicSalary ?? this.basicSalary,
      payFrequency: payFrequency ?? this.payFrequency,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifscCode: ifscCode ?? this.ifscCode,
      panNumber: panNumber ?? this.panNumber,
      epfUan: epfUan ?? this.epfUan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'basicSalary': basicSalary,
      'payFrequency': payFrequency,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'ifscCode': ifscCode,
      'panNumber': panNumber,
      'epfUan': epfUan,
    };
  }

  factory StaffCompensationModel.fromMap(Map<String, dynamic> map) {
    return StaffCompensationModel(
      basicSalary: (map['basicSalary'] as num?)?.toDouble() ?? 0.0,
      payFrequency: (map['payFrequency'] ?? 'Monthly').toString(),
      bankName: (map['bankName'] ?? '').toString(),
      accountNumber: (map['accountNumber'] ?? '').toString(),
      ifscCode: (map['ifscCode'] ?? '').toString(),
      panNumber: (map['panNumber'] ?? '').toString(),
      epfUan: map['epfUan']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffCompensationModel &&
          runtimeType == other.runtimeType &&
          basicSalary == other.basicSalary &&
          payFrequency == other.payFrequency &&
          bankName == other.bankName &&
          accountNumber == other.accountNumber &&
          ifscCode == other.ifscCode &&
          panNumber == other.panNumber &&
          epfUan == other.epfUan;

  @override
  int get hashCode =>
      basicSalary.hashCode ^
      payFrequency.hashCode ^
      bankName.hashCode ^
      accountNumber.hashCode ^
      ifscCode.hashCode ^
      panNumber.hashCode ^
      epfUan.hashCode;
}
