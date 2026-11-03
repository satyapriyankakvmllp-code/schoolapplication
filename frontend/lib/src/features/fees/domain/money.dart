import 'package:intl/intl.dart';

/// Helper class for financial calculations in Indian Rupees and Paise.
/// Guarantees exact integer math in paise (1 INR = 100 Paise) to eliminate
/// floating-point representation and rounding drift.
class Money {
  final int paise;

  const Money(this.paise);

  /// Parse a rupee decimal value (e.g. 28000.0) to integer paise using round(value * 100).
  factory Money.fromRupees(num? rupees) {
    if (rupees == null) return const Money(0);
    return Money((rupees * 100).round());
  }

  /// Direct constructor from integer paise.
  const Money.fromPaise(this.paise);

  /// Converts integer paise back to rupee double (paise / 100.0) for JSON persistence.
  double toRupees() => paise / 100.0;

  static int rupeesToPaise(num? rupees) {
    if (rupees == null) return 0;
    return (rupees * 100).round();
  }

  static double paiseToRupees(int paise) {
    return paise / 100.0;
  }

  static final NumberFormat _enInFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _enInDecimalFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats the amount into Indian Rupee display string (e.g. "₹28,000" or "₹28,000.50").
  String format({bool includeDecimalsIfZero = false}) {
    final rupees = toRupees();
    if (!includeDecimalsIfZero && paise % 100 == 0) {
      return _enInFormat.format(rupees);
    }
    return _enInDecimalFormat.format(rupees);
  }

  static String formatRupees(num? rupees, {bool includeDecimalsIfZero = false}) {
    return Money.fromRupees(rupees).format(
      includeDecimalsIfZero: includeDecimalsIfZero,
    );
  }

  static String formatPaise(int paise, {bool includeDecimalsIfZero = false}) {
    return Money.fromPaise(paise).format(
      includeDecimalsIfZero: includeDecimalsIfZero,
    );
  }

  Money operator +(Money other) => Money(paise + other.paise);
  Money operator -(Money other) => Money(paise - other.paise);
  Money operator *(int factor) => Money(paise * factor);

  bool get isZero => paise == 0;
  bool get isPositive => paise > 0;
  bool get isNegative => paise < 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money && runtimeType == other.runtimeType && paise == other.paise;

  @override
  int get hashCode => paise.hashCode;

  @override
  String toString() => format();
}

