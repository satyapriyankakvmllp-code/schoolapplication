class AdmissionDocumentModel {
  final String id;
  final String title;
  final String fileName;
  final String? fileUrl;
  final String fileSize;
  final String fileType; // pdf, image, etc.
  final bool isVerified;
  final DateTime uploadedAt;

  const AdmissionDocumentModel({
    required this.id,
    required this.title,
    required this.fileName,
    this.fileUrl,
    required this.fileSize,
    required this.fileType,
    this.isVerified = false,
    required this.uploadedAt,
  });

  factory AdmissionDocumentModel.fromJson(Map<String, dynamic> json) {
    return AdmissionDocumentModel(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Document',
      fileName: json['file_name'] as String? ?? 'file.pdf',
      fileUrl: json['file_url'] as String?,
      fileSize: json['file_size'] as String? ?? '1.2 MB',
      fileType: json['file_type'] as String? ?? 'pdf',
      isVerified: json['is_verified'] as bool? ?? false,
      uploadedAt: json['uploaded_at'] != null
          ? DateTime.tryParse(json['uploaded_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'file_name': fileName,
      'file_url': fileUrl,
      'file_size': fileSize,
      'file_type': fileType,
      'is_verified': isVerified,
      'uploaded_at': uploadedAt.toIso8601String(),
    };
  }
}
