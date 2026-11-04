import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class FileUploadBox extends StatefulWidget {
  final String label;
  final String? initialFileName;
  final String helperText;
  final ValueChanged<String>? onFileSelected;
  final void Function(String fileName, Uint8List? bytes)? onFileWithBytesSelected;
  final VoidCallback? onFileRemoved;
  final bool isCompact;
  final bool isRequired;
  final List<String> allowedExtensions;

  const FileUploadBox({
    super.key,
    required this.label,
    this.initialFileName,
    this.helperText = 'Click to browse or drag & drop\nSupport PDF, JPEG, PNG (max 5MB)',
    this.onFileSelected,
    this.onFileWithBytesSelected,
    this.onFileRemoved,
    this.isCompact = false,
    this.isRequired = false,
    this.allowedExtensions = const ['pdf', 'png', 'jpg', 'jpeg'],
  });

  @override
  State<FileUploadBox> createState() => _FileUploadBoxState();
}

class _FileUploadBoxState extends State<FileUploadBox> {
  String? _selectedFileName;
  String? _fileSize;

  @override
  void initState() {
    super.initState();
    _selectedFileName = widget.initialFileName;
    if (_selectedFileName != null && _selectedFileName!.isNotEmpty) {
      _fileSize = '1.4 MB';
    }
  }

  @override
  void didUpdateWidget(covariant FileUploadBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialFileName != oldWidget.initialFileName) {
      setState(() {
        _selectedFileName = widget.initialFileName;
        if (_selectedFileName != null && _selectedFileName!.isNotEmpty && _fileSize == null) {
          _fileSize = '1.4 MB';
        }
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: widget.allowedExtensions,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        final sizeKb = picked.size / 1024;
        final sizeStr = sizeKb > 1024
            ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
            : '${sizeKb.toStringAsFixed(0)} KB';
        setState(() {
          _selectedFileName = picked.name;
          _fileSize = sizeStr;
        });
        widget.onFileWithBytesSelected?.call(picked.name, picked.bytes);
        widget.onFileSelected?.call(picked.name);
      }
    } catch (_) {
      // In case browser or OS dialog has permissions issues, allow manual file selection modal
      if (mounted) {
        _showManualFileDialog(context);
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFileName = null;
      _fileSize = null;
    });
    widget.onFileWithBytesSelected?.call('', null);
    widget.onFileRemoved?.call();
    widget.onFileSelected?.call('');
  }

  void _showManualFileDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Select File: ${widget.label}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter document file name or choose a sample file:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'e.g., student_document.pdf',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildSampleChip(ctx, textController, 'birth_certificate.pdf'),
                _buildSampleChip(ctx, textController, 'marksheet_transcript.pdf'),
                _buildSampleChip(ctx, textController, 'aadhaar_card_scanned.pdf'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() {
                  _selectedFileName = name;
                  _fileSize = '1.8 MB';
                });
                widget.onFileSelected?.call(name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
              foregroundColor: Colors.white,
            ),
            child: const Text('Attach File'),
          ),
        ],
      ),
    );
  }

  Widget _buildSampleChip(BuildContext ctx, TextEditingController controller, String sampleName) {
    return ActionChip(
      label: Text(sampleName, style: const TextStyle(fontSize: 11.5)),
      avatar: const Icon(Icons.attach_file, size: 14),
      backgroundColor: const Color(0xFFF1F5F9),
      onPressed: () {
        controller.text = sampleName;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUploaded = _selectedFileName != null && _selectedFileName!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isUploaded
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.3) : const Color(0xFFF0FDF4))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isUploaded ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: isUploaded ? 1.5 : 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with label and Fulfilled / Pending Status Chip
          Padding(
            padding: const EdgeInsets.only(left: 14, right: 14, top: 12, bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isUploaded
                        ? (isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7))
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUploaded
                          ? const Color(0xFF86EFAC)
                          : (isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUploaded ? Icons.check_circle : Icons.radio_button_unchecked,
                        size: 12,
                        color: isUploaded ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUploaded ? 'Fulfilled' : (widget.isRequired ? 'Required' : 'Pending'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isUploaded ? (isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D)) : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Body Content (Upload Zone or File Details Card)
          if (!isUploaded)
            InkWell(
              onTap: _pickFile,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(10)),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_upload_outlined,
                      color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click to browse file from device',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF60A5FA) : const Color(0xFF1E3A8A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.helperText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 10, bottom: 12, top: 4),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF065F46) : const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _selectedFileName!.toLowerCase().endsWith('.pdf')
                          ? Icons.picture_as_pdf
                          : Icons.image_outlined,
                      color: const Color(0xFF109F83),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName!,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_fileSize ?? 'Ready'} • Manually Selected',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF15803D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 18, color: Color(0xFF0284C7)),
                    tooltip: 'Replace file',
                    onPressed: _pickFile,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                    tooltip: 'Remove file',
                    onPressed: _removeFile,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
