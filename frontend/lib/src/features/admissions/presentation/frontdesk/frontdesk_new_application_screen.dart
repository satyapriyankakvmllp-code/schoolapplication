import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/admissions_controller.dart';
import '../../application/frontdesk_controller.dart';
import '../../domain/admission_request_model.dart';
import '../../../classes/application/classes_controller.dart';
import '../widgets/file_upload_box.dart';

/// Dedicated Standalone Walk-In Admission Intake Screen for Front-Desk Officers.
/// Takes details from the visiting parent and directly submits to Admin in PENDING status.
/// Zero duplicate sidebars, zero nested admin scaffolds, fully responsive on phone and desktop.
class FrontDeskNewApplicationScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final VoidCallback onCancel;
  final VoidCallback onSubmittedSuccess;
  final AdmissionRequestModel? prefilledData;
  final bool initialShowSubmittedList;
  final ValueChanged<FrontDeskPage>? onNavigateFrontDesk;

  const FrontDeskNewApplicationScreen({
    super.key,
    required this.isDark,
    required this.onCancel,
    required this.onSubmittedSuccess,
    this.prefilledData,
    this.initialShowSubmittedList = false,
    this.onNavigateFrontDesk,
  });

  @override
  ConsumerState<FrontDeskNewApplicationScreen> createState() =>
      _FrontDeskNewApplicationScreenState();
}

