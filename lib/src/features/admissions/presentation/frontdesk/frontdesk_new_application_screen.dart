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

  const FrontDeskNewApplicationScreen({
    super.key,
    required this.isDark,
    required this.onCancel,
    required this.onSubmittedSuccess,
    this.prefilledData,
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
  String? _birthCertFileName;
  String? _tcFileName;
  String? _govtIdFileName;
  String? _immunizationFileName;

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
        if (dLower.contains('birth')) {
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
      status: AdmissionRequestStatus.pending,
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
      documents: docs,
      notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
    );

    await ref.read(admissionRequestsListProvider.notifier).createRequest(newRequest);
    ref.read(frontDeskDraftInquiryProvider.notifier).state = null;

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

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 24,
        vertical: 20,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Form(
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
      subtitle: 'Basic identity and demographic information of the child',
      icon: Icons.face_rounded,
      children: [
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
                onFileSelected: (fn) => setState(() => _birthCertFileName = fn.trim().isEmpty ? null : fn.trim()),
                onFileRemoved: () => setState(() => _birthCertFileName = null),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: FileUploadBox(
                label: 'Transfer Certificate (TC) / Previous Report Card',
                helperText: 'Required for Grade 1+ admissions (PDF, JPG, PNG)',
                initialFileName: _tcFileName,
                isRequired: false,
                onFileSelected: (fn) => setState(() => _tcFileName = fn.trim().isEmpty ? null : fn.trim()),
                onFileRemoved: () => setState(() => _tcFileName = null),
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
                onFileSelected: (fn) => setState(() => _govtIdFileName = fn.trim().isEmpty ? null : fn.trim()),
                onFileRemoved: () => setState(() => _govtIdFileName = null),
              ),
            ),
            if (!isMobile) const SizedBox(width: 16),
            Expanded(
              child: FileUploadBox(
                label: 'Medical / Immunization Record (Optional)',
                helperText: 'Vaccination chart or blood group report (PDF, JPG, PNG)',
                initialFileName: _immunizationFileName,
                isRequired: false,
                onFileSelected: (fn) => setState(() => _immunizationFileName = fn.trim().isEmpty ? null : fn.trim()),
                onFileRemoved: () => setState(() => _immunizationFileName = null),
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
}
