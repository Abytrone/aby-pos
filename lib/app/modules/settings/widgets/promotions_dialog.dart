import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/promotion_repository.dart';
import '../../../domain/promotions.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/dialogs.dart';

String promotionKindLabel(AppLocalizations l, PromotionKind k) => switch (k) {
      PromotionKind.percentOff => l.promoKindPercent,
      PromotionKind.buyGet => l.promoKindBuyGet,
      PromotionKind.bundle => l.promoKindBundle,
      PromotionKind.quantityBreak => l.promoKindQuantity,
      PromotionKind.spend => l.promoKindSpend,
    };

String promotionKindExample(AppLocalizations l, PromotionKind k) => switch (k) {
      PromotionKind.percentOff => l.promoKindPercentExample,
      PromotionKind.buyGet => l.promoKindBuyGetExample,
      PromotionKind.bundle => l.promoKindBundleExample,
      PromotionKind.quantityBreak => l.promoKindQuantityExample,
      PromotionKind.spend => l.promoKindSpendExample,
    };

List<String> _dayNames(AppLocalizations l) => [l.dayMon, l.dayTue, l.dayWed, l.dayThu, l.dayFri, l.daySat, l.daySun];

/// "Mon to Fri, 14:00 to 16:00, until 31 Dec 2026".
String promotionWhen(AppLocalizations l, Promotion p) {
  final days = _dayNames(l);
  final on = [for (var d = 0; d < 7; d++) if (p.days & (1 << d) != 0) days[d]];
  return [
    if (p.days != 127) on.join(', '),
    if (p.fromMinute != null && p.toMinute != null)
      '${formatMinutesOfDay(p.fromMinute!)} – ${formatMinutesOfDay(p.toMinute!)}',
    if (p.startsOn != null) l.promoFrom(formatDate(p.startsOn!)),
    if (p.endsOn != null) l.promoUntil(formatDate(p.endsOn!)),
  ].join('  ·  ');
}

/// Promotions changes need "Change prices" (or a PIN).
Future<Authorization?> _authorize() =>
    Get.find<PermissionService>().authorize(Permission.changePrices, reason: appL10n().promoApprovalReason);

/// Settings → Promotions: the automatic ones, on or off.
Future<void> showPromotions() => Get.dialog<void>(const _Promotions());

class _Promotions extends StatefulWidget {
  const _Promotions();

  @override
  State<_Promotions> createState() => _PromotionsState();
}

class _PromotionsState extends State<_Promotions> {
  final PromotionRepository _repo = Get.find();
  List<Promotion> _list = const [];
  Catalogue? _menu;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await _repo.list();
    final menu = _menu ?? await Get.find<CatalogRepository>().load(includeInactive: true);
    if (!mounted) return;
    setState(() {
      _list = list;
      _menu = menu;
    });
  }

  Future<void> _edit([Promotion? p]) async {
    final menu = _menu;
    if (menu == null) return;
    final saved = await Get.dialog<bool>(_PromotionEditor(promotion: p, menu: menu));
    if (saved ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final now = DateTime.now();
    return AlertDialog(
      title: Text(l.promoTitle),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.promoHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s2),
          Flexible(
            child: _list.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(AbySpace.s4),
                    child: Text(l.promoNone, style: AbyText.body.copyWith(color: c.inkMuted)),
                  )
                : ListView(shrinkWrap: true, children: [
                    for (final p in _list)
                      ListTile(
                        title: Text(p.name, style: TextStyle(color: p.active ? c.ink : c.inkMuted)),
                        subtitle: Text([
                          promotionKindLabel(l, p.kind),
                          if (promotionWhen(l, p).isNotEmpty) promotionWhen(l, p),
                          if (p.runsAt(now)) l.promoRunningNow,
                        ].join('  ·  ')),
                        onTap: () => _edit(p),
                        trailing: Switch(
                          value: p.active,
                          onChanged: (on) async {
                            final auth = await _authorize();
                            if (auth == null) return;
                            await _repo.save(
                              Promotion(
                                id: p.id,
                                name: p.name,
                                kind: p.kind,
                                rule: p.rule,
                                startsOn: p.startsOn,
                                endsOn: p.endsOn,
                                days: p.days,
                                fromMinute: p.fromMinute,
                                toMinute: p.toMinute,
                                stackable: p.stackable,
                                active: on,
                              ),
                              by: auth.authority,
                            );
                            await _load();
                          },
                        ),
                      ),
                  ]),
          ),
        ]),
      ),
      actions: [
        OutlinedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text(l.promoNew)),
        FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
      ],
    );
  }
}

