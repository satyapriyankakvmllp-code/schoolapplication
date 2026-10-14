import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admissions/data/models/user_model.dart';
import 'package:frontend/features/auth/presentation/widgets/logout_button.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('SMS App renders successfully on mobile in Admin mode', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.admin),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Student Details'), findsWidgets);

    // Toggle theme to dark
    final themeToggleFinder = find.byTooltip('Toggle Theme');
    expect(themeToggleFinder, findsOneWidget);
    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    // Toggle theme back to light
    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    // Open mobile drawer
    final menuButtonFinder = find.byTooltip('Open Menu');
    expect(menuButtonFinder, findsOneWidget);
    await tester.tap(menuButtonFinder);
    await tester.pumpAndSettle();

    // Verify drawer opened with EduPulse
    expect(find.text('EduPulse'), findsWidgets);

    // Tap Add New Student in the drawer
    await tester.tap(find.text('Add New Student'));
    await tester.pumpAndSettle();

    // Verify Add Student Form screen rendered without overflow
    expect(find.text('Student Admission Intake'), findsOneWidget);
  });

  testWidgets('SMS App renders and toggles sidebar on laptop and desktop in Admin mode', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.admin),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('EduPulse'), findsWidgets);
    expect(find.text('Student Details'), findsWidgets);

    // Sidebar should be expanded by default on desktop/laptop
    expect(find.byTooltip('Collapse Sidebar'), findsOneWidget);

    // Collapse sidebar
    await tester.tap(find.byTooltip('Collapse Sidebar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Now it should show Expand Sidebar
    expect(find.byTooltip('Expand Sidebar'), findsOneWidget);

    // Tap Expand button to expand again
    await tester.tap(find.byTooltip('Expand Sidebar'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byTooltip('Collapse Sidebar'), findsOneWidget);
  });

  testWidgets('Student Details and Edit Student screens start empty on first render and populate upon interaction', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.admin),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Student Details starts empty on initial launch / refresh
    expect(find.text('No Student Selected'), findsOneWidget);
    expect(find.text('Choose student from directory...'), findsOneWidget);

    // 2. Select Aarav Sharma via directory quick select chip
    final aaravChip = find.textContaining('Aarav Sharma');
    expect(aaravChip, findsWidgets);
    await tester.tap(aaravChip.first);
    await tester.pumpAndSettle();

    // 3. Now verify Student Details is populated with Aarav Sharma
    expect(find.text('Aarav Sharma'), findsWidgets);
    expect(find.text('ADM-2026-0042'), findsWidgets);
    expect(find.text('Personal Info'), findsOneWidget);

    // 4. Click "Edit Profile" button
    final editProfileButton = find.widgetWithText(ElevatedButton, 'Edit Profile');
    expect(editProfileButton, findsOneWidget);
    await tester.tap(editProfileButton);
    await tester.pumpAndSettle();

    // 5. Verify Edit Student screen is populated with Aarav's data
    expect(find.text('Edit Student: Aarav Sharma'), findsOneWidget);
    expect(find.text('Aarav'), findsOneWidget);
    expect(find.text('Sharma'), findsOneWidget);

    // 6. Tap "Clear / Blank Form" to verify empty state behavior
    final clearButton = find.text('Clear / Blank Form');
    expect(clearButton, findsOneWidget);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    // 7. Verify fields are empty and Empty State badge is shown
    expect(find.text('Empty State'), findsOneWidget);
    expect(find.text('Select student to populate fields...'), findsOneWidget);
  });

  testWidgets('Single Credential Sign-In Gateway authenticates and header logout redirects to sign-in page', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Launch without initialRole -> opens single Credential Sign-In Gateway
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify single Credential Sign-In Form components
    expect(find.text('Institutional Sign In'), findsOneWidget);
    expect(find.text('Institutional Role Identity'), findsOneWidget);
    expect(find.text('Institutional Email Address'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    // 2. Select Parent role chip
    await tester.tap(find.text('Parent Portal'));
    await tester.pumpAndSettle();

    // Verify Sign In as Parent Portal button exists and tap it
    final parentSignInButton = find.widgetWithText(ElevatedButton, 'Sign In as Parent Portal');
    expect(parentSignInButton, findsOneWidget);
    await tester.ensureVisible(parentSignInButton);
    await tester.tap(parentSignInButton);
    await tester.pumpAndSettle();

    // 3. Verify Parent Portal Workspace is rendered
    expect(find.text('Parent & Guardian Portal'), findsOneWidget);
    expect(find.textContaining('Aarav Rajesh Sharma'), findsOneWidget);

    // 4. Verify Logout button is present in the header
    expect(find.byType(LogoutButton), findsOneWidget);

    // 5. Tap Logout button in header
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    // 6. Verify redirected back to the Sign-In page
    expect(find.text('Institutional Sign In'), findsOneWidget);
    expect(find.text('Institutional Role Identity'), findsOneWidget);

    // 7. Now select Admin role chip and sign in
    await tester.tap(find.text('Admin Console'));
    await tester.pumpAndSettle();

    final adminSignInButton = find.widgetWithText(ElevatedButton, 'Sign In as Admin Console');
    expect(adminSignInButton, findsOneWidget);
    await tester.ensureVisible(adminSignInButton);
    await tester.tap(adminSignInButton);
    await tester.pumpAndSettle();

    // 8. Verify Admin Console is rendered
    expect(find.text('Student Details'), findsWidgets);

    // 9. Tap Logout button in Admin Console header
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    // 10. Verify redirected back to Sign-In page
    expect(find.text('Institutional Sign In'), findsOneWidget);
  });

  testWidgets('Phase 2 Front-Desk Officer Workspace renders Option A full admissions sidebar and navigates across lifecycle modules', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Launch with initialRole: UserRole.admissions
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.admissions),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Front-Desk Workspace Cockpit renders
    expect(find.text('Admissions & Intake Cockpit'), findsOneWidget);
    expect(find.text('FRONT-DESK DESK'), findsOneWidget);
    expect(find.text('Priya Verma'), findsWidgets);

    // 2. Verify all Option A Sidebar Navigation Items are visible
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Inquiries & Leads'), findsWidgets);
    expect(find.text('New Application'), findsWidgets);
    expect(find.text('Document Verification'), findsWidgets);
    expect(find.text('Interview Scheduler'), findsWidgets);
    expect(find.text('Student ID Cards'), findsWidgets);
    expect(find.text('Student Directory Lookup'), findsWidgets);
    expect(find.text('Logout'), findsWidgets);

    // 3. Navigate to Inquiries & Leads
    await tester.tap(find.text('Inquiries & Leads'));
    await tester.pumpAndSettle();
    expect(find.text('Admission Inquiries & Walk-In Desk'), findsOneWidget);
    expect(find.text('Kabir Rajesh Sharma'), findsOneWidget);

    // 4. Navigate to Document Verification
    await tester.tap(find.text('Document Verification'));
    await tester.pumpAndSettle();
    expect(find.text('Document Verification Queue'), findsOneWidget);
    expect(find.text('Birth Certificate'), findsOneWidget);

    // 5. Navigate to Student ID Cards
    await tester.tap(find.text('Student ID Cards'));
    await tester.pumpAndSettle();
    expect(find.text('Student Photo ID Badge Studio'), findsOneWidget);
    expect(find.text('Print Badge'), findsOneWidget);
    expect(find.text('EDUPULSE ACADEMY'), findsOneWidget);

    // 6. Navigate to Student Directory Lookup
    await tester.tap(find.text('Student Directory Lookup'));
    await tester.pumpAndSettle();
    expect(find.text('Student Directory & Visitor Verification'), findsOneWidget);
    expect(find.text('Aarav Rajesh Sharma'), findsOneWidget);

    // 7. Verify Logout button in header redirects to Sign-In Gateway
    expect(find.byType(LogoutButton), findsOneWidget);
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    expect(find.text('Institutional Sign In'), findsOneWidget);
  });
}
