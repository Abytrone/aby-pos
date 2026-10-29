import 'package:flutter/material.dart';

import '../../../core/permissions.dart';
import '../../../domain/audit_details.dart';
import '../../../models/audit.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/setting_labels.dart';

/// What an entry recorded, drawn for its kind: a price list, a role's
/// permissions, fields that changed, or the amounts behind the action.
class ActivityDetails extends StatelessWidget {
  const ActivityDetails({super.key, required this.entry, required this.details, this.names = const {}});

  final AuditEntry entry;
  final AuditDetails details;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      switch (details) {
        PriceChanges(:final rows) => _PriceList(rows: rows),
        final PermissionChanges p => _Permissions(change: p),
        FieldChanges(:final fields) => _Fields(action: entry.action, fields: fields),
        AuditFacts(:final fields) => _Facts(action: entry.action, fields: fields),
        final SettingChange s => _Setting(change: s, names: names),
      },
      const SizedBox(height: AbySpace.s2),
      Text(context.l10n.activityEntryNumber(entry.seq), style: AbyText.caption.copyWith(color: c.inkMuted, fontSize: 11)),
    ]);
  }
}

/// Bulk price changes: one line per product, biggest change first, with
/// the first few shown and the rest a tap away.
class _PriceList extends StatefulWidget {
  const _PriceList({required this.rows});

  final List<PriceRow> rows;

  @override
  State<_PriceList> createState() => _PriceListState();
}

class _PriceListState extends State<_PriceList> {
  static const _preview = 8;
  bool _all = false;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final rows = widget.rows;
    final up = rows.where((r) => r.difference > 0).length;
    final down = rows.where((r) => r.difference < 0).length;
    final shown = _all ? rows : rows.take(_preview).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s1, children: [
        if (up > 0) _Pill(icon: Icons.arrow_upward, text: l.activityPricesUp(up), color: c.success, background: c.successSoft),
        if (down > 0) _Pill(icon: Icons.arrow_downward, text: l.activityPricesDown(down), color: c.danger, background: c.dangerSoft),
      ]),
      const SizedBox(height: AbySpace.s2),
      DecoratedBox(
        decoration: BoxDecoration(
          color: c.surfaceSunken,
          borderRadius: BorderRadius.circular(AbyRadius.sm),
        ),
        child: Column(children: [
          for (final (i, r) in shown.indexed) ...[
            if (i > 0) Divider(height: 1, color: c.line),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3, vertical: AbySpace.s2),
              child: _PriceLine(row: r),
            ),
          ],
        ]),
      ),
      if (rows.length > _preview)
        TextButton(
          onPressed: () => setState(() => _all = !_all),
          child: Text(_all ? l.activityShowFewer : l.activityShowAll(rows.length)),
        ),
    ]);
  }
}

class _PriceLine extends StatelessWidget {
  const _PriceLine({required this.row});

  final PriceRow row;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final name = Text(
      row.label ?? l.activityProductGone,
      style: AbyText.body.copyWith(color: row.label == null ? c.inkMuted : c.ink, fontStyle: row.label == null ? FontStyle.italic : null),
      overflow: TextOverflow.ellipsis,
    );
    final prices = Wrap(
      spacing: AbySpace.s2,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _BeforeAfter(before: formatMoney(row.before), after: formatMoney(row.after)),
        _ChangePill(difference: row.difference, percent: row.percent),
      ],
    );
    return LayoutBuilder(
      builder: (context, box) => box.maxWidth < 420
          ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [name, const SizedBox(height: 2), prices])
          : Row(children: [Expanded(child: name), const SizedBox(width: AbySpace.s3), prices]),
    );
  }
}

/// "+GH₵ 1.00 · 8%" in green going up, red going down.
class _ChangePill extends StatelessWidget {
  const _ChangePill({required this.difference, this.percent});

