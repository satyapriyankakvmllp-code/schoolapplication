import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../../authentication/domain/user_model.dart';
import '../../application/admissions_controller.dart';
import '../../data/admissions_repository.dart';
import '../../domain/admission_document_model.dart';
import '../../domain/parent_profile_model.dart';
import '../../domain/student_admission_model.dart';
import '../../domain/student_profile_model.dart';
import '../widgets/file_upload_box.dart';

class AddStudentFormScreen extends ConsumerStatefulWidget {
  final VoidCallback? onCancel;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final VoidCallback? onToggleTheme;
  final bool isDark;
  final StudentAdmissionModel? admissionToEdit;
  final bool isEditMode;
  final ValueChanged<String>? onSelectStudentForEdit;

  const AddStudentFormScreen({
    super.key,
    this.onCancel,
    this.onSubmitted,
    this.onNavigate,
    this.onToggleTheme,
    this.isDark = false,
    this.admissionToEdit,
    this.isEditMode = false,
    this.onSelectStudentForEdit,
  });

  @override
  ConsumerState<AddStudentFormScreen> createState() => _AddStudentFormScreenState();
}

class _AddStudentFormScreenState extends ConsumerState<AddStudentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  // Current Step: 0: Demographics, 1: Academic & Placement, 2: Guardian Linking, 3: Document Verification
  int _currentStep = 0;

  // --- STEP 1: Student Demographics ---
  String? _studentPhotoUrl;
  Uint8List? _studentPhotoBytes;
  String? _studentPhotoFileName;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  DateTime? _dateOfBirth;
  late String _gender;
  late String _bloodGroup;
  late final TextEditingController _studentPhoneController;
  late final TextEditingController _currentAddressController;

  // Step 1: Student Demographics & Identification
  late final TextEditingController _studentIdController;
  DateTime? _admissionDate;

  // --- STEP 2: Academic & Class Placement ---
  late String _academicYear;
  late String _selectedClass;
  late String _selectedSection;
  late final TextEditingController _step2RollNumberController;
  late String _mediumOfInstruction;
  late String _houseGroup;
  late String _secondLanguage;

  // --- STEP 3: Guardian & Contact Linking ---
  // A. Primary Guardian
  late final TextEditingController _primaryGuardianNameController;
  late String _primaryGuardianRelation;
  late final TextEditingController _primaryGuardianPhoneController;
  late final TextEditingController _primaryGuardianEmailController;
  late final TextEditingController _primaryGuardianAddressController;
  bool _primaryIsPrimaryContact = true;
  bool _primaryIsFeePayer = true;

  // B. Secondary Guardian (Optional)
  late final TextEditingController _secondaryGuardianNameController;
  late String _secondaryGuardianRelation;
  late final TextEditingController _secondaryGuardianPhoneController;
  late final TextEditingController _secondaryGuardianEmailController;
  bool _secondaryIsPrimaryContact = false;
  bool _secondaryIsFeePayer = false;

  // --- STEP 4: Document Verification ---
  String? _birthCertificateFile;
  String? _academicRecordFile;
  late String _idType;
  late final TextEditingController _idNumberController;
  DateTime? _idExpiryDate;
  String? _govtIdFile;

  // C. Declaration & Submission
  bool _certifyAuthentic = true;
  bool _consentVerification = true;

  bool _isSubmitting = false;
  StudentAdmissionModel? _activeAdmissionToEdit;

  @override
  void initState() {
    super.initState();
    _activeAdmissionToEdit = widget.admissionToEdit ?? ref.read(prefilledAdmissionDraftProvider);
    _initControllers();
    if (_activeAdmissionToEdit != null) {
      _populateFromAdmission(_activeAdmissionToEdit!);
    }
  }

  void _initControllers() {
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dateOfBirth = null;
    _gender = 'Male';
    _bloodGroup = 'O+';
    _studentPhoneController = TextEditingController();
    _currentAddressController = TextEditingController();

    _studentIdController = TextEditingController();
    _admissionDate = null;

    _academicYear = '2026-2027';
    _selectedClass = 'Class 1';
    _selectedSection = 'A';
    _step2RollNumberController = TextEditingController();
    _mediumOfInstruction = 'English';
    _houseGroup = 'Shivaji House';
    _secondLanguage = 'Hindi';

    _primaryGuardianNameController = TextEditingController();
    _primaryGuardianRelation = 'Father';
    _primaryGuardianPhoneController = TextEditingController();
    _primaryGuardianEmailController = TextEditingController();
    _primaryGuardianAddressController = TextEditingController();

    _secondaryGuardianNameController = TextEditingController();
    _secondaryGuardianRelation = 'Mother';
    _secondaryGuardianPhoneController = TextEditingController();
    _secondaryGuardianEmailController = TextEditingController();

    _idType = 'Aadhaar Card';
    _idNumberController = TextEditingController();
    _idExpiryDate = null;

    _studentPhotoUrl = null;
    _studentPhotoBytes = null;
    _studentPhotoFileName = null;
    _birthCertificateFile = null;
    _academicRecordFile = null;
    _govtIdFile = null;
  }

  void _populateFromAdmission(StudentAdmissionModel edit) {
    _studentPhotoUrl = edit.user.profilePhotoUrl;
    _firstNameController.text = edit.user.firstName;
    _lastNameController.text = edit.user.lastName;
    _dateOfBirth = edit.user.dateOfBirth ?? DateTime(2008, 4, 15);
    _gender = edit.user.gender?.displayName ?? 'Male';
    _bloodGroup = edit.student.bloodGroup ?? 'B+';
    _studentPhoneController.text = edit.user.phoneNumber;
    _currentAddressController.text = edit.student.currentAddress;

    _studentIdController.text = edit.student.admissionNumber;
    _admissionDate = edit.student.admissionDate;

    final guardianName = edit.father?.fullName ?? edit.guardian?.fullName ?? edit.mother?.fullName ?? '';
    final guardianRel = edit.selectedGuardianType;

    _academicYear = edit.student.academicYear;
    _selectedClass = edit.student.className;
    _selectedSection = edit.student.section;
    _step2RollNumberController.text = edit.student.rollNumber ?? '';
    _mediumOfInstruction = edit.student.mediumOfInstruction ?? 'English';
    _houseGroup = edit.student.houseGroup ?? 'Shivaji House';
    _secondLanguage = edit.student.secondLanguage ?? 'Hindi';

    _primaryGuardianNameController.text = guardianName;
    _primaryGuardianRelation = guardianRel;
    _primaryGuardianPhoneController.text = edit.father?.phoneNumber ?? edit.guardian?.phoneNumber ?? edit.mother?.phoneNumber ?? '';
    _primaryGuardianEmailController.text = edit.father?.email ?? edit.guardian?.email ?? edit.mother?.email ?? '';
    _primaryGuardianAddressController.text = edit.father?.residentialAddress ?? edit.student.currentAddress;

    _secondaryGuardianNameController.text = edit.mother?.fullName ?? '';
    _secondaryGuardianRelation = 'Mother';
    _secondaryGuardianPhoneController.text = edit.mother?.phoneNumber ?? '';
    _secondaryGuardianEmailController.text = edit.mother?.email ?? '';

    _birthCertificateFile = edit.student.dobCertificate;
    _academicRecordFile = null;
    _govtIdFile = null;
    if (edit.documents.isNotEmpty) {
      for (final doc in edit.documents) {
        final t = doc.title.toLowerCase();
        final f = doc.fileName.toLowerCase();
        if (t.contains('birth') || f.contains('birth') || f.contains('dob')) {
          _birthCertificateFile = doc.fileName;
        } else if (t.contains('academic') || t.contains('marksheet') || t.contains('transfer') || t.contains('tc') || f.contains('transfer') || f.contains('tc') || f.contains('marks') || f.contains('report')) {
          _academicRecordFile = doc.fileName;
        } else if (t.contains('govt') || t.contains('aadhaar') || t.contains('id') || f.contains('govt') || f.contains('aadhaar') || f.contains('id') || f.contains('passport')) {
          _govtIdFile = doc.fileName;
        }
      }
    }
    _idType = 'Aadhaar Card';
    _idNumberController.text = edit.student.nationalIdNumber ?? '';
    _idExpiryDate = (edit.student.nationalIdNumber != null && edit.student.nationalIdNumber!.isNotEmpty)
        ? DateTime(2032, 8, 20)
        : null;
  }

  void _clearControllers() {
    _firstNameController.clear();
    _lastNameController.clear();
    _dateOfBirth = null;
    _gender = 'Male';
    _bloodGroup = 'O+';
    _studentPhoneController.clear();
    _currentAddressController.clear();

    _studentIdController.clear();
    _admissionDate = null;

    _academicYear = '2026-2027';
    _selectedClass = 'Class 1';
    _selectedSection = 'A';
    _step2RollNumberController.clear();
    _mediumOfInstruction = 'English';
    _houseGroup = 'Shivaji House';
    _secondLanguage = 'Hindi';

    _primaryGuardianNameController.clear();
    _primaryGuardianRelation = 'Father';
    _primaryGuardianPhoneController.clear();
    _primaryGuardianEmailController.clear();
    _primaryGuardianAddressController.clear();

    _secondaryGuardianNameController.clear();
    _secondaryGuardianRelation = 'Mother';
    _secondaryGuardianPhoneController.clear();
    _secondaryGuardianEmailController.clear();

    _idType = 'Aadhaar Card';
    _idNumberController.clear();
    _idExpiryDate = null;

    _studentPhotoUrl = null;
    _studentPhotoBytes = null;
    _studentPhotoFileName = null;
    _birthCertificateFile = null;
    _academicRecordFile = null;
    _govtIdFile = null;
  }

  @override
  void didUpdateWidget(covariant AddStudentFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.admissionToEdit != oldWidget.admissionToEdit) {
      _activeAdmissionToEdit = widget.admissionToEdit;
      if (widget.admissionToEdit != null) {
        setState(() {
          _populateFromAdmission(widget.admissionToEdit!);
        });
      } else {
        setState(() {
          _clearControllers();
        });
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _studentPhoneController.dispose();
    _currentAddressController.dispose();
    _studentIdController.dispose();
    _step2RollNumberController.dispose();
    _primaryGuardianNameController.dispose();
    _primaryGuardianPhoneController.dispose();
    _primaryGuardianEmailController.dispose();
    _primaryGuardianAddressController.dispose();
    _secondaryGuardianNameController.dispose();
    _secondaryGuardianPhoneController.dispose();
    _secondaryGuardianEmailController.dispose();
    _idNumberController.dispose();
    super.dispose();
  }

  void _saveDraft() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Draft saved successfully! You can resume anytime.'),
        backgroundColor: Color(0xFF1E3A8A),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _submitApplication() async {
    if (!_certifyAuthentic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please certify document authenticity to proceed with submission.'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }


    setState(() => _isSubmitting = true);

    try {
      final isOriginatingRequest = ref.read(originatingRequestIdProvider) != null;
      final isEditing = !isOriginatingRequest && (widget.admissionToEdit != null || widget.isEditMode || _activeAdmissionToEdit != null);
      final studentId = _activeAdmissionToEdit != null
          ? _activeAdmissionToEdit!.student.id
          : (widget.admissionToEdit != null
              ? widget.admissionToEdit!.student.id
              : 'std-${DateTime.now().millisecondsSinceEpoch}');
      final userId = _activeAdmissionToEdit != null
          ? _activeAdmissionToEdit!.user.id
          : (widget.admissionToEdit != null
              ? widget.admissionToEdit!.user.id
              : 'usr-${DateTime.now().millisecondsSinceEpoch}');

      final newAdmission = StudentAdmissionModel(
        user: UserModel(
          id: userId,
          email: '${_firstNameController.text.toLowerCase().trim()}.${_lastNameController.text.toLowerCase().trim()}@example.com',
          phoneNumber: _studentPhoneController.text.trim(),
          userRole: UserRole.student,
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          profilePhotoUrl: _studentPhotoUrl,
          gender: Gender.fromString(_gender),
          dateOfBirth: _dateOfBirth,
          status: AccountStatus.active,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        student: StudentProfileModel(
          id: studentId,
          userId: userId,
          admissionNumber: _studentIdController.text.trim(),
          rollNumber: _step2RollNumberController.text.trim(),
          className: _selectedClass,
          section: _selectedSection,
          admissionDate: _admissionDate ?? DateTime.now(),
          academicYear: _academicYear,
          bloodGroup: _bloodGroup,
          emergencyContactPhone: (_secondaryIsPrimaryContact && _secondaryGuardianPhoneController.text.trim().isNotEmpty)
              ? _secondaryGuardianPhoneController.text.trim()
              : _primaryGuardianPhoneController.text.trim(),
          currentAddress: _currentAddressController.text.trim(),
          residentialAddress: _currentAddressController.text.trim(),
          dobCertificate: _birthCertificateFile,
          mediumOfInstruction: _mediumOfInstruction,
          houseGroup: _houseGroup,
          secondLanguage: _secondLanguage,
          nationalIdNumber: _idNumberController.text.trim(),
        ),
        father: ParentProfileModel(
          id: 'par-p-${DateTime.now().millisecondsSinceEpoch}',
          userId: 'usr-p-${DateTime.now().millisecondsSinceEpoch}',
          fullName: _primaryGuardianNameController.text.trim(),
          relationship: _primaryGuardianRelation,
          phoneNumber: _primaryGuardianPhoneController.text.trim(),
          email: _primaryGuardianEmailController.text.trim(),
          residentialAddress: _primaryGuardianAddressController.text.trim(),
        ),
        mother: ParentProfileModel(
          id: 'par-s-${DateTime.now().millisecondsSinceEpoch}',
          userId: 'usr-s-${DateTime.now().millisecondsSinceEpoch}',
          fullName: _secondaryGuardianNameController.text.trim(),
          relationship: _secondaryGuardianRelation,
          phoneNumber: _secondaryGuardianPhoneController.text.trim(),
          email: _secondaryGuardianEmailController.text.trim(),
          residentialAddress: _primaryGuardianAddressController.text.trim(),
        ),
        guardian: ParentProfileModel(
          id: 'par-g-${DateTime.now().millisecondsSinceEpoch}',
          userId: 'usr-g-${DateTime.now().millisecondsSinceEpoch}',
          fullName: _primaryGuardianNameController.text.trim(),
          relationship: _primaryGuardianRelation,
          phoneNumber: _primaryGuardianPhoneController.text.trim(),
          email: _primaryGuardianEmailController.text.trim(),
          residentialAddress: _primaryGuardianAddressController.text.trim(),
        ),
        selectedGuardianType: _primaryGuardianRelation,
        documents: [
          if (_birthCertificateFile != null)
            AdmissionDocumentModel(
              id: 'doc-01',
              title: 'Birth Certificate',
              fileName: _birthCertificateFile!,
              fileSize: '1.4 MB',
              fileType: _birthCertificateFile!.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
              isVerified: true,
              uploadedAt: DateTime.now(),
            ),
          if (_academicRecordFile != null)
            AdmissionDocumentModel(
              id: 'doc-02',
              title: 'Previous Academic Record',
              fileName: _academicRecordFile!,
              fileSize: '2.1 MB',
              fileType: _academicRecordFile!.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
              isVerified: true,
              uploadedAt: DateTime.now(),
            ),
          if (_govtIdFile != null)
            AdmissionDocumentModel(
              id: 'doc-03',
              title: 'Government ID ($_idType)',
              fileName: _govtIdFile!,
              fileSize: '2.8 MB',
              fileType: _govtIdFile!.toLowerCase().endsWith('.pdf') ? 'pdf' : 'image',
              isVerified: true,
              uploadedAt: DateTime.now(),
            ),
        ],
        loginEmail: '${_firstNameController.text.toLowerCase().trim()}.${_lastNameController.text.toLowerCase().trim()}@example.com',
        loginPassword: '••••••••',
      );

      final notifier = ref.read(admissionsListProvider.notifier);
      await notifier.saveAdmission(newAdmission);
      ref.read(selectedStudentIdProvider.notifier).state = studentId;

      final originatingReqId = ref.read(originatingRequestIdProvider);
      if (originatingReqId != null) {
        await ref.read(admissionRequestsListProvider.notifier).markApproved(originatingReqId);
        ref.read(originatingRequestIdProvider.notifier).state = null;
        ref.read(prefilledAdmissionDraftProvider.notifier).state = null;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? 'Student profile for ${newAdmission.user.fullName} updated successfully!'
                : 'Admission intake for ${newAdmission.user.fullName} completed successfully!'),
            backgroundColor: const Color(0xFF109F83),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onSubmitted?.call(studentId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allStudents = ref.watch(admissionsListProvider).valueOrNull ?? MockAdmissionsRepository.defaultAdmissions;
    final isEditing = widget.isEditMode;

    return EdupluseScaffold(
      activePage: widget.isEditMode ? EdupluseNavPage.editStudent : EdupluseNavPage.addNewStudent,
      onNavigate: widget.onNavigate,
      onToggleTheme: widget.onToggleTheme,
      isDark: widget.isDark,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 24, vertical: isMobile ? 14 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTopBar(isMobile: isMobile, isEditing: isEditing),
                  if (widget.isEditMode) ...[
                    const SizedBox(height: 16),
                    _buildStudentPickerForEdit(
                      isMobile: isMobile,
                      isDark: widget.isDark,
                      allStudents: allStudents,
                    ),
                  ],
                  const SizedBox(height: 18),
                  _buildStepperIndicator(isMobile: isMobile),
                  const SizedBox(height: 18),
                  _buildCurrentStepCard(isMobile: isMobile),
                  const SizedBox(height: 24),
                  _buildBottomActionBar(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // --- STUDENT PICKER FOR EDIT MODE ---
  Widget _buildStudentPickerForEdit({
    required bool isMobile,
    required bool isDark,
    required List<StudentAdmissionModel> allStudents,
  }) {
    final selectedStudentId = allStudents.any((s) => s.student.id == _activeAdmissionToEdit?.student.id)
        ? _activeAdmissionToEdit?.student.id
        : null;
    final hasActiveStudent = selectedStudentId != null;

    final dropdownWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasActiveStudent
              ? const Color(0xFF109F83)
              : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedStudentId,
          hint: Row(
            children: const [
              Icon(Icons.touch_app_outlined, size: 16, color: Color(0xFF109F83)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Select student to populate fields...',
                  style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          items: allStudents.map((s) {
            return DropdownMenuItem<String>(
              value: s.student.id,
              child: Text(
                '${s.user.fullName} (${s.student.admissionNumber} - ${s.student.className})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: (id) {
            if (id != null) {
              final chosen = allStudents.firstWhere((s) => s.student.id == id);
              setState(() {
                _activeAdmissionToEdit = chosen;
                _populateFromAdmission(chosen);
              });
              widget.onSelectStudentForEdit?.call(id);
            }
          },
        ),
      ),
    );

    final clearButton = TextButton.icon(
      onPressed: () {
        setState(() {
          _activeAdmissionToEdit = null;
          _clearControllers();
        });
      },
      icon: const Icon(Icons.refresh, size: 15, color: Color(0xFFEF4444)),
      label: const Text(
        'Clear / Blank Form',
        style: TextStyle(color: Color(0xFFEF4444), fontSize: 12.5, fontWeight: FontWeight.w600),
      ),
    );

    final quickChips = Wrap(
      spacing: 6,
      runSpacing: 6,
      children: allStudents.take(4).map((s) {
        final isSelected = _activeAdmissionToEdit?.student.id == s.student.id;
        return ActionChip(
          avatar: Icon(
            isSelected ? Icons.check_circle : Icons.person_outline,
            size: 14,
            color: isSelected ? Colors.white : const Color(0xFF109F83),
          ),
          label: Text(s.user.fullName),
          labelStyle: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
          ),
          backgroundColor: isSelected
              ? const Color(0xFF109F83)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF109F83)
                : (isDark ? const Color(0xFF475569) : Colors.grey.shade300),
          ),
          onPressed: () {
            setState(() {
              _activeAdmissionToEdit = s;
              _populateFromAdmission(s);
            });
            widget.onSelectStudentForEdit?.call(s.student.id);
          },
        );
      }).toList(),
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasActiveStudent
              ? const Color(0xFF109F83).withOpacity(0.4)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF109F83).withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.manage_accounts_outlined, size: 16, color: Color(0xFF109F83)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Student to Edit',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  if (!hasActiveStudent) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Empty State',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.amber),
                      ),
                    ),
                  ],
                ],
              ),
              if (hasActiveStudent) clearButton,
            ],
          ),
          const SizedBox(height: 10),
          if (isMobile) ...[
            dropdownWidget,
            const SizedBox(height: 8),
            quickChips,
          ] else ...[
            Row(
              children: [
                Expanded(child: dropdownWidget),
                const SizedBox(width: 12),
                quickChips,
              ],
            ),
          ],
        ],
      ),
    );
  }

  // --- TOP BAR ---
  Widget _buildTopBar({required bool isMobile, required bool isEditing}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    final backButton = InkWell(
      onTap: widget.onCancel ?? () => widget.onNavigate?.call(EdupluseNavPage.studentDetails),
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.arrow_back, size: 16, color: Color(0xFF475569)),
            const SizedBox(width: 6),
            Text(
              isEditing ? 'Edit Student Details' : 'New Student Admission',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );

    final titleWidget = Text(
      isEditing
          ? (_activeAdmissionToEdit != null
              ? 'Edit Student: ${_activeAdmissionToEdit!.user.fullName}'
              : 'Edit Student Details')
          : 'Student Admission Intake',
      style: TextStyle(
        fontSize: isMobile ? 20 : 24,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
        letterSpacing: -0.5,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );

    final subtitleWidget = Text(
      isEditing
          ? (_activeAdmissionToEdit != null
              ? 'Updating enrollment & profile details for ${_activeAdmissionToEdit!.student.admissionNumber}'
              : 'Select an enrolled student to edit their details, or start entering information')
          : 'Academic Session 2026–2027',
      style: TextStyle(
        fontSize: 12.5,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w400,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    final saveDraftButton = OutlinedButton(
      onPressed: _saveDraft,
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
        side: BorderSide(
          color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1),
          width: 1.2,
        ),
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 18, vertical: isMobile ? 8 : 11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        isMobile ? 'Save Draft' : 'Save as Draft',
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          backButton,
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleWidget,
                    const SizedBox(height: 2),
                    subtitleWidget,
                  ],
                ),
              ),
              const SizedBox(width: 8),
              saveDraftButton,
            ],
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              backButton,
              const SizedBox(height: 6),
              titleWidget,
              const SizedBox(height: 2),
              subtitleWidget,
            ],
          ),
        ),
        const SizedBox(width: 16),
        saveDraftButton,
      ],
    );
  }

  // --- 4-STEP INDICATOR ---
  Widget _buildStepperIndicator({required bool isMobile}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final steps = [
      'Student Demographics',
      'Academic & Class Placement',
      'Guardian & Contact Linking',
      'Document Verification',
    ];

    if (isMobile) {
      // Sleek mobile stepper: Step counter + Active step title + Progress pills
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: const [
            BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Step ${_currentStep + 1} of 4: ${steps[_currentStep]}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${((_currentStep + 1) * 25)}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF109F83),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: List.generate(4, (index) {
                final isPast = index < _currentStep;
                final isCurrent = index == _currentStep;
                return Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _currentStep = index),
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      height: 6,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: isPast || isCurrent
                            ? const Color(0xFF1E3A8A)
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 3)),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(steps.length * 2 - 1, (index) {
            if (index.isOdd) {
              final leftStep = index ~/ 2;
              final isCompleted = leftStep < _currentStep;
              return Container(
                width: 48,
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: isCompleted ? const Color(0xFF1E3A8A) : (isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1)),
              );
            }

            final stepIndex = index ~/ 2;
            final isPast = stepIndex < _currentStep;
            final isCurrent = stepIndex == _currentStep;

            return InkWell(
              onTap: () => setState(() => _currentStep = stepIndex),
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isPast || isCurrent ? const Color(0xFF1E3A8A) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: isPast
                          ? const Icon(Icons.check, size: 16, color: Colors.white)
                          : Text(
                              '0${stepIndex + 1}',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isCurrent ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    steps[stepIndex],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  // --- STEP CARD CONTAINER ---
  Widget _buildCurrentStepCard({required bool isMobile}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 16 : 28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x06000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: _buildStepContent(),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildStep1Demographics();
      case 1:
        return _buildStep2AcademicPlacement();
      case 2:
        return _buildStep3GuardianLinking();
      case 3:
      default:
        return _buildStep4DocumentVerification();
    }
  }

  Future<void> _pickStudentPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.first;
        setState(() {
          _studentPhotoBytes = picked.bytes;
          _studentPhotoFileName = picked.name;
          _studentPhotoUrl = picked.name;
        });
      }
    } catch (_) {
      if (mounted) {
        _showManualPhotoDialog();
      }
    }
  }

  void _removeStudentPhoto() {
    setState(() {
      _studentPhotoBytes = null;
      _studentPhotoFileName = null;
      _studentPhotoUrl = null;
    });
  }

  void _showManualPhotoDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Attach Student Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter image file name or choose a sample photo:',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              decoration: InputDecoration(
                hintText: 'e.g., student_passport_photo.jpg',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.person, size: 14),
                  label: const Text('arjun_photo.jpg', style: TextStyle(fontSize: 11.5)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onPressed: () => textController.text = 'arjun_photo.jpg',
                ),
                ActionChip(
                  avatar: const Icon(Icons.person, size: 14),
                  label: const Text('passport_size_photo.png', style: TextStyle(fontSize: 11.5)),
                  backgroundColor: const Color(0xFFF1F5F9),
                  onPressed: () => textController.text = 'passport_size_photo.png',
                ),
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
                  _studentPhotoFileName = name;
                  _studentPhotoUrl = name;
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF109F83),
              foregroundColor: Colors.white,
            ),
            child: const Text('Attach Photo'),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoUploader() {
    final isFulfilled = _studentPhotoUrl != null && _studentPhotoUrl!.isNotEmpty;

    return Center(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: _pickStudentPhoto,
                borderRadius: BorderRadius.circular(60),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isFulfilled ? const Color(0xFFF0FDF4) : const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFulfilled ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                      width: isFulfilled ? 2.5 : 1.5,
                    ),
                    boxShadow: [
                      if (isFulfilled)
                        const BoxShadow(
                          color: Color(0x1810B981),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                    ],
                  ),
                  child: ClipOval(
                    child: _studentPhotoBytes != null
                        ? Image.memory(
                            _studentPhotoBytes!,
                            width: 120,
                            height: 120,
                            fit: BoxFit.cover,
                          )
                        : (_studentPhotoUrl != null && _studentPhotoUrl!.startsWith('http'))
                            ? Image.network(
                                _studentPhotoUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.account_circle,
                                  size: 48,
                                  color: Color(0xFF109F83),
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isFulfilled ? Icons.account_circle : Icons.camera_alt_outlined,
                                    size: 36,
                                    color: isFulfilled ? const Color(0xFF109F83) : const Color(0xFF64748B),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    isFulfilled ? 'Photo Added' : 'Upload Photo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isFulfilled ? const Color(0xFF109F83) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                  ),
                ),
              ),
              if (isFulfilled)
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 14, color: Colors.white),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: isFulfilled ? const Color(0xFFDCFCE7) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFulfilled ? const Color(0xFF86EFAC) : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFulfilled ? Icons.check_circle : Icons.radio_button_unchecked,
                  size: 11,
                  color: isFulfilled ? const Color(0xFF15803D) : const Color(0xFF64748B),
                ),
                const SizedBox(width: 4),
                Text(
                  isFulfilled ? 'Fulfilled' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isFulfilled ? const Color(0xFF15803D) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          if (isFulfilled && _studentPhotoFileName != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                _studentPhotoFileName!,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (isFulfilled)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: _pickStudentPhoto,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text('Change', style: TextStyle(fontSize: 11, color: Color(0xFF0284C7))),
                ),
                TextButton(
                  onPressed: _removeStudentPhoto,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  child: const Text('Remove', style: TextStyle(fontSize: 11, color: Color(0xFFEF4444))),
                ),
              ],
            )
          else
            Text(
              'JPG, PNG max 2MB',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // STEP 1: Student Demographics
  // ==========================================
  Widget _buildStep1Demographics() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 750;
        final photoUploader = _buildPhotoUploader();

        final formFields = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Student Personal Details
            _buildSectionHeader('Student Personal Details'),
            const SizedBox(height: 14),
            _buildGridRow([
              _buildReadOnlyField('Student ID', _studentIdController, hasLock: true),
              _buildField('First Name', 'First Name', _firstNameController),
              _buildField('Last Name', 'Last Name', _lastNameController),
            ], flexes: [1, 1, 1]),
            const SizedBox(height: 14),
            _buildGridRow([
              _buildDatePicker('Date of Birth', _dateOfBirth, (d) => setState(() => _dateOfBirth = d), placeholder: 'Select Date of Birth'),
              _buildDropdown('Gender', _gender, ['Male', 'Female', 'Other'], (v) => setState(() => _gender = v!)),
              _buildDropdown('Blood Group', _bloodGroup, ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'], (v) => setState(() => _bloodGroup = v!)),
            ]),
            const SizedBox(height: 14),
            _buildGridRow([
              _buildField('Phone Number', 'Phone Number', _studentPhoneController),
              _buildField('Current Address', 'Current Address', _currentAddressController),
            ], flexes: [1, 2]),
          ],
        );

        if (isMobile) {
          return Column(
            children: [
              photoUploader,
              const SizedBox(height: 24),
              formFields,
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 150, child: photoUploader),
            const SizedBox(width: 32),
            Expanded(child: formFields),
          ],
        );
      },
    );
  }

  // ==========================================
  // STEP 2: Academic & Class Placement
  // ==========================================
  Widget _buildStep2AcademicPlacement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Admission & Enrollment
        _buildSectionHeader('A. Admission & Enrollment'),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildReadOnlyField('Admission Number', _studentIdController, hasLock: true),
          _buildDatePicker('Admission Date', _admissionDate, (d) => setState(() => _admissionDate = d), placeholder: 'Select Admission Date'),
          _buildDropdown('Academic Year', _academicYear, [
            '2024-2025',
            '2025-2026',
            '2026-2027',
            '2027-2028',
            'Jun 2025/2026'
          ], (v) => setState(() => _academicYear = v!)),
        ]),

        const SizedBox(height: 28),
        // B. Class Placement
        _buildSectionHeader('B. Class Placement'),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildDropdown('Class & Section', _selectedClass, [
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
            'Primary',
            'Grade 8',
            'Grade 9',
            'Grade 10',
          ], (v) => setState(() => _selectedClass = v!)),
          _buildDropdown('Section', _selectedSection, ['A', 'B', 'C', 'D', 'Science', 'Commerce', 'Arts'], (v) => setState(() => _selectedSection = v!)),
          _buildField('Roll Number', 'Roll Number', _step2RollNumberController),
          _buildDropdown('Medium of Instruction', _mediumOfInstruction, ['English', 'Hindi', 'Spanish', 'French', 'Bilingual'], (v) => setState(() => _mediumOfInstruction = v!)),
        ]),

        const SizedBox(height: 28),
        // C. Additional Assignment
        _buildSectionHeader('C. Additional Assignment'),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildDropdown('House / Group', _houseGroup, [
            'Shivaji House',
            'Tagore House',
            'Ashoka House',
            'Raman House',
            'Phoenix',
            'Titans',
            'Spartans',
            'Hawks',
            'Red House',
            'Blue House'
          ], (v) => setState(() => _houseGroup = v!)),
          _buildDropdown('Second Language / Elective', _secondLanguage, ['Hindi', 'Sanskrit', 'Spanish', 'French', 'German', 'Computer Science'], (v) => setState(() => _secondLanguage = v!)),
        ]),
      ],
    );
  }

  // ==========================================
  // STEP 3: Guardian & Contact Linking
  // ==========================================
  Widget _buildStep3GuardianLinking() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Primary Guardian Information
        _buildSectionHeader('A. Primary Guardian Information'),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildField('Parent / Guardian Full Name', 'Enter full name', _primaryGuardianNameController),
          _buildDropdown('Relationship', _primaryGuardianRelation, ['Father', 'Mother', 'Legal Guardian', 'Grandparent', 'Other'], (v) => setState(() => _primaryGuardianRelation = v!)),
        ]),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildField('Phone Number', 'Enter phone number', _primaryGuardianPhoneController),
          _buildField('Email Address', 'Enter email address', _primaryGuardianEmailController),
        ]),
        const SizedBox(height: 14),
        _buildField('Current Address', 'Enter current address', _primaryGuardianAddressController, maxLines: 2),
        const SizedBox(height: 14),
        Wrap(
          spacing: 32,
          runSpacing: 12,
          children: [
            _buildToggleSwitch(
              label: 'Set as Primary Contact',
              value: _primaryIsPrimaryContact,
              onChanged: (v) => setState(() {
                _primaryIsPrimaryContact = v;
                _secondaryIsPrimaryContact = !v;
              }),
            ),
            _buildToggleSwitch(
              label: 'Authorized Fee Payer',
              value: _primaryIsFeePayer,
              onChanged: (v) => setState(() {
                _primaryIsFeePayer = v;
                _secondaryIsFeePayer = !v;
              }),
            ),
          ],
        ),

        const SizedBox(height: 32),
        // B. Secondary Guardian Information (Optional)
        _buildSectionHeader('B. Secondary Guardian Information (Optional)'),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildField('Parent / Guardian Full Name', 'Enter full name', _secondaryGuardianNameController),
          _buildDropdown('Relationship', _secondaryGuardianRelation, ['Mother', 'Father', 'Legal Guardian', 'Other'], (v) => setState(() => _secondaryGuardianRelation = v!)),
        ]),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildField('Phone Number', 'Enter phone number', _secondaryGuardianPhoneController),
          _buildField('Email Address', 'Enter email address', _secondaryGuardianEmailController),
        ]),
        const SizedBox(height: 14),
        Wrap(
          spacing: 32,
          runSpacing: 12,
          children: [
            _buildToggleSwitch(
              label: 'Set as Primary Contact',
              value: _secondaryIsPrimaryContact,
              onChanged: (v) => setState(() {
                _secondaryIsPrimaryContact = v;
                _primaryIsPrimaryContact = !v;
              }),
            ),
            _buildToggleSwitch(
              label: 'Authorized Fee Payer',
              value: _secondaryIsFeePayer,
              onChanged: (v) => setState(() {
                _secondaryIsFeePayer = v;
                _primaryIsFeePayer = !v;
              }),
            ),
          ],
        ),
      ],
    );
  }

  // ==========================================
  // STEP 4: Document Verification
  // ==========================================
  Widget _buildStep4DocumentVerification() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A. Upload Required Documents
        _buildSectionHeader('A. Upload Required Documents'),
        const SizedBox(height: 14),
        _buildGridRow([
          FileUploadBox(
            label: 'Birth Certificate',
            helperText: 'Click to upload or drag & drop\nSupport PDF, JPEG, PNG (max 5MB)',
            initialFileName: _birthCertificateFile,
            isRequired: false,
            onFileSelected: (fn) => setState(() => _birthCertificateFile = fn.isEmpty ? null : fn),
            onFileRemoved: () => setState(() => _birthCertificateFile = null),
          ),
          FileUploadBox(
            label: 'Previous Academic Record / Transcript (Optional)',
            helperText: 'Click to upload or drag & drop\nSupport PDF, JPEG, PNG (max 5MB)',
            initialFileName: _academicRecordFile,
            isRequired: false,
            onFileSelected: (fn) => setState(() => _academicRecordFile = fn.isEmpty ? null : fn),
            onFileRemoved: () => setState(() => _academicRecordFile = null),
          ),
        ]),

        const SizedBox(height: 28),
        // B. Identification & ID Details
        _buildSectionHeader('B. Identification & ID Details'),
        const SizedBox(height: 14),
        _buildGridRow([
          _buildDropdown('ID Type', _idType, ['National ID', 'Passport', 'Birth Certificate', 'Aadhaar Card'], (v) => setState(() => _idType = v!)),
          _buildField('ID Number', 'Enter ID number', _idNumberController),
          _buildDatePicker('ID Expiry Date', _idExpiryDate, (d) => setState(() => _idExpiryDate = d), placeholder: 'Select Expiry Date'),
        ]),
        const SizedBox(height: 16),
        FileUploadBox(
          label: 'Upload Government ID (Optional)',
          helperText: 'Click to upload or drag & drop\nSupport PDF, JPEG, PNG (max 10MB)',
          initialFileName: _govtIdFile,
          isRequired: false,
          onFileSelected: (fn) => setState(() => _govtIdFile = fn.isEmpty ? null : fn),
          onFileRemoved: () => setState(() => _govtIdFile = null),
        ),

        const SizedBox(height: 28),
        // C. Declaration & Submission
        _buildSectionHeader('C. Declaration & Submission'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 32,
          runSpacing: 14,
          children: [
            _buildToggleSwitch(
              label: 'I certify that all uploaded documents are authentic and original',
              value: _certifyAuthentic,
              onChanged: (v) => setState(() => _certifyAuthentic = v),
            ),
            _buildToggleSwitch(
              label: 'Consent to standard identification verification checks',
              value: _consentVerification,
              onChanged: (v) => setState(() => _consentVerification = v),
            ),
          ],
        ),
      ],
    );
  }

  // --- BOTTOM ACTION BAR ---
  Widget _buildBottomActionBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 650;

        final proceedButton = ElevatedButton(
          onPressed: _isSubmitting
              ? null
              : () {
                  if (_currentStep < 3) {
                    setState(() => _currentStep++);
                  } else {
                    _submitApplication();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1E3A8A),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 24, vertical: isMobile ? 14 : 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  _currentStep < 3
                      ? 'Proceed to Next Step →'
                      : ((ref.read(originatingRequestIdProvider) == null && (widget.admissionToEdit != null || widget.isEditMode || _activeAdmissionToEdit != null))
                          ? 'Update Student Information →'
                          : 'Submit Application →'),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  textAlign: TextAlign.center,
                ),
        );

        final saveDraftButton = OutlinedButton(
          onPressed: _saveDraft,
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
            side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.2),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 12 : 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save Draft', style: TextStyle(fontWeight: FontWeight.w600)),
        );

        final cancelButton = OutlinedButton(
          onPressed: widget.onCancel ?? () => widget.onNavigate?.call(EdupluseNavPage.studentDetails),
          style: OutlinedButton.styleFrom(
            foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
            side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.2),
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 12 : 13),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
        );

        final backButton = _currentStep > 0
            ? OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark ? Colors.white : const Color(0xFF334155),
                  side: BorderSide(color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), width: 1.2),
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: isMobile ? 12 : 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('← Back', style: TextStyle(fontWeight: FontWeight.w600)),
              )
            : null;

        if (isMobile) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              proceedButton,
              const SizedBox(height: 10),
              Row(
                children: [
                  if (backButton != null) ...[
                    Expanded(child: backButton),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: saveDraftButton),
                ],
              ),
              const SizedBox(height: 10),
              cancelButton,
            ],
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                cancelButton,
                if (backButton != null) ...[
                  const SizedBox(width: 10),
                  backButton,
                ],
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                saveDraftButton,
                const SizedBox(width: 12),
                proceedButton,
              ],
            ),
          ],
        );
      },
    );
  }

  // --- REUSABLE UI BUILDERS ---

  Widget _buildSectionHeader(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Text(
      title,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1E293B),
        letterSpacing: -0.2,
      ),
    );
  }

  Widget _buildGridRow(List<Widget> children, {List<int>? flexes}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 650) {
          return Column(
            children: children
                .map((w) => Padding(padding: const EdgeInsets.only(bottom: 12), child: w))
                .toList(),
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(children.length, (i) {
            final flex = flexes != null && i < flexes.length ? flexes[i] : 1;
            return Expanded(
              flex: flex,
              child: Padding(
                padding: EdgeInsets.only(
                  right: i == children.length - 1 ? 0 : 12,
                ),
                child: children[i],
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildField(String label, String hint, TextEditingController controller, {int maxLines = 1}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade400,
              fontSize: 13,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyField(String label, TextEditingController controller, {bool hasLock = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (hasLock) ...[
              const SizedBox(width: 8),
              Text('Read-only', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade500)),
            ],
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: true,
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF0F172A)),
          decoration: InputDecoration(
            hintText: controller.text.isEmpty ? 'Auto-assigned upon save' : null,
            hintStyle: TextStyle(fontSize: 12.5, color: isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
            filled: true,
            fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            suffixIcon: hasLock ? Icon(Icons.lock_outline, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)) : null,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    final cleanValue = value.trim();
    final uniqueItems = <String>{};
    if (cleanValue.isNotEmpty) {
      uniqueItems.add(cleanValue);
    }
    for (final it in items) {
      final t = it.trim();
      if (t.isNotEmpty) uniqueItems.add(t);
    }
    final effectiveItems = uniqueItems.toList();
    final effectiveValue = effectiveItems.contains(cleanValue)
        ? cleanValue
        : (effectiveItems.isNotEmpty ? effectiveItems.first : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          key: ValueKey('${label}_${effectiveValue}_${effectiveItems.length}'),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          initialValue: effectiveValue,
          items: effectiveItems
              .map((e) => DropdownMenuItem<String>(
                    value: e,
                    child: Text(
                      e,
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
        ),
      ],
    );
  }

  Widget _buildDatePicker(String label, DateTime? value, ValueChanged<DateTime> onChanged, {String placeholder = 'Select Date'}) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime(2012, 1, 1),
              firstDate: DateTime(1990),
              lastDate: DateTime(2035),
            );
            if (picked != null) onChanged(picked);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value != null ? DateFormat('dd-MM-yyyy').format(value) : placeholder,
                    style: TextStyle(
                      fontSize: 13,
                      color: value != null
                          ? (isDark ? Colors.white : const Color(0xFF0F172A))
                          : (isDark ? const Color(0xFF64748B) : Colors.grey.shade400),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.calendar_today_outlined, size: 16, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSwitch({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark || widget.isDark;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: value,
                activeThumbColor: const Color(0xFF109F83),
                onChanged: onChanged,
              ),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
