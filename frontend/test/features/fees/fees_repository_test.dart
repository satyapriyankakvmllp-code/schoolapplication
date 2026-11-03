import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/fees/data/fees_repository.dart';
import 'package:frontend/src/features/fees/domain/fee_structure.dart';
import 'package:frontend/src/features/fees/domain/student_fee_invoice.dart';
import 'package:frontend/src/utils/asset_loader.dart';
import 'package:frontend/src/utils/dynamic_data_client.dart';

class MockInMemoryLoader extends AssetLoader {
  const MockInMemoryLoader();
  @override
  Future<dynamic> loadJson(String path, {int delayMs = 0}) async => {};
  @override
  Future<Map<String, dynamic>> loadJsonObject(String path, {int delayMs = 0}) async => {};
}

void main() {
  group('FeesRepository Invariant Tests', () {
    late FeesRepository repo;

    final initialStructures = [
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
        isActive: false, // inactive
        createdAt: '2026-05-01T09:00:00.000Z',
        updatedAt: '2026-05-01T09:00:00.000Z',
      ),
    ];

    final initialInvoices = [
      const StudentFeeInvoice(
        id: 'inv-2026-0042',
        invoiceNumber: 'INV-2026-0042',
        studentId: 'std-prof-501',
        feeStructureId: 'fee-str-10-term1', // references fee-str-10-term1
        baseAmount: 42500.0,
        concessionAmount: 5000.0,
        lateFineAmount: 0.0,
        totalPayable: 37500.0,
        amountPaid: 37500.0,
        paymentStatus: PaymentStatus.PAID,
        dueDate: '2026-11-15',
        createdAt: '2026-06-01T09:00:00.000Z',
        updatedAt: '2026-06-10T14:30:00.000Z',
      ),
    ];

    setUp(() {
      final client = DynamicDataClient(assetLoader: const MockInMemoryLoader());
      repo = FeesRepository(dataClient: client);
      repo.preloadData(
        structures: initialStructures,
        invoices: initialInvoices,
      );
    });

    test('Invariant 1: Block deleting a structure referenced by any invoice (offer Deactivate instead)', () async {
      // fee-str-10-term1 is referenced by inv-2026-0042
      expect(
        () => repo.deleteFeeStructure('fee-str-10-term1'),
        throwsA(isA<FeesReferenceException>().having(
          (e) => e.message,
          'message',
          contains('referenced by existing student invoices. Please deactivate it instead'),
        )),
      );

      // fee-str-11-term1 is NOT referenced by any invoice, so deletion succeeds
      await repo.deleteFeeStructure('fee-str-11-term1');
      final remaining = await repo.getFeeStructures();
      expect(remaining.any((s) => s.id == 'fee-str-11-term1'), isFalse);
    });

    test('Invariant 2: No two ACTIVE structures with the same class_name + term_name + academic_year', () async {
      // Trying to add a new ACTIVE structure for Class 10, Term 1, 2026-2027 should be blocked
      const duplicateActive = FeeStructure(
        id: 'fee-str-new-duplicate',
        className: 'Class 10',
        termName: 'Term 1',
        academicYear: '2026-2027',
        tuitionFee: 30000.0,
        labComputerFee: 2000.0,
        developmentFee: 1000.0,
        otherFee: 1000.0,
        totalFee: 34000.0,
        dueDate: '2026-12-01',
        isActive: true,
        createdAt: '',
        updatedAt: '',
      );

      expect(
        () => repo.saveFeeStructure(duplicateActive, isNew: true),
        throwsA(isA<FeesValidationException>().having(
          (e) => e.message,
          'message',
          contains('An active fee structure already exists'),
        )),
      );

      // But saving as INACTIVE is allowed!
      final inactiveDuplicate = duplicateActive.copyWith(isActive: false);
      final saved = await repo.saveFeeStructure(inactiveDuplicate, isNew: true);
      expect(saved.isActive, isFalse);

      // Now attempting to activate it must throw
      expect(
        () => repo.toggleActive(saved.id, true),
        throwsA(isA<FeesValidationException>().having(
          (e) => e.message,
          'message',
          contains('An active fee structure already exists'),
        )),
      );
    });

    test('Invariant 3: Editing or deactivating a structure must NEVER change existing invoices', () async {
      // Modify fee-str-10-term1 tuition and total
      final existing = (await repo.getFeeStructureById('fee-str-10-term1'))!;
      final modified = existing.copyWith(
        tuitionFee: 99999.0,
        otherFee: 5000.0,
      );

      await repo.saveFeeStructure(modified);

      // Verify invoice base_amount is untouched (it remains 42500.0 snapshot copy)
      final invoices = await repo.getInvoices();
      final targetInvoice = invoices.firstWhere((inv) => inv.id == 'inv-2026-0042');
      expect(targetInvoice.baseAmount, 42500.0);
      expect(targetInvoice.totalPayable, 37500.0);
    });

    test('Validation: requires class, term, year, due date, tuition > 0, others >= 0', () async {
      final invalidTuition = initialStructures.first.copyWith(id: 'fee-test-1', tuitionFee: 0);
      expect(
        () => repo.saveFeeStructure(invalidTuition),
        throwsA(isA<FeesValidationException>().having(
          (e) => e.message,
          'message',
          contains('Tuition fee must be greater than 0'),
        )),
      );

      final invalidLab = initialStructures.first.copyWith(id: 'fee-test-2', labComputerFee: -100);
      expect(
        () => repo.saveFeeStructure(invalidLab),
        throwsA(isA<FeesValidationException>().having(
          (e) => e.message,
          'message',
          contains('cannot be negative'),
        )),
      );

      final emptyClass = initialStructures.first.copyWith(id: 'fee-test-3', className: '  ');
      expect(
        () => repo.saveFeeStructure(emptyClass),
        throwsA(isA<FeesValidationException>().having(
          (e) => e.message,
          'message',
          contains('Class name is required'),
        )),
      );
    });
  });
}

