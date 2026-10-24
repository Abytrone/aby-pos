import '../models/enums.dart';
import '../models/sale.dart';
import '../services/money.dart';

/// A payment cannot be taken as entered. Nothing has been saved.
class PaymentException implements Exception {
  const PaymentException(this.message);
  final String message;

  @override
  String toString() => 'PaymentException: $message';
}

/// One payment as it will be saved.
class SettledPayment {
  const SettledPayment({required this.input, required this.amount, this.change = 0});

  final PaymentInput input;

  /// Pesewas applied to the sale.
  final int amount;

  /// Pesewas given back (cash only).
  final int change;
}

/// How a set of payments covers a total, worked out the same way in the
/// checkout and when the sale is saved. Amounts are pesewas.
class Settlement {
  const Settlement._(this.payments, this.rounding);

  /// Covers [total] with [inputs], in order. Each payment covers its
  /// [PaymentInput.amount], or the rest. Only the last payment may be more
  /// than what is left, and only in cash (it gives change). When the last
  /// payment is cash and [roundTo] is set (10 or 50 pesewas), the cash due
  /// is rounded to the nearest [roundTo] and the difference recorded.
  factory Settlement.of(int total, List<PaymentInput> inputs, {int roundTo = 0}) {
    if (inputs.isEmpty) throw const PaymentException('Choose how the customer pays.');
    var remaining = total;
    var rounding = 0;
    final settled = <SettledPayment>[];
    for (final (i, p) in inputs.indexed) {
      final last = i == inputs.length - 1;
      _checkDetails(p);
      if (p.method == PaymentMethod.cash && last) {
        var due = remaining;
        if (roundTo > 0) {
          final rounded = roundCash(remaining, roundTo);
          if (rounded > 0) due = rounded;
        }
        final tendered = p.tendered ?? due;
        if (tendered < due) throw PaymentException('Cash given is less than ${formatMoney(due)}.');
        rounding = due - remaining;
        settled.add(SettledPayment(input: p, amount: due, change: tendered - due));
        remaining = 0;
        continue;
      }
      final amount = p.amount ?? (p.method == PaymentMethod.cash ? (p.tendered ?? remaining) : remaining);
      if (amount > remaining) {
        throw PaymentException(
          last && p.method != PaymentMethod.cash
              ? '${p.label} is more than the ${formatMoney(remaining)} left to pay.'
              : 'A payment is more than the ${formatMoney(remaining)} left to pay.',
        );
      }
      if (amount <= 0 && total > 0) throw const PaymentException('Each payment must be more than nothing.');
      if (p.method == PaymentMethod.cash && (p.tendered ?? amount) != amount) {
        throw const PaymentException('Only the last payment can give change.');
      }
      settled.add(SettledPayment(input: p, amount: amount));
      remaining -= amount;
    }
    if (remaining > 0) throw PaymentException('${formatMoney(remaining)} still to pay.');
    return Settlement._(settled, rounding);
  }

  final List<SettledPayment> payments;

  /// Pesewas added (or taken off) by cash rounding.
  final int rounding;

  int get change => payments.fold(0, (s, p) => s + p.change);

  /// Pesewas received for the sale (its total plus rounding).
  int get paid => payments.fold(0, (s, p) => s + p.amount);

  /// [amount] to the nearest [to] pesewas (half up).
  static int roundCash(int amount, int to) => to <= 0 ? amount : ((amount + to ~/ 2) ~/ to) * to;

  /// A reference typed by the cashier, as stored and compared.
  static String cleanReference(String reference) => reference.replaceAll(RegExp(r'\s+'), '').toUpperCase();

  static void _checkDetails(PaymentInput p) {
    if (p.method == PaymentMethod.credit && (p.customer ?? '').trim().isEmpty) {
      throw const PaymentException('Enter the customer name or phone.');
    }
    if (!p.needsReference) return;
    final ref = cleanReference(p.reference ?? '');
    if (ref.isEmpty) throw PaymentException('Enter the transaction reference for ${p.label}.');
    if (p.shortReference && ref.length < 4) {
      throw const PaymentException('Enter at least the last 4 characters of the reference.');
    }
  }
}
