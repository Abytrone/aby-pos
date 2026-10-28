import '../domain/loyalty.dart';
import '../services/money.dart';
import 'l10n.dart';

/// Where a customer stands, for the cart: "Ama has a free item",
/// "4 of 9 stamps", "230 points (GH₵ 10.00 off)", "Gold: 5% off".
String? loyaltyText(AppLocalizations l, LoyaltyConfig c, LoyaltyStatus? s, String name) {
  if (s == null || !c.on) return null;
  return switch ((c.style, Loyalty.available(c, s))) {
    (_, FreeItemReward()) => l.loyaltyFreeReady(name),
    (_, PointsReward(:final amount)) => l.loyaltyPointsReward(s.balance, formatMoney(amount)),
    (_, GoldReward(:final percent)) => l.loyaltyGold(percent),
    (LoyaltyStyle.stamps, _) => l.loyaltyStampsHave(s.balance, c.stampsForReward),
    (LoyaltyStyle.points, _) => l.loyaltyPointsHave(s.balance),
    _ => null,
  };
}
