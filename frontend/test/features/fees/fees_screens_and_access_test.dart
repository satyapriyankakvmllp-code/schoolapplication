import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/authentication/application/auth_controller.dart';
import 'package:frontend/src/features/authentication/domain/user_model.dart';
import 'package:frontend/src/features/fees/application/fees_access.dart';
import 'package:frontend/src/features/fees/application/fees_controller.dart';
import 'package:frontend/src/features/fees/data/fees_repository.dart';
import 'package:frontend/src/features/fees/domain/fee_structure.dart';
import 'package:frontend/src/features/fees/presentation/fee_structure_form_panel.dart';
import 'package:frontend/src/features/fees/presentation/fee_structure_list_screen.dart';
import 'package:frontend/src/utils/asset_loader.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestAssetLoader extends AssetLoader {
  const TestAssetLoader();
  @override
  Future<dynamic> loadJson(String path, {int delayMs = 0}) async => {};
  @override
  Future<Map<String, dynamic>> loadJsonObject(String path, {int delayMs = 0}) async => {};
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Fees Access Control Tests', () {
    test('canRoleAccessFees returns true only for Admin and Finance', () {
      expect(canRoleAccessFees(UserRole.admin), isTrue);
      expect(canRoleAccessFees(UserRole.finance), isTrue);
      expect(canRoleAccessFees(UserRole.teacher), isFalse);
      expect(canRoleAccessFees(UserRole.parent), isFalse);
      expect(canRoleAccessFees(UserRole.student), isFalse);
      expect(canRoleAccessFees(UserRole.admissions), isFalse);
      expect(canRoleAccessFees(null), isFalse);
    });
  });

  group('FeeStructure Screens Responsive Tests', () {
    late FeesRepository mockRepo;

    final sampleStructures = [
      const FeeStructure(
        id: 'fee-str-10-term1',
        className: 'Class 10',
        termName: 'Term 1',
        academicYear: '2026-2027',
        tuitionFee: 28000.0,
        labComputerFee: 6000.0,
        developmentFee: 5000.0,
        otherFee: 3500.0,
        totalFee: 42500.0,
        dueDate: '2026-11-15',
        isActive: true,
        createdAt: '2026-05-01T09:00:00.000Z',
        updatedAt: '2026-05-01T09:00:00.000Z',
      ),
      const FeeStructure(
        id: 'fee-str-11-term1',
        className: 'Class 11',
        termName: 'Term 1',
        academicYear: '2026-2027',
        tuitionFee: 32000.0,
        labComputerFee: 8000.0,
        developmentFee: 5000.0,
        otherFee: 4000.0,
        totalFee: 49000.0,
        dueDate: '2026-11-15',
        isActive: false,
        createdAt: '2026-05-01T09:00:00.000Z',
        updatedAt: '2026-05-01T09:00:00.000Z',
      ),
    ];

    setUp(() {
      final client = DynamicDataClient(assetLoader: const TestAssetLoader());
      mockRepo = FeesRepository(dataClient: client);
      mockRepo.preloadData(structures: sampleStructures, invoices: []);
    });

    Widget createTestApp({required Widget child, UserRole role = UserRole.admin}) {
      return ProviderScope(
        overrides: [
          feesRepositoryProvider.overrideWithValue(mockRepo),
          activeUserRoleProvider.overrideWith((ref) => role),
        ],
        child: MaterialApp(
          home: child,
        ),
      );
    }

    testWidgets('FeeStructureListScreen renders on phone screen (390x844) without overflow', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: const FeeStructureListScreen(isDark: false),
          role: UserRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      // Verify title & buttons
      expect(find.text('Fee Structure'), findsWidgets);
      expect(find.text('Add'), findsWidgets);

      // Verify mobile cards loaded
      expect(find.text('Class 10'), findsWidgets);
      expect(find.text('Class 11'), findsWidgets);
      expect(find.text('₹42,500'), findsWidgets);
      expect(find.text('Active'), findsWidgets);
      expect(find.text('Inactive'), findsWidgets);

      // Verify no RenderFlex exception occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('FeeStructureFormPanel renders on phone screen (390x844) and updates live total', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        createTestApp(
          child: Scaffold(
            body: FeeStructureFormPanel(
              existing: sampleStructures.first,
              onClose: () {},
            ),
          ),
          role: UserRole.admin,
        ),
      );
      await tester.pumpAndSettle();

      // Verify fields
      expect(find.text('Edit Fee Structure'), findsOneWidget);
      expect(find.text('Tuition Fee (₹) *'), findsOneWidget);
      expect(find.text('TOTAL TERM FEE'), findsOneWidget);
      expect(find.text('₹42,500'), findsOneWidget);

      // Verify no RenderFlex exception occurred
      expect(tester.takeException(), isNull);
    });

    testWidgets('Access denied for Teacher on FeeStructureListScreen', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          child: const FeeStructureListScreen(isDark: false),
          role: UserRole.teacher,
        ),
      );
      await tester.pumpAndSettle();

      // Access restricted message should be rendered
      expect(find.text('Access restricted'), findsOneWidget);
      expect(find.text('Your role does not have permission to view this screen.'), findsOneWidget);
    });
  });
}

