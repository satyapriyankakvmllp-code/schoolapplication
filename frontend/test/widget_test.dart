import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/commonwidgets/logout_button.dart';
import 'package:frontend/features/admissions/application/admissions_controller.dart';
import 'package:frontend/features/admissions/domain/admission_request_model.dart';
import 'package:frontend/features/admissions/domain/parent_profile_model.dart';
import 'package:frontend/features/admissions/domain/student_admission_model.dart';
import 'package:frontend/features/admissions/domain/student_profile_model.dart';
import 'package:frontend/features/admissions/presentation/admin/add_student_form_screen.dart';
import 'package:frontend/features/admissions/presentation/admin/student_categories_screen.dart';
import 'package:frontend/features/admissions/presentation/frontdesk/frontdesk_workspace_screen.dart';
import 'package:frontend/features/admissions/presentation/parent/parent_portal_workspace_screen.dart';
import 'package:frontend/features/authentication/domain/user_model.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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

  testWidgets('Complete End-to-End Admission Flow: Parent submits 3-step application and Admin reviews in Pipeline', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Launch directly as Parent
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.parent),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Verify Parent Portal loaded
    expect(find.text('Parent & Guardian Portal'), findsWidgets);
    expect(find.text('New Child Admission'), findsOneWidget);

    // 3. Navigate to New Child Admission tab
    await tester.tap(find.text('New Child Admission'));
    await tester.pumpAndSettle();

    // Verify 3-step wizard Step 1 is rendered
    expect(find.text('Step 1: Child Demographics & Grade Applied'), findsOneWidget);

    // Fill child first & last name and address
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Ishaan');
    await tester.enterText(textFields.at(1), 'Sharma');
    await tester.enterText(textFields.at(4), '42 Lotus Enclave, MG Road');
    await tester.pumpAndSettle();

    // Click Next Step
    final nextButton = find.text('Next Step ➔');
    expect(nextButton, findsOneWidget);
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // 4. Verify Step 2: Guardian Details is rendered
    expect(find.text('Step 2: Parent / Guardian & Emergency Linking'), findsOneWidget);
    expect(find.text('Rajesh Sharma'), findsWidgets);

    // Click Next Step to go to Step 3
    await tester.ensureVisible(nextButton);
    await tester.tap(nextButton);
    await tester.pumpAndSettle();

    // 5. Verify Step 3: Documents & Declaration
    expect(find.text('Step 3: Document Attachments & Declaration'), findsOneWidget);
    expect(find.text('Ishaan Sharma'), findsWidgets);

    // Accept Declaration Checkbox
    final declarationFinder = find.byType(Checkbox).last;
    await tester.ensureVisible(declarationFinder);
    await tester.tap(declarationFinder);
    await tester.pumpAndSettle();

    // Submit Application to Admin
    final submitButton = find.text('Submit Application to Admin ➔');
    expect(submitButton, findsOneWidget);
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // 6. Verify switched to My Applications & Status Tracker tab showing Ishaan Sharma in Pending Admin Review
    expect(find.text('Admission Applications & Status Tracker'), findsOneWidget);
    expect(find.text('Ishaan Sharma'), findsOneWidget);
    expect(find.text('Pending Admin Review'), findsWidgets);

    // 7. Log out from Parent Portal
    expect(find.byType(LogoutButton), findsOneWidget);
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();
    expect(find.text('Institutional Sign In'), findsOneWidget);

    // 8. Sign in as Admin Console
    await tester.tap(find.text('Admin Console'));
    await tester.pumpAndSettle();
    final adminSignInBtn = find.widgetWithText(ElevatedButton, 'Sign In as Admin Console');
    await tester.ensureVisible(adminSignInBtn);
    await tester.tap(adminSignInBtn);
    await tester.pumpAndSettle();

    // 9. Navigate to Student Pipeline (Categories)
    final pipelineNavFinder = find.text('Student Pipeline');
    expect(pipelineNavFinder, findsWidgets);
    await tester.tap(pipelineNavFinder.first);
    await tester.pumpAndSettle();

    // 10. Verify Ishaan Sharma is present in the Admin Pipeline under Pending with Parent Portal badge!
    expect(find.text('Ishaan Sharma'), findsWidgets);
    expect(find.text('Parent Portal'), findsWidgets);
  });

  testWidgets('Front-Desk Officer Walk-In Intake Form renders separately on Phone (390x844) without Admin sidebar and submits to Admin pending queue', (WidgetTester tester) async {
    // Set viewport to mobile phone size (iPhone 13/14/15 size: 390x844)
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Launch with admissions (Front-Desk) role
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.admissions),
      ),
    );
    await tester.pumpAndSettle();

    // 2. On mobile phone, verify hamburger button exists and opens drawer
    final menuButton = find.byIcon(Icons.menu);
    expect(menuButton, findsOneWidget);
    await tester.tap(menuButton);
    await tester.pumpAndSettle();

    // 3. Tap "New Application" from drawer
    final newAppNavItem = find.text('New Application');
    expect(newAppNavItem, findsOneWidget);
    await tester.tap(newAppNavItem);
    await tester.pumpAndSettle();

    // 4. Verify Front-Desk Standalone Intake form is rendered WITHOUT Admin sidebar
    expect(find.text('Walk-In Admission Intake Form'), findsOneWidget);
    expect(find.text('1. Student Personal Details'), findsOneWidget);
    expect(find.text('2. Academic Placement Applied'), findsOneWidget);
    expect(find.text('3. Parent / Guardian & Emergency Linking'), findsOneWidget);
    expect(find.text('4. Documents Presented by Parent'), findsOneWidget);

    // Fill student personal details
    final textFields = find.byType(TextFormField);
    await tester.ensureVisible(textFields.at(0));
    await tester.enterText(textFields.at(0), 'Ananya'); // First Name
    await tester.ensureVisible(textFields.at(1));
    await tester.enterText(textFields.at(1), 'Kulkarni'); // Last Name
    await tester.ensureVisible(textFields.at(3));
    await tester.enterText(textFields.at(3), '12 Palm Grove, Pune'); // Address
    await tester.ensureVisible(textFields.at(6));
    await tester.enterText(textFields.at(6), 'Suresh Kulkarni'); // Guardian Name
    await tester.ensureVisible(textFields.at(7));
    await tester.enterText(textFields.at(7), '+91 98220 12345'); // Guardian Phone
    await tester.ensureVisible(textFields.at(8));
    await tester.enterText(textFields.at(8), 'suresh.kulkarni@example.com'); // Guardian Email
    await tester.pumpAndSettle();

    // Scroll down to submit button
    final submitButton = find.text('Submit Application to Admin ➔');
    expect(submitButton, findsOneWidget);
    await tester.ensureVisible(submitButton);
    await tester.pumpAndSettle();
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify submission modal dialog with Pending status
    expect(find.text('Application Submitted!'), findsOneWidget);
    expect(find.text('Pending Review'), findsOneWidget);

    // Click Return to Dashboard
    final returnBtn = find.text('Return to Dashboard');
    expect(returnBtn, findsOneWidget);
    await tester.tap(returnBtn);
    await tester.pumpAndSettle();

    // Verify returned to Front-Desk Dashboard
    expect(find.text('Admissions & Intake Cockpit'), findsOneWidget);
  });

  testWidgets('Front-Desk Officer attaches documents, submits to Admin, and Admin approves into registration form without crash', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.admissions),
      ),
    );
    await tester.pumpAndSettle();

    // Navigate to New Application
    final newAppNavItem = find.text('New Application');
    expect(newAppNavItem, findsWidgets);
    await tester.tap(newAppNavItem.first);
    await tester.pumpAndSettle();

    expect(find.text('4. Documents Presented by Parent'), findsOneWidget);
    expect(find.text('Student Birth Certificate *'), findsOneWidget);

    // Fill form
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Rohit');
    await tester.enterText(textFields.at(1), 'Verma');
    await tester.enterText(textFields.at(3), '42 MG Road, Bangalore');
    await tester.enterText(textFields.at(6), 'Vikram Verma');
    await tester.enterText(textFields.at(7), '+91 98888 77777');
    await tester.enterText(textFields.at(8), 'vikram.verma@example.com');
    await tester.pumpAndSettle();

    // Submit Application to Admin
    final submitButton = find.text('Submit Application to Admin ➔');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Dismiss modal dialog
    final returnBtn = find.text('Return to Dashboard');
    expect(returnBtn, findsOneWidget);
    await tester.tap(returnBtn);
    await tester.pumpAndSettle();

    // Log out and switch to Admin Console
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin Console'));
    await tester.pumpAndSettle();
    final adminSignInBtn = find.widgetWithText(ElevatedButton, 'Sign In as Admin Console');
    await tester.ensureVisible(adminSignInBtn);
    await tester.tap(adminSignInBtn);
    await tester.pumpAndSettle();

    // Navigate to Student Pipeline
    final pipelineNavFinder = find.text('Student Pipeline');
    expect(pipelineNavFinder, findsWidgets);
    await tester.tap(pipelineNavFinder.first);
    await tester.pumpAndSettle();

    // Verify Rohit Verma appears in the pipeline
    expect(find.text('Rohit Verma'), findsWidgets);

    // Open review modal via Review button
    final reviewButtons = find.text('Review');
    expect(reviewButtons, findsWidgets);
    await tester.tap(reviewButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify documents are displayed in review sheet
    expect(find.text('Application Details'), findsOneWidget);
    expect(find.text('Submitted Documents'), findsOneWidget);

    // Click Approve & Pre-fill Form
    final approveBtn = find.text('Approve & Pre-fill Form');
    expect(approveBtn, findsOneWidget);
    await tester.tap(approveBtn);
    await tester.pumpAndSettle();

    // Verify Add Student Form Screen opens without crash and pre-fills Rohit Verma!
    expect(find.text('Student Personal Details'), findsOneWidget);
    expect(find.text('Rohit'), findsWidgets);
    expect(find.text('Verma'), findsWidgets);

    // Navigate through steps to Step 4: Document Verification
    for (int i = 0; i < 3; i++) {
      final proceedBtn = find.text('Proceed to Next Step →');
      await tester.dragUntilVisible(
        proceedBtn,
        find.byType(SingleChildScrollView).last,
        const Offset(0, -150),
      );
      await tester.pumpAndSettle();
      await tester.tap(proceedBtn, warnIfMissed: false);
      await tester.pumpAndSettle();
    }

    // Verify default fake documents were NOT automatically populated
    expect(find.text('Class_9_Marksheet.pdf'), findsNothing);
    expect(find.text('Govt_Aadhaar_Card.pdf'), findsNothing);
    expect(find.text('Aadhaar_Birth_Certificate.pdf'), findsNothing);

    // Update and register student succeeds without blocking on missing optional documents
    final submitBtn = find.byType(ElevatedButton).last;
    await tester.dragUntilVisible(
      submitBtn,
      find.byType(SingleChildScrollView).last,
      const Offset(0, -150),
    );
    await tester.pumpAndSettle();
    await tester.tap(submitBtn, warnIfMissed: false);
    await tester.pumpAndSettle();
  });

  testWidgets('Parent Portal renders responsive mobile layout on phone (390x844) with bottom navigation and switches tabs cleanly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.parent),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Mobile Header and Bottom Navigation Bar
    expect(find.text('EduPulse'), findsOneWidget);
    expect(find.text('PARENT & GUARDIAN PORTAL'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);

    // Verify Sibling switcher and stats on mobile
    expect(find.text('Aarav Sharma'), findsWidgets);
    expect(find.text('Kabir Sharma'), findsWidgets);
    expect(find.text('Attendance Rate'), findsOneWidget);

    // Switch child to Kabir Sharma
    await tester.tap(find.text('Kabir Sharma').first);
    await tester.pumpAndSettle();
    expect(find.text('Kabir Rajesh Sharma'), findsOneWidget);

    // Tap New Child Admission on Bottom Navigation
    await tester.tap(find.text('New Child Admission'));
    await tester.pumpAndSettle();
    expect(find.text('Step 1: Child Demographics & Grade Applied'), findsOneWidget);

    // Tap My Applications on Bottom Navigation
    await tester.tap(find.text('My Applications'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Admission Applications & Status Tracker'), findsOneWidget);

    // Tap Header Back Button to return to Enrolled Children Overview
    await tester.tap(find.byTooltip('Back to Overview'));
    await tester.pumpAndSettle();
    expect(find.text('Kabir Rajesh Sharma'), findsOneWidget);
  });

  testWidgets('Cross-role verification: Admin student approval reactively updates Parent and Front-Desk views', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Launch directly as Parent
    await tester.pumpWidget(
      const ProviderScope(
        child: SchoolManagementApp(initialRole: UserRole.parent),
      ),
    );
    await tester.pumpAndSettle();

    // 2. Navigate to "New Child Admission" wizard
    await tester.tap(find.text('New Child Admission'));
    await tester.pumpAndSettle();

    // Fill new student details: "Aditi" "Sharma"
    final textFields = find.byType(TextFormField);
    await tester.enterText(textFields.at(0), 'Aditi');
    await tester.enterText(textFields.at(1), 'Sharma');
    await tester.enterText(textFields.at(4), '42 Lotus Enclave, MG Road');
    await tester.pumpAndSettle();

    // Step 1 -> Step 2
    final nextBtn = find.text('Next Step ➔');
    await tester.ensureVisible(nextBtn);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Step 2 -> Step 3
    await tester.ensureVisible(nextBtn);
    await tester.tap(nextBtn);
    await tester.pumpAndSettle();

    // Accept Declaration Checkbox & Submit Application
    final declarationFinder = find.byType(Checkbox).last;
    await tester.ensureVisible(declarationFinder);
    await tester.tap(declarationFinder);
    await tester.pumpAndSettle();

    final submitAppBtn = find.text('Submit Application to Admin ➔');
    await tester.ensureVisible(submitAppBtn);
    await tester.tap(submitAppBtn);
    await tester.pumpAndSettle();

    // Verify parent tracker immediately shows Aditi Sharma as Pending Admin Review
    expect(find.text('Admission Applications & Status Tracker'), findsOneWidget);
    expect(find.text('Aditi Sharma'), findsOneWidget);
    expect(find.text('Pending Admin Review'), findsWidgets);

    // 3. Log out and switch to Admin Console
    expect(find.byType(LogoutButton), findsOneWidget);
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Admin Console'));
    await tester.pumpAndSettle();
    final adminSignInBtn = find.widgetWithText(ElevatedButton, 'Sign In as Admin Console');
    await tester.ensureVisible(adminSignInBtn);
    await tester.tap(adminSignInBtn);
    await tester.pumpAndSettle();

    // Navigate to Student Pipeline
    final pipelineNavFinder = find.text('Student Pipeline');
    expect(pipelineNavFinder, findsWidgets);
    await tester.tap(pipelineNavFinder.first);
    await tester.pumpAndSettle();

    // Verify Aditi Sharma is in the pending pipeline
    expect(find.text('Aditi Sharma'), findsWidgets);

    // Open Review modal for Aditi Sharma
    final reviewButtons = find.text('Review');
    await tester.tap(reviewButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Application Details'), findsOneWidget);
    final approveBtn = find.text('Approve & Pre-fill Form');
    expect(approveBtn, findsOneWidget);
    await tester.tap(approveBtn);
    await tester.pumpAndSettle();

    // Verify Add Student Form screen opens pre-filled with Aditi Sharma
    expect(find.text('Student Personal Details'), findsOneWidget);
    expect(find.text('Aditi'), findsWidgets);
    expect(find.text('Sharma'), findsWidgets);

    // Dismiss any lingering snackbars so action buttons aren't obscured
    ScaffoldMessenger.of(tester.element(find.byType(AddStudentFormScreen))).clearSnackBars();
    await tester.pumpAndSettle();

    // Step through the form to Step 4
    for (int i = 0; i < 3; i++) {
      final proceedBtn = find.text('Proceed to Next Step →');
      await tester.ensureVisible(proceedBtn);
      await tester.pumpAndSettle();
      await tester.tap(proceedBtn);
      await tester.pumpAndSettle();
    }

    // Submit and register student into official institutional records
    final submitIntakeBtn = find.text('Submit Application →');
    await tester.ensureVisible(submitIntakeBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitIntakeBtn);
    await tester.pumpAndSettle();

    // Verify confirmation snackbar
    expect(find.textContaining('completed successfully'), findsWidgets);

    // 4. Log out from Admin Console and Switch back to Parent Portal
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Parent Portal').first);
    await tester.pumpAndSettle();
    final parentSignInBtn = find.widgetWithText(ElevatedButton, 'Sign In as Parent Portal');
    await tester.ensureVisible(parentSignInBtn);
    await tester.tap(parentSignInBtn);
    await tester.pumpAndSettle();

    // VERIFY PARENT END:
    // (A) In Tab 1: Aditi Sharma is now reactively present in Enrolled Children switcher!
    expect(find.text('Parent & Guardian Portal'), findsWidgets);
    expect(find.text('Aditi Sharma'), findsWidgets);

    // Tap Aditi Sharma to view her snapshot card
    await tester.tap(find.text('Aditi Sharma').first);
    await tester.pumpAndSettle();
    expect(find.text('100% (Newly Enrolled)'), findsOneWidget);

    // (B) In Tab 3: Navigate to "My Applications & Status Tracker"
    await tester.tap(find.text('My Applications & Status'));
    await tester.pumpAndSettle();

    // Verify status reactively changed to "Approved & Enrolled" with stage 3 completed!
    expect(find.text('Approved & Enrolled'), findsWidgets);
    expect(find.text('3. Final Enrollment'), findsWidgets);

    // 5. Log out from Parent Portal and Switch to Admissions Officer (Front-Desk)
    await tester.tap(find.byType(LogoutButton));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Front-Desk Desk').first);
    await tester.pumpAndSettle();
    final frontDeskSignInBtn = find.widgetWithText(ElevatedButton, 'Sign In as Front-Desk Desk');
    await tester.ensureVisible(frontDeskSignInBtn);
    await tester.tap(frontDeskSignInBtn);
    await tester.pumpAndSettle();

    // VERIFY FRONT-DESK END:
    // (A) Front-Desk Dashboard KPI shows live enrolled scholars
    expect(find.text('Live student directory & badges'), findsOneWidget);

    // (B) Navigate to Student Directory Lookup
    await tester.tap(find.text('Student Directory Lookup').first);
    await tester.pumpAndSettle();

    // Verify newly approved student Aditi Sharma is listed in the Front-Desk directory with Enrolled status
    expect(find.text('Student Directory & Visitor Verification'), findsOneWidget);
    expect(find.text('Aditi Sharma'), findsWidgets);
    expect(find.text('Enrolled'), findsWidgets);

    // Search specifically for Aditi Sharma in directory
    await tester.enterText(find.byType(TextField).last, 'Aditi');
    await tester.pumpAndSettle();

    // (C) Tap "View Badge" for Aditi Sharma and verify ID Badge Studio
    final viewBadgeBtns = find.text('View Badge');
    expect(viewBadgeBtns, findsWidgets);
    await tester.tap(viewBadgeBtns.first);
    await tester.pumpAndSettle();

    // Verify ID Badge Studio is active with Aditi Sharma selected
    expect(find.text('Student Photo ID Badge Studio'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Aditi Sharma'));
    await tester.pumpAndSettle();

    expect(find.text('Front Side (Identity)'), findsOneWidget);
    expect(find.text('EDUPULSE ACADEMY'), findsOneWidget);

    // Switch to Back Side of the badge
    await tester.tap(find.text('Back Side (Emergency & Address)'));
    await tester.pumpAndSettle();
    expect(find.text('EMERGENCY & GUARDIAN DIRECTORY'), findsOneWidget);
    expect(find.text('Rajesh Sharma'), findsWidgets);
  });

}

