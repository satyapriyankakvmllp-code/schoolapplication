class ParentProfileModel {
  final String id;
  final String userId;
  final String fullName;
  final String relationship; // Father, Mother, Guardian, Others
  final String phoneNumber;
  final String? email;
  final String? occupation;
  final String? photoUrl;
  final String residentialAddress;
  final String preferredLanguage;
  final String? billingEmail;

  const ParentProfileModel({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.relationship,
    required this.phoneNumber,
    this.email,
    this.occupation,
    this.photoUrl,
    required this.residentialAddress,
    this.preferredLanguage = 'en',
    this.billingEmail,
  });

  factory ParentProfileModel.fromJson(Map<String, dynamic> json) {
    return ParentProfileModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      relationship: json['relationship'] as String? ?? 'Guardian',
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String?,
      occupation: json['occupation'] as String?,
      photoUrl: json['photo_url'] as String?,
      residentialAddress: json['residential_address'] as String? ?? '',
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      billingEmail: json['billing_email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'full_name': fullName,
      'relationship': relationship,
      'phone_number': phoneNumber,
      'email': email,
      'occupation': occupation,
      'photo_url': photoUrl,
      'residential_address': residentialAddress,
      'preferred_language': preferredLanguage,
      'billing_email': billingEmail,
    };
  }
}
