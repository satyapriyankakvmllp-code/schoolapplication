import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/utils/app_constants.dart';
import 'src/themes/app_theme.dart';
import 'src/features/admissions/domain/student_admission_model.dart';
import 'src/features/authentication/domain/user_model.dart';
import 'src/features/admissions/application/admissions_controller.dart';
import 'src/features/admissions/presentation/admin/add_student_form_screen.dart';
import 'src/features/admissions/presentation/admin/student_categories_screen.dart';
import 'src/features/admissions/presentation/admin/student_details_screen.dart';
import 'src/features/admissions/presentation/admin/student_list_screen.dart';
import 'src/commonwidgets/edupluse_scaffold.dart';
import 'src/features/authentication/application/auth_controller.dart';
import 'src/features/authentication/presentation/portal_gateway_screen.dart';
import 'src/features/authentication/presentation/role_workspace_hub_screen.dart';
import 'src/features/authentication/application/student_auth_controller.dart';
import 'src/features/authentication/application/parent_auth_controller.dart';
import 'src/features/admissions/presentation/frontdesk/frontdesk_workspace_screen.dart';
import 'src/features/admissions/presentation/parent/parent_portal_workspace_screen.dart';
import 'src/features/classes/presentation/shared/classes_hub_screen.dart';
import 'src/features/staff/domain/staff_member_model.dart';
import 'src/features/staff/application/staff_controller.dart';
import 'src/features/staff/presentation/admin/staff_list_screen.dart';
import 'src/features/staff/presentation/admin/add_staff_form_screen.dart';
import 'src/features/staff/presentation/admin/staff_details_screen.dart';
import 'src/features/staff/presentation/admin/staff_departments_screen.dart';
import 'src/features/staff/presentation/admin/edit_staff_screen.dart';
import 'src/features/staff/presentation/admin/staff_accounts_ledger_screen.dart';
import 'src/routing/route_names.dart';
import 'src/features/staff/domain/staff_menu_item.dart';
import 'src/features/staff/application/staff_auth_controller.dart';
import 'src/features/staff/presentation/staff/staff_shell_layout.dart';
import 'src/features/staff/presentation/staff/common/dashboard_switcher.dart';
import 'src/features/staff/presentation/staff/common/my_profile_screen.dart';
import 'src/features/staff/presentation/staff/common/my_attendance_screen.dart';
import 'src/features/staff/presentation/staff/common/my_leave_screen.dart';
import 'src/features/staff/presentation/staff/common/my_payroll_screen.dart';
import 'src/features/staff/presentation/staff/common/my_library_screen.dart';
import 'src/features/staff/presentation/staff/common/announcements_screen.dart';
import 'src/features/staff/presentation/staff/role_views/teacher_workspace_screen.dart';
import 'src/features/staff/presentation/staff/role_views/accountant_workspace_screen.dart';
import 'src/features/staff/presentation/staff/role_views/librarian_workspace_screen.dart';
import 'src/features/staff/presentation/staff/role_views/transport_workspace_screen.dart';
import 'src/features/staff/presentation/staff/role_views/receptionist_workspace_screen.dart';
import 'src/features/staff/presentation/staff/role_views/principal_faculty_leaves_screen.dart';
import 'src/features/staff/presentation/staff/role_views/principal_examinations_screen.dart';
import 'src/features/staff/presentation/staff/role_views/principal_finance_screen.dart';
import 'src/features/classes/presentation/admin/classes_list_screen.dart';
import 'src/features/classes/presentation/shared/teacher_work_management_screen.dart';
import 'src/features/classes/presentation/admin/curriculum_management_screen.dart';
import 'src/features/classes/presentation/admin/timetable_management_screen.dart';

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
  EdupluseNavPage _activeNavPage = EdupluseNavPage.staffList;
  String? _selectedStudentId;
  StudentAdmissionModel? _editingAdmission;
  StaffMemberModel? _editingStaff;
  bool _isDarkMode = false;
  bool _initialized = false;

  void _handleAdminNavigation(EdupluseNavPage page) {
    if (page == EdupluseNavPage.dashboard) {
      setState(() {
        _activeNavPage = EdupluseNavPage.staffList;
      });
      return;
    }
    setState(() {
      if (page == EdupluseNavPage.addNewStudent) {
        _editingAdmission = null;
      } else if (page == EdupluseNavPage.editStudent) {
        _editingAdmission = _selectedStudentId != null
            ? ref.read(studentDetailsProvider(_selectedStudentId)).valueOrNull
            : null;
      } else if (page == EdupluseNavPage.studentDetails) {
        _selectedStudentId ??= ref.read(selectedStudentIdProvider);
      } else if (page == EdupluseNavPage.addNewStaff || page == EdupluseNavPage.editStaff) {
        _editingStaff = null;
      }
      _activeNavPage = page;
    });
  }

  void _handleStaffShellAdminNavigation(EdupluseNavPage page) {
    if (page == EdupluseNavPage.dashboard) {
      _handleAdminNavigation(EdupluseNavPage.staffList);
      return;
    }
    _handleAdminNavigation(page);
    if (page == EdupluseNavPage.staffList) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
    } else if (page == EdupluseNavPage.addNewStaff) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminAddStaff;
    } else if (page == EdupluseNavPage.staffDepartments) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaffDepartments;
    } else if (page == EdupluseNavPage.accounts) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminAccounts;
    } else if (page == EdupluseNavPage.editStaff) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminEditStaff;
    } else if (page == EdupluseNavPage.staffDetails) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaffDetails;
    } else if (page == EdupluseNavPage.studentPipeline) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffAdmissionsPipeline;
    } else if (page == EdupluseNavPage.studentList) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffStudentDirectory;
    } else if (page == EdupluseNavPage.classes) {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.staffClassesManagement;
    } else {
      ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
    }
  }


  @override
  void initState() {
    super.initState();
    if (widget.initialRole != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(activeUserRoleProvider.notifier).state = widget.initialRole;
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(staffAuthControllerProvider).checkAutoLogin();
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

  void _exitToGateway() {
    setState(() {
      _selectedStudentId = null;
      _editingAdmission = null;
      _editingStaff = null;
      _activeNavPage = EdupluseNavPage.staffList;
    });
    ref.read(activeUserRoleProvider.notifier).state = null;
    ref.read(selectedStudentUserIdProvider.notifier).state = null;
    ref.read(selectedParentUserIdProvider.notifier).state = null;
    ref.read(selectedStaffIdProvider.notifier).state = null;
    ref.read(selectedStudentIdProvider.notifier).state = null;
    ref.read(staffAuthControllerProvider).logout();
    ref.read(studentAuthControllerProvider).logout();
    ref.read(parentAuthControllerProvider).logout();
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
    final activeStaff = ref.watch(currentLoggedInStaffProvider);

    // Phase 1 Gateway: If no role or staff session is active, render PortalGatewayScreen
    if (activeRole == null && activeStaff == null) {
      return PortalGatewayScreen(
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onSelectRole: (role) {
          ref.read(activeUserRoleProvider.notifier).state = role;
          if (role == UserRole.admin) {
            setState(() {
              _activeNavPage = EdupluseNavPage.staffList;
            });
          }
        },
      );
    }

    // 0. If activeRole is Admin, render the School Administrator console directly
    if (activeRole == UserRole.admin) {
      return _buildAdminScreen();
    }

    // 1. Staff End Module: If staff is authenticated, render appropriate shell
    final activeStaffRoute = ref.watch(activeStaffRouteProvider);

    if (activeStaff != null) {
      final role = activeStaff.effectiveRole.toLowerCase();

      // If user is Admin, they belong strictly in the School Administrator console (_buildAdminScreen).
      // They should NEVER see the Staff Shell (Faculty & Staff Workspace) or Super Admin workspace screen.
      if (isSuperAdmin(role)) {
        return _buildAdminScreen();
      }

      var effectiveRoute = activeStaffRoute;

      // If non-admin staff tries to access /admin/*, check role
      if (effectiveRoute.startsWith('/admin')) {
        if (role == 'principal') {
          if (effectiveRoute != RouteNames.adminStaff &&
              effectiveRoute != RouteNames.adminStaffDetails) {
            effectiveRoute = RouteNames.staffAdmissionsPipeline;
          }
        } else {
          effectiveRoute = RouteNames.staffDashboard;
        }
      }

      // Principal has no dummy dashboard: redirect to admissions pipeline
      if (role == 'principal' && effectiveRoute == RouteNames.staffDashboard) {
        effectiveRoute = RouteNames.staffAdmissionsPipeline;
      }

      return StaffShellLayout(
        currentRoute: effectiveRoute,
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onLogout: () async {
          await ref.read(staffAuthControllerProvider).logout();
        },
        onNavigate: (route) {
          ref.read(staffAuthControllerProvider).setActiveRoute(route);
          if (route == RouteNames.adminStaff) {
            setState(() {
              _activeNavPage = EdupluseNavPage.staffList;
            });
          } else if (route == RouteNames.adminAddStaff) {
            setState(() {
              _activeNavPage = EdupluseNavPage.addNewStaff;
            });
          } else if (route == RouteNames.adminStaffDepartments) {
            setState(() {
              _activeNavPage = EdupluseNavPage.staffDepartments;
            });
          } else if (route == RouteNames.adminAccounts) {
            setState(() {
              _activeNavPage = EdupluseNavPage.accounts;
            });
          }
        },
        child: _buildStaffScreen(effectiveRoute, activeStaff),
      );
    }

    // Direct Classes navigation across all roles (Admin, Teacher, Student, Parent, Admissions)
    if (_isClassesPage(_activeNavPage)) {
      return ClassesHubScreen(
        activeNavPage: _activeNavPage,
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
        onExitToGateway: _exitToGateway,
      );
    }

    // Front-Desk / Admissions Officer Workspace
    if (activeRole == UserRole.admissions) {
      return FrontDeskWorkspaceScreen(
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onExitToGateway: _exitToGateway,
      );
    }

    // Parent & Guardian Portal
    if (activeRole == UserRole.parent) {
      return ParentPortalWorkspaceScreen(
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onExitToGateway: _exitToGateway,
      );
    }

    // Role-tailored workspace for other non-admin roles (Teacher, Student, Finance)
    if (activeRole != null && activeRole != UserRole.admin) {
      return RoleWorkspaceHubScreen(
        role: activeRole,
        isDark: _isDarkMode,
        onToggleTheme: _toggleTheme,
        onNavigate: (page) {
          setState(() {
            _activeNavPage = page;
          });
        },
        onExitToGateway: _exitToGateway,
      );
    }

    // Full Administrative Console (Admissions Module)
    return _buildAdminScreen();
  }

  bool _isClassesPage(EdupluseNavPage page) {
    return page == EdupluseNavPage.classes ||
        page == EdupluseNavPage.classesSubjects ||
        page == EdupluseNavPage.classesSections ||
        page == EdupluseNavPage.classesCurriculum ||
        page == EdupluseNavPage.classesDailyLessons ||
        page == EdupluseNavPage.classesTimetable ||
        page == EdupluseNavPage.classesClassrooms ||
        page == EdupluseNavPage.classesTeacherWork;
  }

  Widget _buildAdminScreen() {
    switch (_activeNavPage) {
      case EdupluseNavPage.classes:
      case EdupluseNavPage.classesSubjects:
      case EdupluseNavPage.classesSections:
      case EdupluseNavPage.classesCurriculum:
      case EdupluseNavPage.classesDailyLessons:
      case EdupluseNavPage.classesTimetable:
      case EdupluseNavPage.classesClassrooms:
      case EdupluseNavPage.classesTeacherWork:
        return ClassesHubScreen(
          activeNavPage: _activeNavPage,
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
        );
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
          onExitToGateway: _exitToGateway,
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
          onNavigate: _handleAdminNavigation,
        );
      case EdupluseNavPage.studentPipeline:
        return StudentCategoriesScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
        );
      case EdupluseNavPage.studentList:
        return StudentListScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
          onSelectStudent: (id) {
            _selectStudent(id);
          },
        );
      case EdupluseNavPage.staffList:
        return StaffListScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
          onSelectStaff: (staffId) {
            ref.read(selectedStaffIdProvider.notifier).state = staffId;
            setState(() {
              _activeNavPage = EdupluseNavPage.staffDetails;
            });
          },
          onEditStaff: (staff) {
            ref.read(selectedStaffIdProvider.notifier).state = staff.id;
            setState(() {
              _editingStaff = staff;
              _activeNavPage = EdupluseNavPage.editStaff;
            });
          },
        );
      case EdupluseNavPage.addNewStaff:
        return AddStaffFormScreen(
          key: const ValueKey('add_new_staff'),
          isDark: _isDarkMode,
          isEditMode: false,
          staffToEdit: null,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
          onSubmitted: (staffId) {
            ref.read(selectedStaffIdProvider.notifier).state = staffId;
            setState(() {
              _editingStaff = null;
              _activeNavPage = EdupluseNavPage.staffDetails;
            });
          },
          onCancel: () {
            setState(() {
              _editingStaff = null;
              _activeNavPage = EdupluseNavPage.staffList;
            });
          },
        );
      case EdupluseNavPage.editStaff:
        final staffToUse = _editingStaff;
        return EditStaffScreen(
          key: ValueKey('edit_staff_${staffToUse?.id ?? 'empty'}'),
          initialStaff: staffToUse,
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
          onSubmitted: (staffId) {
            ref.read(selectedStaffIdProvider.notifier).state = staffId;
            setState(() {
              _editingStaff = null;
              _activeNavPage = EdupluseNavPage.staffDetails;
            });
          },
          onCancel: () {
            setState(() {
              _editingStaff = null;
              _activeNavPage = EdupluseNavPage.staffList;
            });
          },
          onSelectStaffForEdit: (staff) {
            setState(() {
              _editingStaff = staff;
            });
            ref.read(selectedStaffIdProvider.notifier).state = staff.id;
          },
        );
      case EdupluseNavPage.staffDetails:
        return StaffDetailsScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
          onEditStaff: (staff) {
            ref.read(selectedStaffIdProvider.notifier).state = staff.id;
            setState(() {
              _editingStaff = staff;
              _activeNavPage = EdupluseNavPage.editStaff;
            });
          },
        );
      case EdupluseNavPage.staffDepartments:
        return StaffDepartmentsScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
          onSelectStaff: (staffId) {
            ref.read(selectedStaffIdProvider.notifier).state = staffId;
            setState(() {
              _activeNavPage = EdupluseNavPage.staffDetails;
            });
          },
        );
      case EdupluseNavPage.accounts:
        final currentStaffId = ref.watch(selectedStaffIdProvider);
        final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
        if (staffList.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final staff = staffList.firstWhere(
          (s) => s.id == currentStaffId,
          orElse: () => staffList.first,
        );
        return StaffAccountsLedgerScreen(
          staff: staff,
          isDark: _isDarkMode,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
        );
      case EdupluseNavPage.studentDetails:
      default:
        return StudentDetailsScreen(
          studentId: _selectedStudentId,
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleAdminNavigation,
          onExitToGateway: _exitToGateway,
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


  Widget _buildStaffScreen(String route, StaffMemberModel staff) {
    switch (route) {
      case RouteNames.staffMyProfile:
        return MyProfileScreen(isDark: _isDarkMode);
      case RouteNames.staffMyAttendance:
        return MyAttendanceScreen(isDark: _isDarkMode);
      case RouteNames.staffMyLeave:
        return MyLeaveScreen(isDark: _isDarkMode);
      case RouteNames.staffMyPayroll:
        return MyPayrollScreen(isDark: _isDarkMode);
      case RouteNames.staffMyLibrary:
        return MyLibraryScreen(isDark: _isDarkMode);
      case RouteNames.staffAnnouncements:
        return AnnouncementsScreen(isDark: _isDarkMode);
      case RouteNames.staffSectionAttendance:
      case RouteNames.staffMyClasses:
      case RouteNames.staffMarksEntry:
      case RouteNames.staffHomework:
        return TeacherWorkspaceScreen(isDark: _isDarkMode);
      case RouteNames.staffFeeCollection:
      case RouteNames.staffPayrollDesk:
        return AccountantWorkspaceScreen(isDark: _isDarkMode);
      case RouteNames.staffLibraryDesk:
        return LibrarianWorkspaceScreen(isDark: _isDarkMode);
      case RouteNames.staffFleetRoutes:
        return TransportWorkspaceScreen(isDark: _isDarkMode);
      case RouteNames.staffVisitorLog:
        return ReceptionistWorkspaceScreen(isDark: _isDarkMode);

      // Principal Executive Modules -> Directly use canonical Admin screens
      case RouteNames.staffAdmissionsPipeline:
        return StudentCategoriesScreen(
          isDark: _isDarkMode,
          isEmbedded: true,
          onNavigate: _handleStaffShellAdminNavigation,
          onExitToGateway: _exitToGateway,
        );
      case RouteNames.staffStudentDirectory:
        return StudentListScreen(
          isDark: _isDarkMode,
          isEmbedded: true,
          onNavigate: _handleStaffShellAdminNavigation,
          onExitToGateway: _exitToGateway,
          onSelectStudent: (studentId) {
            _selectStudent(studentId);
          },
        );
      case RouteNames.staffFacultyLeaveApprovals:
        return PrincipalFacultyLeavesScreen(isDark: _isDarkMode);
      case RouteNames.staffClassesManagement:
        return const AdminClassesListScreen();
      case RouteNames.staffTeacherWorkload:
        return const TeacherWorkManagementScreen();
      case RouteNames.staffCurriculumReview:
        return const CurriculumManagementScreen();
      case RouteNames.staffMasterTimetable:
        return const TimetableManagementScreen();
      case RouteNames.staffExaminations:
        return PrincipalExaminationsScreen(isDark: _isDarkMode, isMarksModeration: false);
      case RouteNames.staffMarksModeration:
        return PrincipalExaminationsScreen(isDark: _isDarkMode, isMarksModeration: true);
      case RouteNames.staffFeeAnalytics:
        return PrincipalFinanceScreen(isDark: _isDarkMode, isWaiversView: false);
      case RouteNames.staffFeeWaivers:
        return PrincipalFinanceScreen(isDark: _isDarkMode, isWaiversView: true);

      // Super Admin & Staff subroutes within Staff Shell
      case RouteNames.adminStaff:
        return StaffListScreen(
          isDark: _isDarkMode,
          isEmbedded: true,
          onNavigate: _handleStaffShellAdminNavigation,
          onSelectStaff: (staffId) {
            ref.read(selectedStaffIdProvider.notifier).state = staffId;
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaffDetails;
          },
          onEditStaff: (s) {
            ref.read(selectedStaffIdProvider.notifier).state = s.id;
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminEditStaff;
          },
        );
      case RouteNames.adminAddStaff:
        return AddStaffFormScreen(
          key: const ValueKey('admin_add_staff_shell'),
          isDark: _isDarkMode,
          isEditMode: false,
          staffToEdit: null,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleStaffShellAdminNavigation,
          onSubmitted: (staffId) {
            ref.read(selectedStaffIdProvider.notifier).state = staffId;
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaffDetails;
          },
          onCancel: () {
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
          },
        );
      case RouteNames.adminStaffDetails:
        return StaffDetailsScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleStaffShellAdminNavigation,
          onEditStaff: (s) {
            ref.read(selectedStaffIdProvider.notifier).state = s.id;
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminEditStaff;
          },
        );
      case RouteNames.adminStaffDepartments:
        return StaffDepartmentsScreen(
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleStaffShellAdminNavigation,
          onSelectStaff: (staffId) {
            ref.read(selectedStaffIdProvider.notifier).state = staffId;
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaffDetails;
          },
        );
      case RouteNames.adminAccounts:
        final currentStaffId = ref.watch(selectedStaffIdProvider);
        final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
        final staffToUse = staffList.firstWhere(
          (s) => s.id == currentStaffId,
          orElse: () => staff,
        );
        return StaffAccountsLedgerScreen(
          staff: staffToUse,
          isDark: _isDarkMode,
          onNavigate: _handleStaffShellAdminNavigation,
        );
      case RouteNames.adminEditStaff:
        final currentStaffId = ref.watch(selectedStaffIdProvider);
        final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
        final staffToUse = staffList.firstWhere(
          (s) => s.id == currentStaffId,
          orElse: () => staff,
        );
        return EditStaffScreen(
          key: ValueKey('admin_edit_staff_${staffToUse.id}'),
          initialStaff: staffToUse,
          isDark: _isDarkMode,
          onToggleTheme: _toggleTheme,
          onNavigate: _handleStaffShellAdminNavigation,
          onSubmitted: (id) {
            ref.read(selectedStaffIdProvider.notifier).state = id;
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaffDetails;
          },
          onCancel: () {
            ref.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;
          },
        );

      case RouteNames.staffDashboard:
      default:
        return DashboardSwitcher(isDark: _isDarkMode);
    }
  }
}
