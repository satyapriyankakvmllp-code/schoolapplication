import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/admissions/presentation/admin/student_categories_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('StudentCategoriesScreen renders matrix cards and filters requests', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudentCategoriesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify header and 3 matrix cards render
    expect(find.text('Admission Requests & Pipeline'), findsOneWidget);
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('Approved Students'), findsOneWidget);
    expect(find.text('Rejected Catalog'), findsOneWidget);

    // Filter by Approved
    await tester.tap(find.text('Approved Students'));
    await tester.pumpAndSettle();

    // Filter by Rejected
    await tester.tap(find.text('Rejected Catalog'));
    await tester.pumpAndSettle();

    // Reset to Pending
    await tester.tap(find.text('Pending Requests'));
    await tester.pumpAndSettle();

    // Review button should exist
    final reviewButtons = find.text('Review');
    expect(reviewButtons, findsWidgets);

    // Tap first review button to open modal sheet
    await tester.tap(reviewButtons.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Modal sheet should display Application Details and Approve & Pre-fill Form
    // Close modal sheet
    await tester.tap(find.byIcon(Icons.close));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // --- TEST MOBILE PHONE VIEWPORT (360x800) ---
    tester.view.physicalSize = const Size(360, 800);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify matrix cards render vertically on phone screen
    expect(find.text('Pending Requests'), findsOneWidget);
    expect(find.text('Approved Students'), findsOneWidget);
    expect(find.text('Rejected Catalog'), findsOneWidget);

    // Verify mobile applicant item renders
    expect(find.text('Reyansh Patel'), findsOneWidget);

    // Scroll down on mobile so applicant item is in viewport
    await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -400));
    await tester.pump();

    // Tap applicant item on mobile to open review sheet
    await tester.tap(find.text('Reyansh Patel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify bottom sheet content and stacked actions on mobile
    expect(find.text('Application Details'), findsOneWidget);
    expect(find.text('Approve & Pre-fill Form'), findsOneWidget);
    expect(find.text('Reject Request'), findsOneWidget);
  });
}
