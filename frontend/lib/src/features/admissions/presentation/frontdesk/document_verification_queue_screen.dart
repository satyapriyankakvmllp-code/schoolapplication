import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/frontdesk_controller.dart';
import '../../../staff/application/staff_auth_controller.dart';

class DocumentVerificationQueueScreen extends ConsumerStatefulWidget {
  final bool isDark;

  const DocumentVerificationQueueScreen({
    super.key,
    required this.isDark,
  });

  @override
  ConsumerState<DocumentVerificationQueueScreen> createState() => _DocumentVerificationQueueScreenState();
}

class _DocumentVerificationQueueScreenState extends ConsumerState<DocumentVerificationQueueScreen> {
  DocVerifyStatus? _selectedStatusFilter;

  bool _isDocumentAPhoto(ApplicantDocumentItem doc) {
    final type = doc.documentType.toLowerCase();
    final file = doc.fileName.toLowerCase();
    if (type.contains('photo') || type.contains('photograph') || type.contains('portrait')) {
      return true;
    }
    if (file.endsWith('.jpg') || file.endsWith('.jpeg') || file.endsWith('.png')) {
      if (!type.contains('certificate') && !type.contains('proof') && !type.contains('bill')) {
        return true;
      }
    }
    return false;
  }

  bool _isImageDoc(ApplicantDocumentItem doc) {
    if (doc.fileBytes != null && doc.fileBytes!.isNotEmpty) {
      final bytes = doc.fileBytes!;
      if (bytes.length >= 4 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47) return true; // PNG
      if (bytes.length >= 3 && bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) return true; // JPEG
      if (bytes.length >= 3 && bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46) return true; // GIF
      if (bytes.length >= 12 && bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46) return true; // WEBP
    }
    final lower = doc.fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp');
  }

  bool _isPdfDoc(ApplicantDocumentItem doc) {
    if (doc.fileBytes != null && doc.fileBytes!.isNotEmpty) {
      final bytes = doc.fileBytes!;
      if (bytes.length >= 4 && bytes[0] == 0x25 && bytes[1] == 0x50 && bytes[2] == 0x44 && bytes[3] == 0x46) return true; // %PDF
    }
    return doc.fileName.toLowerCase().endsWith('.pdf');
  }

