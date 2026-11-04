import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/main.dart';
import 'package:frontend/src/commonwidgets/edupluse_scaffold.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/staff/presentation/staff/staff_shell_layout.dart';
import 'package:frontend/src/features/authentication/presentation/portal_gateway_screen.dart';
import 'package:frontend/src/routing/app_router.dart';
import 'package:frontend/src/routing/route_names.dart';
import 'package:shared_preferences/shared_preferences.dart';


void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ShellRoute Separation & Universal Access Tests', () {
    testWidgets('Router redirect guard redirects non-admin staff attempting to access /admin/staff to /staff/dashboard', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      final staff = await authController.mockStaffLogin('rajeshwari.swaminathan@edupulse.edu.in', '123456');
      expect(staff, isNotNull);
      expect(staff!.effectiveRole, equals('teacher'));

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Attempt to navigate to /admin/staff
      router.go(RouteNames.adminStaff);
      await tester.pumpAndSettle();

      // Should be redirected to /staff/dashboard
      expect(router.state.uri.path, equals(RouteNames.staffDashboard));
    });

    testWidgets('Router redirect guard redirects Admin on /staff/* to /admin/staff', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      final staff = await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      expect(staff, isNotNull);
      expect(staff!.isSuperAdmin, isTrue);

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to /admin/staff
      router.go(RouteNames.adminStaff);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, equals(RouteNames.adminStaff));

      // Attempting to navigate to /staff/dashboard redirects Admin to /admin/staff
      router.go(RouteNames.staffDashboard);
      await tester.pumpAndSettle();
      expect(router.state.uri.path, equals(RouteNames.adminStaff));
    });

    testWidgets('Super Admin on /admin/staff renders ONLY EdupluseScaffold (Admin sidebar) without outer StaffShellLayout', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. StaffShellLayout (outer sidebar "Faculty & Staff Workspace") MUST NOT be present
      expect(find.byType(StaffShellLayout), findsNothing);
      expect(find.text('Faculty & Staff Workspace'), findsNothing);

      // 2. EdupluseScaffold (inner sidebar "Dr. Sarah Jenkins School Administrator") MUST be present
      expect(find.byType(EdupluseScaffold), findsOneWidget);
      expect(find.text('Dr. Sarah Jenkins'), findsWidgets);
      expect(find.text('School Administrator'), findsWidgets);

      // 3. Staff & Faculty Directory content MUST be present
      expect(find.text('Staff & Faculty Directory'), findsOneWidget);
      expect(find.text('Total Personnel'), findsOneWidget);
      expect(find.text('Teaching Faculty'), findsWidgets);
    });

    testWidgets('Admin on /staff/dashboard renders ONLY EdupluseScaffold and never StaffShellLayout', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.staffDashboard;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      // 1. StaffShellLayout MUST NOT be present
      expect(find.byType(StaffShellLayout), findsNothing);
      expect(find.text('Faculty & Staff Workspace'), findsNothing);

      // 2. EdupluseScaffold (Admin console) MUST be present
      expect(find.byType(EdupluseScaffold), findsOneWidget);
      expect(find.text('Dr. Sarah Jenkins'), findsWidgets);
    });

    testWidgets('Clicking Student List in sidebar from Admin side navigates to Student Directory', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff & Faculty Directory'), findsOneWidget);

      // Tap Student List in sidebar
      final studentListFinder = find.text('Student List');
      expect(studentListFinder, findsWidgets);
      await tester.tap(studentListFinder.first);
      await tester.pumpAndSettle();

      // Verify Student Directory is shown
      expect(find.text('Student Directory'), findsOneWidget);
    });

    testWidgets('Clicking Student List from Staff Details (Admin Profile) navigates to Student Directory', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Open Staff Details / Admin Profile
      expect(find.text('Profile'), findsWidgets);
      await tester.tap(find.text('Profile').first);
      await tester.pumpAndSettle();

      expect(find.text('Staff 360° Profile Dossier'), findsOneWidget);

      // Now tap Student List in sidebar
      final studentListFinder = find.text('Student List');
      expect(studentListFinder, findsWidgets);
      await tester.tap(studentListFinder.first);
      await tester.pumpAndSettle();

      // Verify Student Directory is shown
      expect(find.text('Student Directory'), findsOneWidget);
    });

    testWidgets('In GoRouter: Clicking Student List in sidebar from /admin/staff navigates to Student Directory', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RouteNames.adminStaff);
      await tester.pumpAndSettle();

      expect(find.text('Staff & Faculty Directory'), findsOneWidget);

      // Tap Student List in sidebar
      final studentListFinder = find.text('Student List');
      expect(studentListFinder, findsWidgets);
      await tester.tap(studentListFinder.first);
      await tester.pumpAndSettle();

      // Verify Student Directory is shown
      expect(find.text('Student Directory'), findsOneWidget);
    });
    testWidgets('Clicking Student Pipeline in sidebar from Admin side navigates to Student Pipeline', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff & Faculty Directory'), findsOneWidget);

      // Tap Student Pipeline in sidebar
      final pipelineFinder = find.text('Student Pipeline');
      expect(pipelineFinder, findsWidgets);
      await tester.tap(pipelineFinder.first);
      await tester.pumpAndSettle();

      // Verify Student Pipeline / Application Matrix is shown
      expect(find.text('Admission Requests & Pipeline'), findsOneWidget);
    });

    testWidgets('Clicking Add New Student in sidebar from Admin side navigates to Add Student Form', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Add New Student in sidebar
      final addStudentFinder = find.text('Add New Student');
      expect(addStudentFinder, findsWidgets);
      await tester.tap(addStudentFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('Student Admission Intake'), findsOneWidget);
    });

    testWidgets('Clicking Edit Student in sidebar from Admin side navigates to Edit Student Form', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Edit Student in sidebar
      final editStudentFinder = find.text('Edit Student');
      expect(editStudentFinder, findsWidgets);
      await tester.tap(editStudentFinder.first);
      await tester.pumpAndSettle();

      expect(find.text('Select Student to Edit'), findsOneWidget);
    });

    testWidgets('In Student List: Clicking a student item row navigates to Student Details Dossier', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');
      container.read(activeStaffRouteProvider.notifier).state = RouteNames.adminStaff;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Student List
      await tester.tap(find.text('Student List').first);
      await tester.pumpAndSettle();

      expect(find.text('Student Directory'), findsOneWidget);

      // Tap on a student row or 'View Profile' button
      final viewProfileFinder = find.text('View Profile');
      expect(viewProfileFinder, findsWidgets);
      await tester.tap(viewProfileFinder.first);
      await tester.pumpAndSettle();

      // Verify Student Details is shown
      expect(find.byTooltip('Back to Student Directory'), findsOneWidget);
    });

    testWidgets('In GoRouter: Clicking Student Pipeline in sidebar from /admin/staff navigates to Student Pipeline', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RouteNames.adminStaff);
      await tester.pumpAndSettle();

      // Tap Student Pipeline in sidebar
      await tester.tap(find.text('Student Pipeline').first);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, equals(RouteNames.adminPipeline));
      expect(find.text('Admission Requests & Pipeline'), findsOneWidget);
    });

    testWidgets('In GoRouter: Clicking Add New Student in sidebar navigates to /admin/admissions/new', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RouteNames.adminStaff);
      await tester.pumpAndSettle();

      // Tap Add New Student in sidebar
      await tester.tap(find.text('Add New Student').first);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, equals(RouteNames.newAdmission));
      expect(find.text('Student Admission Intake'), findsOneWidget);
    });

    testWidgets('In GoRouter: Clicking Edit Student in sidebar navigates to /admin/edit-student', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RouteNames.adminStaff);
      await tester.pumpAndSettle();

      // Tap Edit Student in sidebar
      await tester.tap(find.text('Edit Student').first);
      await tester.pumpAndSettle();

      expect(router.state.uri.path, equals(RouteNames.adminEditStudent));
      expect(find.text('Select Student to Edit'), findsOneWidget);
    });

    testWidgets('In GoRouter: Clicking a student item row navigates to /admin/admissions/:id', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

      final router = container.read(appRouterProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      router.go(RouteNames.adminAdmissions);
      await tester.pumpAndSettle();

      expect(find.text('Student Directory'), findsOneWidget);

      // Tap on View Profile
      await tester.tap(find.text('View Profile').first);
      await tester.pumpAndSettle();

      expect(router.state.uri.path.startsWith('/admin/admissions/'), isTrue);
      expect(find.byTooltip('Back to Student Directory'), findsOneWidget);
    });

    testWidgets('App open and reload shows Sign-In Gateway screen, allowing user to select any role', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // 1. Initial pump (simulating app open or browser reload)
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SchoolManagementApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Sign-In Gateway is shown first, not admin or staff console
      expect(find.byType(PortalGatewayScreen), findsOneWidget);
      expect(find.text('Unified Gateway'), findsOneWidget);
      expect(find.text('Login as Admin'), findsOneWidget);
      expect(find.byType(EdupluseScaffold), findsNothing);
      expect(find.byType(StaffShellLayout), findsNothing);

      // 2. User clicks "Login as Admin"
      await tester.tap(find.text('Login as Admin'));
      await tester.pumpAndSettle();

      // Verify Admin console is now shown
      expect(find.byType(EdupluseScaffold), findsOneWidget);
      expect(find.text('Dr. Sarah Jenkins'), findsWidgets);
      expect(find.byType(PortalGatewayScreen), findsNothing);
    });
  });
}


