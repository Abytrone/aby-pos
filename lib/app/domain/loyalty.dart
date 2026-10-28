import 'dart:convert';

import '../core/settings.dart';
import '../models/cart_line.dart';
import '../models/enums.dart';
import 'promotions.dart';

/// One loyalty style per shop (CUS-04).
enum LoyaltyStyle { off, stamps, points, tiers }

/// The shop's loyalty rules, from settings.
class LoyaltyConfig {
  const LoyaltyConfig({
    this.style = LoyaltyStyle.off,
    this.stampTarget = const PromoTarget(),
    this.stampsForReward = 9,
    this.pointsPerCedi = 1,
    this.pointsForReward = 100,
    this.rewardValue = 500,
    this.expireDays = 0,
    this.goldSpend = 50000,
    this.goldPercent = 5,
  });

  final LoyaltyStyle style;

  /// Products that earn stamps (and one of which is the free one).
  final PromoTarget stampTarget;

  /// Buy this many, get the next free.
  final int stampsForReward;
  final int pointsPerCedi;
  final int pointsForReward;

  /// Pesewas off per [pointsForReward] points.
  final int rewardValue;

  /// Points go after this many days without a purchase; 0 = never.
  final int expireDays;

  /// Pesewas spent in 90 days to be Gold, and Gold's percent off.
  final int goldSpend;
  final int goldPercent;

  /// From the shop's settings ([get] is SettingsService.get).
  factory LoyaltyConfig.read(T Function<T extends Object>(Setting<T>) get) => LoyaltyConfig(
        style: LoyaltyStyle.values.asNameMap()[get<String>(AppSettings.loyaltyStyle)] ?? LoyaltyStyle.off,
        stampTarget: decodeTarget(get<String>(AppSettings.loyaltyStampTarget)),
        stampsForReward: get<int>(AppSettings.loyaltyStamps),
        pointsPerCedi: get<int>(AppSettings.loyaltyPointsPerCedi),
        pointsForReward: get<int>(AppSettings.loyaltyPointsForReward),
        rewardValue: get<int>(AppSettings.loyaltyRewardValue),
        expireDays: get<int>(AppSettings.loyaltyExpireDays),
        goldSpend: get<int>(AppSettings.loyaltyGoldSpend),
        goldPercent: get<int>(AppSettings.loyaltyGoldPercent),
      );

  bool get on => style != LoyaltyStyle.off;

  static PromoTarget decodeTarget(String json) {
    try {
      return PromoTarget.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } on Object {
      return const PromoTarget();
    }
  }
}

/// Where a customer stands: stamps or points held, and what they spent in
/// the last 90 days (for tiers).
class LoyaltyStatus {
  const LoyaltyStatus({this.balance = 0, this.spend90 = 0});

  final int balance;

  /// Pesewas.
  final int spend90;
}

/// The reward a customer can have now, for the cart.
sealed class LoyaltyReward {
  const LoyaltyReward();
}

/// Stamps: the next eligible item is free.
class FreeItemReward extends LoyaltyReward {
  const FreeItemReward();
}

/// Points: [count] rewards of [value] pesewas each.
class PointsReward extends LoyaltyReward {
  const PointsReward(this.count, this.value);

  final int count;
  final int value;

  int get amount => count * value;
}

class GoldReward extends LoyaltyReward {
  const GoldReward(this.percent);

  final int percent;
}

/// Loyalty rewards work as promotions that stack with the shop's own, so
/// the cart, sale lines, receipts and reports show them the same way.
abstract final class Loyalty {
  static const stampsId = 'loyalty-stamps';
  static const pointsId = 'loyalty-points';
  static const goldId = 'loyalty-gold';

  // Names on the cart line and the receipt.
  static const stampsName = 'Loyalty: free item';
  static const pointsName = 'Loyalty points';
  static const goldName = 'Gold discount';

  /// What the customer has earned, whether or not this cart can use it.
  static LoyaltyReward? available(LoyaltyConfig c, LoyaltyStatus s) => switch (c.style) {
        LoyaltyStyle.stamps when c.stampsForReward > 0 && s.balance >= c.stampsForReward => const FreeItemReward(),
        LoyaltyStyle.points when c.pointsForReward > 0 && s.balance >= c.pointsForReward =>
          PointsReward(s.balance ~/ c.pointsForReward, c.rewardValue),
        LoyaltyStyle.tiers when c.goldSpend > 0 && s.spend90 >= c.goldSpend => GoldReward(c.goldPercent),
        _ => null,
      };

  /// The reward as a promotion for a cart worth [cartNet] pesewas (after
  /// the shop's promotions). Points are used in whole rewards that fit.
  static Promotion? promotion(LoyaltyConfig c, LoyaltyStatus s, {required int cartNet}) {
    switch (available(c, s)) {
      case FreeItemReward():
        return Promotion(
          id: stampsId,
          name: stampsName,
          kind: PromotionKind.spend,
          rule: PromoRule(threshold: 1, spendReward: SpendReward.free, reward: c.stampTarget),
          stackable: true,
        );
      case PointsReward(:final count, :final value):
        final fits = value <= 0 ? 0 : cartNet ~/ value;
        final use = count < fits ? count : fits;
        if (use <= 0) return null;
        return Promotion(
          id: pointsId,
          name: pointsName,
          kind: PromotionKind.spend,
          rule: PromoRule(threshold: 1, spendReward: SpendReward.amount, amount: use * value),
          stackable: true,
        );
      case GoldReward(:final percent):
        if (percent <= 0) return null;
        return Promotion(
          id: goldId,
          name: goldName,
          kind: PromotionKind.percentOff,
          rule: PromoRule(percent: percent),
          stackable: true,
        );
      case null:
        return null;
    }
  }

  /// The shop's promotions, then the customer's reward on what is left.
  static PromotionResult apply(
    List<CartLine> lines,
    List<Promotion> promotions,
    DateTime at,
    LoyaltyConfig c,
    LoyaltyStatus? status,
  ) {
    final shop = PromotionEngine.apply(lines, promotions, at);
    if (status == null || !c.on) return shop;
    var net = 0;
    for (final (i, l) in lines.indexed) {
      net += l.netTotal - shop.off[i];
    }
    final reward = promotion(c, status, cartNet: net);
    return reward == null ? shop : PromotionEngine.apply(lines, [...promotions, reward], at);
  }

  /// Stamps or points used by a sale, from what the reward took off.
  static int redeemed(LoyaltyConfig c, PromotionResult r) => switch (c.style) {
        LoyaltyStyle.stamps => (r.byPromotion[stampsId] ?? 0) > 0 ? c.stampsForReward : 0,
        LoyaltyStyle.points => c.rewardValue <= 0
            ? 0
            : ((r.byPromotion[pointsId] ?? 0) + c.rewardValue - 1) ~/ c.rewardValue * c.pointsForReward,
        _ => 0,
      };

  /// Stamps or points a sale earns: a stamp per eligible item (the free
  /// one earns none), or points per cedi of [total].
  static int earned(LoyaltyConfig c, List<CartLine> lines, PromotionResult r, int total) {
    switch (c.style) {
      case LoyaltyStyle.stamps:
        final items = lines.where((l) => !l.weighed && c.stampTarget.matches(l.product)).fold(0, (s, l) => s + l.quantity);
        final free = (r.byPromotion[stampsId] ?? 0) > 0 ? 1 : 0;
        return items - free;
      case LoyaltyStyle.points:
        return total <= 0 ? 0 : total * c.pointsPerCedi ~/ 100;
      case LoyaltyStyle.tiers || LoyaltyStyle.off:
        return 0;
    }
  }
}
