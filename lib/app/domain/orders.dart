import '../models/cart_line.dart';
import 'promotions.dart';

/// Queue numbers and prep (SEL-11): which sales get a number, and how it
/// reads.
class OrderConfig {
  const OrderConfig({this.prep = const PromoTarget(), this.prefix = 'A', this.dayStartMinutes = 5 * 60});

  /// Items that need prep; a sale with none gets no number.
  final PromoTarget prep;
  final String prefix;

  /// Numbers start again each business day.
  final int dayStartMinutes;

  bool needsPrep(List<CartLine> lines) => lines.any((l) => prep.matches(l.product));

  List<CartLine> prepLines(List<CartLine> lines) => [for (final l in lines) if (prep.matches(l.product)) l];

  String label(int number) => '$prefix$number';
}
