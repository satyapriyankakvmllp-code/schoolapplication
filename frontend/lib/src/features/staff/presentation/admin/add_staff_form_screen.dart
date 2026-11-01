import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../commonwidgets/edupluse_scaffold.dart';
import '../../application/staff_controller.dart';
import '../../domain/class_subject_assignment.dart';
import '../../domain/staff_compensation_model.dart';
import '../../domain/staff_login_account_model.dart';
import '../../domain/staff_member_model.dart';
import '../../../classes/application/classes_controller.dart';
import '../widgets/class_pairing_box.dart';

class AddStaffFormScreen extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isEditMode;
  final StaffMemberModel? staffToEdit;
  final VoidCallback? onToggleTheme;
  final ValueChanged<EdupluseNavPage>? onNavigate;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onCancel;
  final VoidCallback? onExitToGateway;

  const AddStaffFormScreen({
    super.key,
    required this.isDark,
    this.isEditMode = false,
    this.staffToEdit,
    this.onToggleTheme,
    this.onNavigate,
    this.onSubmitted,
    this.onCancel,
    this.onExitToGateway,
  });

  @override
  ConsumerState<AddStaffFormScreen> createState() => _AddStaffFormScreenState();
}

class _AddStaffFormScreenState extends ConsumerState<AddStaffFormScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Step 1 Controllers
  late String _staffId;
  final _fullNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _currentAddressCtrl = TextEditingController();
  final _permanentAddressCtrl = TextEditingController();
  final _emergencyContactCtrl = TextEditingController();
  String _gender = 'Female';
  String _bloodGroup = 'O+';
  DateTime? _dob = DateTime(1988, 5, 15);

  // Step 2 Controllers
  StaffCategory _category = StaffCategory.teaching;
  String _department = 'Mathematics';
  final _designationCtrl = TextEditingController();
  final _qualificationCtrl = TextEditingController();
  DateTime _joiningDate = DateTime.now();
  EmploymentType _employmentType = EmploymentType.permanent;

  // Step 3 Controllers (Teaching conditional)
  final _specializationCtrl = TextEditingController();
  List<ClassSubjectAssignment> _assignedClasses = [];

  // Step 4 Controllers (Compensation & Login)
  final _salaryCtrl = TextEditingController();
  final _bankNameCtrl = TextEditingController();
  final _accountNumberCtrl = TextEditingController();
  final _ifscCtrl = TextEditingController();
  final _panCtrl = TextEditingController();
  final _epfUanCtrl = TextEditingController();

  bool _sameAsCurrentAddress = false;

  bool _provisionLogin = true;
  final _loginEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();
  String _systemRole = 'teacher';

  bool _isSaving = false;

  static const Map<StaffCategory, List<String>> _categoryDepartments = {
    StaffCategory.teaching: [
      'Mathematics',
      'Science',
      'Humanities',
      'Computer Science',
      'Languages',
      'Physical Education',
      'Commerce',
      'Fine Arts',
    ],
    StaffCategory.administrative: [
      'Accounts & Finance',
      'Admissions & Reception',
      'Administration',
      'Human Resources',
      'Examination & Records',
      'Library',
    ],
    StaffCategory.support: [
      'Campus Operations',
      'Security',
      'Transport & Logistics',
      'Housekeeping',
      'IT & Lab Support',
      'Health & Infirmary',
    ],
  };

  List<String> get _currentDepartments {
    final base = _categoryDepartments[_category] ?? _categoryDepartments[StaffCategory.teaching]!;
    final staffList = ref.watch(staffListProvider).value ?? [];
    final existingDepts = staffList
        .where((s) => s.category == _category)
        .map((s) => s.department)
        .where((d) => d.trim().isNotEmpty)
        .toSet();
    return <String>{...base, ...existingDepts}.toList();
  }

  @override
  void initState() {
    super.initState();
    _currentAddressCtrl.addListener(_onCurrentAddressChanged);
    _initializeForm();
  }

  void _onCurrentAddressChanged() {
    if (_sameAsCurrentAddress) {
      _permanentAddressCtrl.text = _currentAddressCtrl.text;
    }
  }

  void _initializeForm() {
    final staff = widget.staffToEdit;
    if (staff != null) {
      _staffId = staff.id;
      _fullNameCtrl.text = staff.fullName;
      _phoneCtrl.text = staff.phone;
      _emailCtrl.text = staff.email;
      _currentAddressCtrl.text = staff.currentAddress;
      _permanentAddressCtrl.text = staff.permanentAddress;
      _emergencyContactCtrl.text = staff.emergencyContact ?? '';
      _gender = staff.gender ?? 'Female';
      _bloodGroup = staff.bloodGroup ?? 'O+';
      _dob = staff.dateOfBirth;

      _category = staff.category;
      _department = staff.department;
      _designationCtrl.text = staff.designation;
      _qualificationCtrl.text = staff.qualification;
      _joiningDate = staff.joiningDate;
      _employmentType = staff.employmentType;

      _specializationCtrl.text = staff.specialization ?? '';
      _assignedClasses = List.from(staff.assignedClasses);

      _salaryCtrl.text = staff.compensation.basicSalary.toStringAsFixed(0);
      _bankNameCtrl.text = staff.compensation.bankName;
      _accountNumberCtrl.text = staff.compensation.accountNumber;
      _ifscCtrl.text = staff.compensation.ifscCode;
      _panCtrl.text = staff.compensation.panNumber;
      _epfUanCtrl.text = staff.compensation.epfUan ?? '';

      _sameAsCurrentAddress = staff.currentAddress.isNotEmpty &&
          staff.currentAddress == staff.permanentAddress;

      if (staff.loginAccount != null) {
        _provisionLogin = staff.loginAccount!.isEnabled;
        _loginEmailCtrl.text = staff.loginAccount!.institutionalEmail;
        _systemRole = staff.loginAccount!.systemRole;
      }
    } else {
      _staffId = 'Generating...';
      _fetchNextId();
      _department = _categoryDepartments[StaffCategory.teaching]!.first;
      _dob = null;
      _sameAsCurrentAddress = false;
      // All fields start clean & empty without dummy data:
      _fullNameCtrl.clear();
      _phoneCtrl.clear();
      _emailCtrl.clear();
      _currentAddressCtrl.clear();
      _permanentAddressCtrl.clear();
      _emergencyContactCtrl.clear();
      _designationCtrl.clear();
      _qualificationCtrl.clear();
      _specializationCtrl.clear();
      _salaryCtrl.clear();
      _bankNameCtrl.clear();
      _accountNumberCtrl.clear();
      _ifscCtrl.clear();
      _panCtrl.clear();
      _epfUanCtrl.clear();
      _loginEmailCtrl.clear();
      _loginPasswordCtrl.clear();
    }
  }

  Future<void> _fetchNextId() async {
    final nextId = await ref.read(staffListProvider.notifier).getNextStaffId();
    if (mounted) {
      setState(() {
        _staffId = nextId;
      });
    }
  }

  @override
  void dispose() {
    _currentAddressCtrl.removeListener(_onCurrentAddressChanged);
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _currentAddressCtrl.dispose();
    _permanentAddressCtrl.dispose();
    _emergencyContactCtrl.dispose();
    _designationCtrl.dispose();
    _qualificationCtrl.dispose();
    _specializationCtrl.dispose();
    _salaryCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountNumberCtrl.dispose();
    _ifscCtrl.dispose();
    _panCtrl.dispose();
    _epfUanCtrl.dispose();
    _loginEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    super.dispose();
  }

  void _submitForm() async {
    if (_fullNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the staff member\'s Full Name.')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final compensation = StaffCompensationModel(
        basicSalary: double.tryParse(_salaryCtrl.text.trim()) ?? 0.0,
        payFrequency: 'Monthly',
        bankName: _bankNameCtrl.text.trim(),
        accountNumber: _accountNumberCtrl.text.trim(),
        ifscCode: _ifscCtrl.text.trim().toUpperCase(),
        panNumber: _panCtrl.text.trim().toUpperCase(),
        epfUan: _epfUanCtrl.text.trim().isNotEmpty ? _epfUanCtrl.text.trim() : null,
      );

      StaffLoginAccountModel? loginAccount;
      if (_provisionLogin) {
        loginAccount = StaffLoginAccountModel(
          isEnabled: true,
          institutionalEmail: _loginEmailCtrl.text.trim().isNotEmpty
              ? _loginEmailCtrl.text.trim()
              : _emailCtrl.text.trim(),
          temporaryPassword: _loginPasswordCtrl.text.trim().isNotEmpty
              ? _loginPasswordCtrl.text.trim()
              : null,
          systemRole: _systemRole,
        );
      }

      final effectivePermanentAddress = _sameAsCurrentAddress
          ? _currentAddressCtrl.text.trim()
          : (_permanentAddressCtrl.text.trim().isNotEmpty
              ? _permanentAddressCtrl.text.trim()
              : _currentAddressCtrl.text.trim());

      final staffMember = StaffMemberModel(
        id: _staffId,
        fullName: _fullNameCtrl.text.trim(),
        photoUrl: widget.staffToEdit?.photoUrl,
        category: _category,
        designation: _designationCtrl.text.trim(),
        department: _department,
        qualification: _qualificationCtrl.text.trim(),
        specialization: _category == StaffCategory.teaching
            ? (_specializationCtrl.text.trim().isNotEmpty ? _specializationCtrl.text.trim() : null)
            : null,
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        currentAddress: _currentAddressCtrl.text.trim(),
        permanentAddress: effectivePermanentAddress,
        joiningDate: _joiningDate,
        employmentType: _employmentType,
        assignedClasses: _category == StaffCategory.teaching ? _assignedClasses : const [],
        compensation: compensation,
        loginAccount: loginAccount,
        status: widget.staffToEdit?.status ?? StaffStatus.active,
        gender: _gender,
        dateOfBirth: _dob,
        bloodGroup: _bloodGroup,
        emergencyContact: _emergencyContactCtrl.text.trim().isNotEmpty
            ? _emergencyContactCtrl.text.trim()
            : null,
      );

      await ref.read(staffListProvider.notifier).saveStaff(staffMember);

      // Two-way cross-module synchronization: update classTeacherId in classes.json
      if (staffMember.category == StaffCategory.teaching) {
        try {
          final classesList = ref.read(classesControllerProvider).value ?? [];
          final ctGrades = staffMember.classTeacherAssignments
              .map((a) => a.grade.trim().toLowerCase())
              .toSet();

          for (final cls in classesList) {
            final isAssignedAsCT = ctGrades.contains(cls.name.trim().toLowerCase());
            if (isAssignedAsCT && cls.classTeacherId != staffMember.id) {
              await ref.read(classesControllerProvider.notifier).assignClassTeacher(cls.id, staffMember.id);
            } else if (!isAssignedAsCT && cls.classTeacherId == staffMember.id) {
              await ref.read(classesControllerProvider.notifier).assignClassTeacher(cls.id, null);
            }
          }
        } catch (syncErr) {
          debugPrint('Class teacher cross-module sync note: $syncErr');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Staff profile for ${staffMember.fullName} updated successfully!'
                  : 'New staff member ${staffMember.fullName} onboarded with ID ${staffMember.id}!',
            ),
            backgroundColor: const Color(0xFF109F83),
            behavior: SnackBarBehavior.floating,
          ),
        );

        ref.read(selectedStaffIdProvider.notifier).state = staffMember.id;
        widget.onSubmitted?.call(staffMember.id);
        widget.onNavigate?.call(EdupluseNavPage.staffList);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save staff record: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return EdupluseScaffold(
      activePage: widget.isEditMode ? EdupluseNavPage.editStaff : EdupluseNavPage.addNewStaff,
      isDark: isDark,
      onToggleTheme: widget.onToggleTheme,
      onNavigate: widget.onNavigate,
      onExitToGateway: widget.onExitToGateway,
      body: Container(
        color: bgColor,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header
              Row(
                children: [
                  IconButton(
                    onPressed: widget.onCancel ?? () => widget.onNavigate?.call(EdupluseNavPage.staffList),
                    icon: const Icon(Icons.arrow_back),
                    tooltip: 'Back to Directory',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isEditMode ? 'Edit Staff Profile' : 'Staff Onboarding Wizard',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        Text(
                          widget.isEditMode
                              ? 'Modify institutional, academic, and compensation records for $_staffId'
                              : 'Complete the 4-step wizard to register faculty and assign institutional roles.',
                          style: TextStyle(fontSize: 12, color: subColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Form Container
              Container(
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                          primary: const Color(0xFF109F83),
                        ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Stepper(
                    currentStep: _currentStep,
                    type: StepperType.vertical,
                    physics: const ClampingScrollPhysics(),
                    onStepTapped: (step) => setState(() => _currentStep = step),
                    onStepContinue: () {
                      if (_currentStep < 3) {
                        setState(() => _currentStep += 1);
                      } else {
                        _submitForm();
                      }
                    },
                    onStepCancel: () {
                      if (_currentStep > 0) {
                        setState(() => _currentStep -= 1);
                      } else {
                        widget.onCancel?.call();
                      }
                    },
                    controlsBuilder: (context, details) {
                      final isLastStep = _currentStep == 3;
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 10,
                          children: [
                            ElevatedButton(
                              onPressed: _isSaving ? null : details.onStepContinue,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF109F83),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : Text(isLastStep ? (widget.isEditMode ? 'Update Profile' : 'Save & Onboard Staff') : 'Continue to Next Step'),
                            ),
                            if (_currentStep > 0)
                              OutlinedButton(
                                onPressed: details.onStepCancel,
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Previous Step'),
                              ),
                          ],
                        ),
                      );
                    },
                    steps: [
                      // Step 1: Personal & Demographics
                      Step(
                        title: const Text('Personal & Demographic Coordinates', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Staff ID, Identity, and Contact Information'),
                        isActive: _currentStep >= 0,
                        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                        content: _buildStep1Personal(isDark, textColor, subColor),
                      ),
                      // Step 2: Employment & Placement
                      Step(
                        title: const Text('Employment & Institutional Placement', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Category, Department, Designation & Qualifications'),
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                        content: _buildStep2Employment(isDark, textColor, subColor),
                      ),
                      // Step 3: Academic Assignments (Teaching Conditional)
                      Step(
                        title: const Text('Academic Workload & Class Pairings', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          _category == StaffCategory.teaching
                              ? 'Subject specialization & class teacher responsibilities'
                              : 'Waived for administrative / operational staff',
                        ),
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                        content: _buildStep3Academic(isDark, textColor, subColor),
                      ),
                      // Step 4: Compensation & Portal Login
                      Step(
                        title: const Text('Compensation, Banking & Portal Login', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: const Text('Salary details, Bank coordinates, and System access provisioning'),
                        isActive: _currentStep >= 3,
                        state: _currentStep == 3 ? StepState.indexed : StepState.complete,
                        content: _buildStep4PayrollAndLogin(isDark, textColor, subColor),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1Personal(bool isDark, Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Staff ID (Read-only lock)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF109F83).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFF109F83).withValues(alpha: 0.3)),
          ),
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Icon(Icons.lock_outline, size: 18, color: Color(0xFF109F83)),
              const Text('Assigned Staff ID: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Text(
                _staffId,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Color(0xFF109F83),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Full Name
        TextFormField(
          controller: _fullNameCtrl,
          decoration: const InputDecoration(
            labelText: 'Full Name *',
            hintText: 'e.g. Dr. Rajeshwari Swaminathan',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 14),

        // Gender & DOB & Blood Group
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final genderField = DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: const InputDecoration(labelText: 'Gender', border: OutlineInputBorder()),
              items: ['Female', 'Male', 'Other']
                  .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _gender = val);
              },
            );

            final bgField = DropdownButtonFormField<String>(
              initialValue: _bloodGroup,
              decoration: const InputDecoration(labelText: 'Blood Group', border: OutlineInputBorder()),
              items: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
                  .map((bg) => DropdownMenuItem(value: bg, child: Text(bg)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _bloodGroup = val);
              },
            );

            if (isNarrow) {
              return Column(
                children: [
                  genderField,
                  const SizedBox(height: 14),
                  bgField,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: genderField),
                const SizedBox(width: 12),
                Expanded(child: bgField),
              ],
            );
          },
        ),

        const SizedBox(height: 14),

        // Phone & Official Email
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final phoneField = TextFormField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'Phone Number *',
                hintText: '+91 98450 12345',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            );

            final emailField = TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'Institutional Email *',
                hintText: 'name@edupulse.edu.in',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            );

            if (isNarrow) {
              return Column(
                children: [phoneField, const SizedBox(height: 14), emailField],
              );
            }

            return Row(
              children: [Expanded(child: phoneField), const SizedBox(width: 12), Expanded(child: emailField)],
            );
          },
        ),

        const SizedBox(height: 14),

        // Current & Permanent Address
        TextFormField(
          controller: _currentAddressCtrl,
          decoration: const InputDecoration(
            labelText: 'Current Residential Address',
            hintText: 'e.g. Flat 402, Green Glen Layout, Bengaluru, KA 560103',
            prefixIcon: Icon(Icons.home_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 8),

        // Checkbox: Same as Current Address
        InkWell(
          onTap: () {
            setState(() {
              _sameAsCurrentAddress = !_sameAsCurrentAddress;
              if (_sameAsCurrentAddress) {
                _permanentAddressCtrl.text = _currentAddressCtrl.text;
              }
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _sameAsCurrentAddress,
                    activeColor: const Color(0xFF109F83),
                    onChanged: (val) {
                      setState(() {
                        _sameAsCurrentAddress = val ?? false;
                        if (_sameAsCurrentAddress) {
                          _permanentAddressCtrl.text = _currentAddressCtrl.text;
                        }
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Permanent address is the same as current residential address',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        TextFormField(
          controller: _permanentAddressCtrl,
          readOnly: _sameAsCurrentAddress,
          decoration: InputDecoration(
            labelText: 'Permanent Address',
            hintText: _sameAsCurrentAddress
                ? 'Same as current address'
                : 'e.g. Flat 402, Green Glen Layout, Bengaluru, KA 560103',
            prefixIcon: const Icon(Icons.location_on_outlined),
            border: const OutlineInputBorder(),
            filled: _sameAsCurrentAddress,
            fillColor: _sameAsCurrentAddress
                ? (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Employment(bool isDark, Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Staff Category Selector (Crucial field)
        const Text(
          'Staff Category (Determines Academic Modules)',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SegmentedButton<StaffCategory>(
            segments: const [
              ButtonSegment(
                value: StaffCategory.teaching,
                label: Text('Teaching Faculty'),
                icon: Icon(Icons.school_outlined, size: 16),
              ),
              ButtonSegment(
                value: StaffCategory.administrative,
                label: Text('Administrative'),
                icon: Icon(Icons.admin_panel_settings_outlined, size: 16),
              ),
              ButtonSegment(
                value: StaffCategory.support,
                label: Text('Support'),
                icon: Icon(Icons.handyman_outlined, size: 16),
              ),
            ],
            selected: {_category},
            onSelectionChanged: (set) {
              setState(() {
                _category = set.first;
                if (_category == StaffCategory.teaching) {
                  _systemRole = 'teacher';
                } else if (_category == StaffCategory.administrative) {
                  _systemRole = 'admin';
                } else {
                  _systemRole = 'frontDesk';
                }
                final available = _currentDepartments;
                if (!available.contains(_department)) {
                  _department = available.first;
                }
              });
            },
          ),
        ),

        const SizedBox(height: 16),

        // Department & Designation
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final deptField = DropdownButtonFormField<String>(
              key: ValueKey('dept_${_category.name}_$_department'),
              initialValue: _currentDepartments.contains(_department)
                  ? _department
                  : _currentDepartments.first,
              decoration: const InputDecoration(labelText: 'Department *', border: OutlineInputBorder()),
              items: _currentDepartments
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _department = val);
              },
            );

            final desigField = TextFormField(
              controller: _designationCtrl,
              decoration: const InputDecoration(
                labelText: 'Designation / Job Title *',
                hintText: 'e.g. Senior PGT Mathematics',
                border: OutlineInputBorder(),
              ),
            );

            if (isNarrow) {
              return Column(children: [deptField, const SizedBox(height: 14), desigField]);
            }
            return Row(children: [Expanded(child: deptField), const SizedBox(width: 12), Expanded(child: desigField)]);
          },
        ),

        const SizedBox(height: 14),

        // Qualification
        TextFormField(
          controller: _qualificationCtrl,
          decoration: const InputDecoration(
            labelText: 'Highest Qualification & Degrees *',
            hintText: 'e.g. Ph.D. Applied Mathematics, M.Sc., B.Ed.',
            prefixIcon: Icon(Icons.history_edu_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 14),

        // Employment Type & Date of Joining
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;
            final empTypeField = DropdownButtonFormField<EmploymentType>(
              initialValue: _employmentType,
              decoration: const InputDecoration(labelText: 'Employment Type', border: OutlineInputBorder()),
              items: EmploymentType.values
                  .map((et) => DropdownMenuItem(value: et, child: Text(et.label)))
                  .toList(),
              onChanged: (val) {
                if (val != null) setState(() => _employmentType = val);
              },
            );

            final dateBtn = InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _joiningDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2030),
                );
                if (picked != null) setState(() => _joiningDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Date of Joining',
                  prefixIcon: Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  '${_joiningDate.day}/${_joiningDate.month}/${_joiningDate.year}',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            );

            if (isNarrow) {
              return Column(children: [empTypeField, const SizedBox(height: 14), dateBtn]);
            }
            return Row(children: [Expanded(child: empTypeField), const SizedBox(width: 12), Expanded(child: dateBtn)]);
          },
        ),
      ],
    );
  }

  Widget _buildStep3Academic(bool isDark, Color textColor, Color subColor) {
    if (_category != StaffCategory.teaching) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Class-Subject timetable pairings and academic specialization fields are waived for ${_category.label}. You may proceed directly to Step 4.',
                style: const TextStyle(fontSize: 13, color: Color(0xFF3B82F6), fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Specialization Field
        TextFormField(
          controller: _specializationCtrl,
          decoration: const InputDecoration(
            labelText: 'Subject Specialization Domain',
            hintText: 'e.g. Pure Calculus, Mechanics, World Literature',
            prefixIcon: Icon(Icons.psychology_outlined),
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 16),

        // Pairing Box
        ClassPairingBox(
          initialAssignments: _assignedClasses,
          isDark: isDark,
          onChanged: (updated) {
            setState(() {
              _assignedClasses = updated;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStep4PayrollAndLogin(bool isDark, Color textColor, Color subColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Salary Coordinates
        Text(
          'Compensation & Banking (Admin / HR Protected)',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
        ),
        const SizedBox(height: 12),

        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final salaryField = TextFormField(
              controller: _salaryCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Basic Monthly Salary (₹) *',
                hintText: 'e.g. 55000',
                prefixIcon: Icon(Icons.currency_rupee),
                border: OutlineInputBorder(),
              ),
            );

            final panField = TextFormField(
              controller: _panCtrl,
              decoration: const InputDecoration(
                labelText: 'PAN Card Number *',
                hintText: 'e.g. ABCDE1234F',
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
            );

            if (isNarrow) {
              return Column(children: [salaryField, const SizedBox(height: 12), panField]);
            }
            return Row(children: [Expanded(child: salaryField), const SizedBox(width: 12), Expanded(child: panField)]);
          },
        ),

        const SizedBox(height: 14),

        // Bank Name & Account Number & IFSC
        LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 600;

            final bankField = TextFormField(
              controller: _bankNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Bank Name *',
                hintText: 'e.g. State Bank of India',
                prefixIcon: Icon(Icons.account_balance_outlined),
                border: OutlineInputBorder(),
              ),
            );

            final accField = TextFormField(
              controller: _accountNumberCtrl,
              decoration: const InputDecoration(
                labelText: 'Bank Account Number *',
                hintText: 'e.g. 1092837465',
                prefixIcon: Icon(Icons.pin_outlined),
                border: OutlineInputBorder(),
              ),
            );

            final ifscField = TextFormField(
              controller: _ifscCtrl,
              decoration: const InputDecoration(
                labelText: 'IFSC Code *',
                hintText: 'e.g. SBIN0001234',
                border: OutlineInputBorder(),
              ),
            );

            if (isNarrow) {
              return Column(children: [bankField, const SizedBox(height: 12), accField, const SizedBox(height: 12), ifscField]);
            }
            return Row(children: [Expanded(flex: 2, child: bankField), const SizedBox(width: 8), Expanded(flex: 2, child: accField), const SizedBox(width: 8), Expanded(flex: 1, child: ifscField)]);
          },
        ),

        const SizedBox(height: 20),
        const Divider(),
        const SizedBox(height: 14),

        // Portal Login Provisioning Section
        Row(
          children: [
            const Icon(Icons.vpn_key_outlined, size: 18, color: Color(0xFF109F83)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Institutional Portal Login Account',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor),
              ),
            ),
            Switch(
              value: _provisionLogin,
              activeThumbColor: const Color(0xFF109F83),
              onChanged: (val) => setState(() => _provisionLogin = val),
            ),
          ],
        ),

        if (_provisionLogin) ...[
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 600;

              final loginEmail = TextFormField(
                controller: _loginEmailCtrl,
                decoration: const InputDecoration(
                  labelText: 'Portal Login ID / Email',
                  hintText: 'e.g. faculty@edupulse.edu.in',
                  prefixIcon: Icon(Icons.alternate_email),
                  border: OutlineInputBorder(),
                ),
              );

              final tempPass = TextFormField(
                controller: _loginPasswordCtrl,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Temporary Password',
                  hintText: 'e.g. EduPulse@2026',
                  prefixIcon: Icon(Icons.lock_outline),
                  border: OutlineInputBorder(),
                ),
              );

              final roleField = DropdownButtonFormField<String>(
                initialValue: _systemRole,
                decoration: const InputDecoration(labelText: 'Assigned Role', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher Portal')),
                  DropdownMenuItem(value: 'frontDesk', child: Text('Front-Desk Workspace')),
                  DropdownMenuItem(value: 'admin', child: Text('System Administrator')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _systemRole = val);
                },
              );

              if (isNarrow) {
                return Column(children: [loginEmail, const SizedBox(height: 12), tempPass, const SizedBox(height: 12), roleField]);
              }
              return Row(children: [Expanded(child: loginEmail), const SizedBox(width: 8), Expanded(child: tempPass), const SizedBox(width: 8), Expanded(child: roleField)]);
            },
          ),
        ],
      ],
    );
  }
}
