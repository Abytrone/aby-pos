import '../models/audit.dart';
import 'loyalty.dart';

/// A value as the activity log shows it.
sealed class AuditValue {
  const AuditValue();
}

class MoneyValue extends AuditValue {
  const MoneyValue(this.pesewas, {this.signed = false});
  final int pesewas;

  /// Show "+" on gains (stock found, not a price).
  final bool signed;
}

class PercentValue extends AuditValue {
  const PercentValue(this.percent);
  final num percent;
}

class YesNoValue extends AuditValue {
  const YesNoValue(this.yes);
  final bool yes;
}

class TextValue extends AuditValue {
  const TextValue(this.text);
  final String text;
}

/// An enum stored by name, e.g. "powerCut"; shown in plain words.
class NameValue extends AuditValue {
  const NameValue(this.name);
  final String name;
}

/// Nothing set.
class EmptyValue extends AuditValue {
  const EmptyValue();
}

/// One line of an entry's details. [key] is the stored field name; null for
/// an entry about one value (a price, a setting).
class AuditField {
  const AuditField(this.key, {this.before, this.after});
  final String? key;
  final AuditValue? before;
  final AuditValue? after;

  bool get changed => before != null && after != null;
}

class PriceRow {
  const PriceRow({required this.label, required this.before, required this.after});

  /// Product and variant, or null when the product is gone.
  final String? label;
  final int before;
  final int after;

  int get difference => after - before;

  /// Change as a percentage of the old price; null from zero.
  double? get percent => before == 0 ? null : difference * 100 / before;
}

/// What an entry's details say, ready to draw.
sealed class AuditDetails {
  const AuditDetails();
}

/// Before and after (or just after, for something new), field by field.
class FieldChanges extends AuditDetails {
  const FieldChanges(this.fields);
  final List<AuditField> fields;
}

/// Facts recorded with the action: amounts, counts, flags.
class AuditFacts extends AuditDetails {
  const AuditFacts(this.fields);
  final List<AuditField> fields;
}

/// Many prices at once, biggest change first.
class PriceChanges extends AuditDetails {
  const PriceChanges(this.rows);
  final List<PriceRow> rows;
}

/// A setting: its stored key and raw values, for the Settings wording.
/// [hasBefore] is false for entries saved before the old value was kept.
class SettingChange extends AuditDetails {
  const SettingChange({required this.key, required this.before, required this.after, this.hasBefore = true});
  final String key;
  final Object? before;
  final Object? after;
  final bool hasBefore;
}

/// A role's permissions: what it gained and lost, and the discount limit.
class PermissionChanges extends AuditDetails {
  const PermissionChanges({required this.added, required this.removed, this.maxDiscountBefore, this.maxDiscountAfter});
  final List<String> added;
  final List<String> removed;
  final int? maxDiscountBefore;
  final int? maxDiscountAfter;
}

/// Reads [entry]'s stored details into something to draw; null when there
/// is nothing worth opening. [names] turns stored ids (variants, roles)
/// into names, for entries saved before names were kept.
AuditDetails? describeAuditDetails(AuditEntry entry, {Map<String, String> names = const {}}) {
  final d = entry.details;
  if (d == null || d.isEmpty) return null;
  final result = switch (entry.action) {
    AuditAction.pricesBulkChanged => _bulkPrices(d, names),
    AuditAction.roleCreated || AuditAction.roleUpdated => _permissions(d),
    AuditAction.priceChanged || AuditAction.priceScheduled || AuditAction.momoChargesSet => _scalar(d, (v) => _money(v)),
    AuditAction.settingChanged when entry.entityId != null => SettingChange(
        key: entry.entityId!,
        before: d['before'],
        after: d['after'],
        hasBefore: d.containsKey('before'),
      ),
    AuditAction.staffRoleChanged => _scalar(d, (v) => v is String ? TextValue(names[v] ?? v) : _plain(v)),
    _ when d.containsKey('before') || d.containsKey('after') => _beforeAfter(entry.action, d),
    _ => _facts(entry.action, d),
  };
  return switch (result) {
    FieldChanges(:final fields) || AuditFacts(:final fields) when fields.isEmpty => null,
    PriceChanges(:final rows) when rows.isEmpty => null,
    PermissionChanges(:final added, :final removed, :final maxDiscountBefore, :final maxDiscountAfter)
        when added.isEmpty && removed.isEmpty && maxDiscountBefore == maxDiscountAfter =>
      null,
    _ => result,
  };
}

/// Variant ids an entry names but does not label, so the caller can look
/// them up once for the whole list.
Set<String> auditIdsToName(AuditEntry entry) {
  final d = entry.details;
  if (d == null) return const {};
  return switch (entry.action) {
    AuditAction.pricesBulkChanged when d['items'] is! List => {
        for (final MapEntry(:key, :value) in d.entries)
          if (value is Map) key,
      },
    AuditAction.staffRoleChanged => {
        for (final v in [d['before'], d['after']])
          if (v is String) v,
      },
    AuditAction.settingChanged => {
        for (final v in [d['before'], d['after']]) ...settingIds(entry.entityId ?? '', v),
      },
    _ => const {},
  };
}