class _FrontDeskNewApplicationScreenState
    extends ConsumerState<FrontDeskNewApplicationScreen> {
  final _formKey = GlobalKey<FormState>();

  // --- Student Personal Details ---
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  DateTime? _dateOfBirth;
  String _gender = 'MALE';
  String _bloodGroup = 'O+';
  late final TextEditingController _studentPhoneController;
  late final TextEditingController _currentAddressController;

  // --- Academic Placement ---
  String _gradeApplied = 'Class 1';
  String _academicYear = '2026-2027';
  late final TextEditingController _previousSchoolController;

  // --- Parent / Guardian Details ---
  late final TextEditingController _parentFullNameController;
  String _parentRelationship = 'Father';
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _parentEmailController;
  late final TextEditingController _parentOccupationController;
  late final TextEditingController _emergencyContactController;
  bool _sameAsParentPhone = true;

  // --- Document Verification & Uploads ---
  String? _studentPhotoFileName;
  Uint8List? _studentPhotoBytes;
  String? _birthCertFileName;
  Uint8List? _birthCertBytes;
  String? _tcFileName;
  Uint8List? _tcBytes;
  String? _govtIdFileName;
  Uint8List? _govtIdBytes;
  String? _immunizationFileName;
  Uint8List? _immunizationBytes;

  // --- View Mode & Tracker State ---
  bool _showSubmittedList = false;
  String _searchSubmittedQuery = '';
  String _statusSubmittedFilter = 'All';

  // --- Consultation Notes ---
  late final TextEditingController _notesController;

  bool _isSubmitting = false;

  final List<String> _gradeOptions = [
    'Nursery',
    'Kindergarten',
    'Class 1',
    'Class 2',
    'Class 3',
    'Class 4',
    'Class 5',
    'Class 6',
    'Class 7',
    'Class 8',
    'Class 9',
    'Class 10',
    'Class 11',
    'Class 12',
  ];

  final List<String> _bloodGroups = [
    'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-', 'Unknown'
  ];

  @override
  void initState() {
    super.initState();
    _showSubmittedList = widget.initialShowSubmittedList;
    final init = widget.prefilledData;

    _firstNameController = TextEditingController(text: init?.applicantFirstName ?? '');
    _lastNameController = TextEditingController(text: init?.applicantLastName ?? '');
    _dateOfBirth = init?.dateOfBirth ?? DateTime(2018, 5, 12);
    _gender = init?.gender ?? 'MALE';
    _bloodGroup = init?.bloodGroup ?? 'O+';
    _studentPhoneController = TextEditingController(text: init?.parentPhone ?? '');
    _currentAddressController = TextEditingController(text: init?.currentAddress ?? '');

    _gradeApplied = init?.gradeApplied ?? 'Class 1';
    _academicYear = init?.academicYear ?? '2026-2027';
    _previousSchoolController = TextEditingController(text: init?.previousSchoolName ?? '');

    _parentFullNameController = TextEditingController(text: init?.parentFullName ?? '');
    _parentRelationship = init?.parentRelationship ?? 'Father';
    _parentPhoneController = TextEditingController(text: init?.parentPhone ?? '');
    _parentEmailController = TextEditingController(text: init?.parentEmail ?? '');
    _parentOccupationController = TextEditingController(text: init?.parentOccupation ?? '');
    _emergencyContactController = TextEditingController(
      text: init?.emergencyContactPhone.isNotEmpty == true
          ? init!.emergencyContactPhone
          : init?.parentPhone ?? '',
    );

    _notesController = TextEditingController(text: init?.notes ?? '');

    if (init?.documents != null) {
      for (final doc in init!.documents) {
        final dLower = doc.toLowerCase();
        if (dLower.contains('photo') || dLower.contains('avatar') || dLower.contains('passport')) {
          _studentPhotoFileName = doc;
        } else if (dLower.contains('birth')) {
          _birthCertFileName = doc;
        } else if (dLower.contains('transfer') || dLower.contains('tc') || dLower.contains('report') || dLower.contains('marks')) {
          _tcFileName = doc;
        } else if (dLower.contains('govt') || dLower.contains('id') || dLower.contains('aadhaar') || dLower.contains('parent')) {
          _govtIdFileName = doc;
        } else if (dLower.contains('immun') || dLower.contains('medical') || dLower.contains('vaccin')) {
          _immunizationFileName = doc;
        }
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentPhoneController.dispose();
    _currentAddressController.dispose();
    _previousSchoolController.dispose();
    _parentFullNameController.dispose();
    _parentPhoneController.dispose();
    _parentEmailController.dispose();
    _parentOccupationController.dispose();
    _emergencyContactController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submitToAdmin() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields before submitting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select Date of Birth.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final docs = <String>[];
    if (_studentPhotoFileName != null && _studentPhotoFileName!.trim().isNotEmpty) {
      docs.add(_studentPhotoFileName!.trim());
    }
    if (_birthCertFileName != null && _birthCertFileName!.trim().isNotEmpty) {
      docs.add(_birthCertFileName!.trim());
    }
    if (_tcFileName != null && _tcFileName!.trim().isNotEmpty) {
      docs.add(_tcFileName!.trim());
    }
    if (_govtIdFileName != null && _govtIdFileName!.trim().isNotEmpty) {
      docs.add(_govtIdFileName!.trim());
    }
    if (_immunizationFileName != null && _immunizationFileName!.trim().isNotEmpty) {
      docs.add(_immunizationFileName!.trim());
    }

    final generatedId = 'REQ-${DateTime.now().millisecondsSinceEpoch % 100000}';

    final newRequest = AdmissionRequestModel(
      id: widget.prefilledData?.id ?? generatedId,
      applicantFirstName: _firstNameController.text.trim(),
      applicantLastName: _lastNameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth!,
      bloodGroup: _bloodGroup,
      gradeApplied: _gradeApplied,
      academicYear: _academicYear,
      source: AdmissionRequestSource.frontDesk,
      status: AdmissionRequestStatus.pendingReview,
      appliedAt: DateTime.now(),
      parentFullName: _parentFullNameController.text.trim(),
      parentRelationship: _parentRelationship,
      parentPhone: _parentPhoneController.text.trim(),
      parentEmail: _parentEmailController.text.trim(),
      parentOccupation: _parentOccupationController.text.trim(),
      currentAddress: _currentAddressController.text.trim(),
      emergencyContactPhone: _sameAsParentPhone
          ? _parentPhoneController.text.trim()
          : _emergencyContactController.text.trim(),
      previousSchoolName: _previousSchoolController.text.trim().isNotEmpty
          ? _previousSchoolController.text.trim()
          : null,
      studentPhotoUrl: _studentPhotoBytes != null
          ? 'data:image/jpeg;base64,${base64Encode(_studentPhotoBytes!)}'
          : (_studentPhotoFileName?.trim().isNotEmpty == true
              ? _studentPhotoFileName!.trim()
              : null),
      documents: docs,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    await ref.read(admissionRequestsListProvider.notifier).createRequest(newRequest);
    ref.read(frontDeskDraftInquiryProvider.notifier).state = null;

    // Bridge documents into Front-Desk Document Queue
    if (_studentPhotoFileName != null && _studentPhotoFileName!.trim().isNotEmpty) {
      ref.read(documentQueueProvider.notifier).addDocument(
        ApplicantDocumentItem(
          id: 'DOC-${DateTime.now().millisecondsSinceEpoch % 10000}-PHOTO',
          applicantId: newRequest.id,
          applicantName: newRequest.applicantFullName,
          grade: newRequest.gradeApplied,
          documentType: 'Student Passport Photo',
          fileName: _studentPhotoFileName!.trim(),
          fileSize: '480 KB',
          status: DocVerifyStatus.pending,
          uploadedAt: DateTime.now(),
          base64Data: _studentPhotoBytes != null ? base64Encode(_studentPhotoBytes!) : null,
          dateOfBirth: newRequest.dateOfBirth,
          gender: newRequest.gender,
          parentFullName: newRequest.parentFullName,
          parentRelationship: newRequest.parentRelationship,
          currentAddress: newRequest.currentAddress,
          bloodGroup: newRequest.bloodGroup,
        ),
      );
    }
    if (_birthCertFileName != null && _birthCertFileName!.trim().isNotEmpty) {
      ref.read(documentQueueProvider.notifier).addDocument(
        ApplicantDocumentItem(
          id: 'DOC-${DateTime.now().millisecondsSinceEpoch % 10000}-BC',
          applicantId: newRequest.id,
          applicantName: newRequest.applicantFullName,
          grade: newRequest.gradeApplied,
          documentType: 'Birth Certificate',
          fileName: _birthCertFileName!.trim(),
          fileSize: '1.2 MB',
          status: DocVerifyStatus.pending,
          uploadedAt: DateTime.now(),
          base64Data: _birthCertBytes != null ? base64Encode(_birthCertBytes!) : null,
          dateOfBirth: newRequest.dateOfBirth,
          gender: newRequest.gender,
          parentFullName: newRequest.parentFullName,
          parentRelationship: newRequest.parentRelationship,
          currentAddress: newRequest.currentAddress,
          bloodGroup: newRequest.bloodGroup,
        ),
      );
    }
    if (_tcFileName != null && _tcFileName!.trim().isNotEmpty) {
      ref.read(documentQueueProvider.notifier).addDocument(
        ApplicantDocumentItem(
          id: 'DOC-${DateTime.now().millisecondsSinceEpoch % 10000}-TC',
          applicantId: newRequest.id,
          applicantName: newRequest.applicantFullName,
          grade: newRequest.gradeApplied,
          documentType: 'Transfer Certificate (TC)',
          fileName: _tcFileName!.trim(),
          fileSize: '1.8 MB',
          status: DocVerifyStatus.pending,
          uploadedAt: DateTime.now(),
          base64Data: _tcBytes != null ? base64Encode(_tcBytes!) : null,
          dateOfBirth: newRequest.dateOfBirth,
          gender: newRequest.gender,
          parentFullName: newRequest.parentFullName,
          parentRelationship: newRequest.parentRelationship,
          currentAddress: newRequest.currentAddress,
          bloodGroup: newRequest.bloodGroup,
        ),
      );
    }
    if (_govtIdFileName != null && _govtIdFileName!.trim().isNotEmpty) {
      ref.read(documentQueueProvider.notifier).addDocument(
        ApplicantDocumentItem(
          id: 'DOC-${DateTime.now().millisecondsSinceEpoch % 10000}-ID',
          applicantId: newRequest.id,
          applicantName: newRequest.applicantFullName,
          grade: newRequest.gradeApplied,
          documentType: 'Parent Govt ID Proof',
          fileName: _govtIdFileName!.trim(),
          fileSize: '950 KB',
          status: DocVerifyStatus.pending,
          uploadedAt: DateTime.now(),
          base64Data: _govtIdBytes != null ? base64Encode(_govtIdBytes!) : null,
          dateOfBirth: newRequest.dateOfBirth,
          gender: newRequest.gender,
          parentFullName: newRequest.parentFullName,
          parentRelationship: newRequest.parentRelationship,
          currentAddress: newRequest.currentAddress,
          bloodGroup: newRequest.bloodGroup,
        ),
      );
    }
    if (_immunizationFileName != null && _immunizationFileName!.trim().isNotEmpty) {
      ref.read(documentQueueProvider.notifier).addDocument(
        ApplicantDocumentItem(
          id: 'DOC-${DateTime.now().millisecondsSinceEpoch % 10000}-MED',
          applicantId: newRequest.id,
          applicantName: newRequest.applicantFullName,
          grade: newRequest.gradeApplied,
          documentType: 'Medical / Immunization Record',
          fileName: _immunizationFileName!.trim(),
          fileSize: '720 KB',
          status: DocVerifyStatus.pending,
          uploadedAt: DateTime.now(),
          base64Data: _immunizationBytes != null ? base64Encode(_immunizationBytes!) : null,
          dateOfBirth: newRequest.dateOfBirth,
          gender: newRequest.gender,
          parentFullName: newRequest.parentFullName,
          parentRelationship: newRequest.parentRelationship,
          currentAddress: newRequest.currentAddress,
          bloodGroup: newRequest.bloodGroup,
        ),
      );
    }

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    // Show confirmation modal dialog
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Application Submitted!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'New admission application for ${newRequest.applicantFullName} has been recorded and sent to the School Administrator in PENDING status.',
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: widget.isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text(
                          'Application Reference:',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        newRequest.id,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('Grade Applied:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        newRequest.gradeApplied,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: widget.isDark ? Colors.white : Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Flexible(
                        child: Text('Admin Status:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Pending Review', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF59E0B))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.assignment_turned_in_outlined, size: 16),
            label: const Text('Track Application Status'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF3B82F6),
              side: const BorderSide(color: Color(0xFF3B82F6)),
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              if (widget.onNavigateFrontDesk != null) {
                widget.onNavigateFrontDesk!(FrontDeskPage.applicationsTracker);
              } else {
                setState(() => _showSubmittedList = true);
              }
            },
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              widget.onSubmittedSuccess();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Return to Dashboard'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final requests = ref.watch(admissionRequestsListProvider).valueOrNull ?? [];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Segmented Mode Selector
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D31) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            avatar: const Icon(Icons.edit_note_rounded, size: 16),
                            label: const Text('Intake Form (New Walk-In)'),
                            selected: !_showSubmittedList,
                            selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: !_showSubmittedList ? FontWeight.bold : FontWeight.normal,
                              color: !_showSubmittedList ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) => setState(() => _showSubmittedList = false),
                          ),
                          ChoiceChip(
                            avatar: const Icon(Icons.fact_check_outlined, size: 16),
                            label: Text('Submitted Status Tracker (${requests.length})'),
                            selected: _showSubmittedList,
                            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.25),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: _showSubmittedList ? FontWeight.bold : FontWeight.normal,
                              color: _showSubmittedList ? const Color(0xFF10B981) : (isDark ? Colors.white70 : Colors.black87),
                            ),
                            onSelected: (_) => setState(() => _showSubmittedList = true),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              if (_showSubmittedList)
                _buildSubmittedApplicationsTracker(isDark, isMobile)
              else
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(isDark, isMobile),
                      const SizedBox(height: 20),
                      _buildStudentDemographicsCard(isDark, isMobile),
                      const SizedBox(height: 20),
                      _buildAcademicPlacementCard(isDark, isMobile),
                      const SizedBox(height: 20),
                      _buildGuardianDetailsCard(isDark, isMobile),
                      const SizedBox(height: 20),
                      _buildDocumentChecklistCard(isDark, isMobile),
                      const SizedBox(height: 20),
                      _buildNotesCard(isDark, isMobile),
                      const SizedBox(height: 24),
                      _buildActionButtons(isDark, isMobile),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Header Card
  // --------------------------------------------------------------------------
  Widget _buildHeaderCard(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFF59E0B), size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'Walk-In Admission Intake Form',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'FRONT-DESK',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFF59E0B)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Fill in applicant details from visiting parents. Submits directly to Institutional Admin for evaluation & section assignment.',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Section 1: Student Demographics
  // --------------------------------------------------------------------------
  Widget _buildStudentDemographicsCard(bool isDark, bool isMobile) {
    return _buildCardContainer(
      isDark: isDark,
      isMobile: isMobile,
      title: '1. Student Personal Details',
      subtitle: 'Basic identity, demographic information, and student photograph',
      icon: Icons.face_rounded,
      children: [
        // Student Passport Photo Box
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _studentPhotoFileName != null
                  ? const Color(0xFF10B981).withValues(alpha: 0.5)
                  : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade200),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 82,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _studentPhotoFileName != null
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    width: _studentPhotoFileName != null ? 2 : 1,
                  ),
                ),
                child: _studentPhotoFileName != null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 26),
                          const SizedBox(height: 4),
                          Text(
                            'Uploaded',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              color: isDark ? Colors.white38 : Colors.grey.shade400, size: 28),
                          const SizedBox(height: 4),
                          Text(
                            'Photo 3:4',
                            style: TextStyle(fontSize: 9, color: isDark ? Colors.white38 : Colors.grey.shade500),
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Student Passport-Size Photo',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Required for ID Card',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _studentPhotoFileName ?? 'Upload student photograph (JPG, PNG). Will be attached to admission profile and printed on Student ID Badge.',
                      style: TextStyle(
                        fontSize: 11,
                        color: _studentPhotoFileName != null
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.upload, size: 14),
                          label: Text(
                            _studentPhotoFileName == null ? 'Upload Photo' : 'Change Photo',
                            style: const TextStyle(fontSize: 11),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                          onPressed: () => _showPhotoSelectionDialog(context),
                        ),
                        if (_studentPhotoFileName != null)
                          TextButton.icon(
                            icon: const Icon(Icons.delete_outline, size: 14, color: Colors.redAccent),
                            label: const Text('Remove', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                            onPressed: () => setState(() {
                              _studentPhotoFileName = null;
                              _studentPhotoBytes = null;
                            }),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'First Name *',
                controller: _firstNameController,
                hint: 'e.g. Aarav',
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'First name is required' : null,
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Last Name *',
                controller: _lastNameController,
                hint: 'e.g. Sharma',
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Last name is required' : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            // Gender
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Gender *', style: _labelStyle(isDark)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['MALE', 'FEMALE', 'OTHER'].map((g) {
                      final isSelected = _gender == g;
                      return ChoiceChip(
                        label: Text(g[0] + g.substring(1).toLowerCase()),
                        selected: isSelected,
                        selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black87),
                        ),
                        onSelected: (_) => setState(() => _gender = g),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            // Date of Birth
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date of Birth *', style: _labelStyle(isDark)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _dateOfBirth ?? DateTime(2018, 5, 12),
                        firstDate: DateTime(2005),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _dateOfBirth = picked);
                      }
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 16, color: isDark ? Colors.white70 : Colors.grey.shade700),
                          const SizedBox(width: 10),
                          Text(
                            _dateOfBirth != null
                                ? DateFormat('dd MMM yyyy').format(_dateOfBirth!)
                                : 'Select Date of Birth',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Blood Group', style: _labelStyle(isDark)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _bloodGroup,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: _inputDecoration(isDark),
                    items: _bloodGroups.map((bg) {
                      return DropdownMenuItem(value: bg, child: Text(bg, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _bloodGroup = val);
                    },
                  ),
                ],
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Student Contact / Mobile',
                controller: _studentPhoneController,
                hint: '+91 98765 00000',
                keyboardType: TextInputType.phone,
                isDark: isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Residential / Current Address *',
          controller: _currentAddressController,
          hint: 'Full street address, apartment / house number, area, city, pincode',
          isDark: isDark,
          maxLines: 2,
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Current address is required' : null,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 2: Academic Placement
  // --------------------------------------------------------------------------
  Widget _buildAcademicPlacementCard(bool isDark, bool isMobile) {
    return _buildCardContainer(
      isDark: isDark,
      isMobile: isMobile,
      title: '2. Academic Placement Applied',
      subtitle: 'Target grade and previous institution history',
      icon: Icons.school_rounded,
      children: [
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Grade / Class Applying For *', style: _labelStyle(isDark)),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final classesAsync = ref.watch(classesControllerProvider);
                      final dynamicGrades = classesAsync.value
                              ?.map((c) => c.name)
                              .where((n) => n.trim().isNotEmpty)
                              .toSet()
                              .toList() ??
                          [];
                      final effectiveGrades = dynamicGrades.isNotEmpty ? dynamicGrades : _gradeOptions;
                      final effectiveVal = effectiveGrades.contains(_gradeApplied)
                          ? _gradeApplied
                          : (effectiveGrades.isNotEmpty ? effectiveGrades.first : null);

                      return DropdownButtonFormField<String>(
                        key: ValueKey('fd_grade_${effectiveVal}_${effectiveGrades.length}'),
                        initialValue: effectiveVal,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        decoration: _inputDecoration(isDark),
                        items: effectiveGrades.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _gradeApplied = val);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Academic Session',
                controller: TextEditingController(text: _academicYear),
                isDark: isDark,
                readOnly: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField(
          label: 'Previous School Name (if transferring)',
          controller: _previousSchoolController,
          hint: 'e.g. St. Xavier’s Primary School, Bengaluru',
          isDark: isDark,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 3: Parent / Guardian Details
  // --------------------------------------------------------------------------
  Widget _buildGuardianDetailsCard(bool isDark, bool isMobile) {
    return _buildCardContainer(
      isDark: isDark,
      isMobile: isMobile,
      title: '3. Parent / Guardian & Emergency Linking',
      subtitle: 'Official primary contact for communications, fee billing, and safety notices',
      icon: Icons.family_restroom_rounded,
      children: [
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              flex: 2,
              child: _buildTextField(
                label: 'Guardian Full Name *',
                controller: _parentFullNameController,
                hint: 'e.g. Rajesh Sharma',
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Guardian name is required' : null,
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Relationship *', style: _labelStyle(isDark)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _parentRelationship,
                    dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    decoration: _inputDecoration(isDark),
                    items: ['Father', 'Mother', 'Guardian', 'Other'].map((r) {
                      return DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _parentRelationship = val);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Primary Phone / WhatsApp *',
                controller: _parentPhoneController,
                hint: '+91 98765 43210',
                keyboardType: TextInputType.phone,
                isDark: isDark,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Phone number is required' : null,
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: _buildTextField(
                label: 'Email Address *',
                controller: _parentEmailController,
                hint: 'parent@example.com',
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email address';
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              child: _buildTextField(
                label: 'Occupation / Employer',
                controller: _parentOccupationController,
                hint: 'e.g. Senior Software Architect / Business Owner',
                isDark: isDark,
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emergency Contact Phone *', style: _labelStyle(isDark)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emergencyContactController,
                    enabled: !_sameAsParentPhone,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: _inputDecoration(isDark).copyWith(
                      hintText: '+91 98765 00000',
                      prefixIcon: const Icon(Icons.phone_in_talk, size: 16),
                    ),
                    validator: (v) {
                      if (!_sameAsParentPhone && (v == null || v.trim().isEmpty)) {
                        return 'Emergency phone is required';
                      }
                      return null;
                    },
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _sameAsParentPhone = !_sameAsParentPhone;
                        if (_sameAsParentPhone) {
                          _emergencyContactController.text = _parentPhoneController.text.trim();
                        }
                      });
                    },
                    child: Row(
                      children: [
                        Checkbox(
                          value: _sameAsParentPhone,
                          activeColor: const Color(0xFFF59E0B),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          onChanged: (val) {
                            setState(() {
                              _sameAsParentPhone = val ?? false;
                              if (_sameAsParentPhone) {
                                _emergencyContactController.text = _parentPhoneController.text.trim();
                              }
                            });
                          },
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Same as primary phone number',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 4: Document Checklist
  // --------------------------------------------------------------------------
  Widget _buildDocumentChecklistCard(bool isDark, bool isMobile) {
    return _buildCardContainer(
      isDark: isDark,
      isMobile: isMobile,
      title: '4. Documents Presented by Parent',
      subtitle: 'Upload physical or digital certificates presented during the front-desk visit',
      icon: Icons.upload_file_rounded,
      children: [
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              child: FileUploadBox(
                label: 'Student Birth Certificate *',
                helperText: 'Municipal Birth Certificate or hospital record (PDF, JPG, PNG)',
                initialFileName: _birthCertFileName,
                isRequired: true,
                onFileWithBytesSelected: (fn, bytes) => setState(() {
                  _birthCertFileName = fn.trim().isEmpty ? null : fn.trim();
                  _birthCertBytes = bytes;
                }),
                onFileRemoved: () => setState(() {
                  _birthCertFileName = null;
                  _birthCertBytes = null;
                }),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: FileUploadBox(
                label: 'Transfer Certificate (TC) / Previous Report Card',
                helperText: 'Required for Grade 1+ admissions (PDF, JPG, PNG)',
                initialFileName: _tcFileName,
                isRequired: false,
                onFileWithBytesSelected: (fn, bytes) => setState(() {
                  _tcFileName = fn.trim().isEmpty ? null : fn.trim();
                  _tcBytes = bytes;
                }),
                onFileRemoved: () => setState(() {
                  _tcFileName = null;
                  _tcBytes = null;
                }),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildResponsiveRow(
          isMobile: isMobile,
          children: [
            Expanded(
              child: FileUploadBox(
                label: 'Parent Government ID Proof',
                helperText: 'Aadhaar Card, Passport, or Voter ID (PDF, JPG, PNG)',
                initialFileName: _govtIdFileName,
                isRequired: false,
                onFileWithBytesSelected: (fn, bytes) => setState(() {
                  _govtIdFileName = fn.trim().isEmpty ? null : fn.trim();
                  _govtIdBytes = bytes;
                }),
                onFileRemoved: () => setState(() {
                  _govtIdFileName = null;
                  _govtIdBytes = null;
                }),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: FileUploadBox(
                label: 'Medical / Immunization Record (Optional)',
                helperText: 'Vaccination chart or blood group report (PDF, JPG, PNG)',
                initialFileName: _immunizationFileName,
                isRequired: false,
                onFileWithBytesSelected: (fn, bytes) => setState(() {
                  _immunizationFileName = fn.trim().isEmpty ? null : fn.trim();
                  _immunizationBytes = bytes;
                }),
                onFileRemoved: () => setState(() {
                  _immunizationFileName = null;
                  _immunizationBytes = null;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Section 5: Consultation Notes
  // --------------------------------------------------------------------------
  Widget _buildNotesCard(bool isDark, bool isMobile) {
    return _buildCardContainer(
      isDark: isDark,
      isMobile: isMobile,
      title: '5. Front-Desk Consultation Notes',
      subtitle: 'Record internal observations, sibling ties, or special requests for the Admin',
      icon: Icons.rate_review_rounded,
      children: [
        _buildTextField(
          label: 'Internal Remarks / Parent Inquiries',
          controller: _notesController,
          hint: 'e.g. Sibling studying in Class 8; parent requested morning school bus pickup from Indiranagar; interested in robotics club elective.',
          isDark: isDark,
          maxLines: 3,
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Bottom Action Buttons
  // --------------------------------------------------------------------------
  Widget _buildActionButtons(bool isDark, bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitToAdmin,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    _isSubmitting ? 'Submitting to Admin...' : 'Submit Application to Admin ➔',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel Intake'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: widget.onCancel,
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Cancel Intake'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitToAdmin,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, size: 16),
                  label: Text(
                    _isSubmitting ? 'Submitting to Admin...' : 'Submit Application to Admin ➔',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }

  // --------------------------------------------------------------------------
  // Helper Widgets
  // --------------------------------------------------------------------------
  Widget _buildCardContainer({
    required bool isDark,
    required bool isMobile,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFFF59E0B), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }


  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    bool readOnly = false,
    bool isDark = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(isDark)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          readOnly: readOnly,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          decoration: _inputDecoration(isDark).copyWith(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }

  TextStyle _labelStyle(bool isDark) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: isDark ? Colors.white : const Color(0xFF0F172A),
    );
  }

  InputDecoration _inputDecoration(bool isDark) {
    return InputDecoration(
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Widget _buildResponsiveRow({required bool isMobile, required List<Widget> children}) {
    if (isMobile) {
      final unwrapped = children
          .where((c) => !(c is SizedBox && c.width != null && (c.height == null || c.height == 0)))
          .map((c) => c is Expanded ? c.child : c)
          .toList();
      final separated = <Widget>[];
      for (int i = 0; i < unwrapped.length; i++) {
        separated.add(unwrapped[i]);
        if (i < unwrapped.length - 1) {
          separated.add(const SizedBox(height: 16));
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: separated,
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  // --------------------------------------------------------------------------
  // Photo Selection Dialog
  // --------------------------------------------------------------------------
  void _showPhotoSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.add_a_photo_outlined, color: Color(0xFFF59E0B)),
            const SizedBox(width: 8),
            Text(
              'Upload Student Passport Photo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select a file from your computer or choose a sample photo for testing:',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.folder_open, color: Color(0xFFF59E0B), size: 22),
              ),
              title: const Text('Browse Device Storage', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              subtitle: const Text('Upload JPG, JPEG, or PNG passport photo', style: TextStyle(fontSize: 11)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              tileColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              onTap: () async {
                Navigator.of(ctx).pop();
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['jpg', 'jpeg', 'png'],
                    withData: true,
                  );
                  if (result != null && result.files.isNotEmpty) {
                    setState(() {
                      _studentPhotoFileName = result.files.first.name;
                      _studentPhotoBytes = result.files.first.bytes;
                    });
                  }
                } catch (_) {}
              },
            ),
            const SizedBox(height: 14),
            Text(
              'Quick Demo Sample Photos:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.face, size: 16),
                  label: const Text('student_photo_boy.jpg', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() => _studentPhotoFileName = 'student_photo_boy.jpg');
                    Navigator.of(ctx).pop();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.face_3, size: 16),
                  label: const Text('student_photo_girl.jpg', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() => _studentPhotoFileName = 'student_photo_girl.jpg');
                    Navigator.of(ctx).pop();
                  },
                ),
                ActionChip(
                  avatar: const Icon(Icons.portrait, size: 16),
                  label: const Text('aarav_passport_photo.png', style: TextStyle(fontSize: 11)),
                  onPressed: () {
                    setState(() => _studentPhotoFileName = 'aarav_passport_photo.png');
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // Submitted Applications Tracker View
  // --------------------------------------------------------------------------
  Widget _buildSubmittedApplicationsTracker(bool isDark, bool isMobile) {
    final requestsAsync = ref.watch(admissionRequestsListProvider);

    return requestsAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, st) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('Error loading requests: $e'),
      ),
      data: (requests) {
        final filtered = requests.where((req) {
          final q = _searchSubmittedQuery.toLowerCase().trim();
          final matchesSearch = q.isEmpty ||
              req.id.toLowerCase().contains(q) ||
              req.applicantFullName.toLowerCase().contains(q) ||
              req.parentFullName.toLowerCase().contains(q) ||
              req.parentPhone.contains(q) ||
              req.gradeApplied.toLowerCase().contains(q);

          bool matchesStatus = true;
          if (_statusSubmittedFilter == 'Pending') {
            matchesStatus = req.status.isPendingReview;
          } else if (_statusSubmittedFilter == 'Approved') {
            matchesStatus = req.status == AdmissionRequestStatus.approved;
          } else if (_statusSubmittedFilter == 'Rejected') {
            matchesStatus = req.status == AdmissionRequestStatus.rejected;
          }

          return matchesSearch && matchesStatus;
        }).toList()
          ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

        final pendingCount = requests.where((r) => r.status.isPendingReview).length;
        final approvedCount = requests.where((r) => r.status == AdmissionRequestStatus.approved).length;
        final rejectedCount = requests.where((r) => r.status == AdmissionRequestStatus.rejected).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.assignment_turned_in_outlined, color: Color(0xFF10B981), size: 26),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Submitted Applications & Live Status',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track applications lodged at front desk and monitor real-time Admin review decisions',
                          style: TextStyle(
                            fontSize: isMobile ? 11 : 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Walk-In'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => setState(() => _showSubmittedList = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Search and Status Filter Chips
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF131D31) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (v) => setState(() => _searchSubmittedQuery = v),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, size: 20),
                      hintText: 'Search by reference ID, student name, parent phone...',
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All (${requests.length})',
                        'Pending ($pendingCount)',
                        'Approved ($approvedCount)',
                        'Rejected ($rejectedCount)',
                      ].map((item) {
                        final rawStatus = item.split(' ').first;
                        final isSelected = _statusSubmittedFilter == rawStatus;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(item),
                            selected: isSelected,
                            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                            onSelected: (_) => setState(() => _statusSubmittedFilter = rawStatus),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Applications List Cards
            if (filtered.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(36),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF131D31) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 40, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('No applications matching current search criteria.'),
                  ],
                ),
              )
            else
              ...filtered.map((req) => _buildSubmittedRequestCard(req, isDark, isMobile)),
          ],
        );
      },
    );
  }

  Widget _buildSubmittedRequestCard(AdmissionRequestModel req, bool isDark, bool isMobile) {
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    switch (req.status) {
      case AdmissionRequestStatus.approved:
        statusColor = const Color(0xFF10B981);
        statusLabel = 'Approved & Enrolled';
        statusIcon = Icons.check_circle_rounded;
        break;
      case AdmissionRequestStatus.rejected:
        statusColor = const Color(0xFFEF4444);
        statusLabel = 'Rejected';
        statusIcon = Icons.cancel_rounded;
        break;
      case AdmissionRequestStatus.pending:
      case AdmissionRequestStatus.pendingReview:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'Pending Review';
        statusIcon = Icons.hourglass_top_rounded;
        break;
      case AdmissionRequestStatus.correctionRequested:
        statusColor = const Color(0xFFD97706);
        statusLabel = 'Correction Requested';
        statusIcon = Icons.edit_note_rounded;
        break;
    }

    final hasPhoto = req.documents.any((d) {
      final dl = d.toLowerCase();
      return dl.contains('photo') || dl.contains('avatar') || dl.contains('passport');
    });

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: req.status == AdmissionRequestStatus.correctionRequested
              ? const Color(0xFFD97706).withValues(alpha: 0.5)
              : (isDark ? const Color(0xFF24334C) : Colors.grey.shade200),
          width: req.status == AdmissionRequestStatus.correctionRequested ? 1.5 : 1.0,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showApplicationDetailsModal(req, isDark),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        req.source.displayName,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: hasPhoto
                          ? const Color(0xFF10B981).withValues(alpha: 0.2)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      child: hasPhoto
                          ? const Icon(Icons.account_circle, color: Color(0xFF10B981), size: 26)
                          : Text(
                              req.applicantFirstName.isNotEmpty ? req.applicantFirstName[0].toUpperCase() : '?',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                            ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.applicantFullName,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Grade: ${req.gradeApplied} • DOB: ${DateFormat('dd MMM yyyy').format(req.dateOfBirth)} • Gender: ${req.gender}',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Parent: ${req.parentFullName} (${req.parentPhone}) • ${req.currentAddress}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF64748B) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Review Status Feedback Banner
                if (req.correctionNotes != null && req.correctionNotes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD97706).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, size: 15, color: Color(0xFFD97706)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Admin Feedback: ${req.correctionNotes}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (req.rejectionReason != null && req.rejectionReason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.cancel_outlined, size: 15, color: Color(0xFFEF4444)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Declined by Admin: ${req.rejectionReason}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEF4444)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                // Attached Documents Chips & View Dossier Prompt
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 12, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Documents (${req.documents.length})',
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    if (hasPhoto)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.photo_camera, size: 12, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text('Photo Attached', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    const SizedBox(width: 4),
                    Text(
                      'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(req.appliedAt)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF64748B) : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Dossier', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF3B82F6))),
                          SizedBox(width: 2),
                          Icon(Icons.arrow_forward_ios_rounded, size: 9, color: Color(0xFF3B82F6)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showApplicationDetailsModal(AdmissionRequestModel req, bool isDark) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Modal Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                      child: Text(
                        req.applicantFirstName.isNotEmpty ? req.applicantFirstName[0].toUpperCase() : '?',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF59E0B)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.applicantFullName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Application Reference: ${req.id} • ${req.gradeApplied}',
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
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              // Modal Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status Banner
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: req.status.isPendingReview
                              ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                              : (req.status == AdmissionRequestStatus.approved
                                  ? const Color(0xFF10B981).withValues(alpha: 0.12)
                                  : const Color(0xFFEF4444).withValues(alpha: 0.12)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: req.status.isPendingReview
                                ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                : (req.status == AdmissionRequestStatus.approved
                                    ? const Color(0xFF10B981).withValues(alpha: 0.3)
                                    : const Color(0xFFEF4444).withValues(alpha: 0.3)),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              req.status.isPendingReview
                                  ? Icons.hourglass_top_rounded
                                  : (req.status == AdmissionRequestStatus.approved
                                      ? Icons.check_circle_rounded
                                      : Icons.cancel_rounded),
                              color: req.status.isPendingReview
                                  ? const Color(0xFFF59E0B)
                                  : (req.status == AdmissionRequestStatus.approved
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444)),
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Status: ${req.status.displayName}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: req.status.isPendingReview
                                          ? const Color(0xFFF59E0B)
                                          : (req.status == AdmissionRequestStatus.approved
                                              ? const Color(0xFF10B981)
                                              : const Color(0xFFEF4444)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    req.status.isPendingReview
                                        ? 'Application is currently in the Administrator & Principal review pipeline. Verification decisions will update here in real time.'
                                        : (req.status == AdmissionRequestStatus.approved
                                            ? 'Application has been approved by the School Administrator and enrolled.'
                                            : (req.rejectionReason ?? 'Application was declined by the Admissions Board.')),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Demographics Section
                      Text(
                        'Student Demographics',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Grade Applied', req.gradeApplied, isDark),
                            _buildInfoRow('Academic Year', req.academicYear, isDark),
                            _buildInfoRow('Date of Birth', DateFormat('dd MMM yyyy').format(req.dateOfBirth), isDark),
                            _buildInfoRow('Gender', req.gender, isDark),
                            _buildInfoRow('Blood Group', req.bloodGroup ?? 'N/A', isDark),
                            _buildInfoRow('Previous School', req.previousSchoolName ?? 'None (Fresher)', isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Parent Details Section
                      Text(
                        'Parent / Guardian Contacts',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow('Parent Name', req.parentFullName, isDark),
                            _buildInfoRow('Relationship', req.parentRelationship, isDark),
                            _buildInfoRow('Phone', req.parentPhone, isDark),
                            _buildInfoRow('Email', req.parentEmail, isDark),
                            _buildInfoRow('Occupation', req.parentOccupation ?? 'N/A', isDark),
                            _buildInfoRow('Residential Address', req.currentAddress, isDark),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Attached Documents
                      Text(
                        'Uploaded Documents & Credentials (${req.documents.length})',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...req.documents.map((doc) => Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.description_outlined, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                doc,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ),
                            const Text('Attached', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )),
                      if (req.notes != null && req.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text(
                          'Front-Desk Officer Consultation Notes',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
                          ),
                          child: Text(
                            req.notes!,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