/// Picks products and categories (null when cancelled), outside a
/// promotion: the items that need prep, for example.
Future<PromoTarget?> pickProducts(String title, PromoTarget current) async {
  final menu = await Get.find<CatalogRepository>().load(includeInactive: true);
  return Get.dialog<PromoTarget>(_TargetPicker(target: current, menu: menu, title: title));
}

/// Products and categories, as a short line: "Everything", "Cones, Waffle".
String _targetText(AppLocalizations l, PromoTarget t, Catalogue menu) {
  if (t.everything) return l.promoEverything;
  return [
    for (final c in menu.categories) if (t.categories.contains(c.id)) c.name,
    for (final p in menu.products) if (t.products.contains(p.id)) p.name,
  ].join(', ');
}

/// A field that picks products and categories.
class PromoTargetField extends StatelessWidget {
  const PromoTargetField({super.key, required this.label, required this.target, required this.menu, required this.onChanged});

  final String label;
  final PromoTarget target;
  final Catalogue menu;
  final ValueChanged<PromoTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return InkWell(
      onTap: () async {
        final picked = await Get.dialog<PromoTarget>(_TargetPicker(target: target, menu: menu, title: label));
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, isDense: true, suffixIcon: const Icon(Icons.arrow_drop_down)),
        child: Text(_targetText(l, target, menu), maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

class _TargetPicker extends StatefulWidget {
  const _TargetPicker({required this.target, required this.menu, required this.title});

  final PromoTarget target;
  final Catalogue menu;
  final String title;

  @override
  State<_TargetPicker> createState() => _TargetPickerState();
}

class _TargetPickerState extends State<_TargetPicker> {
  late final _categories = {...widget.target.categories};
  late final _products = {...widget.target.products};

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: 420,
        height: 460,
        child: ListView(children: [
          Text(l.promoPickHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          Text(l.navProducts.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          for (final cat in widget.menu.categories)
            CheckboxListTile(
              dense: true,
              title: Text(l.promoAllIn(cat.name)),
              value: _categories.contains(cat.id),
              onChanged: (v) => setState(() => (v ?? false) ? _categories.add(cat.id) : _categories.remove(cat.id)),
            ),
          const Divider(),
          for (final p in widget.menu.products.where((p) => !p.archived))
            CheckboxListTile(
              dense: true,
              title: Text(p.name),
              value: _products.contains(p.id),
              onChanged: (v) => setState(() => (v ?? false) ? _products.add(p.id) : _products.remove(p.id)),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => goBack(result: const PromoTarget()), child: Text(l.promoEverything)),
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () => goBack(result: PromoTarget(products: _products, categories: _categories)),
          child: Text(l.commonDone),
        ),
      ],
    );
  }
}

class _PromotionEditor extends StatefulWidget {
  const _PromotionEditor({this.promotion, required this.menu});

  final Promotion? promotion;
  final Catalogue menu;

  @override
  State<_PromotionEditor> createState() => _PromotionEditorState();
}

class _PromotionEditorState extends State<_PromotionEditor> {
  late final Promotion? _p = widget.promotion;
  late final PromoRule _r = _p?.rule ?? const PromoRule(percent: 10);
  late final _name = TextEditingController(text: _p?.name ?? '');
  late PromotionKind _kind = _p?.kind ?? PromotionKind.percentOff;
  late PromoTarget _target = _r.target;
  late PromoTarget _reward = _r.reward;
  late final List<PromoTarget> _parts = _r.parts.isEmpty ? [const PromoTarget(), const PromoTarget()] : [..._r.parts];
  late final _percent = TextEditingController(text: '${_r.percent == 0 ? '' : _r.percent}');
  late final _amount = TextEditingController(text: _r.amount == 0 ? '' : (_r.amount / 100).toStringAsFixed(2));
  late final _quantity = TextEditingController(text: _r.quantity == 0 ? '' : '${_r.quantity}');
  late final _rewardQuantity = TextEditingController(text: '${_r.rewardQuantity}');
  late final _threshold = TextEditingController(text: _r.threshold == 0 ? '' : (_r.threshold / 100).toStringAsFixed(2));
  late SpendReward _spendReward = _r.spendReward;
  late DateTime? _startsOn = _p?.startsOn;
  late DateTime? _endsOn = _p?.endsOn;
  late int _days = _p?.days ?? 127;
  late int? _from = _p?.fromMinute;
  late int? _to = _p?.toMinute;
  late bool _stackable = _p?.stackable ?? false;
  late bool _active = _p?.active ?? true;
  String? _error;

  @override
  void dispose() {
    for (final t in [_name, _percent, _amount, _quantity, _rewardQuantity, _threshold]) {
      t.dispose();
    }
    super.dispose();
  }

  int? _int(TextEditingController t) => int.tryParse(t.text.trim());

  /// The rule from the form, or null with [_error] set.
  PromoRule? _rule() {
    final l = context.l10n;
    final percent = _int(_percent) ?? 0;
    final amount = _amount.text.trim().isEmpty ? 0 : parseMoney(_amount.text);
    final quantity = _int(_quantity) ?? 0;
    final threshold = _threshold.text.trim().isEmpty ? 0 : parseMoney(_threshold.text);
    String? problem;
    final needsPercent = _kind == PromotionKind.percentOff ||
        _kind == PromotionKind.buyGet ||
        (_kind == PromotionKind.spend && _spendReward == SpendReward.percent);
    if (needsPercent && (percent < 1 || percent > 100)) problem = l.promoPercentInvalid;
    final needsAmount = _kind == PromotionKind.bundle ||
        _kind == PromotionKind.quantityBreak ||
        (_kind == PromotionKind.spend && _spendReward == SpendReward.amount);
    if (needsAmount && (amount == null || amount <= 0)) problem = l.promoAmountInvalid;
    if ((_kind == PromotionKind.buyGet || _kind == PromotionKind.quantityBreak) && quantity < 1) {
      problem = l.promoQuantityInvalid;
    }
    if (_kind == PromotionKind.spend && (threshold == null || threshold <= 0)) problem = l.promoThresholdInvalid;
    if (_kind == PromotionKind.bundle && _parts.length < 2) problem = l.promoPartsInvalid;
    if (problem != null) {
      setState(() => _error = problem);
      return null;
    }
    return PromoRule(
      target: _target,
      reward: _reward,
      parts: _kind == PromotionKind.bundle ? _parts : const [],
      percent: percent,
      amount: amount ?? 0,
      quantity: quantity,
      rewardQuantity: (_int(_rewardQuantity) ?? 1).clamp(1, 99),
      threshold: threshold ?? 0,
      spendReward: _spendReward,
    );
  }

  Future<void> _save() async {
    final l = context.l10n;
    if (_name.text.trim().isEmpty) return setState(() => _error = l.promoNameRequired);
    if (_days == 0) return setState(() => _error = l.promoDaysRequired);
    final rule = _rule();
    if (rule == null) return;
    final auth = await _authorize();
    if (auth == null) return;
    await Get.find<PromotionRepository>().save(
      Promotion(
        id: _p?.id ?? '',
        name: _name.text,
        kind: _kind,
        rule: rule,
        startsOn: _startsOn,
        endsOn: _endsOn,
        days: _days,
        fromMinute: _from != null && _to != null ? _from : null,
        toMinute: _from != null && _to != null ? _to : null,
        stackable: _stackable,
        active: _active,
      ),
      by: auth.authority,
    );
    goBack(result: true);
  }

  Future<void> _delete() async {
    final auth = await _authorize();
    if (auth == null) return;
    await Get.find<PromotionRepository>().delete(_p!.id, by: auth.authority);
    goBack(result: true);
  }

  Future<DateTime?> _pickDate(DateTime? current) => showDatePicker(
        context: context,
        initialDate: current ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2100),
      );

  Future<int?> _pickTime(int? current) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: (current ?? 14 * 60) ~/ 60, minute: (current ?? 0) % 60),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final menu = widget.menu;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    const gap = SizedBox(height: AbySpace.s3);
    Widget number(TextEditingController t, String label, {String? suffix, bool money = false}) => TextField(
          controller: t,
          keyboardType: money ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
          inputFormatters: money ? null : digits,
          decoration: InputDecoration(labelText: label, suffixText: suffix, prefixText: money ? 'GH₵ ' : null, isDense: true),
        );
    final days = _dayNames(l);
    return AlertDialog(
      title: Text(_p == null ? l.promoNew : l.promoEdit),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _name,
              autofocus: _p == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(labelText: l.promoName, helperText: l.promoNameHelp),
            ),
            gap,
            DropdownButtonFormField<PromotionKind>(
              initialValue: _kind,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.promoKind, helperText: promotionKindExample(l, _kind)),
              items: [
                for (final k in PromotionKind.values) DropdownMenuItem(value: k, child: Text(promotionKindLabel(l, k))),
              ],
              onChanged: (k) => setState(() => _kind = k ?? _kind),
            ),
            gap,
            ...switch (_kind) {
              PromotionKind.percentOff => [
                  PromoTargetField(label: l.promoOn, target: _target, menu: menu, onChanged: (t) => setState(() => _target = t)),
                  gap,
                  number(_percent, l.promoPercentOff, suffix: '%'),
                ],
              PromotionKind.quantityBreak => [
                  PromoTargetField(label: l.promoOn, target: _target, menu: menu, onChanged: (t) => setState(() => _target = t)),
                  gap,
                  Row(children: [
                    Expanded(child: number(_quantity, l.promoMinQuantity)),
                    const SizedBox(width: AbySpace.s3),
                    Expanded(child: number(_amount, l.promoPriceEach, money: true)),
                  ]),
                ],
              PromotionKind.buyGet => [
                  Row(children: [
                    SizedBox(width: 96, child: number(_quantity, l.promoBuy)),
                    const SizedBox(width: AbySpace.s3),
                    Expanded(
                      child: PromoTargetField(label: l.promoOf, target: _target, menu: menu, onChanged: (t) => setState(() => _target = t)),
                    ),
                  ]),
                  gap,
                  Row(children: [
                    SizedBox(width: 96, child: number(_rewardQuantity, l.promoGet)),
                    const SizedBox(width: AbySpace.s3),
                    Expanded(
                      child: PromoTargetField(
                        label: l.promoOfSameOrOther,
                        target: _reward,
                        menu: menu,
                        onChanged: (t) => setState(() => _reward = t),
                      ),
                    ),
                  ]),
                  gap,
                  number(_percent, l.promoRewardPercent, suffix: '%'),
                ],
              PromotionKind.bundle => [
                  for (final (i, part) in _parts.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AbySpace.s2),
                      child: Row(children: [
                        Expanded(
                          child: PromoTargetField(
                            label: l.promoPart(i + 1),
                            target: part,
                            menu: menu,
                            onChanged: (t) => setState(() => _parts[i] = t),
                          ),
                        ),
                        if (_parts.length > 2)
                          IconButton(
                            tooltip: l.optionsRemove,
                            onPressed: () => setState(() => _parts.removeAt(i)),
                            icon: const Icon(Icons.close),
                          ),
                      ]),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => setState(() => _parts.add(const PromoTarget())),
                      icon: const Icon(Icons.add),
                      label: Text(l.promoAddPart),
                    ),
                  ),
                  number(_amount, l.promoBundlePrice, money: true),
                ],
              PromotionKind.spend => [
                  number(_threshold, l.promoSpendAtLeast, money: true),
                  gap,
                  SegmentedButton<SpendReward>(
                    segments: [
                      ButtonSegment(value: SpendReward.percent, label: Text(l.promoRewardPercentOff)),
                      ButtonSegment(value: SpendReward.amount, label: Text(l.promoRewardAmountOff)),
                      ButtonSegment(value: SpendReward.free, label: Text(l.promoRewardFree)),
                    ],
                    selected: {_spendReward},
                    onSelectionChanged: (s) => setState(() => _spendReward = s.first),
                  ),
                  gap,
                  switch (_spendReward) {
                    SpendReward.percent => number(_percent, l.promoPercentOff, suffix: '%'),
                    SpendReward.amount => number(_amount, l.promoAmountOff, money: true),
                    SpendReward.free => PromoTargetField(
                        label: l.promoFreeItem,
                        target: _reward,
                        menu: menu,
                        onChanged: (t) => setState(() => _reward = t),
                      ),
                  },
                ],
            },
            const Divider(height: AbySpace.s6),
            Text(l.promoWhen.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s1, children: [
              for (var d = 0; d < 7; d++)
                FilterChip(
                  label: Text(days[d]),
                  selected: _days & (1 << d) != 0,
                  onSelected: (on) => setState(() => _days = on ? _days | (1 << d) : _days & ~(1 << d)),
                ),
            ]),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              ActionChip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(_from == null || _to == null
                    ? l.promoAllDay
                    : '${formatMinutesOfDay(_from!)} – ${formatMinutesOfDay(_to!)}'),
                onPressed: () async {
                  final from = await _pickTime(_from);
                  if (from == null) return;
                  final to = await _pickTime(_to ?? from + 120);
                  if (to != null) {
                    setState(() {
                      _from = from;
                      _to = to;
                    });
                  }
                },
              ),
              if (_from != null) TextButton(
                  onPressed: () => setState(() {
                    _from = null;
                    _to = null;
                  }),
                  child: Text(l.promoAllDay),
                ),
              ActionChip(
                avatar: const Icon(Icons.event, size: 18),
                label: Text(_startsOn == null ? l.promoStartsNow : l.promoFrom(formatDate(_startsOn!))),
                onPressed: () async {
                  final d = await _pickDate(_startsOn);
                  if (d != null) setState(() => _startsOn = d);
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.event_busy, size: 18),
                label: Text(_endsOn == null ? l.promoNoEnd : l.promoUntil(formatDate(_endsOn!))),
                onPressed: () async {
                  final d = await _pickDate(_endsOn);
                  if (d != null) setState(() => _endsOn = d);
                },
              ),
              if (_startsOn != null || _endsOn != null)
                TextButton(
                  onPressed: () => setState(() {
                    _startsOn = null;
                    _endsOn = null;
                  }),
                  child: Text(l.promoAnyDate),
                ),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.promoStackable),
              subtitle: Text(l.promoStackableHelp),
              value: _stackable,
              onChanged: (v) => setState(() => _stackable = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.promoOn2),
              value: _active,
              onChanged: (v) => setState(() => _active = v),
            ),
            if (_error != null) Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
          ]),
        ),
      ),
      actions: [
        if (_p != null) TextButton(onPressed: _delete, child: Text(l.commonDelete, style: TextStyle(color: c.danger))),
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
