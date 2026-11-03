import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:frontend/src/features/staff/application/staff_controller.dart';
import 'package:frontend/src/features/staff/data/staff_repository.dart';
import 'package:frontend/src/features/staff/domain/staff_compensation_model.dart';
import 'package:frontend/src/features/staff/domain/staff_member_model.dart';
import 'package:frontend/src/features/staff/presentation/admin/staff_accounts_ledger_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildTestableWidget(Widget child) {
    return ProviderScope(
      overrides: [
        staffRepositoryProvider.overrideWithValue(MockStaffRepository(preloadDefaultsOnly: true)),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  final testStaff = StaffMemberModel(
    id: 'STF-2026-0101',
    fullName: 'Dr. Rajeshwari Swaminathan',
    category: StaffCategory.teaching,
    designation: 'HOD & Senior PGT Mathematics',
    department: 'Mathematics',
    qualification: 'Ph.D. in Applied Mathematics, M.Sc., B.Ed.',
    phone: '+91 98450 12345',
    email: 'rajeshwari.swaminathan@edupulse.edu.in',
    currentAddress: 'Flat 402, Kaveri Heights, Indiranagar, Bengaluru, KA 560038',
    permanentAddress: 'Plot 12, Swaminathan Nilayam, Anna Nagar, Chennai, TN 600040',
    joiningDate: DateTime(2020, 6, 15),
    employmentType: EmploymentType.permanent,
    compensation: const StaffCompensationModel(
      basicSalary: 85000,
      bankName: 'State Bank of India',
      accountNumber: '30192847561',
      ifscCode: 'SBIN0004512',
      panNumber: 'ABCPS1234E',
      epfUan: '100984726152',
    ),
  );

  group('StaffAccountsLedgerScreen Tests', () {
    testWidgets('Renders complete faculty financial profile and bank account details', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          StaffAccountsLedgerScreen(staff: testStaff, isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Breadcrumbs
      expect(find.text('Accounts & Salary Disbursement Ledger'), findsOneWidget);
      expect(find.text('Official Registry'), findsOneWidget);
      expect(find.text('Faculty Financial & Bank Clearance Profile'), findsOneWidget);

      // Verify Bank Account Details
      expect(find.text('State Bank of India'), findsWidgets);
      expect(find.text('SBIN0004512'), findsOneWidget);
      expect(find.text('ABCPS1234E'), findsOneWidget);
      expect(find.text('100984726152'), findsOneWidget);

      // Account number is masked by default
      expect(find.text('•••• 7561'), findsOneWidget);

      // Verify KPI Cards
      expect(find.text('Monthly Basic Pay'), findsOneWidget);
      expect(find.text('Annualized Gross Pay'), findsOneWidget);
      expect(find.text('Annual Deductions (TDS/PF)'), findsOneWidget);
      expect(find.text('Total Disbursed to Date'), findsOneWidget);

      // Verify Registry Table
      expect(find.text('Salary Clearing & Bank Transfer Registry'), findsOneWidget);
      expect(find.text('Voucher ID'), findsOneWidget);
      expect(find.text('ACC-VCH-2026-08'), findsOneWidget);
    });

    testWidgets('Toggles account number mask on eye icon click', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          StaffAccountsLedgerScreen(staff: testStaff, isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Masked initially
      expect(find.text('•••• 7561'), findsOneWidget);

      // Tap reveal eye icon
      await tester.tap(find.byTooltip('Reveal Account Number'));
      await tester.pumpAndSettle();

      // Fully unmasked
      expect(find.text('30192847561'), findsOneWidget);

      // Tap mask eye icon again
      await tester.tap(find.byTooltip('Mask Account Number'));
      await tester.pumpAndSettle();

      // Masked again
      expect(find.text('•••• 7561'), findsOneWidget);
    });

    testWidgets('Update Account Details dialog opens and saves updated bank details', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          StaffAccountsLedgerScreen(staff: testStaff, isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Click Update Account Details button
      final updateBtn = find.text('Update Account Details');
      expect(updateBtn, findsOneWidget);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      // Dialog opens
      expect(find.text('Update Bank & Salary Details'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Bank Name'), findsOneWidget);

      // Modify Bank Name to HDFC Bank
      final bankField = find.widgetWithText(TextFormField, 'Bank Name');
      await tester.enterText(bankField, 'HDFC Bank');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Save Details'));
      await tester.pumpAndSettle();

      // Verify dialog dismissed and new bank name rendered
      expect(find.text('Update Bank & Salary Details'), findsNothing);
      expect(find.text('HDFC Bank'), findsOneWidget);
    });

    testWidgets('View Voucher button opens official voucher dialog', (tester) async {
      tester.view.physicalSize = const Size(2200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          StaffAccountsLedgerScreen(staff: testStaff, isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      // Tap first View Voucher button in table
      final voucherBtn = find.text('View Voucher').first;
      await tester.tap(voucherBtn);
      await tester.pumpAndSettle();

      // Verify Voucher Dialog opens
      expect(find.textContaining('Disbursement Voucher'), findsOneWidget);
      expect(find.text('Beneficiary Faculty'), findsOneWidget);
      expect(find.text('Net Disbursed Amount'), findsOneWidget);
      expect(find.text('Print Voucher'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Beneficiary Faculty'), findsNothing);
    });

    testWidgets('Adapts to phone screen (390x844) without any RenderFlex overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        buildTestableWidget(
          StaffAccountsLedgerScreen(staff: testStaff, isDark: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.byType(StaffAccountsLedgerScreen), findsOneWidget);
    });
  });
}
