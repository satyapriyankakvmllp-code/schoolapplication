import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/src/features/staff/application/staff_auth_controller.dart';
import 'package:frontend/src/features/admissions/presentation/admin/student_list_screen.dart';
import 'package:frontend/src/features/admissions/application/admissions_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StudentListScreen renders on desktop (1440x900) with admin staff login', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final authController = container.read(staffAuthControllerProvider);
    await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

    String? selectedId;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: StudentListScreen(
            onSelectStudent: (id) => selectedId = id,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(StudentListScreen), findsOneWidget);
    expect(find.text('Student Directory'), findsOneWidget);
    expect(find.text('All Classes'), findsOneWidget);

    // Verify search works
    await tester.enterText(find.byType(TextField), 'Aarav');
    await tester.pumpAndSettle();
    expect(find.text('Aarav Sharma'), findsOneWidget);

    // Verify selecting student triggers callback and updates provider
    final viewProfileButton = find.widgetWithText(ElevatedButton, 'View Profile').first;
    await tester.tap(viewProfileButton);
    await tester.pumpAndSettle();

    expect(selectedId, isNotNull);
    expect(container.read(selectedStudentIdProvider), equals(selectedId));
  });

  testWidgets('StudentListScreen renders without throwing error when no user logged in', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudentListScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(StudentListScreen), findsOneWidget);
    expect(find.text('Student Directory'), findsOneWidget);
  });

  testWidgets('StudentListScreen renders on mobile 390x844 without any overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer();
    addTearDown(container.dispose);

    final authController = container.read(staffAuthControllerProvider);
    await authController.mockStaffLogin('admin@edupulse.edu.in', '123456');

    String? selectedId;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: StudentListScreen(
            onSelectStudent: (id) => selectedId = id,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(StudentListScreen), findsOneWidget);

    // Verify narrow card view Profile button
    final viewProfileButton = find.widgetWithText(OutlinedButton, 'View Profile').first;
    await tester.tap(viewProfileButton);
    await tester.pumpAndSettle();

    expect(selectedId, isNotNull);
  });
}