  Future<void> _pickAndUploadDocument(
    BuildContext context,
    String docId,
    VoidCallback onUpdated,
  ) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'webp'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        if (picked.bytes != null && picked.bytes!.isNotEmpty) {
          final sizeKb = picked.size / 1024;
          final sizeStr = sizeKb > 1024
              ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
              : '${sizeKb.toStringAsFixed(0)} KB';
          ref.read(documentQueueProvider.notifier).updateDocumentFile(
                docId,
                fileName: picked.name,
                bytes: picked.bytes!,
                fileSize: sizeStr,
              );
          onUpdated();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Attached original file: ${picked.name} ($sizeStr)'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick file: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  void _showDocumentPreviewDialog(BuildContext context, ApplicantDocumentItem doc) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final loggedInStaff = ref.read(currentLoggedInStaffProvider);
    final officerName = loggedInStaff?.fullName ?? 'Priya Sharma (Senior Admissions Officer)';

    double zoomLevel = 1.0;
    int rotationTurns = 0;
    String selectedRejectReason = 'Blurry scan; illegible text or official seal.';
    final customReasonController = TextEditingController(text: selectedRejectReason);

    final quickRejectOptions = [
      'Blurry scan; illegible text or official seal.',
      'Missing official rubber stamp or registrar seal.',
      'Applicant name or DOB mismatch with admissions form.',
      'Incomplete certificate; margins or clauses cut off.',
      'Expired utility bill / invalid residence proof.',
    ];

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            final allDocs = ref.watch(documentQueueProvider);
            final currentDoc = allDocs.firstWhere((d) => d.id == doc.id, orElse: () => doc);
            final isPhoto = _isDocumentAPhoto(currentDoc);

            return Dialog(
              backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              insetPadding: EdgeInsets.symmetric(
                horizontal: isMobile ? 12 : 24,
                vertical: isMobile ? 16 : 24,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 720,
                  maxHeight: MediaQuery.sizeOf(context).height * 0.94,
                ),
                padding: EdgeInsets.all(isMobile ? 16 : 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // --- Modal Header ---
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (isPhoto ? const Color(0xFF8B5CF6) : const Color(0xFF10B981))
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isPhoto ? Icons.portrait_rounded : Icons.verified_user_rounded,
                            color: isPhoto ? const Color(0xFF8B5CF6) : const Color(0xFF10B981),
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      currentDoc.documentType,
                                      style: TextStyle(
                                        fontSize: isMobile ? 16 : 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildStatusBadge(currentDoc.status),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Applicant: ${currentDoc.applicantName} • ${currentDoc.grade} • Ref: ${currentDoc.applicantId}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          color: isDark ? Colors.white70 : Colors.black54,
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // --- Interactive Inspection Toolbar ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                        ),
                      ),
                      child: Wrap(
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          // Zoom controls
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: zoomLevel > 0.8
                                    ? () => setDialogState(() => zoomLevel = (zoomLevel - 0.25).clamp(0.75, 2.0))
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.zoom_out, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${(zoomLevel * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: zoomLevel < 2.0
                                    ? () => setDialogState(() => zoomLevel = (zoomLevel + 0.25).clamp(0.75, 2.0))
                                    : null,
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(Icons.zoom_in, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Rotate tool
                              InkWell(
                                onTap: () => setDialogState(() => rotationTurns = (rotationTurns + 1) % 4),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.rotate_right, size: 18, color: isDark ? Colors.white70 : Colors.black87),
                                      const SizedBox(width: 4),
                                      Text('${rotationTurns * 90}°', style: const TextStyle(fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Reset tool
                              if (zoomLevel != 1.0 || rotationTurns != 0)
                                TextButton(
                                  onPressed: () => setDialogState(() {
                                    zoomLevel = 1.0;
                                    rotationTurns = 0;
                                  }),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text('Reset', style: TextStyle(fontSize: 11)),
                                ),
                            ],
                          ),
                          // Attach / Replace File Button
                          ElevatedButton.icon(
                            icon: const Icon(Icons.upload_file_rounded, size: 14),
                            label: Text(
                              currentDoc.fileBytes != null ? 'Replace File' : 'Upload File',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B82F6),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: () {
                              _pickAndUploadDocument(context, currentDoc.id, () {
                                setDialogState(() {});
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- Scrollable Original Document / Real File Preview ---
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF090D16) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade300,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: InteractiveViewer(
                            boundaryMargin: const EdgeInsets.all(20),
                            minScale: 0.8,
                            maxScale: 2.5,
                            child: Center(
                              child: SingleChildScrollView(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.all(16),
                                child: Transform.rotate(
                                  angle: rotationTurns * (math.pi / 2),
                                  child: Transform.scale(
                                    scale: zoomLevel,
                                    child: _buildOriginalDocumentViewer(
                                      context: context,
                                      doc: currentDoc,
                                      isDark: isDark,
                                      isMobile: isMobile,
                                      onAttachFile: () {
                                        _pickAndUploadDocument(context, currentDoc.id, () {
                                          setDialogState(() {});
                                        });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // --- File Metadata & Status Information Strip ---
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPhoto ? Icons.image_rounded : Icons.file_present_rounded,
                            size: 16,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'File: ${currentDoc.fileName} (${currentDoc.fileSize}) • Uploaded: ${currentDoc.uploadedAt.day}/${currentDoc.uploadedAt.month}/${currentDoc.uploadedAt.year}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (currentDoc.reviewedBy != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              'Reviewed by: ${currentDoc.reviewedBy}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: currentDoc.status == DocVerifyStatus.verified
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (currentDoc.rejectionReason != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Current Rejection Note: ${currentDoc.rejectionReason}',
                                style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // --- Quick Rejection Reason Chips ---
                    Text(
                      'Rejection Pre-Check Tags (click to set reason):',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: quickRejectOptions.map((opt) {
                          final isSelected = selectedRejectReason == opt;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: ChoiceChip(
                              label: Text(opt.split(';').first),
                              selected: isSelected,
                              selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              onSelected: (_) {
                                setDialogState(() {
                                  selectedRejectReason = opt;
                                  customReasonController.text = opt;
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- Action Buttons ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject Document'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFEF4444),
                            side: const BorderSide(color: Color(0xFFEF4444)),
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 12 : 16,
                              vertical: isMobile ? 10 : 12,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            _showRejectReasonDialog(context, currentDoc.id, prefill: customReasonController.text);
                          },
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('Approve & Mark Verified'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isMobile ? 14 : 20,
                              vertical: isMobile ? 10 : 12,
                            ),
                          ),
                          onPressed: () {
                            ref.read(documentQueueProvider.notifier).approveDocument(
                                  currentDoc.id,
                                  officerName: officerName,
                                );
                            Navigator.of(ctx).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('"${currentDoc.documentType}" for ${currentDoc.applicantName} marked as Verified by $officerName!'),
                                backgroundColor: const Color(0xFF10B981),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --------------------------------------------------------------------------
  // Original Document Viewer (Strictly Real Scans/Photos, Zero Fake Vectors)
  // --------------------------------------------------------------------------
  Widget _buildOriginalDocumentViewer({
    required BuildContext context,
    required ApplicantDocumentItem doc,
    required bool isDark,
    required bool isMobile,
    required VoidCallback onAttachFile,
  }) {
    // 1. If raw uploaded file bytes are available (real image uploaded by user/staff)
    if (doc.fileBytes != null && doc.fileBytes!.isNotEmpty) {
      if (_isImageDoc(doc)) {
        return Container(
          constraints: BoxConstraints(
            maxWidth: isMobile ? 360 : 560,
            maxHeight: isMobile ? 420 : 500,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.memory(
              doc.fileBytes!,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => _buildPdfOrRawDocCard(
                doc: doc,
                isDark: isDark,
                isMobile: isMobile,
                onUpload: onAttachFile,
              ),
            ),
          ),
        );
      } else {
        // PDF or binary document format with raw bytes
        return _buildPdfOrRawDocCard(
          doc: doc,
          isDark: isDark,
          isMobile: isMobile,
          onUpload: onAttachFile,
        );
      }
    }

    // 2. If no raw bytes exist yet (e.g. legacy demo records)
    return _buildNoFileBytesCard(
      doc: doc,
      isDark: isDark,
      isMobile: isMobile,
      onUpload: onAttachFile,
    );
  }

  Widget _buildPdfOrRawDocCard({
    required ApplicantDocumentItem doc,
    required bool isDark,
    required bool isMobile,
    required VoidCallback onUpload,
  }) {
    final isPdf = _isPdfDoc(doc);
    final sizeKb = (doc.fileBytes?.lengthInBytes ?? 0) ~/ 1024;
    final sizeText = sizeKb > 0 ? '$sizeKb KB' : doc.fileSize;

    return Container(
      width: isMobile ? 320 : 440,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPdf ? const Color(0xFFEF4444).withValues(alpha: 0.5) : const Color(0xFF3B82F6).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6)).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPdf ? Icons.picture_as_pdf_rounded : Icons.file_present_rounded,
              size: 44,
              color: isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isPdf ? 'ORIGINAL PDF DOCUMENT SCAN' : 'ORIGINAL DOCUMENT FILE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: isPdf ? const Color(0xFFEF4444) : const Color(0xFF3B82F6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            doc.fileName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${doc.documentType} • $sizeText',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildInfoRow('Applicant Name', doc.applicantName, isDark),
                const SizedBox(height: 6),
                _buildInfoRow('Applied Grade', doc.grade, isDark),
                const SizedBox(height: 6),
                _buildInfoRow('Upload Timestamp', '${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}', isDark),
                const SizedBox(height: 6),
                _buildInfoRow('Verification Status', doc.status.displayName, isDark),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.upload_file_rounded, size: 15),
                label: const Text('Replace with Image / PDF', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF3B82F6),
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onPressed: onUpload,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoFileBytesCard({
    required ApplicantDocumentItem doc,
    required bool isDark,
    required bool isMobile,
    required VoidCallback onUpload,
  }) {
    return Container(
      width: isMobile ? 320 : 440,
      padding: EdgeInsets.all(isMobile ? 18 : 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.file_upload_outlined,
              size: 44,
              color: Color(0xFFF59E0B),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'ORIGINAL DOCUMENT SCAN PENDING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.8,
              color: Color(0xFFF59E0B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            doc.documentType,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Expected File: ${doc.fileName} (${doc.fileSize})',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
            ),
            child: Column(
              children: [
                _buildInfoRow('Applicant Name', doc.applicantName, isDark),
                const SizedBox(height: 6),
                _buildInfoRow('Applied Grade', doc.grade, isDark),
                const SizedBox(height: 6),
                _buildInfoRow('Intake Mode', 'Record logged from Front-Desk', isDark),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Upload the original certificate or photo given by the user/parent to verify authenticity.',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.cloud_upload_rounded, size: 16),
            label: const Text('Attach / Upload Original Document Scan'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(DocVerifyStatus status) {
    Color color;
    switch (status) {
      case DocVerifyStatus.verified:
        color = const Color(0xFF10B981);
        break;
      case DocVerifyStatus.rejected:
        color = const Color(0xFFEF4444);
        break;
      case DocVerifyStatus.pending:
        color = const Color(0xFFF59E0B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.displayName,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  void _showRejectReasonDialog(BuildContext context, String docId, {String? prefill}) {
    final reasonCtrl = TextEditingController(text: prefill ?? 'Blurry scan; missing official school stamp.');

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: widget.isDark ? const Color(0xFF0F172A) : Colors.white,
          title: const Text('Reason for Rejection'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This message will be visible to the parent for re-uploading:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
              onPressed: () {
                final loggedInStaff = ref.read(currentLoggedInStaffProvider);
                final officerName = loggedInStaff?.fullName ?? 'Priya Sharma (Senior Admissions Officer)';
                ref.read(documentQueueProvider.notifier).rejectDocument(
                      docId,
                      reasonCtrl.text.trim(),
                      officerName: officerName,
                    );
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Document rejected. Parent notified for re-upload.'),
                    backgroundColor: Color(0xFFEF4444),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Confirm Rejection'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final documents = ref.watch(documentQueueProvider);
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final filtered = _selectedStatusFilter == null
        ? documents
        : documents.where((d) => d.status == _selectedStatusFilter).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Document Verification Queue',
                      style: TextStyle(
                        fontSize: isMobile ? 18 : 22,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Screen uploaded student photos & certificates, verify seals & approve for enrollment',
                      style: TextStyle(
                        fontSize: isMobile ? 11 : 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Status filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Documents', null),
                const SizedBox(width: 8),
                _buildFilterChip('Pending Verification', DocVerifyStatus.pending),
                const SizedBox(width: 8),
                _buildFilterChip('Verified & Approved', DocVerifyStatus.verified),
                const SizedBox(width: 8),
                _buildFilterChip('Rejected', DocVerifyStatus.rejected),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Document list items
          if (filtered.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.folder_open_rounded, size: 48, color: isDark ? Colors.white30 : Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'No documents found in this queue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Submitted intake documents and student photos will appear here automatically.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((doc) => _buildDocCard(doc, isDark, isMobile)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DocVerifyStatus? status) {
    final isSelected = _selectedStatusFilter == status;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.25),
      backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF3B82F6) : (widget.isDark ? Colors.white70 : Colors.black87),
      ),
      onSelected: (_) => setState(() => _selectedStatusFilter = status),
    );
  }

  Widget _buildDocCard(ApplicantDocumentItem doc, bool isDark, bool isMobile) {
    Color statusColor;
    switch (doc.status) {
      case DocVerifyStatus.verified:
        statusColor = const Color(0xFF10B981);
        break;
      case DocVerifyStatus.rejected:
        statusColor = const Color(0xFFEF4444);
        break;
      case DocVerifyStatus.pending:
        statusColor = const Color(0xFFF59E0B);
        break;
    }

    final isPhoto = _isDocumentAPhoto(doc);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Real uploaded image or document thumbnail
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: (isPhoto ? const Color(0xFF8B5CF6) : statusColor).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (isPhoto ? const Color(0xFF8B5CF6) : statusColor).withValues(alpha: 0.3),
                  ),
                ),
                child: (doc.fileBytes != null && doc.fileBytes!.isNotEmpty && _isImageDoc(doc))
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.memory(
                          doc.fileBytes!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Icon(
                            _isPdfDoc(doc) ? Icons.picture_as_pdf_rounded : Icons.description_outlined,
                            color: statusColor,
                            size: 22,
                          ),
                        ),
                      )
                    : (_isPdfDoc(doc)
                        ? const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 22)
                        : (isPhoto
                            ? const Icon(Icons.portrait_rounded, color: Color(0xFF8B5CF6), size: 24)
                            : Icon(Icons.description_outlined, color: statusColor, size: 22))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            doc.documentType,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPhoto) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'PHOTO',
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Applicant: ${doc.applicantName} • ${doc.grade} • ${doc.fileName} (${doc.fileSize})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  doc.status.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          if (doc.rejectionReason != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Reason: ${doc.rejectionReason}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.remove_red_eye_rounded, size: 14),
                label: const Text('Inspect & Review Document', style: TextStyle(fontSize: 12)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => _showDocumentPreviewDialog(context, doc),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
