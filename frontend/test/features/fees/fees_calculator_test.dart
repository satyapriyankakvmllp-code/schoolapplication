import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/src/features/fees/domain/fee_payment_transaction.dart';
import 'package:frontend/src/features/fees/domain/fees_calculator.dart';
import 'package:frontend/src/features/fees/domain/money.dart';
import 'package:frontend/src/features/fees/domain/student_fee_invoice.dart';

void main() {
  group('Money Helper Tests', () {
    test('converts rupee decimal to integer paise and back', () {
      final money = Money.fromRupees(28000.0);
      expect(money.paise, 2800000);
      expect(money.toRupees(), 28000.0);

      final fractional = Money.fromRupees(42500.75);
      expect(fractional.paise, 4250075);
      expect(fractional.toRupees(), 42500.75);
    });

    test('formats rupees in Indian en_IN format', () {
      expect(Money.formatRupees(28000.0), '₹28,000');
      expect(Money.formatRupees(150000.0), '₹1,50,000');
      expect(Money.formatRupees(42500.50), '₹42,500.50');
    });

    test('supports integer arithmetic without float inaccuracies', () {
      final m1 = Money.fromRupees(100.10);
      final m2 = Money.fromRupees(200.20);
      final sum = m1 + m2;
      expect(sum.paise, 30030);
      expect(sum.toRupees(), 300.30);
    });
  });

  group('FeesCalculator Unit Tests', () {
    test('1. structure total_fee = tuition + lab_computer + development + other', () {
      // Test using seeded Class 10 values: 28000 + 6000 + 5000 + 3500 = 42500
      final total = FeesCalculator.calculateStructureTotalRupees(
        tuition: 28000.0,
        labComputer: 6000.0,
        development: 5000.0,
        other: 3500.0,
      );
      expect(total, 42500.0);

      final totalPaise = FeesCalculator.calculateStructureTotalPaise(
        tuitionPaise: 2800000,
        labComputerPaise: 600000,
        developmentPaise: 500000,
        otherPaise: 350000,
      );
      expect(totalPaise, 4250000);
    });

    test('2. invoice total_payable = base_amount - concession_amount + late_fine_amount', () {
      // Seeded inv-2026-0042: 42500 - 5000 + 0 = 37500
      final payable1 = FeesCalculator.calculateInvoiceTotalPayableRupees(
        baseAmount: 42500.0,
        concessionAmount: 5000.0,
        lateFineAmount: 0.0,
      );
      expect(payable1, 37500.0);

      // Seeded inv-2026-0044: 42500 - 0 + 500 = 43000
      final payable2 = FeesCalculator.calculateInvoiceTotalPayableRupees(
        baseAmount: 42500.0,
        concessionAmount: 0.0,
        lateFineAmount: 500.0,
      );
      expect(payable2, 43000.0);
    });

    test('3. amount_paid = sum of SUCCESS transactions only (FAILED, INITIATED, REFUNDED do not count)', () {
      final transactions = [
        const FeePaymentTransaction(
          id: 'txn-1',
          invoiceId: 'inv-1',
          transactionReference: 'REF1',
          gatewayName: 'Razorpay',
          amount: 20000.0,
          status: TransactionStatus.SUCCESS,
          paymentMethod: 'UPI',
          createdAt: '2026-06-10T10:00:00Z',
          updatedAt: '2026-06-10T10:00:00Z',
        ),
        const FeePaymentTransaction(
          id: 'txn-2',
          invoiceId: 'inv-1',
          transactionReference: 'REF2',
          gatewayName: 'Razorpay',
          amount: 15000.0,
          status: TransactionStatus.FAILED, // must not count
          paymentMethod: 'NetBanking',
          createdAt: '2026-06-11T10:00:00Z',
          updatedAt: '2026-06-11T10:00:00Z',
        ),
        const FeePaymentTransaction(
          id: 'txn-3',
          invoiceId: 'inv-1',
          transactionReference: 'REF3',
          gatewayName: 'Razorpay',
          amount: 5000.0,
          status: TransactionStatus.INITIATED, // must not count
          paymentMethod: 'Card',
          createdAt: '2026-06-12T10:00:00Z',
          updatedAt: '2026-06-12T10:00:00Z',
        ),
        const FeePaymentTransaction(
          id: 'txn-4',
          invoiceId: 'inv-1',
          transactionReference: 'REF4',
          gatewayName: 'Cash',
          amount: 7500.0,
          status: TransactionStatus.REFUNDED, // must not count
          paymentMethod: 'Cash',
          createdAt: '2026-06-13T10:00:00Z',
          updatedAt: '2026-06-13T10:00:00Z',
        ),
        const FeePaymentTransaction(
          id: 'txn-5',
          invoiceId: 'inv-1',
          transactionReference: 'REF5',
          gatewayName: 'Cash Desk',
          amount: 17500.0,
          status: TransactionStatus.SUCCESS, // must count
          paymentMethod: 'Cash',
          createdAt: '2026-06-14T10:00:00Z',
          updatedAt: '2026-06-14T10:00:00Z',
        ),
      ];

      final totalPaid = FeesCalculator.calculateAmountPaidRupees(transactions);
      expect(totalPaid, 37500.0); // 20000 + 17500 = 37500
    });

    test('4. pending = total_payable - amount_paid', () {
      final pending = FeesCalculator.calculatePendingRupees(
        totalPayable: 42500.0,
        amountPaid: 20000.0,
      );
      expect(pending, 22500.0);

      final zeroPending = FeesCalculator.calculatePendingRupees(
        totalPayable: 37500.0,
        amountPaid: 37500.0,
      );
      expect(zeroPending, 0.0);
    });

    test('5. derived status and days_overdue', () {
      final dueDate = DateTime(2026, 11, 15);
      final beforeDueDate = DateTime(2026, 11, 1);
      final afterDueDate = DateTime(2026, 11, 20);

      // PAID if pending == 0
      final statusPaid = FeesCalculator.derivePaymentStatus(
        totalPayablePaise: 3750000,
        amountPaidPaise: 3750000,
        dueDate: dueDate,
        asOfDate: beforeDueDate,
      );
      expect(statusPaid, PaymentStatus.PAID);

      // PARTIALLY_PAID if paid > 0
      final statusPartiallyPaid = FeesCalculator.derivePaymentStatus(
        totalPayablePaise: 4250000,
        amountPaidPaise: 2000000,
        dueDate: dueDate,
        asOfDate: beforeDueDate,
      );
      expect(statusPartiallyPaid, PaymentStatus.PARTIALLY_PAID);

      // OVERDUE if due_date passed and pending > 0 (and paid == 0)
      final statusOverdue = FeesCalculator.derivePaymentStatus(
        totalPayablePaise: 4300000,
        amountPaidPaise: 0,
        dueDate: dueDate,
        asOfDate: afterDueDate,
      );
      expect(statusOverdue, PaymentStatus.OVERDUE);

      // else UNPAID (due date in future, paid == 0)
      final statusUnpaid = FeesCalculator.derivePaymentStatus(
        totalPayablePaise: 4250000,
        amountPaidPaise: 0,
        dueDate: dueDate,
        asOfDate: beforeDueDate,
      );
      expect(statusUnpaid, PaymentStatus.UNPAID);

      // days_overdue derived from due_date
      expect(FeesCalculator.calculateDaysOverdue(dueDate, asOfDate: afterDueDate), 5);
      expect(FeesCalculator.calculateDaysOverdue(dueDate, asOfDate: beforeDueDate), 0);
    });
  });
}

