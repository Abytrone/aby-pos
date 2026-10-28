import '../core/tax.dart';
import '../models/cart_line.dart';
import '../models/discount.dart';
import 'promotions.dart';

/// One cart line, priced: promotions, its share of the order discount and
/// its tax.
class PricedLine {
  const PricedLine({
    required this.line,
    required this.orderShare,
    required this.tax,
    this.promotion = 0,
    this.promotionNames = const [],
  });

  final CartLine line;

  /// Pesewas taken off by automatic promotions, and which.
  final int promotion;
  final List<String> promotionNames;

  /// Pesewas of the order discount carried by this line.
  final int orderShare;

  /// Tax worked out on the line after both discounts.
  final TaxResult tax;

  /// Pesewas after every discount (tax included when prices include it).
  int get net => line.netTotal - promotion - orderShare;

  /// Pesewas after the line's own discount and promotions.
  int get lineNet => line.netTotal - promotion;
}

/// The cart's numbers, the same in the cart panel, checkout and the saved
/// sale. Amounts are pesewas.
class CartPricing {
  const CartPricing._(this.lines, this.orderDiscountAmount, this.taxMode);

  /// Promotions come off after line discounts. The order discount is a
  /// percentage or amount of what is left, shared across lines in proportion
  /// (largest remainder, so the shares add up exactly). Tax is worked out
  /// per line on what is left.
  factory CartPricing.of(
    List<CartLine> lines, {
    Discount? orderDiscount,
    TaxMode taxMode = TaxMode.off,
    PromotionResult? promotions,
  }) {
    final promo = promotions ?? PromotionResult.none(lines.length);
    final nets = [for (final (i, l) in lines.indexed) l.netTotal - promo.off[i]];
    final base = nets.fold(0, (s, n) => s + n);
    final off = orderDiscount?.amountOn(base) ?? 0;
    final shares = allocate(off, nets);
    return CartPricing._(
      [
        for (final (i, l) in lines.indexed)
          PricedLine(
            line: l,
            orderShare: shares[i],
            promotion: promo.off[i],
            promotionNames: promo.names[i],
            tax: computeTax(nets[i] - shares[i], [for (final t in l.product.taxes) t.spec], taxMode),
          ),
      ],
      off,
      taxMode,
    );
  }

  final List<PricedLine> lines;
  final int orderDiscountAmount;
  final TaxMode taxMode;

  /// Before any discount.
  int get subtotal => lines.fold(0, (s, l) => s + l.line.lineTotal);

  /// Manual line discounts.
  int get lineDiscounts => lines.fold(0, (s, l) => s + l.line.discountAmount);

  int get promotionTotal => lines.fold(0, (s, l) => s + l.promotion);

  int get discountTotal => lineDiscounts + promotionTotal + orderDiscountAmount;

  /// After discounts, before tax added on top.
  int get net => subtotal - discountTotal;

  int get taxTotal => lines.fold(0, (s, l) => s + l.tax.taxTotal);

  /// What the customer pays.
  int get total => taxMode == TaxMode.exclusive ? net + taxTotal : net;

  /// Splits [amount] across [weights] in proportion. The parts add up to
  /// [amount]; leftover pesewas go to the largest remainders, first line
  /// first on ties.
  static List<int> allocate(int amount, List<int> weights) {
    final total = weights.fold(0, (s, w) => s + w);
    if (amount <= 0 || total <= 0) return List.filled(weights.length, 0);
    final parts = [for (final w in weights) amount * w ~/ total];
    var left = amount - parts.fold(0, (s, p) => s + p);
    final order = List.generate(weights.length, (i) => i)
      ..sort((a, b) {
        final ra = amount * weights[a] % total;
        final rb = amount * weights[b] % total;
        return ra != rb ? rb.compareTo(ra) : a.compareTo(b);
      });
    for (final i in order) {
      if (left == 0) break;
      parts[i]++;
      left--;
    }
    return parts;
  }
}
