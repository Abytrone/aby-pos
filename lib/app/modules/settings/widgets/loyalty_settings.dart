import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../domain/loyalty.dart';
import '../../../domain/promotions.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/settings_controller.dart';
import 'promotions_dialog.dart';

String loyaltyStyleLabel(AppLocalizations l, LoyaltyStyle s) => switch (s) {
      LoyaltyStyle.off => l.settingsOff,
      LoyaltyStyle.stamps => l.loyaltyStampCard,
      LoyaltyStyle.points => l.loyaltyPointsStyle,
      LoyaltyStyle.tiers => l.loyaltyTiers,
    };

/// Settings → Loyalty: one style for the shop and its numbers.
Future<void> showLoyaltySettings(SettingsController settings) async {
  final menu = await Get.find<CatalogRepository>().load(includeInactive: true);
  await Get.dialog<void>(_LoyaltySettings(settings: settings, menu: menu));
}

class _LoyaltySettings extends StatefulWidget {
  const _LoyaltySettings({required this.settings, required this.menu});

  final SettingsController settings;
  final Catalogue menu;

  @override
  State<_LoyaltySettings> createState() => _LoyaltySettingsState();
}

class _LoyaltySettingsState extends State<_LoyaltySettings> {
  late final SettingsController _s = widget.settings;
  late final LoyaltyConfig _c = LoyaltyConfig.read(<T extends Object>(Setting<T> x) => _s.value<T>(x));
  late LoyaltyStyle _style = _c.style;
  late PromoTarget _target = _c.stampTarget;
  late final _stamps = TextEditingController(text: '${_c.stampsForReward}');
  late final _perCedi = TextEditingController(text: '${_c.pointsPerCedi}');
  late final _forReward = TextEditingController(text: '${_c.pointsForReward}');
  late final _value = TextEditingController(text: (_c.rewardValue / 100).toStringAsFixed(2));
  late final _expire = TextEditingController(text: '${_c.expireDays}');
  late final _goldSpend = TextEditingController(text: (_c.goldSpend / 100).toStringAsFixed(2));
  late final _goldPercent = TextEditingController(text: '${_c.goldPercent}');
  String? _error;

  @override
  void dispose() {
    for (final t in [_stamps, _perCedi, _forReward, _value, _expire, _goldSpend, _goldPercent]) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    int? n(TextEditingController t) => int.tryParse(t.text.trim());
    final stamps = n(_stamps), perCedi = n(_perCedi), forReward = n(_forReward), expire = n(_expire);
    final value = parseMoney(_value.text), goldSpend = parseMoney(_goldSpend.text), goldPercent = n(_goldPercent);
    final ok = switch (_style) {
      LoyaltyStyle.off => true,
      LoyaltyStyle.stamps => stamps != null && stamps >= 1,
      LoyaltyStyle.points =>
        perCedi != null && perCedi >= 1 && forReward != null && forReward >= 1 && value != null && value > 0 && expire != null,
      LoyaltyStyle.tiers => goldSpend != null && goldSpend > 0 && goldPercent != null && goldPercent >= 1 && goldPercent <= 100,
    };
    if (!ok) return setState(() => _error = l.loyaltyNumbersInvalid);
    if (!await _s.saveAll([
      (AppSettings.loyaltyStyle, _style.name),
      if (_style == LoyaltyStyle.stamps) ...[
        (AppSettings.loyaltyStamps, stamps!),
        (AppSettings.loyaltyStampTarget, jsonEncode(_target.toJson())),
      ],
      if (_style == LoyaltyStyle.points) ...[
        (AppSettings.loyaltyPointsPerCedi, perCedi!),
        (AppSettings.loyaltyPointsForReward, forReward!),
        (AppSettings.loyaltyRewardValue, value!),
        (AppSettings.loyaltyExpireDays, expire!),
      ],
      if (_style == LoyaltyStyle.tiers) ...[
        (AppSettings.loyaltyGoldSpend, goldSpend!),
        (AppSettings.loyaltyGoldPercent, goldPercent!),
      ],
    ])) {
      return;
    }
    Get.back<void>();
    _s.saved();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    const gap = SizedBox(height: AbySpace.s3);
    Widget field(TextEditingController t, String label, {String? helper, bool money = false, String? suffix}) => TextField(
          controller: t,
          keyboardType: money ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
          inputFormatters: money ? null : digits,
          decoration: InputDecoration(
            labelText: label,
            helperText: helper,
            helperMaxLines: 2,
            prefixText: money ? 'GH₵ ' : null,
            suffixText: suffix,
            isDense: true,
          ),
        );
    return AlertDialog(
      title: Text(l.loyaltyTitle),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.loyaltyHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            gap,
            SegmentedButton<LoyaltyStyle>(
              segments: [
                for (final s in LoyaltyStyle.values) ButtonSegment(value: s, label: Text(loyaltyStyleLabel(l, s))),
              ],
              selected: {_style},
              onSelectionChanged: (s) => setState(() => _style = s.first),
            ),
            gap,
            ...switch (_style) {
              LoyaltyStyle.off => [Text(l.loyaltyOffHelp, style: AbyText.body.copyWith(color: c.inkMuted))],
              LoyaltyStyle.stamps => [
                  field(_stamps, l.loyaltyStampsNeeded, helper: l.loyaltyStampsNeededHelp),
                  gap,
                  PromoTargetField(
                    label: l.loyaltyStampProducts,
                    target: _target,
                    menu: widget.menu,
                    onChanged: (t) => setState(() => _target = t),
                  ),
                ],
              LoyaltyStyle.points => [
                  field(_perCedi, l.loyaltyPointsPerCedi),
                  gap,
                  Row(children: [
                    Expanded(child: field(_forReward, l.loyaltyPointsForReward)),
                    const SizedBox(width: AbySpace.s3),
                    Expanded(child: field(_value, l.loyaltyRewardValue, money: true)),
                  ]),
                  gap,
                  field(_expire, l.loyaltyExpireDays, helper: l.loyaltyExpireDaysHelp, suffix: l.loyaltyDays),
                ],
              LoyaltyStyle.tiers => [
                  Text(l.loyaltyTiersHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
                  gap,
                  field(_goldSpend, l.loyaltyGoldSpend, money: true),
                  gap,
                  field(_goldPercent, l.loyaltyGoldPercent, suffix: '%'),
                ],
            },
            if (_error != null) ...[gap, Text(_error!, style: AbyText.body.copyWith(color: c.danger))],
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
