import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'utils/app_constants.dart';
import 'themes/app_theme.dart';
import 'features/admissions/domain/student_admission_model.dart';
import 'features/authentication/domain/user_model.dart';
import 'features/admissions/application/admissions_controller.dart';
import 'features/admissions/presentation/admin/add_student_form_screen.dart';
import 'features/admissions/presentation/admin/student_categories_screen.dart';
import 'features/admissions/presentation/admin/student_details_screen.dart';
import 'features/admissions/presentation/admin/student_list_screen.dart';
import 'commonwidgets/edupluse_scaffold.dart';
import 'features/authentication/application/auth_controller.dart';
import 'features/authentication/presentation/portal_gateway_screen.dart';
import 'features/authentication/presentation/role_workspace_hub_screen.dart';
import 'features/admissions/presentation/frontdesk/frontdesk_workspace_screen.dart';
import 'features/admissions/presentation/parent/parent_portal_workspace_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: SchoolManagementApp()));
}

class SchoolManagementApp extends ConsumerStatefulWidget {
  final UserRole? initialRole;

  const SchoolManagementApp({
    super.key,
    this.initialRole,
  });

  @override
  ConsumerState<SchoolManagementApp> createState() => _SchoolManagementAppState();
}

class _SchoolManagementAppState extends ConsumerState<SchoolManagementApp> {
  EdupluseNavPage _activeNavPage = EdupluseNavPage.studentDetails;
  String? _selectedStudentId;
  StudentAdmissionModel? _editingAdmission;
  bool _isDarkMode = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeUserRoleProvider.notifier).state = widget.initialRole;
      });
    }
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  void _selectStudent(String studentId) {
    setState(() {
      _selectedStudentId = studentId;
      _activeNavPage = EdupluseNavPage.studentDetails;
    });
    ref.read(selectedStudentIdProvider.notifier).state = studentId;
  }

  @override
  Widget build(BuildContext context) {
    final activeRole = ref.watch(activeUserRoleProvider);
    final effectiveRole = (!_initialized && widget.initialRole != null && activeRole == null)
        ? widget.initialRole
        : activeRole;

    if (activeRole != null) {
      _initialized = true;
    }

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: _buildCurrentScreen(effectiveRole),
    );
  }

  Widget _buildCurrentScreen(UserRole? activeRole) {
    // Phase 1 Gateway: If no role is active, render PortalGatewayScreen
    if (activeRole == null) {
      return PortalGatewayScreen(
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onSelectRole: (role) {
          ref.read(activeUserRoleProvider.notifier).state = role;
          if (role == UserRole.admin) {
            setState(() {
              _activeNavPage = EdupluseNavPage.studentDetails;
            });
          }
        },
      );
    }

    // Front-Desk / Admissions Officer Workspace (Phase 2)
    if (activeRole == UserRole.admissions) {
      return FrontDeskWorkspaceScreen(
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onExitToGateway: () => ref.read(activeUserRoleProvider.notifier).state = null,
      );
    }

    // Parent & Guardian Portal (Phase 3)
    if (activeRole == UserRole.parent) {
      return ParentPortalWorkspaceScreen(
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onExitToGateway: () => ref.read(activeUserRoleProvider.notifier).state = null,
      );
    }

    // Role-tailored workspace for other non-admin roles (Parent, Teacher, Student, Finance)
    if (activeRole != UserRole.admin) {
      return RoleWorkspaceHubScreen(
        role: activeRole,
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onNavigate: (page) {
          setState(() {
            _activeNavPage = page;
          });
        },
        onExitToGateway: () => ref.read(activeUserRoleProvider.notifier).state = null,
      );
    }

    // Full Administrative Console (Admissions Module)
    return _buildAdminScreen();
  }

  Widget _buildAdminScreen() {
    switch (_activeNavPage) {
      case EdupluseNavPage.editStudent:
      case EdupluseNavPage.addNewStudent:
        final isEditMode = _activeNavPage == EdupluseNavPage.editStudent;
        final currentStudent = _selectedStudentId != null
            ? ref.watch(studentDetailsProvider(_selectedStudentId)).valueOrNull
            : null;
        final prefilledDraft = ref.watch(prefilledAdmissionDraftProvider);
        final admissionToUse = isEditMode
            ? (_editingAdmission ?? currentStudent)
            : (_editingAdmission ?? prefilledDraft);
        return AddStudentFormScreen(
          key: ValueKey('add_student_${admissionToUse?.student.id ?? 'empty'}_${admissionToUse?.student.admissionNumber ?? 'new'}_$isEditMode'),
          isDark: _isDarkMode,
          isEditMode: isEditMode,
          onToggleTheme: _toggleTheme,
          admissionToEdit: admissionToUse,
          onSelectStudentForEdit: (studentId) {
            setState(() {
              _selectedStudentId = studentId;
              _editingAdmission = ref.read(studentDetailsProvider(studentId)).valueOrNull;
            });
            ref.read(selectedStudentIdProvider.notifier).state = studentId;
          },
          onCancel: () {
            ref.read(prefilledAdmissionDraftProvider.notifier).state = null;
            ref.read(originatingRequestIdProvider.notifier).state = null;
            setState(() {
              _editingAdmission = null;
              _activeNavPage = EdupluseNavPage.studentDetails;
            });
          },
          onSubmitted: (newStudentId) {
            ref.read(prefilledAdmissionDraftProvider.notifier).state = null;
            ref.read(originatingRequestIdProvider.notifier).state = null;
            _editingAdmission = null;
            _selectStudent(newStudentId);
          },
          onNavigate: (page) {
            setState(() {
              if (page == EdupluseNavPage.addNewStudent) {
                _editingAdmission = null;
              } else if (page == EdupluseNavPage.editStudent) {
                _editingAdmission = _selectedStudentId != null
                    ? ref.read(studentDetailsProvider(_selectedStudentId)).valueOrNull
                    : null;
              }
              _activeNavPage = page;
            });
          },
        );
      case EdupluseNavPage.studentPipeline:
        return StudentCategoriesScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: (page) {
            setState(() {
              if (page == EdupluseNavPage.addNewStudent) {
                _editingAdmission = null;
              } else if (page == EdupluseNavPage.editStudent) {
                _editingAdmission = _selectedStudentId != null
                    ? ref.read(studentDetailsProvider(_selectedStudentId)).valueOrNull
                    : null;
              }
              _activeNavPage = page;
            });
          },
        );
      case EdupluseNavPage.studentList:
        return StudentListScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: (page) {
            setState(() {
              if (page == EdupluseNavPage.addNewStudent) {
                _editingAdmission = null;
              } else if (page == EdupluseNavPage.editStudent) {
                _editingAdmission = _selectedStudentId != null
                    ? ref.read(studentDetailsProvider(_selectedStudentId)).valueOrNull
                    : null;
              }
              _activeNavPage = page;
            });
          },
          onSelectStudent: (id) {
            _selectStudent(id);
          },
        );
      case EdupluseNavPage.studentDetails:
      default:
        return StudentDetailsScreen(
          studentId: _selectedStudentId,
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: (page) {
            setState(() {
              if (page == EdupluseNavPage.addNewStudent) {
                _editingAdmission = null;
              } else if (page == EdupluseNavPage.editStudent) {
                _editingAdmission = _selectedStudentId != null
                    ? ref.read(studentDetailsProvider(_selectedStudentId)).valueOrNull
                    : null;
              }
              _activeNavPage = page;
            });
          },
          onEditStudent: (admission) {
            setState(() {
              _editingAdmission = admission;
              _selectedStudentId = admission.student.id;
              _activeNavPage = EdupluseNavPage.editStudent;
            });
            ref.read(selectedStudentIdProvider.notifier).state = admission.student.id;
          },
          onEdit: () {
            final currentAdmission = _selectedStudentId != null
                ? ref.read(studentDetailsProvider(_selectedStudentId)).valueOrNull
                : null;
            setState(() {
              _editingAdmission = currentAdmission;
              _activeNavPage = EdupluseNavPage.editStudent;
            });
          },
          onSelectStudent: (studentId) {
            _selectStudent(studentId);
          },
        );
    }
  }
}
