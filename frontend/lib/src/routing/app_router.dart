import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/authentication/presentation/portal_gateway_screen.dart';
import '../features/authentication/presentation/role_workspace_hub_screen.dart';
import '../features/admissions/presentation/parent/parent_portal_workspace_screen.dart';
import '../features/authentication/domain/user_model.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/authentication/application/student_auth_controller.dart';
import '../features/authentication/application/parent_auth_controller.dart';
import '../features/staff/application/staff_auth_controller.dart';
import '../features/staff/application/staff_controller.dart';
import '../features/staff/domain/staff_menu_item.dart';
import '../features/staff/presentation/staff/staff_shell_layout.dart';
import '../features/staff/presentation/staff/common/dashboard_switcher.dart';
import '../features/staff/presentation/staff/common/my_profile_screen.dart';
import '../features/staff/presentation/staff/common/my_attendance_screen.dart';
import '../features/staff/presentation/staff/common/my_leave_screen.dart';
import '../features/staff/presentation/staff/common/my_payroll_screen.dart';
import '../features/staff/presentation/staff/common/my_library_screen.dart';
import '../features/staff/presentation/staff/common/announcements_screen.dart';
import '../features/staff/presentation/staff/role_views/teacher_workspace_screen.dart';
import '../features/staff/presentation/staff/role_views/accountant_workspace_screen.dart';
import '../features/staff/presentation/staff/role_views/librarian_workspace_screen.dart';
import '../features/staff/presentation/staff/role_views/transport_workspace_screen.dart';
import '../features/staff/presentation/staff/role_views/receptionist_workspace_screen.dart';
import '../features/staff/presentation/staff/role_views/principal_admissions_screen.dart';
import '../features/staff/presentation/admin/staff_list_screen.dart';
import '../features/staff/presentation/admin/add_staff_form_screen.dart';
import '../features/staff/presentation/admin/staff_details_screen.dart';
import '../features/staff/presentation/admin/staff_departments_screen.dart';
import '../features/staff/presentation/admin/staff_accounts_ledger_screen.dart';
import '../features/staff/presentation/admin/edit_staff_screen.dart';
import '../features/admin/presentation/shell/admin_shell_layout.dart';
import '../features/admissions/presentation/admin/student_list_screen.dart';
import '../features/admissions/presentation/admin/student_details_screen.dart';
import '../features/admissions/presentation/admin/add_student_form_screen.dart';
import '../features/admissions/presentation/admin/student_categories_screen.dart';
import '../features/admissions/application/admissions_controller.dart';
import '../commonwidgets/edupluse_scaffold.dart';
import 'route_names.dart';


final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'staffShell');
final GlobalKey<NavigatorState> _adminShellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'adminShell');

void _handleAdminNavInRouter(BuildContext context, Ref ref, EdupluseNavPage page) {

  switch (page) {
    case EdupluseNavPage.dashboard:
      context.go(RouteNames.staffDashboard);
      break;
    case EdupluseNavPage.studentList:
      context.go(RouteNames.adminAdmissions);
      break;
    case EdupluseNavPage.studentDetails:
      final studentId = ref.read(selectedStudentIdProvider);
      if (studentId != null) {
        context.go('/admin/admissions/$studentId');
      } else {
        context.go(RouteNames.adminAdmissions);
      }
      break;
    case EdupluseNavPage.addNewStudent:
      context.go(RouteNames.newAdmission);
      break;
    case EdupluseNavPage.staffList:
      context.go(RouteNames.adminStaff);
      break;
    case EdupluseNavPage.addNewStaff:
      context.go(RouteNames.adminAddStaff);
      break;
    case EdupluseNavPage.staffDepartments:
      context.go(RouteNames.adminStaffDepartments);
      break;
    case EdupluseNavPage.accounts:
      context.go(RouteNames.adminAccounts);
      break;
    case EdupluseNavPage.editStaff:
      context.go(RouteNames.adminEditStaff);
      break;
    case EdupluseNavPage.staffDetails:
      context.go(RouteNames.adminStaffDetails);
      break;
    case EdupluseNavPage.studentPipeline:
      context.go(RouteNames.adminPipeline);
      break;
    case EdupluseNavPage.editStudent:
      context.go(RouteNames.adminEditStudent);
      break;
    default:
      context.go(RouteNames.adminStaff);
      break;
  }
}

