import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/features/authentication/presentation/portal_gateway_screen.dart';
import 'package:frontend/src/features/staff/data/staff_repository.dart';
import 'package:frontend/src/features/staff/application/staff_controller.dart';
import 'package:frontend/src/features/authentication/application/student_auth_controller.dart';
import 'package:frontend/src/features/authentication/application/parent_auth_controller.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestGateway({
    Size surfaceSize = const Size(1280, 900),
  }) {
    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SizedBox(
          width: surfaceSize.width,
          height: surfaceSize.height,
          child: const PortalGatewayScreen(isDark: false),
        ),
      ),
    );
  }

  group('Single Institutional Sign-In Gateway Tests', () {
    testWidgets('Renders top header, search field, and password info banner', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(buildTestGateway());
      await tester.pumpAndSettle();

      expect(find.text('Institutional Sign In Gateway'), findsOneWidget);
      expect(find.text('Select any identity to instantly sign in'), findsOneWidget);
      expect(find.text('Demo Password for all: 123456'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(1)); // Only the search field initially
    });

    testWidgets('Renders all 8 unified groups including Student Hub and Parent Portal', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      await tester.pumpWidget(buildTestGateway(surfaceSize: const Size(1280, 2400)));
      await tester.pumpAndSettle();

      // Section headers
      expect(find.text('Super Administrator'), findsWidgets);
      expect(find.text('Principal & Leadership'), findsOneWidget);
      expect(find.text('Teaching Faculty - Class Teacher + Subject Teacher'), findsOneWidget);
      expect(find.text('Finance & Support'), findsOneWidget);
      expect(find.text('Student Hub'), findsOneWidget);
      expect(find.text('Parent Portal'), findsOneWidget);
      expect(find.text('Front-Desk Desk'), findsOneWidget);
      expect(find.text('Finance Ledger'), findsOneWidget);
    });

    testWidgets('Renders dedicated action buttons with correct first-name labels', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      await tester.pumpWidget(buildTestGateway(surfaceSize: const Size(1280, 2400)));
      await tester.pumpAndSettle();

      // Super Admin
      expect(find.text('Login as Admin'), findsOneWidget);

      // Principal (Dr. Anand Roy)
      expect(find.text('Login as Anand'), findsOneWidget);

      // Teaching Faculty
      expect(find.text('Login as Rajeshwari'), findsOneWidget);
      expect(find.text('Login as Vikramaditya'), findsOneWidget);

      // Finance & Support: Sunita (Accountant) must say "Login as Sunita", NOT "Login as Admin"
      expect(find.text('Login as Sunita'), findsWidgets);
      expect(find.text('Login as Meenakshi'), findsOneWidget);
      expect(find.text('Login as Harpreet'), findsOneWidget);
      expect(find.text('Login as Priya'), findsWidgets);

      // Student Hub: Aarav, Diya
      expect(find.text('Login as Aarav'), findsOneWidget);
      expect(find.text('Login as Diya'), findsOneWidget);

      // Parent Portal & Teaching Faculty (Ramesh Parashar & Ramesh Sharma)
      expect(find.text('Login as Ramesh'), findsWidgets);
    });

    testWidgets('Search TextField filters cards across user types dynamically', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 1000));
      await tester.pumpWidget(buildTestGateway());
      await tester.pumpAndSettle();

      final searchField = find.byType(TextField).first;
      await tester.enterText(searchField, 'Aarav');
      await tester.pumpAndSettle();

      // Aarav appears in Student Hub and as child context in Parent Portal
      expect(find.text('Aarav Sharma'), findsWidgets);
      expect(find.text('Login as Aarav'), findsOneWidget);
      expect(find.text('Login as Ramesh'), findsOneWidget); // Ramesh is Aarav's guardian

      // Other unrelated accounts are filtered out
      expect(find.text('Login as Anand'), findsNothing);
      expect(find.text('Login as Vikramaditya'), findsNothing);
    });

    testWidgets('Mobile phone viewport (390x844) renders without RenderFlex overflow', (tester) async {
      FlutterErrorDetails? errorDetails;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(buildTestGateway(surfaceSize: const Size(390, 844)));
      await tester.pumpAndSettle();

      if (errorDetails != null) {
        debugPrint('FLUTTER_ERROR: ${errorDetails.toString()}');
      }
      expect(tester.takeException(), isNull);
      expect(find.text('Institutional Sign In Gateway'), findsOneWidget);
      expect(find.text('Demo Password for all: 123456'), findsOneWidget);
      expect(find.text('Login as Admin'), findsOneWidget);
    });

    testWidgets('Collapsible "Or sign in manually" section expands on tap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      await tester.pumpWidget(buildTestGateway(surfaceSize: const Size(1280, 2400)));
      await tester.pumpAndSettle();

      final manualHeader = find.text('Or sign in manually');
      expect(manualHeader, findsOneWidget);
      // Initially collapsed, "Sign In with Credentials" is not visible
      expect(find.text('Sign In with Credentials'), findsNothing);

      // Scroll into view and tap to expand
      await tester.scrollUntilVisible(manualHeader, 400, scrollable: find.byType(Scrollable).first);
      await tester.tap(manualHeader);
      await tester.pumpAndSettle();

      expect(find.text('Sign In with Credentials'), findsOneWidget);
      expect(find.text('Institutional Email or ID'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('Clicking Student card logs in student and activates student session', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      final container = ProviderContainer(
        overrides: [
          staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SizedBox(
              width: 1280,
              height: 2400,
              child: PortalGatewayScreen(isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final studentLoginBtn = find.text('Login as Aarav');
      expect(studentLoginBtn, findsOneWidget);

      await tester.scrollUntilVisible(studentLoginBtn, 400, scrollable: find.byType(Scrollable).first);
      await tester.tap(studentLoginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(selectedStudentUserIdProvider), 'usr-std-501');
      expect(container.read(currentLoggedInStudentProvider)?.fullName, 'Aarav Sharma');
      expect(container.read(activeUserRoleProvider), UserRole.student);
    });

    testWidgets('Clicking Parent card logs in parent and activates parent session', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      final container = ProviderContainer(
        overrides: [
          staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SizedBox(
              width: 1280,
              height: 2400,
              child: PortalGatewayScreen(isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final parentLoginBtn = find.text('Login as Bhavin'); // Parent Bhavin Patel
      await tester.scrollUntilVisible(parentLoginBtn, 400, scrollable: find.byType(Scrollable).first);
      await tester.tap(parentLoginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(selectedParentUserIdProvider), 'usr-par-603');
      expect(container.read(currentLoggedInParentProvider)?.fullName, 'Bhavin Patel');
      expect(container.read(activeUserRoleProvider), UserRole.parent);
    });

    testWidgets('Clicking Staff card logs in staff and sets selectedStaffIdProvider', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1280, 2400));
      final container = ProviderContainer(
        overrides: [
          staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SizedBox(
              width: 1280,
              height: 2400,
              child: PortalGatewayScreen(isDark: false),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final staffLoginBtn = find.text('Login as Rajeshwari');
      expect(staffLoginBtn, findsOneWidget);

      await tester.scrollUntilVisible(staffLoginBtn, 400, scrollable: find.byType(Scrollable).first);
      await tester.tap(staffLoginBtn);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(container.read(selectedStaffIdProvider), isNotNull);
      expect(container.read(currentLoggedInStaffProvider)?.fullName, contains('Rajeshwari'));
    });
  });
}
