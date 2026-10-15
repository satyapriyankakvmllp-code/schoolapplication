import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/admission_request_model.dart';
import 'file_upload_box.dart';

/// Reusable 3-Step Guided Wizard for New Student Admission Intake.
/// Used by both Front-Desk Officers and Guardians (Parents).
class AdmissionApplicationWizard extends ConsumerStatefulWidget {
  final AdmissionRequestSource source;
  final AdmissionRequestModel? initialData;
  final ValueChanged<AdmissionRequestModel> onSubmitted;
  final VoidCallback onCancel;
  final bool isDark;

  const AdmissionApplicationWizard({
    super.key,
    required this.source,
    this.initialData,
    required this.onSubmitted,
    required this.onCancel,
    this.isDark = false,
  });

  @override
  ConsumerState<AdmissionApplicationWizard> createState() =>
      _AdmissionApplicationWizardState();
}

class _AdmissionApplicationWizardState
    extends ConsumerState<AdmissionApplicationWizard> {
  int _currentStep = 0; // 0: Student, 1: Guardian, 2: Documents & Review

  // Form Keys
  final _step1Key = GlobalKey<FormState>();
  final _step2Key = GlobalKey<FormState>();
  final _step3Key = GlobalKey<FormState>();

  // --- Step 1: Student Demographics ---
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  DateTime? _dateOfBirth;
  String _gender = 'MALE';
  String _bloodGroup = 'O+';
  String _gradeApplied = 'Class 1';
  String _academicYear = '2026-2027';
  late final TextEditingController _currentAddressController;
  late final TextEditingController _previousSchoolController;

  // --- Step 2: Guardian Details & Emergency Contact ---
  late final TextEditingController _parentFullNameController;
  String _parentRelationship = 'Father';
  late final TextEditingController _parentPhoneController;
  late final TextEditingController _parentEmailController;
  late final TextEditingController _parentOccupationController;
  late final TextEditingController _emergencyContactController;
  bool _sameAsParentPhone = true;
  bool _isFeePayer = true;

  // --- Step 3: Documents & Declaration ---
  String? _birthCertFileName;
  String? _tcFileName;
  String? _govtIdFileName;
  String? _immunizationFileName;
  late final TextEditingController _notesController;
  bool _declarationAccepted = false;

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
    final init = widget.initialData;

    _firstNameController = TextEditingController(text: init?.applicantFirstName ?? '');
    _lastNameController = TextEditingController(text: init?.applicantLastName ?? '');
    _dateOfBirth = init?.dateOfBirth ?? DateTime(2018, 5, 12);
    _gender = init?.gender ?? 'MALE';
    _bloodGroup = init?.bloodGroup ?? 'O+';
    _gradeApplied = init?.gradeApplied ?? 'Class 1';
    _academicYear = init?.academicYear ?? '2026-2027';
    _currentAddressController = TextEditingController(text: init?.currentAddress ?? '');
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

  void _nextStep() {
    if (_currentStep == 0) {
      if (!_step1Key.currentState!.validate()) return;
      if (_dateOfBirth == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select Date of Birth')),
        );
        return;
      }
    } else if (_currentStep == 1) {
      if (!_step2Key.currentState!.validate()) return;
      if (_sameAsParentPhone) {
        _emergencyContactController.text = _parentPhoneController.text.trim();
      }
    }

    setState(() {
      _currentStep++;
    });
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  void _submitForm() {
    if (!_step3Key.currentState!.validate()) return;
    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept the declaration to submit application.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

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

    final request = AdmissionRequestModel(
      id: widget.initialData?.id ?? generatedId,
      applicantFirstName: _firstNameController.text.trim(),
      applicantLastName: _lastNameController.text.trim(),
      gender: _gender,
      dateOfBirth: _dateOfBirth ?? DateTime(2018, 1, 1),
      bloodGroup: _bloodGroup,
      gradeApplied: _gradeApplied,
      academicYear: _academicYear,
      source: widget.source,
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

    widget.onSubmitted(request);
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isDark, isMobile),
              const SizedBox(height: 20),
              _buildStepIndicator(isDark, isMobile),
              const SizedBox(height: 24),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: _buildCurrentStepContent(isDark, isMobile),
              ),
              const SizedBox(height: 28),
              _buildNavButtons(isDark, isMobile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    final isFrontDesk = widget.source == AdmissionRequestSource.frontDesk;
    final badgeColor = isFrontDesk ? const Color(0xFFF59E0B) : const Color(0xFF10B981);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
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
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isFrontDesk ? Icons.app_registration_rounded : Icons.family_restroom_rounded,
              color: badgeColor,
              size: isMobile ? 24 : 30,
            ),
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
                      'New Student Admission Application',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        widget.source.displayName,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isFrontDesk
                      ? 'Register a prospective student for walk-in or phone inquiries. Submits to Admin approval queue.'
                      : 'Fill in your child’s details to apply for admission. Application routes directly to Institutional Admin for verification.',
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

  Widget _buildStepIndicator(bool isDark, bool isMobile) {
    final steps = [
      {'title': 'Student Info', 'desc': 'Child Demographics & Grade', 'icon': Icons.person_outline},
      {'title': 'Guardian Details', 'desc': 'Parent & Emergency Contact', 'icon': Icons.supervisor_account_outlined},
      {'title': 'Documents & Submit', 'desc': 'Certificates & Review', 'icon': Icons.verified_user_outlined},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131D31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (index) {
          if (index.isOdd) {
            final stepBefore = index ~/ 2;
            final isPassed = _currentStep > stepBefore;
            return Expanded(
              child: Container(
                height: 2,
                color: isPassed
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
            );
          }

          final stepIdx = index ~/ 2;
          final isActive = _currentStep == stepIdx;
          final isCompleted = _currentStep > stepIdx;

          Color itemColor;
          if (isCompleted) {
            itemColor = const Color(0xFF10B981);
          } else if (isActive) {
            itemColor = const Color(0xFF0D9488);
          } else {
            itemColor = isDark ? const Color(0xFF64748B) : Colors.grey.shade400;
          }

          return InkWell(
            onTap: () {
              if (stepIdx < _currentStep) {
                setState(() => _currentStep = stepIdx);
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: itemColor.withValues(alpha: 0.15),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Color(0xFF10B981))
                      : Text(
                          '${stepIdx + 1}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: itemColor,
                          ),
                        ),
                ),
                if (!isMobile) ...[
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        steps[stepIdx]['title'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          color: isActive
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : itemColor,
                        ),
                      ),
                      Text(
                        steps[stepIdx]['desc'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStepContent(bool isDark, bool isMobile) {
    switch (_currentStep) {
      case 0:
        return _buildStep1StudentDemographics(isDark, isMobile);
      case 1:
        return _buildStep2GuardianDetails(isDark, isMobile);
      case 2:
      default:
        return _buildStep3DocumentsAndReview(isDark, isMobile);
    }
  }

  // --------------------------------------------------------------------------
  // STEP 1: Student Demographics
  // --------------------------------------------------------------------------
  Widget _buildStep1StudentDemographics(bool isDark, bool isMobile) {
    return Form(
      key: _step1Key,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeading(
              'Step 1: Child Demographics & Grade Applied',
              'Basic identity and academic grade the child is enrolling into',
              Icons.school_outlined,
              isDark,
            ),
            const SizedBox(height: 20),

            // Name Row
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

            // Gender & DOB Row
            _buildResponsiveRow(
              isMobile: isMobile,
              children: [
                // Gender Selection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gender *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: ['MALE', 'FEMALE', 'OTHER'].map((g) {
                          final isSelected = _gender == g;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(g[0] + g.substring(1).toLowerCase()),
                              selected: isSelected,
                              selectedColor: const Color(0xFF0D9488).withValues(alpha: 0.2),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? const Color(0xFF0D9488) : (isDark ? Colors.white70 : Colors.black87),
                              ),
                              onSelected: (_) => setState(() => _gender = g),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const SizedBox(width: 16),
                // DOB Picker
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
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
                            border: Border.all(
                              color: isDark ? const Color(0xFF334155) : Colors.grey.shade300,
                            ),
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

            // Grade Applied & Blood Group
            _buildResponsiveRow(
              isMobile: isMobile,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grade / Class Applying For *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _gradeApplied,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        decoration: _inputDecoration(isDark),
                        items: _gradeOptions.map((g) {
                          return DropdownMenuItem(value: g, child: Text(g, style: const TextStyle(fontSize: 13)));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _gradeApplied = val);
                        },
                      ),
                    ],
                  ),
                ),
                if (!isMobile) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blood Group',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
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
              ],
            ),
            const SizedBox(height: 16),

            // Academic Year & Previous School
            _buildResponsiveRow(
              isMobile: isMobile,
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Academic Year',
                    controller: TextEditingController(text: _academicYear),
                    isDark: isDark,
                    readOnly: true,
                  ),
                ),
                if (!isMobile) const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Previous School Name (if applicable)',
                    controller: _previousSchoolController,
                    hint: 'e.g. St. Xavier’s Primary School',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Address
            _buildTextField(
              label: 'Residential / Current Address *',
              controller: _currentAddressController,
              hint: 'Complete street address, apartment, city, pincode',
              isDark: isDark,
              maxLines: 2,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Current address is required' : null,
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 2: Guardian Details
  // --------------------------------------------------------------------------
  Widget _buildStep2GuardianDetails(bool isDark, bool isMobile) {
    return Form(
      key: _step2Key,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeading(
              'Step 2: Parent / Guardian & Emergency Linking',
              'Official primary contact for notifications, billing, and school communication',
              Icons.contact_phone_outlined,
              isDark,
            ),
            const SizedBox(height: 20),

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
                      Text(
                        'Relationship *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
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
                    hint: 'e.g. Senior Software Engineer / Business Owner',
                    isDark: isDark,
                  ),
                ),
                if (!isMobile) const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Emergency Phone Number *',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
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
                      Row(
                        children: [
                          Checkbox(
                            value: _sameAsParentPhone,
                            activeColor: const Color(0xFF0D9488),
                            onChanged: (val) {
                              setState(() {
                                _sameAsParentPhone = val ?? false;
                                if (_sameAsParentPhone) {
                                  _emergencyContactController.text = _parentPhoneController.text.trim();
                                }
                              });
                            },
                          ),
                          Text(
                            'Same as primary phone number',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Fee Payer Toggle
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.receipt_long_outlined, color: Color(0xFF0D9488), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Designated Fee Payer',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Invoices and tuition fee clearance links will be billed to this guardian profile.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isFeePayer,
                    activeThumbColor: const Color(0xFF0D9488),
                    onChanged: (val) => setState(() => _isFeePayer = val),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 3: Documents & Review
  // --------------------------------------------------------------------------
  Widget _buildStep3DocumentsAndReview(bool isDark, bool isMobile) {
    return Form(
      key: _step3Key,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF131D31) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF24334C) : Colors.grey.shade200,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeading(
              'Step 3: Document Attachments & Declaration',
              'Check off submitted documents and confirm application submission',
              Icons.checklist_rounded,
              isDark,
            ),
            const SizedBox(height: 20),

            // Summary Pill Box
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D9488).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0D9488).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Application Summary Preview',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D9488),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 20,
                    runSpacing: 8,
                    children: [
                      _buildSummaryItem('Applicant:', '${_firstNameController.text} ${_lastNameController.text}', isDark),
                      _buildSummaryItem('Grade:', _gradeApplied, isDark),
                      _buildSummaryItem('DOB:', _dateOfBirth != null ? DateFormat('dd MMM yyyy').format(_dateOfBirth!) : '-', isDark),
                      _buildSummaryItem('Guardian:', '${_parentFullNameController.text} ($_parentRelationship)', isDark),
                      _buildSummaryItem('Phone:', _parentPhoneController.text, isDark),
                      _buildSummaryItem('Source:', widget.source.displayName, isDark),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Upload Certificates & Identity Proofs',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Attach scanned copies or clear photos of required documents (PDF, JPEG, PNG)',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 14),

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
            const SizedBox(height: 16),

            // Notes
            _buildTextField(
              label: 'Special Remarks / Internal Notes (Optional)',
              controller: _notesController,
              hint: 'e.g. Sibling studying in Class 8; fee concession requested; preferred second language Sanskrit',
              isDark: isDark,
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Declaration Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : Colors.amber.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _declarationAccepted,
                    activeColor: const Color(0xFF0D9488),
                    onChanged: (val) => setState(() => _declarationAccepted = val ?? false),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Institutional Declaration & Authenticity Guarantee',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'I declare that all details provided in this admission form are accurate and genuine. '
                          'Upon submission, this application will be forwarded to the Institutional Administrator '
                          'for certificate screening, interview scheduling, and official class placement.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
                            height: 1.4,
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
      ),
    );
  }


  Widget _buildSummaryItem(String label, String value, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? const Color(0xFFCBD5E1) : Colors.grey.shade700,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // Navigation & Action Buttons
  // --------------------------------------------------------------------------
  Widget _buildNavButtons(bool isDark, bool isMobile) {
    final prevOrCancelButton = _currentStep == 0
        ? OutlinedButton.icon(
            onPressed: widget.onCancel,
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Cancel Intake'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              foregroundColor: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          )
        : OutlinedButton.icon(
            onPressed: _prevStep,
            icon: const Icon(Icons.arrow_back, size: 16),
            label: const Text('Previous Step'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          );

    final nextOrSubmitButton = _currentStep < 2
        ? ElevatedButton.icon(
            onPressed: _nextStep,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Next Step ➔'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              backgroundColor: const Color(0xFF0D9488),
              foregroundColor: Colors.white,
            ),
          )
        : ElevatedButton.icon(
            onPressed: _submitForm,
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Submit Application to Admin ➔'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          nextOrSubmitButton,
          const SizedBox(height: 10),
          prevOrCancelButton,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        prevOrCancelButton,
        nextOrSubmitButton,
      ],
    );
  }

  // Helper widgets
  Widget _buildSectionHeading(String title, String subtitle, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D9488), size: 22),
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
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
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
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
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
        borderSide: const BorderSide(color: Color(0xFF0D9488), width: 1.5),
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