  final int difference;
  final double? percent;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final up = difference > 0;
    final pct = percent == null ? null : '${percent!.abs().toStringAsFixed(percent!.abs() < 10 ? 1 : 0)}%';
    return _Pill(
      icon: up ? Icons.arrow_upward : Icons.arrow_downward,
      text: [formatMoney(difference.abs()), ?pct].join(' · '),
      color: up ? c.success : c.danger,
      background: up ? c.successSoft : c.dangerSoft,
    );
  }
}

/// Old value struck through, then the new one.
class _BeforeAfter extends StatelessWidget {
  const _BeforeAfter({this.before, required this.after});

  final String? before;
  final String after;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Text.rich(
      TextSpan(children: [
        if (before != null) ...[
          TextSpan(
            text: before,
            style: AbyText.receipt.copyWith(color: c.inkMuted, decoration: TextDecoration.lineThrough),
          ),
          TextSpan(text: '  →  ', style: AbyText.receipt.copyWith(color: c.inkMuted)),
        ],
        TextSpan(text: after, style: AbyText.receiptStrong.copyWith(color: c.ink)),
      ]),
    );
  }
}

/// A role: permissions gained and lost, in the words the Roles screen uses.
class _Permissions extends StatelessWidget {
  const _Permissions({required this.change});

  final PermissionChanges change;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    String label(String name) {
      final p = Permission.values.where((p) => p.name == name).firstOrNull;
      return p == null ? _humanise(name) : permissionLabel(l, p);
    }

    Widget group(String title, List<String> names, IconData icon, Color color, Color background) => Padding(
          padding: const EdgeInsets.only(bottom: AbySpace.s3),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s1),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s1, children: [
              for (final n in names) _Pill(icon: icon, text: label(n), color: color, background: background),
            ]),
          ]),
        );

    final maxBefore = change.maxDiscountBefore, maxAfter = change.maxDiscountAfter;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (change.added.isNotEmpty) group(l.activityCanNow, change.added, Icons.add, c.success, c.successSoft),
      if (change.removed.isNotEmpty) group(l.activityCanNoLonger, change.removed, Icons.remove, c.danger, c.dangerSoft),
      if (maxAfter != null && maxBefore != maxAfter)
        _LabelledLine(
          label: l.activityFieldMaxDiscount,
          child: _BeforeAfter(before: maxBefore == null ? null : '$maxBefore%', after: '$maxAfter%'),
        ),
    ]);
  }
}

/// A setting, in the words and units Settings uses.
class _Setting extends StatelessWidget {
  const _Setting({required this.change, required this.names});

  final SettingChange change;
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    String text(Object? v) => settingValueText(l, change.key, v, names: names);
    return _LabelledLine(
      label: settingLabel(l, change.key),
      child: _BeforeAfter(before: change.hasBefore ? text(change.before) : null, after: text(change.after)),
    );
  }
}

/// Fields that changed, old struck through beside new.
class _Fields extends StatelessWidget {
  const _Fields({required this.action, required this.fields});

  final AuditAction action;
  final List<AuditField> fields;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      for (final f in fields)
        Builder(builder: (context) {
          final after = f.after == null ? null : _text(l, f.after!);
          final before = f.before == null ? null : _text(l, f.before!);
          final line = Wrap(spacing: AbySpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
            _BeforeAfter(before: before, after: after ?? l.activityNotSet),
            if ((f.before, f.after) case (MoneyValue(pesewas: final b), MoneyValue(pesewas: final a)) when a != b)
              _ChangePill(difference: a - b, percent: b == 0 ? null : (a - b) * 100 / b),
          ]);
          return _LabelledLine(
            label: f.key == null ? (_isPrice(action) ? l.activityPrice : l.activityValue) : _fieldLabel(l, action, f.key!),
            child: line,
          );
        }),
    ]);
  }

  static bool _isPrice(AuditAction a) => a == AuditAction.priceChanged || a == AuditAction.priceScheduled;
}

