import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/staff/application/staff_controller.dart';
import 'package:frontend/src/features/staff/data/staff_repository.dart';
import 'package:frontend/src/features/staff/presentation/staff/common/my_profile_screen.dart';
import 'package:frontend/src/routing/route_names.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Staff Restart & Session Persistence Tests', () {
    test('checkAutoLogin restores staff ID, route, and role after restart', () async {
      SharedPreferences.setMockInitialValues({
        'edupulse_active_staff_id': 'STF-2026-0101',
        'edupulse_active_staff_route': RouteNames.staffMyProfile,
        'edupulse_active_user_role': 'teacher',
      });

      final container = ProviderContainer(
        overrides: [
          staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
        ],
      );
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      final restoredId = await authController.checkAutoLogin();

      expect(restoredId, equals('STF-2026-0101'));
      expect(container.read(selectedStaffIdProvider), equals('STF-2026-0101'));
      expect(container.read(activeStaffRouteProvider), equals(RouteNames.staffMyProfile));
      expect(container.read(activeUserRoleProvider), equals(UserRole.teacher));

      // Ensure staff is resolved
      final loggedInStaff = container.read(currentLoggedInStaffProvider);
      expect(loggedInStaff, isNotNull);
      expect(loggedInStaff!.id, equals('STF-2026-0101'));
      expect(loggedInStaff.effectiveRole, equals('teacher'));
    });

    test('logout clears all persistence tokens and session states', () async {
      SharedPreferences.setMockInitialValues({
        'edupulse_active_staff_id': 'STF-2026-0101',
        'edupulse_active_staff_route': RouteNames.staffMyProfile,
        'edupulse_active_user_role': 'teacher',
      });

      final container = ProviderContainer(
        overrides: [
          staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
        ],
      );
      addTearDown(container.dispose);

      final authController = container.read(staffAuthControllerProvider);
      await authController.checkAutoLogin();
      expect(container.read(selectedStaffIdProvider), isNotNull);

      await authController.logout();
      expect(container.read(selectedStaffIdProvider), isNull);
      expect(container.read(activeUserRoleProvider), isNull);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('edupulse_active_staff_id'), isNull);
      expect(prefs.getString('edupulse_active_staff_route'), isNull);
      expect(prefs.getString('edupulse_active_user_role'), isNull);
    });

    testWidgets('MyProfileScreen gracefully recovers and displays profile without No Profile Loaded on restart', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      SharedPreferences.setMockInitialValues({});

      final container = ProviderContainer(
        overrides: [
          staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
          activeUserRoleProvider.overrideWith((ref) => UserRole.teacher),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: MyProfileScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Should NOT show 'No Profile Loaded'
      expect(find.text('No Profile Loaded'), findsNothing);

      // Should show Profile Tabs and Hero Header
      expect(find.text('Overview & Bio'), findsOneWidget);
      expect(find.text('Work & Duties'), findsOneWidget);
      expect(find.text('Payroll & Statutory'), findsOneWidget);
    });
  });
}
