import 'dart:convert';

import '../models/cart_line.dart';
import '../models/catalog.dart';
import '../models/enums.dart';
import 'pricing.dart';

/// Which products a promotion is about: some products, some categories, or
/// (both empty) everything.
class PromoTarget {
  const PromoTarget({this.products = const {}, this.categories = const {}});

  factory PromoTarget.fromJson(Map<String, dynamic>? json) => json == null
      ? const PromoTarget()
      : PromoTarget(
          products: {...(json['products'] as List? ?? const []).cast<String>()},
          categories: {...(json['categories'] as List? ?? const []).cast<String>()},
        );

  final Set<String> products;
  final Set<String> categories;

  bool get everything => products.isEmpty && categories.isEmpty;

  bool matches(Product p) => everything || products.contains(p.id) || categories.contains(p.categoryId);

  Map<String, dynamic> toJson() => {'products': [...products], 'categories': [...categories]};
}

/// For a spend promotion: what reaching the threshold gives.
enum SpendReward { percent, amount, free }

/// What a promotion does. Which fields matter depends on its kind:
///
/// - percentOff: [percent] off [target] (happy hour).
/// - quantityBreak: [quantity] or more of [target] cost [amount] each.
/// - buyGet: buy [quantity] of [target], get [rewardQuantity] of [reward]
///   [percent] off (100 = free); the cheapest qualifying items are the reward.
/// - bundle: one of each of [parts] together for [amount].
/// - spend: spending [threshold] gives [percent] off, [amount] off, or the
///   cheapest [reward] item free.
class PromoRule {
  const PromoRule({
    this.target = const PromoTarget(),
    this.reward = const PromoTarget(),
    this.parts = const [],
    this.percent = 0,
    this.amount = 0,
    this.quantity = 0,
    this.rewardQuantity = 1,
    this.threshold = 0,
    this.spendReward = SpendReward.percent,
  });

  factory PromoRule.fromJson(Map<String, dynamic> j) => PromoRule(
        target: PromoTarget.fromJson(j['target'] as Map<String, dynamic>?),
        reward: PromoTarget.fromJson(j['reward'] as Map<String, dynamic>?),
        parts: [for (final p in (j['parts'] as List? ?? const [])) PromoTarget.fromJson(p as Map<String, dynamic>)],
        percent: j['percent'] as int? ?? 0,
        amount: j['amount'] as int? ?? 0,
        quantity: j['quantity'] as int? ?? 0,
        rewardQuantity: j['rewardQuantity'] as int? ?? 1,
        threshold: j['threshold'] as int? ?? 0,
        spendReward: SpendReward.values.asNameMap()[j['spendReward']] ?? SpendReward.percent,
      );

  static PromoRule decode(String json) => PromoRule.fromJson(jsonDecode(json) as Map<String, dynamic>);

  final PromoTarget target;
  final PromoTarget reward;
  final List<PromoTarget> parts;

  /// Whole percent.
  final int percent;

  /// Pesewas: a bundle price, a quantity-break price each, or money off.
  final int amount;
  final int quantity;
  final int rewardQuantity;

  /// Pesewas.
  final int threshold;
  final SpendReward spendReward;

  Map<String, dynamic> toJson() => {
        'target': target.toJson(),
        'reward': reward.toJson(),
        'parts': [for (final p in parts) p.toJson()],
        'percent': percent,
        'amount': amount,
        'quantity': quantity,
        'rewardQuantity': rewardQuantity,
        'threshold': threshold,
        'spendReward': spendReward.name,
      };

  String encode() => jsonEncode(toJson());
}

class Promotion {
  const Promotion({
    required this.id,
    required this.name,
    required this.kind,
    required this.rule,
    this.startsOn,
    this.endsOn,
    this.days = 127,
    this.fromMinute,
    this.toMinute,
    this.stackable = false,
    this.active = true,
  });

  final String id;
  final String name;
  final PromotionKind kind;
  final PromoRule rule;

  /// First and last day (inclusive); null for open-ended.
  final DateTime? startsOn;
  final DateTime? endsOn;

  /// Bit 0 Monday ... bit 6 Sunday.
  final int days;

  /// Minutes after midnight; null for all day. A window past midnight
  /// (22:00 to 02:00) wraps.
  final int? fromMinute;
  final int? toMinute;
  final bool stackable;
  final bool active;

  bool runsOn(int weekday) => days & (1 << (weekday - 1)) != 0;

  bool runsAt(DateTime at) {
    if (!active || !runsOn(at.weekday)) return false;
    final day = DateTime(at.year, at.month, at.day);
    if (startsOn != null && day.isBefore(DateTime(startsOn!.year, startsOn!.month, startsOn!.day))) return false;
    if (endsOn != null && day.isAfter(DateTime(endsOn!.year, endsOn!.month, endsOn!.day))) return false;
    final from = fromMinute, to = toMinute;
    if (from == null || to == null) return true;
    final m = at.hour * 60 + at.minute;
    return from <= to ? m >= from && m < to : m >= from || m < to;
  }
}

/// What the promotions take off each cart line, and which ones.
class PromotionResult {
  const PromotionResult(this.off, this.names, [this.byPromotion = const {}]);

  /// Nothing applies.
  static PromotionResult none(int lines) =>
      PromotionResult(List.filled(lines, 0), List.generate(lines, (_) => const <String>[]));

  /// Pesewas per cart line.
  final List<int> off;

  /// Promotion names per cart line.
  final List<List<String>> names;

  /// Pesewas each applied promotion took off, by its ID.
  final Map<String, int> byPromotion;

  int get total => off.fold(0, (s, o) => s + o);
}

