import 'fee_payment_transaction.dart';
import 'money.dart';
import 'student_fee_invoice.dart';

/// Pure calculation functions for the Fees module.
/// All monetary calculations are performed in exact integer paise to prevent precision drift.
class FeesCalculator {
  const FeesCalculator._();

  /// structure total_fee = tuition + lab_computer + development + other
  static int calculateStructureTotalPaise({
    required int tuitionPaise,
    required int labComputerPaise,
    required int developmentPaise,
    required int otherPaise,
  }) {
    return tuitionPaise + labComputerPaise + developmentPaise + otherPaise;
  }

  /// Calculates structure total fee in rupees (paise / 100.0).
  static double calculateStructureTotalRupees({
    required num tuition,
    required num labComputer,
    required num development,
    required num other,
  }) {
    final totalPaise = calculateStructureTotalPaise(
      tuitionPaise: Money.rupeesToPaise(tuition),
      labComputerPaise: Money.rupeesToPaise(labComputer),
      developmentPaise: Money.rupeesToPaise(development),
      otherPaise: Money.rupeesToPaise(other),
    );
    return Money.paiseToRupees(totalPaise);
  }

  /// invoice total_payable = base_amount - concession_amount + late_fine_amount
  static int calculateInvoiceTotalPayablePaise({
    required int baseAmountPaise,
    required int concessionAmountPaise,
    required int lateFineAmountPaise,
  }) {
    final payable = baseAmountPaise - concessionAmountPaise + lateFineAmountPaise;
    return payable < 0 ? 0 : payable;
  }

  /// Calculates invoice total payable in rupees (paise / 100.0).
  static double calculateInvoiceTotalPayableRupees({
    required num baseAmount,
    required num concessionAmount,
    required num lateFineAmount,
  }) {
    final payablePaise = calculateInvoiceTotalPayablePaise(
      baseAmountPaise: Money.rupeesToPaise(baseAmount),
      concessionAmountPaise: Money.rupeesToPaise(concessionAmount),
      lateFineAmountPaise: Money.rupeesToPaise(lateFineAmount),
    );
    return Money.paiseToRupees(payablePaise);
  }

  /// amount_paid = sum of SUCCESS transactions only (FAILED, INITIATED, REFUNDED do not count)
  static int calculateAmountPaidPaise(List<FeePaymentTransaction> transactions) {
    int totalPaid = 0;
    for (final txn in transactions) {
      if (txn.status == TransactionStatus.SUCCESS) {
        totalPaid += Money.rupeesToPaise(txn.amount);
      }
    }
    return totalPaid;
  }

  /// Calculates sum of SUCCESS transactions in rupees.
  static double calculateAmountPaidRupees(List<FeePaymentTransaction> transactions) {
    return Money.paiseToRupees(calculateAmountPaidPaise(transactions));
  }

  /// pending = total_payable - amount_paid
  static int calculatePendingPaise({
    required int totalPayablePaise,
    required int amountPaidPaise,
  }) {
    final pending = totalPayablePaise - amountPaidPaise;
    return pending < 0 ? 0 : pending;
  }

  /// Calculates pending amount in rupees.
  static double calculatePendingRupees({
    required num totalPayable,
    required num amountPaid,
  }) {
    final pendingPaise = calculatePendingPaise(
      totalPayablePaise: Money.rupeesToPaise(totalPayable),
      amountPaidPaise: Money.rupeesToPaise(amountPaid),
    );
    return Money.paiseToRupees(pendingPaise);
  }

  /// Derived status:
  /// - PAID if pending == 0
  /// - PARTIALLY_PAID if paid > 0
  /// - OVERDUE if due_date passed and pending > 0
  /// - else UNPAID
  static PaymentStatus derivePaymentStatus({
    required int totalPayablePaise,
    required int amountPaidPaise,
    required DateTime dueDate,
    DateTime? asOfDate,
  }) {
    final pending = calculatePendingPaise(
      totalPayablePaise: totalPayablePaise,
      amountPaidPaise: amountPaidPaise,
    );
    if (pending == 0) {
      return PaymentStatus.PAID;
    }
    if (amountPaidPaise > 0) {
      return PaymentStatus.PARTIALLY_PAID;
    }
    final isPassed = isDueDatePassed(dueDate, asOfDate: asOfDate);
    if (isPassed && pending > 0) {
      return PaymentStatus.OVERDUE;
    }
    return PaymentStatus.UNPAID;
  }

  /// Helper parsing String due date ("YYYY-MM-DD" or ISO) to DateTime
  static DateTime parseDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return DateTime(2099, 1, 1);
    }
  }

  /// Checks if due date has passed comparing date boundaries (ignoring intraday time).
  static bool isDueDatePassed(DateTime dueDate, {DateTime? asOfDate}) {
    final ref = asOfDate ?? DateTime.now();
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final asOfDay = DateTime(ref.year, ref.month, ref.day);
    return asOfDay.isAfter(dueDay);
  }

  /// days_overdue derived from due_date
  static int calculateDaysOverdue(DateTime dueDate, {DateTime? asOfDate}) {
    final ref = asOfDate ?? DateTime.now();
    final dueDay = DateTime(dueDate.year, dueDate.month, dueDate.day);
    final asOfDay = DateTime(ref.year, ref.month, ref.day);
    if (asOfDay.isAfter(dueDay)) {
      return asOfDay.difference(dueDay).inDays;
    }
    return 0;
  }
}

