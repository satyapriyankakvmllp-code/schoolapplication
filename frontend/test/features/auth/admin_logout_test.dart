import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';
import 'package:frontend/src/commonwidgets/logout_button.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/presentation/portal_gateway_screen.dart';
import 'package:frontend/src/features/staff/application/staff_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Admin screen header Logout button terminates admin session and navigates to Gateway', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(
          initialRole: UserRole.admin,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify LogoutButton in the admin screen header is present
    final logoutButtonFinder = find.byType(LogoutButton);
    expect(logoutButtonFinder, findsOneWidget);

    // Tap the Logout button in the header
    await tester.tap(logoutButtonFinder);
    await tester.pumpAndSettle();

    // Verify that the screen returned to PortalGatewayScreen
    expect(find.byType(PortalGatewayScreen), findsOneWidget);
  });

  testWidgets('LogoutButton clears activeUserRoleProvider and selectedStaffIdProvider', (WidgetTester tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(activeUserRoleProvider.notifier).state = UserRole.admin;
    container.read(selectedStaffIdProvider.notifier).state = 'STF-2026-0001';

    bool onLogoutCalled = false;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                LogoutButton(
                  onLogout: () {
                    onLogoutCalled = true;
                  },
                ),
              ],
            ),
            body: const Center(child: Text('Admin Screen')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final logoutFinder = find.byType(LogoutButton);
    expect(logoutFinder, findsOneWidget);

    await tester.tap(logoutFinder);
    await tester.pumpAndSettle();

    expect(onLogoutCalled, isTrue);
    expect(container.read(activeUserRoleProvider), isNull);
    expect(container.read(selectedStaffIdProvider), isNull);
  });
}
