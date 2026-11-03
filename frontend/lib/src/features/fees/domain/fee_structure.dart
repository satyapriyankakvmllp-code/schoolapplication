import 'money.dart';

/// Represents the fee breakdown configured for a specific class and academic term.
/// Persisted in backend "Module 5 Finance" collection `fee_structures`.
class FeeStructure {
  final String id;
  final String className;
  final String termName;
  final String academicYear;
  final double tuitionFee;
  final double labComputerFee;
  final double developmentFee;
  final double otherFee;
  final double totalFee;
  final String dueDate;
  final bool isActive;
  final String createdAt;
  final String updatedAt;

  const FeeStructure({
    required this.id,
    required this.className,
    required this.termName,
    required this.academicYear,
    required this.tuitionFee,
    required this.labComputerFee,
    required this.developmentFee,
    required this.otherFee,
    required this.totalFee,
    required this.dueDate,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  // Integer paise representations for calculations
  int get tuitionPaise => Money.rupeesToPaise(tuitionFee);
  int get labComputerPaise => Money.rupeesToPaise(labComputerFee);
  int get developmentPaise => Money.rupeesToPaise(developmentFee);
  int get otherPaise => Money.rupeesToPaise(otherFee);
  int get totalPaise => Money.rupeesToPaise(totalFee);

  FeeStructure copyWith({
    String? id,
    String? className,
    String? termName,
    String? academicYear,
    double? tuitionFee,
    double? labComputerFee,
    double? developmentFee,
    double? otherFee,
    double? totalFee,
    String? dueDate,
    bool? isActive,
    String? createdAt,
    String? updatedAt,
  }) {
    return FeeStructure(
      id: id ?? this.id,
      className: className ?? this.className,
      termName: termName ?? this.termName,
      academicYear: academicYear ?? this.academicYear,
      tuitionFee: tuitionFee ?? this.tuitionFee,
      labComputerFee: labComputerFee ?? this.labComputerFee,
      developmentFee: developmentFee ?? this.developmentFee,
      otherFee: otherFee ?? this.otherFee,
      totalFee: totalFee ?? this.totalFee,
      dueDate: dueDate ?? this.dueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory FeeStructure.fromJson(Map<String, dynamic> json) {
    return FeeStructure(
      id: (json['id'] ?? '').toString(),
      className: (json['class_name'] ?? '').toString(),
      termName: (json['term_name'] ?? '').toString(),
      academicYear: (json['academic_year'] ?? '').toString(),
      tuitionFee: (json['tuition_fee'] is num)
          ? (json['tuition_fee'] as num).toDouble()
          : double.tryParse(json['tuition_fee']?.toString() ?? '0') ?? 0.0,
      labComputerFee: (json['lab_computer_fee'] is num)
          ? (json['lab_computer_fee'] as num).toDouble()
          : double.tryParse(json['lab_computer_fee']?.toString() ?? '0') ?? 0.0,
      developmentFee: (json['development_fee'] is num)
          ? (json['development_fee'] as num).toDouble()
          : double.tryParse(json['development_fee']?.toString() ?? '0') ?? 0.0,
      otherFee: (json['other_fee'] is num)
          ? (json['other_fee'] as num).toDouble()
          : double.tryParse(json['other_fee']?.toString() ?? '0') ?? 0.0,
      totalFee: (json['total_fee'] is num)
          ? (json['total_fee'] as num).toDouble()
          : double.tryParse(json['total_fee']?.toString() ?? '0') ?? 0.0,
      dueDate: (json['due_date'] ?? '').toString(),
      isActive: json['is_active'] == true,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'class_name': className,
      'term_name': termName,
      'academic_year': academicYear,
      'tuition_fee': tuitionFee,
      'lab_computer_fee': labComputerFee,
      'development_fee': developmentFee,
      'other_fee': otherFee,
      'total_fee': totalFee,
      'due_date': dueDate,
      'is_active': isActive,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FeeStructure &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          className == other.className &&
          termName == other.termName &&
          academicYear == other.academicYear &&
          tuitionFee == other.tuitionFee &&
          labComputerFee == other.labComputerFee &&
          developmentFee == other.developmentFee &&
          otherFee == other.otherFee &&
          totalFee == other.totalFee &&
          dueDate == other.dueDate &&
          isActive == other.isActive;

  @override
  int get hashCode => Object.hash(
        id,
        className,
        termName,
        academicYear,
        tuitionFee,
        labComputerFee,
        developmentFee,
        otherFee,
        totalFee,
        dueDate,
        isActive,
      );
}