/// The amounts and flags behind an action, as small tiles.
class _Facts extends StatelessWidget {
  const _Facts({required this.action, required this.fields});

  final AuditAction action;
  final List<AuditField> fields;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
      for (final f in fields)
        Container(
          constraints: const BoxConstraints(minWidth: 120),
          padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3, vertical: AbySpace.s2),
          decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.sm)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(_fieldLabel(l, action, f.key!), style: AbyText.caption.copyWith(color: c.inkMuted)),
            Text(_text(l, f.after!), style: AbyText.receiptStrong.copyWith(color: _tone(c, f.after!))),
          ]),
        ),
    ]);
  }

  static Color _tone(AbyColors c, AuditValue v) => switch (v) {
        MoneyValue(signed: true, :final pesewas) when pesewas > 0 => c.success,
        MoneyValue(signed: true, :final pesewas) when pesewas < 0 => c.danger,
        _ => c.ink,
      };
}

class _LabelledLine extends StatelessWidget {
  const _LabelledLine({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AbySpace.s2),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 128,
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(label, style: AbyText.caption.copyWith(color: c.inkMuted)),
          ),
        ),
        Expanded(child: child),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.background, this.icon});

  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s2, vertical: 2),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 12, color: color), const SizedBox(width: 2)],
          Text(text, style: AbyText.caption.copyWith(color: color, fontWeight: FontWeight.w700)),
        ]),
      );
}

String _text(AppLocalizations l, AuditValue v) => switch (v) {
      MoneyValue(:final pesewas, signed: true) when pesewas > 0 => '+${formatMoney(pesewas)}',
      MoneyValue(:final pesewas) => formatMoney(pesewas),
      PercentValue(:final percent) => '${percent % 1 == 0 ? percent.toInt() : percent}%',
      YesNoValue(:final yes) => yes ? l.activityYes : l.activityNo,
      TextValue(:final text) => text,
      NameValue(:final name) => _humanise(name),
      EmptyValue() => l.activityNotSet,
    };

String _fieldLabel(AppLocalizations l, AuditAction action, String key) => switch (key) {
      'name' => l.activityFieldName,
      'phone' => l.activityFieldPhone,
      'email' => l.activityFieldEmail,
      'address' => l.activityFieldAddress,
      'emergencyName' => l.activityFieldEmergencyName,
      'emergencyPhone' => l.activityFieldEmergencyPhone,
      'idNumber' => l.activityFieldIdNumber,
      'dateOfBirth' => l.activityFieldDateOfBirth,
      'startedOn' => l.activityFieldStartedOn,
      'notes' => l.activityFieldNotes,
      'rateBp' => l.activityFieldRate,
      'compound' => l.activityFieldCompound,
      'kind' => l.activityFieldKind,
      'scope' => l.activityFieldScope,
      'reason' => l.activityFieldReason,
      'counted' => l.activityFieldCounted,
      'changed' => l.activityFieldChanged,
      'value' when action != AuditAction.discountSaved => l.activityFieldStockValue,
      'value' => l.activityValue,
      'total' => l.activityFieldTotal,
      'subtotal' => l.activityFieldSubtotal,
      'discountTotal' => l.activityFieldDiscountTotal,
      'withoutReceipt' => l.activityFieldWithoutReceipt,
      'amount' => l.activityFieldAmount,
      'cost' => l.activityFieldCost,
      'owedBefore' => l.activityFieldOwedBefore,
      'maxDiscountPercent' => l.activityFieldMaxDiscount,
      _ => _humanise(key),
    };

/// "powerCut" → "Power cut", "device.productView" → "Product view".
String _humanise(String name) {
  final last = name.split('.').last;
  final words = last.replaceAllMapped(RegExp('[A-Z]'), (m) => ' ${m[0]!.toLowerCase()}').replaceAll('_', ' ').trim();
  return words.isEmpty ? name : '${words[0].toUpperCase()}${words.substring(1)}';
}
