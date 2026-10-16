import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/features/staff/application/staff_controller.dart';
import 'package:frontend/features/staff/data/staff_repository.dart';
import 'package:frontend/features/staff/presentation/admin/add_staff_form_screen.dart';
import 'package:frontend/features/staff/presentation/admin/staff_departments_screen.dart';
import 'package:frontend/features/staff/presentation/admin/staff_details_screen.dart';
import 'package:frontend/features/staff/presentation/admin/staff_list_screen.dart';
import 'package:frontend/features/staff/presentation/admin/edit_staff_screen.dart';
import 'package:frontend/commonwidgets/edupluse_scaffold.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child, {Size physicalSize = const Size(1280, 800)}) {
    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Staff Screens Widget Tests', () {
    testWidgets('StaffListScreen renders KPIs and Faculty cards on Desktop', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffListScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Staff & Faculty Directory'), findsOneWidget);
      expect(find.text('Add New Staff'), findsWidgets);

      // Verify KPI text
      expect(find.text('Total Personnel'), findsOneWidget);
      expect(find.text('Teaching Faculty'), findsWidgets);

      // Verify seeded faculty member
      expect(find.text('Dr. Rajeshwari Swaminathan'), findsOneWidget);
      expect(find.text('Vikramaditya Sen'), findsOneWidget);
    });

    testWidgets('StaffListScreen adapts to Phone viewport (390x844) with zero overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffListScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff & Faculty Directory'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddStaffFormScreen renders 4-step wizard with dynamic teaching fields', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const AddStaffFormScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Staff Onboarding Wizard'), findsOneWidget);
      expect(find.text('Personal & Demographic Coordinates'), findsOneWidget);
      expect(find.text('Full Name *'), findsOneWidget);

      // Step forward using first available step continue button
      await tester.tap(find.text('Continue to Next Step').first);
      await tester.pumpAndSettle();

      expect(find.text('Staff Category (Determines Academic Modules)'), findsOneWidget);
      expect(find.text('Teaching Faculty'), findsWidgets);
    });

    testWidgets('AddStaffFormScreen adapts to Phone viewport (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      await tester.pumpWidget(
        buildTestableWidget(
          const AddStaffFormScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      expect(find.text('Staff Onboarding Wizard'), findsOneWidget);
      expect(errorDetails, isNull);
    });

    testWidgets('StaffDetailsScreen toggles sensitive salary masking', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Dr. Rajeshwari Swaminathan'), findsWidgets);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Compensation'), findsOneWidget);

      // Tap Compensation tab
      await tester.tap(find.text('Compensation'));
      await tester.pumpAndSettle();

      expect(find.text('Sensitive HR & Financial Dossier'), findsOneWidget);
      // By default salary is masked
      expect(find.text('₹ ••••••• / month'), findsOneWidget);

      // Tap Reveal Data
      await tester.tap(find.text('Reveal Data'));
      await tester.pumpAndSettle();

      // Salary should now be revealed
      expect(find.text('₹ 85000 / month'), findsOneWidget);
    });

    testWidgets('StaffDepartmentsScreen renders departmental matrix', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDepartmentsScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Departments & Faculty Roster'), findsOneWidget);
      expect(find.text('Mathematics'), findsOneWidget);
      expect(find.text('Science'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AddStaffFormScreen starts with empty fields and syncs permanent address via checkbox', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const AddStaffFormScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Verify name field is empty initially
      final nameFieldFinder = find.widgetWithText(TextFormField, 'Full Name *');
      expect(nameFieldFinder, findsOneWidget);
      final TextFormField nameField = tester.widget(nameFieldFinder);
      expect(nameField.controller?.text, isEmpty);

      // Verify current address field is empty initially
      final currentAddressFinder = find.widgetWithText(TextFormField, 'Current Residential Address');
      expect(currentAddressFinder, findsOneWidget);
      final TextFormField currentAddress = tester.widget(currentAddressFinder);
      expect(currentAddress.controller?.text, isEmpty);

      // Enter current address
      await tester.enterText(currentAddressFinder, 'Flat 501, Prestige Palms, Whitefield');
      await tester.pumpAndSettle();

      // Tap same address checkbox
      final sameAddressRow = find.text('Permanent address is the same as current residential address');
      expect(sameAddressRow, findsOneWidget);
      await tester.tap(sameAddressRow);
      await tester.pumpAndSettle();

      // Permanent address should now mirror current address
      final permAddressFinder = find.widgetWithText(TextFormField, 'Permanent Address');
      expect(permAddressFinder, findsOneWidget);
      final TextFormField permAddress = tester.widget(permAddressFinder);
      expect(permAddress.controller?.text, 'Flat 501, Prestige Palms, Whitefield');
      final TextField innerTextField = tester.widget(
        find.descendant(of: permAddressFinder, matching: find.byType(TextField)),
      );
      expect(innerTextField.readOnly, isTrue);
    });

    testWidgets('AddStaffFormScreen dynamically filters departments based on category', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const AddStaffFormScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Continue to step 2 (Employment)
      await tester.tap(find.text('Continue to Next Step').first);
      await tester.pumpAndSettle();

      // In Teaching Faculty (default), Teaching departments like 'Mathematics' are selected
      expect(find.text('Mathematics'), findsWidgets);

      // Select Administrative
      await tester.tap(find.text('Administrative'));
      await tester.pumpAndSettle();

      // Department should dynamically update to administrative departments
      expect(find.text('Accounts & Finance'), findsWidgets);

      // Select Support
      await tester.tap(find.text('Support'));
      await tester.pumpAndSettle();

      // Department should dynamically update to support departments
      expect(find.text('Campus Operations'), findsWidgets);
    });

    testWidgets('StaffDetailsScreen adapts to Phone viewport (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDetailsScreen(staffId: 'STF-2026-0101', isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      expect(find.text('Dr. Rajeshwari Swaminathan'), findsWidgets);
      expect(errorDetails, isNull);
    });

    testWidgets('StaffDepartmentsScreen adapts to Phone viewport (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      await tester.pumpWidget(
        buildTestableWidget(
          const StaffDepartmentsScreen(isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      expect(find.text('Departments & Faculty Roster'), findsOneWidget);
      expect(errorDetails, isNull);
    });

    testWidgets('EditStaffScreen loads existing staff data and allows updates', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final repo = MockStaffRepository(preloadDefaultsOnly: true);
      final staff = (await repo.getStaffById('STF-2026-0101'))!;

      String? submittedId;
      await tester.pumpWidget(
        buildTestableWidget(
          EditStaffScreen(
            initialStaff: staff,
            isDark: false,
            onSubmitted: (id) => submittedId = id,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that existing data is prefilled in controllers
      expect(find.text('Dr. Rajeshwari Swaminathan'), findsOneWidget);
      expect(find.text('rajeshwari.swaminathan@edupulse.edu.in'), findsWidgets);
      expect(find.text('STF-2026-0101'), findsWidgets);

      // Verify "Same as current address" is checked if current == perm address
      expect(find.text('Permanent address is the same as current residential address'), findsOneWidget);

      // Navigate to step 4 (Compensation)
      final step4Title = find.text('Compensation, Banking & Portal Login');
      await tester.ensureVisible(step4Title);
      await tester.tap(step4Title);
      await tester.pumpAndSettle();

      expect(find.text('Compensation & Banking (Admin / HR Protected)'), findsOneWidget);
      expect(find.text('85000'), findsOneWidget); // Existing basic salary

      // Tap Update Profile (in the active 4th step, controls are the last instance in the vertical Stepper)
      final saveBtn = find.text('Update Profile').last;
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(submittedId, 'STF-2026-0101');
    });

    testWidgets('EditStaffScreen adapts to Phone viewport (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      FlutterErrorDetails? errorDetails;
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (details) {
        errorDetails = details;
      };

      final repo = MockStaffRepository(preloadDefaultsOnly: true);
      final staff = (await repo.getStaffById('STF-2026-0101'))!;

      await tester.pumpWidget(
        buildTestableWidget(
          EditStaffScreen(initialStaff: staff, isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      expect(find.text('Edit Staff Profile'), findsOneWidget);
      expect(find.text('Modify institutional, academic, and compensation records for STF-2026-0101'), findsOneWidget);
      expect(errorDetails, isNull);
    });

    testWidgets('StaffListScreen edit button navigates to editStaff', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      EdupluseNavPage? navigatedPage;
      await tester.pumpWidget(
        buildTestableWidget(
          StaffListScreen(
            isDark: false,
            onNavigate: (page) => navigatedPage = page,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find Edit button on first card
      final editBtn = find.byTooltip('Edit Record').first;
      await tester.tap(editBtn);
      await tester.pumpAndSettle();

      expect(navigatedPage, EdupluseNavPage.editStaff);
    });

    testWidgets('EditStaffScreen starts with empty fields when opened initially without selected staff', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          const EditStaffScreen(
            initialStaff: null,
            isDark: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify empty initial indicators
      expect(find.text('No Staff Selected'), findsOneWidget);
      expect(find.text('No staff member selected. All fields are empty. Click "Edit" on any staff card in the Directory to modify existing records.'), findsOneWidget);
      // Verify text field is empty and doesn't contain Dr. Rajeshwari
      expect(find.text('Dr. Rajeshwari Swaminathan'), findsNothing);
    });
  });
}