Future<void> _handleAdminLogoutInRouter(BuildContext context, Ref ref) async {
  ref.read(activeUserRoleProvider.notifier).state = null;
  ref.read(selectedStudentIdProvider.notifier).state = null;
  ref.read(selectedStaffIdProvider.notifier).state = null;
  await ref.read(staffAuthControllerProvider).logout();
  ref.read(selectedStudentUserIdProvider.notifier).state = null;
  ref.read(studentAuthControllerProvider).logout();
  ref.read(selectedParentUserIdProvider.notifier).state = null;
  ref.read(parentAuthControllerProvider).logout();
  if (context.mounted) {
    context.go(RouteNames.signInGateway);
  }
}

/// Riverpod provider delivering configured GoRouter with full RBAC & multi-user universal redirects
final appRouterProvider = Provider<GoRouter>((ref) {

  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.signInGateway,
    debugLogDiagnostics: false,
    redirect: (BuildContext context, GoRouterState state) {
      final staffId = ref.read(selectedStaffIdProvider);
      final studentId = ref.read(selectedStudentUserIdProvider);
      final parentId = ref.read(selectedParentUserIdProvider);
      final activeUserRole = ref.read(activeUserRoleProvider);

      final currentPath = state.uri.path;
      final isStaffRoute = currentPath.startsWith('/staff');
      final isAdminRoute = currentPath.startsWith('/admin');
      final isStudentRoute = currentPath.startsWith('/student');
      final isParentRoute = currentPath.startsWith('/parent');
      final isGateway = currentPath == RouteNames.signInGateway ||
          currentPath == RouteNames.portalGateway ||
          currentPath == RouteNames.initial ||
          currentPath == RouteNames.login;

      // 1. Unauthenticated users trying to access protected sections are redirected to gateway
      if ((isStaffRoute || isAdminRoute) && staffId == null) {
        return RouteNames.signInGateway;
      }
      if (isStudentRoute && studentId == null && activeUserRole != UserRole.student) {
        return RouteNames.signInGateway;
      }
      if (isParentRoute && parentId == null && activeUserRole != UserRole.parent) {
        return RouteNames.signInGateway;
      }

      // 2. Gateway entrypoint: On open or reload, always remain on the gateway so user can pick their role
      if (isGateway) {
        return null;
      }

      // 3. Super Admin & RBAC Permission Guards for Staff Routes
      if (staffId != null) {
        final staff = ref.read(currentLoggedInStaffProvider);
        if (staff != null) {
          final role = staff.effectiveRole.toLowerCase();

          // Admin belongs strictly in School Administrator console (/admin/*), never /staff/*
          if (isSuperAdmin(role)) {
            if (isStaffRoute) {
              return RouteNames.adminStaff;
            }
            return null;
          }

          // If role != admin && trying to access /admin/*, redirect to /staff/dashboard
          if (isAdminRoute) {
            return RouteNames.staffDashboard;
          }

          if (currentPath == RouteNames.staffDashboard) {
            return null;
          }

          // Principal has universal access across all screens
          if (role == 'principal') {
            return null;
          }

          // Lookup matching menu item to evaluate role & class-teacher constraints
          final item = allStaffMenuItems.cast<StaffMenuItem?>().firstWhere(
                (m) => m?.routeName == currentPath,
                orElse: () => null,
              );

          if (item != null) {
            // Check allowed role list
            if (!item.allowedRoles.contains(role)) {
              return RouteNames.staffDashboard;
            }
            // Check if route requires primary class teacher designation
            if (item.requiresClassTeacher && !staff.isClassTeacher) {
              return RouteNames.staffDashboard;
            }
          }
        }
      }

      return null;
    },
    routes: [
      // Portal Gateway / Sign In
      GoRoute(
        path: RouteNames.initial,
        redirect: (context, state) => RouteNames.signInGateway,
      ),
      GoRoute(
        path: RouteNames.signInGateway,
        builder: (context, state) => PortalGatewayScreen(
          isDark: false,
          onSelectRole: (role) {
            ref.read(activeUserRoleProvider.notifier).state = role;
          },
        ),
      ),
      GoRoute(
        path: RouteNames.portalGateway,
        redirect: (context, state) => RouteNames.signInGateway,
      ),
      GoRoute(
        path: RouteNames.login,
        redirect: (context, state) => RouteNames.signInGateway,
      ),

      // Student Hub Routes
      GoRoute(
        path: RouteNames.studentDashboard,
        builder: (context, state) => RoleWorkspaceHubScreen(
          role: UserRole.student,
          isDark: false,
          onExitToGateway: () {
            ref.read(studentAuthControllerProvider).logout();
            context.go(RouteNames.signInGateway);
          },
        ),
      ),
      GoRoute(
        path: RouteNames.studentProfile,
        builder: (context, state) => RoleWorkspaceHubScreen(
          role: UserRole.student,
          isDark: false,
          onExitToGateway: () {
            ref.read(studentAuthControllerProvider).logout();
            context.go(RouteNames.signInGateway);
          },
        ),
      ),

      // Parent Portal Routes
      GoRoute(
        path: RouteNames.parentDashboard,
        builder: (context, state) => ParentPortalWorkspaceScreen(
          isDark: false,
          onExitToGateway: () {
            ref.read(parentAuthControllerProvider).logout();
            context.go(RouteNames.signInGateway);
          },
        ),
      ),

      // Staff Shell Navigation Hierarchy
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return StaffShellLayout(
            currentRoute: state.uri.path,
            onNavigate: (route) {
              context.go(route);
            },
            onLogout: () async {
              await ref.read(staffAuthControllerProvider).logout();
              if (context.mounted) {
                context.go(RouteNames.signInGateway);
              }
            },
            child: child,
          );
        },
        routes: [
          // Common (7)
          GoRoute(
            path: RouteNames.staffDashboard,
            builder: (context, state) => const DashboardSwitcher(),
          ),
          GoRoute(
            path: RouteNames.staffMyProfile,
            builder: (context, state) => const MyProfileScreen(),
          ),
          GoRoute(
            path: RouteNames.staffMyAttendance,
            builder: (context, state) => const MyAttendanceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffMyLeave,
            builder: (context, state) => const MyLeaveScreen(),
          ),
          GoRoute(
            path: RouteNames.staffMyPayroll,
            builder: (context, state) => const MyPayrollScreen(),
          ),
          GoRoute(
            path: RouteNames.staffMyLibrary,
            builder: (context, state) => const MyLibraryScreen(),
          ),
          GoRoute(
            path: RouteNames.staffAnnouncements,
            builder: (context, state) => const AnnouncementsScreen(),
          ),

          // Role Specific Screens
          GoRoute(
            path: RouteNames.staffSectionAttendance,
            builder: (context, state) => const TeacherWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffMyClasses,
            builder: (context, state) => const TeacherWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffMarksEntry,
            builder: (context, state) => const TeacherWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffHomework,
            builder: (context, state) => const TeacherWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffFeeCollection,
            builder: (context, state) => const AccountantWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffPayrollDesk,
            builder: (context, state) => const AccountantWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffLibraryDesk,
            builder: (context, state) => const LibrarianWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffFleetRoutes,
            builder: (context, state) => const TransportWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffVisitorLog,
            builder: (context, state) => const ReceptionistWorkspaceScreen(),
          ),
          GoRoute(
            path: RouteNames.staffAdmissionsPipeline,
            builder: (context, state) => const PrincipalAdmissionsScreen(isDark: false),
          ),
        ],
      ),

      // ShellRoute 2: Admin Shell Navigation Hierarchy (AdminShellLayout)
      ShellRoute(
        navigatorKey: _adminShellNavigatorKey,
        builder: (context, state, child) {
          return AdminShellLayout(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.adminStaff,
            builder: (context, state) => StaffListScreen(
              isDark: false,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              onSelectStaff: (staffId) {
                ref.read(selectedStaffIdProvider.notifier).state = staffId;
                context.go(RouteNames.adminStaffDetails);
              },
              onEditStaff: (staff) {
                ref.read(selectedStaffIdProvider.notifier).state = staff.id;
                context.go(RouteNames.adminEditStaff);
              },
            ),
          ),
          GoRoute(
            path: RouteNames.adminAddStaff,
            builder: (context, state) => AddStaffFormScreen(
              key: const ValueKey('add_staff_route'),
              isDark: false,
              isEditMode: false,
              staffToEdit: null,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              onSubmitted: (staffId) {
                ref.read(selectedStaffIdProvider.notifier).state = staffId;
                context.go(RouteNames.adminStaffDetails);
              },
              onCancel: () => context.go(RouteNames.adminStaff),
            ),
          ),
          GoRoute(
            path: RouteNames.adminStaffDetails,
            builder: (context, state) => StaffDetailsScreen(
              isDark: false,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              onEditStaff: (staff) {
                ref.read(selectedStaffIdProvider.notifier).state = staff.id;
                context.go(RouteNames.adminEditStaff);
              },
            ),
          ),
          GoRoute(
            path: RouteNames.adminStaffDepartments,
            builder: (context, state) => StaffDepartmentsScreen(
              isDark: false,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              onSelectStaff: (staffId) {
                ref.read(selectedStaffIdProvider.notifier).state = staffId;
                context.go(RouteNames.adminStaffDetails);
              },
            ),
          ),
          GoRoute(
            path: RouteNames.adminAccounts,
            builder: (context, state) {
              final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
              final currentStaffId = ref.watch(selectedStaffIdProvider);
              if (staffList.isEmpty) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final staff = staffList.firstWhere(
                (s) => s.id == currentStaffId,
                orElse: () => staffList.first,
              );
              return StaffAccountsLedgerScreen(
                staff: staff,
                isDark: false,
                onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
                onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              );
            },
          ),
          GoRoute(
            path: RouteNames.adminEditStaff,
            builder: (context, state) {
              final staffList = ref.watch(staffListProvider).valueOrNull ?? [];
              final currentStaffId = ref.watch(selectedStaffIdProvider);
              if (staffList.isEmpty) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              final staff = staffList.firstWhere(
                (s) => s.id == currentStaffId,
                orElse: () => staffList.first,
              );
              return EditStaffScreen(
                initialStaff: staff,
                isDark: false,
                onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
                onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
                onSubmitted: (id) => context.go(RouteNames.adminStaffDetails),
                onCancel: () => context.go(RouteNames.adminStaff),
              );
            },
          ),
          GoRoute(
            path: RouteNames.adminAdmissions,
            builder: (context, state) => StudentListScreen(
              isDark: false,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              onSelectStudent: (studentId) {
                ref.read(selectedStudentIdProvider.notifier).state = studentId;
                context.go('/admin/admissions/$studentId');
              },
            ),
          ),
          GoRoute(
            path: RouteNames.newAdmission,
            builder: (context, state) => AddStudentFormScreen(
              isDark: false,
              isEditMode: false,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              onCancel: () => context.go(RouteNames.adminAdmissions),
              onSubmitted: (newStudentId) {
                ref.read(selectedStudentIdProvider.notifier).state = newStudentId;
                context.go('/admin/admissions/$newStudentId');
              },
            ),
          ),
          GoRoute(
            path: RouteNames.admissionDetail,
            builder: (context, state) {
              final studentId = state.pathParameters['id'];
              return StudentDetailsScreen(
                studentId: studentId,
                isDark: false,
                onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
                onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              );
            },
          ),
          GoRoute(
            path: RouteNames.adminPipeline,
            builder: (context, state) => StudentCategoriesScreen(
              isDark: false,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
            ),
          ),
          GoRoute(
            path: RouteNames.adminEditStudent,
            builder: (context, state) => AddStudentFormScreen(
              isDark: false,
              isEditMode: true,
              onNavigate: (page) => _handleAdminNavInRouter(context, ref, page),
              onExitToGateway: () => _handleAdminLogoutInRouter(context, ref),
              onCancel: () => context.go(RouteNames.adminAdmissions),
              onSubmitted: (newStudentId) {
                ref.read(selectedStudentIdProvider.notifier).state = newStudentId;
                context.go('/admin/admissions/$newStudentId');
              },
            ),
          ),
        ],
      ),
    ],
  );

  // Trigger router re-evaluation whenever authenticated sessions change
  ref.listen(selectedStaffIdProvider, (_, _) => router.refresh());
  ref.listen(selectedStudentUserIdProvider, (_, _) => router.refresh());
  ref.listen(selectedParentUserIdProvider, (_, _) => router.refresh());
  ref.listen(activeUserRoleProvider, (_, _) => router.refresh());

  return router;
});

