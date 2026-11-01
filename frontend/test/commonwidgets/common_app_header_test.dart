import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/commonwidgets/common_app_header.dart';
import 'package:frontend/src/commonwidgets/logout_button.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('CommonAppHeader renders menu icon, role pill, theme toggle, and logout button',
      (tester) async {
    bool toggledSidebar = false;
    bool toggledTheme = false;
    bool loggedOut = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeUserRoleProvider.overrideWith((ref) => UserRole.admin),
        ],
        child: MaterialApp(
          home: Scaffold(
            appBar: CommonAppHeader(
              isDark: false,
              onToggleSidebar: () => toggledSidebar = true,
              onToggleTheme: () => toggledTheme = true,
              onLogout: () => loggedOut = true,
            ),
            body: const Center(child: Text('Content')),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Left side menu icon
    final menuIconFinder = find.byIcon(Icons.menu);
    expect(menuIconFinder, findsOneWidget);
    await tester.tap(menuIconFinder);
    await tester.pumpAndSettle();
    expect(toggledSidebar, isTrue);

    // 2. Right side: Role pill displays "Admin"
    expect(find.text('Admin'), findsOneWidget);

    // 3. Theme toggle button
    final themeToggleFinder = find.byTooltip('Switch to Dark Mode');
    expect(themeToggleFinder, findsOneWidget);
    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();
    expect(toggledTheme, isTrue);

    // 4. Logout button
    final logoutBtnFinder = find.byType(LogoutButton);
    expect(logoutBtnFinder, findsOneWidget);
    await tester.tap(logoutBtnFinder);
    await tester.pumpAndSettle();
    expect(loggedOut, isTrue);
  });

  testWidgets('CommonAppHeader respects roleOverride and custom color',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: const CommonAppHeader(
            isDark: true,
            roleOverride: 'Principal',
            roleColorOverride: Color(0xFF8B5CF6),
          ),
          body: const SizedBox.shrink(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Principal'), findsOneWidget);
    // Dark mode shows light mode sun icon
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}
