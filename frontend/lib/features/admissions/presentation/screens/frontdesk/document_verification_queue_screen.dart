import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/frontdesk_controller.dart';

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

  void _showDocumentPreviewDialog(BuildContext context, ApplicantDocumentItem doc) {
    final isDark = widget.isDark;

    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: const EdgeInsets.all(16),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 620),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.file_present_rounded, color: Color(0xFF3B82F6)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            doc.documentType,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Applicant: ${doc.applicantName} (${doc.grade}) • ID: ${doc.applicantId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
                  ],
                ),
                const SizedBox(height: 16),
                // Simulated Document Canvas Preview
                Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.picture_as_pdf_outlined, size: 48, color: Color(0xFFEF4444)),
                        const SizedBox(height: 10),
                        Text(
                          doc.fileName,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${doc.fileSize} • Uploaded ${doc.uploadedAt.day}/${doc.uploadedAt.month}/${doc.uploadedAt.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (doc.rejectionReason != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Rejection Reason: ${doc.rejectionReason}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject Document'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        _showRejectReasonDialog(context, doc.id);
                      },
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve & Mark Verified'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(documentQueueProvider.notifier).approveDocument(doc.id);
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Document approved & verified successfully!'),
                            backgroundColor: Color(0xFF10B981),
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
  }

  void _showRejectReasonDialog(BuildContext context, String docId) {
    final reasonCtrl = TextEditingController(text: 'Blurry scan; missing official school stamp.');

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
                ref.read(documentQueueProvider.notifier).rejectDocument(docId, reasonCtrl.text.trim());
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
                      'Screen uploaded student certificates, verify seals & approve for enrollment',
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.description_outlined, color: statusColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doc.documentType,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'Applicant: ${doc.applicantName} • ${doc.grade} • ${doc.fileName} (${doc.fileSize})',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
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
            Text(
              'Reason: ${doc.rejectionReason}',
              style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.remove_red_eye_outlined, size: 14),
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