/// Product and category ids a setting's value names (items that earn
/// stamps, items that need prep).
Set<String> settingIds(String key, Object? value) => switch ((key, value)) {
      ('loyalty.stampTarget' || 'orders.prepTarget', final String json) => {
          ...LoyaltyConfig.decodeTarget(json).products,
          ...LoyaltyConfig.decodeTarget(json).categories,
        },
      _ => const {},
    };

PriceChanges _bulkPrices(Map<String, dynamic> d, Map<String, String> names) {
  PriceRow? row(Object? change, String? id, String? name) => switch (change) {
        {'before': final int b, 'after': final int a} => PriceRow(label: name ?? names[id], before: b, after: a),
        _ => null,
      };
  final rows = [
    // Saved since names were kept: {'items': [{id, name, before, after}]}.
    if (d['items'] case final List<Object?> items)
      for (final i in items.whereType<Map<Object?, Object?>>()) row(i, i['id'] as String?, i['name'] as String?)
    // Older entries: {variantId: {before, after}}.
    else
      for (final MapEntry(:key, :value) in d.entries) row(value, key, null),
  ].nonNulls.toList()
    ..sort((x, y) => y.difference.abs().compareTo(x.difference.abs()));
  return PriceChanges(rows);
}

PermissionChanges _permissions(Map<String, dynamic> d) {
  Set<String> perms(Object? side) =>
      side is Map && side['permissions'] is List ? {...(side['permissions'] as List).whereType<String>()} : {};
  int? max(Object? side) => side is Map ? side['maxDiscountPercent'] as int? : null;
  final before = perms(d['before']), after = perms(d['after']);
  return PermissionChanges(
    added: (after.difference(before).toList()..sort()),
    removed: (before.difference(after).toList()..sort()),
    maxDiscountBefore: d.containsKey('before') ? max(d['before']) : null,
    maxDiscountAfter: max(d['after']),
  );
}

FieldChanges _scalar(Map<String, dynamic> d, AuditValue Function(Object?) read) => FieldChanges([
      AuditField(
        null,
        before: d.containsKey('before') ? read(d['before']) : null,
        after: d.containsKey('after') ? read(d['after']) : null,
      ),
    ]);

FieldChanges _beforeAfter(AuditAction action, Map<String, dynamic> d) {
  final before = d['before'], after = d['after'];
  if (before is! Map && after is! Map) {
    return _scalar(d, (v) => _plain(v));
  }
  final b = before is Map ? before : null;
  final a = after is Map ? after : const {};
  final keys = {...?b?.keys.cast<String>(), ...a.keys.cast<String>()};
  return FieldChanges([
    for (final k in keys)
      if (b == null || b[k] != a[k])
        AuditField(
          k,
          before: b == null ? null : _field(action, k, b[k], b),
          after: a.containsKey(k) ? _field(action, k, a[k], a) : const EmptyValue(),
        ),
  ]);
}

/// Quantities are stored in base units without the unit; the summary line
/// already says them properly, so they are left out here.
const _quantityKeys = {
  AuditAction.stockAdjusted: {'change'},
  AuditAction.stockWasted: {'quantity'},
  AuditAction.stockProduced: {'amount'},
};

AuditFacts _facts(AuditAction action, Map<String, dynamic> d) => AuditFacts([
      for (final MapEntry(:key, :value) in d.entries)
        if (!(_quantityKeys[action]?.contains(key) ?? false))
          if (value is! Map && value is! List) AuditField(key, after: _field(action, key, value, d)),
    ]);

const _moneyKeys = {
  'value', 'amount', 'cost', 'total', 'subtotal', 'discountTotal', 'owedBefore',
};

AuditValue _field(AuditAction action, String key, Object? value, Map<dynamic, dynamic> all) {
  if (value == null) return const EmptyValue();
  // Signed: stock counts and adjustments can go either way.
  final signed = action == AuditAction.stockCountPosted || action == AuditAction.stockAdjusted;
  return switch ((key, value)) {
    ('rateBp', final int bp) => PercentValue(bp / 100),
    ('maxDiscountPercent', final int p) => PercentValue(p),
    // A saved discount's value is a percentage or an amount, by its kind.
    ('value', final int v) when action == AuditAction.discountSaved =>
      all['kind'] == 'percent' ? PercentValue(v) : MoneyValue(v),
    ('counted' || 'changed', final int n) when action == AuditAction.stockCountPosted => TextValue('$n'),
    ('kind' || 'scope' || 'reason', final String s) => NameValue(s),
    (final k, final int v) when _moneyKeys.contains(k) => MoneyValue(v, signed: signed),
    _ => _plain(value),
  };
}

AuditValue _money(Object? v) => v is int ? MoneyValue(v) : _plain(v);

AuditValue _plain(Object? v) => switch (v) {
      null => const EmptyValue(),
      bool b => YesNoValue(b),
      String s when s.isEmpty => const EmptyValue(),
      String s => TextValue(s),
      List<Object?> l => TextValue(l.join(', ')),
      _ => TextValue('$v'),
    };