/// One item in the cart (a weighed line is one item), at what it costs
/// after the line's manual discount.
class _Unit {
  _Unit(this.line, this.price, this.product, this.weighed);

  final int line;
  final int price;
  final Product product;
  final bool weighed;
}

/// Applies automatic promotions to a cart (SEL-06). Each promotion is
/// worked out on its own; of those that do not stack, the one saving the
/// customer most applies (the best deal), and every stacking one applies
/// too. No item ever goes below zero.
abstract final class PromotionEngine {
  static PromotionResult apply(List<CartLine> lines, List<Promotion> promotions, DateTime at) {
    final none = PromotionResult.none(lines.length);
    final running = [for (final p in promotions) if (p.runsAt(at)) p];
    if (running.isEmpty || lines.isEmpty) return none;

    final units = <_Unit>[];
    for (final (i, l) in lines.indexed) {
      if (l.weighed) {
        units.add(_Unit(i, l.netTotal, l.product, true));
      } else {
        for (final price in CartPricing.allocate(l.netTotal, List.filled(l.quantity, 1))) {
          units.add(_Unit(i, price, l.product, false));
        }
      }
    }

    final results = {for (final p in running) p: _evaluate(p, units)};
    int sum(List<int> offs) => offs.fold(0, (s, o) => s + o);
    Promotion? best;
    for (final p in running.where((p) => !p.stackable)) {
      final total = sum(results[p]!);
      if (total > 0 && (best == null || total > sum(results[best]!))) best = p;
    }
    final chosen = [?best, ...running.where((p) => p.stackable && sum(results[p]!) > 0)];
    if (chosen.isEmpty) return none;

    final left = [for (final u in units) u.price];
    final off = List.filled(lines.length, 0);
    final names = List.generate(lines.length, (_) => <String>[]);
    final byPromotion = <String, int>{};
    for (final p in chosen) {
      final offs = results[p]!;
      for (final (i, u) in units.indexed) {
        final take = offs[i] < left[i] ? offs[i] : left[i];
        if (take <= 0) continue;
        left[i] -= take;
        off[u.line] += take;
        byPromotion[p.id] = (byPromotion[p.id] ?? 0) + take;
        if (!names[u.line].contains(p.name)) names[u.line].add(p.name);
      }
    }
    return PromotionResult(off, names, byPromotion);
  }

  /// Pesewas off each unit for one promotion on its own.
  static List<int> _evaluate(Promotion p, List<_Unit> units) {
    final r = p.rule;
    final off = List.filled(units.length, 0);
    int pct(int price, int percent) => (price * percent + 50) ~/ 100;
    List<int> counted(PromoTarget t) => [for (final (i, u) in units.indexed) if (!u.weighed && t.matches(u.product)) i];

    switch (p.kind) {
      case PromotionKind.percentOff:
        for (final (i, u) in units.indexed) {
          if (r.target.matches(u.product)) off[i] = pct(u.price, r.percent);
        }
      case PromotionKind.quantityBreak:
        final hits = counted(r.target);
        if (r.quantity > 0 && hits.length >= r.quantity) {
          for (final i in hits) {
            off[i] = units[i].price > r.amount ? units[i].price - r.amount : 0;
          }
        }
      case PromotionKind.buyGet:
        if (r.quantity <= 0 || r.rewardQuantity <= 0) break;
        // The customer pays for the dearest items; the cheapest are the reward.
        final payers = counted(r.target)..sort((a, b) => units[b].price.compareTo(units[a].price));
        final rewards = counted(r.reward.everything ? r.target : r.reward)
          ..sort((a, b) => units[a].price.compareTo(units[b].price));
        final used = <int>{};
        while (true) {
          final pay = payers.where((i) => !used.contains(i)).take(r.quantity).toList();
          if (pay.length < r.quantity) break;
          final got = rewards.where((i) => !used.contains(i) && !pay.contains(i)).take(r.rewardQuantity).toList();
          if (got.isEmpty) break;
          used.addAll(pay);
          for (final i in got) {
            used.add(i);
            off[i] = pct(units[i].price, r.percent);
          }
        }
      case PromotionKind.bundle:
        if (r.parts.isEmpty) break;
        final used = <int>{};
        while (true) {
          final picked = <int>[];
          for (final part in r.parts) {
            final options = counted(part).where((i) => !used.contains(i) && !picked.contains(i)).toList()
              ..sort((a, b) => units[b].price.compareTo(units[a].price));
            if (options.isEmpty) break;
            picked.add(options.first);
          }
          if (picked.length < r.parts.length) break;
          final prices = [for (final i in picked) units[i].price];
          final saving = prices.fold(0, (s, x) => s + x) - r.amount;
          if (saving <= 0) break;
          for (final (k, share) in CartPricing.allocate(saving, prices).indexed) {
            off[picked[k]] = share;
          }
          used.addAll(picked);
        }
      case PromotionKind.spend:
        final prices = [for (final u in units) u.price];
        final base = prices.fold(0, (s, x) => s + x);
        if (r.threshold <= 0 || base < r.threshold) break;
        switch (r.spendReward) {
          case SpendReward.percent:
            off.setAll(0, CartPricing.allocate(pct(base, r.percent), prices));
          case SpendReward.amount:
            off.setAll(0, CartPricing.allocate(r.amount < base ? r.amount : base, prices));
          case SpendReward.free:
            final hits = counted(r.reward)..sort((a, b) => units[a].price.compareTo(units[b].price));
            if (hits.isNotEmpty) off[hits.first] = units[hits.first].price;
        }
    }
    return off;
  }
}
