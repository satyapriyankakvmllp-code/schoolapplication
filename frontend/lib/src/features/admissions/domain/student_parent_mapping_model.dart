enum RelationshipType {
  father,
  mother,
  legalGuardian,
  other;

  String get displayName {
    switch (this) {
      case RelationshipType.father:
        return 'Father';
      case RelationshipType.mother:
        return 'Mother';
      case RelationshipType.legalGuardian:
        return 'Legal Guardian';
      case RelationshipType.other:
        return 'Other';
    }
  }

  static RelationshipType fromString(String? type) {
    switch (type?.toUpperCase()) {
      case 'FATHER':
        return RelationshipType.father;
      case 'MOTHER':
        return RelationshipType.mother;
      case 'LEGAL_GUARDIAN':
      case 'GUARDIAN':
        return RelationshipType.legalGuardian;
      default:
        return RelationshipType.other;
    }
  }
}

class StudentParentMappingModel {
  final String id;
  final String studentId;
  final String parentId;
  final RelationshipType relationshipType;
  final bool isPrimaryContact;
  final bool isFeePayer;

  const StudentParentMappingModel({
    required this.id,
    required this.studentId,
    required this.parentId,
    required this.relationshipType,
    this.isPrimaryContact = false,
    this.isFeePayer = false,
  });

  factory StudentParentMappingModel.fromJson(Map<String, dynamic> json) {
    return StudentParentMappingModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? '',
      relationshipType: RelationshipType.fromString(json['relationship_type'] as String?),
      isPrimaryContact: json['is_primary_contact'] as bool? ?? false,
      isFeePayer: json['is_fee_payer'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'parent_id': parentId,
      'relationship_type': relationshipType.name.toUpperCase(),
      'is_primary_contact': isPrimaryContact,
      'is_fee_payer': isFeePayer,
    };
  }
}
