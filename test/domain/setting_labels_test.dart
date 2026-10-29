import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/domain/audit_details.dart';
import 'package:aby_pos/app/models/audit.dart';
import 'package:aby_pos/app/ui/setting_labels.dart';
import 'package:aby_pos/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final l = lookupAppLocalizations(const Locale('en'));

  test('every setting has the title Settings gives it, not its stored key', () {
    for (final s in AppSettings.all) {
      expect(knownSettingLabel(l, s.key), isNotNull, reason: '${s.key} needs a title in knownSettingLabel');
    }
    expect(settingLabel(l, 'some.newThing'), 'New thing');
  });

  test('no setting value is shown as JSON', () {
    const samples = <String, Object>{
      'loyalty.stampTarget': '{"products":["p1"],"categories":["c1"]}',
      'orders.prepTarget': '{"products":[],"categories":[]}',
      'receipt.copies': '{"credit":2}',
      'device.printer': '{"kind":"network","address":"10.0.0.9","name":"Counter"}',
      'device.kitchenPrinter': '',
      'device.scale': '',
    };
    for (final s in AppSettings.all) {
      for (final v in [s.defaultValue, ?samples[s.key]]) {
        final text = settingValueText(l, s.key, v, names: const {'p1': 'Waffle', 'c1': 'Cones'});
        expect(text, isNot(anyOf(startsWith('{'), startsWith('['))), reason: '${s.key}: $v');
      }
    }
  });

  test('values read the way Settings shows them', () {
    String v(String key, Object? value) => settingValueText(l, key, value, names: const {'p1': 'Waffle', 'c1': 'Cones'});
    expect(v('loyalty.stampTarget', '{"products":["p1"],"categories":["c1"]}'), 'Cones, Waffle');
    expect(v('loyalty.stampTarget', '{}'), 'Everything');
    expect(v('loyalty.stampTarget', '{"products":["gone"]}'), 'an item no longer on file');
    expect(v('receipt.copies', '{"credit":2}'), l.receiptTwoCopies);
    expect(v('device.printer', '{"kind":"network","address":"10.0.0.9","name":"Counter"}'), startsWith('Counter ('));
    expect(v('stock.allowNegative', true), 'On');
    expect(v('shift.varianceLimit', 500), 'GH₵ 5.00');
    expect(v('security.autoLockMinutes', 0), l.settingsAutoLockOff);
    expect(v('receipt.logo', 'iVBORw0KGgo...'), 'A logo');
  });

  test('a stamp target entry names the ids it needs looked up', () {
    final e = AuditEntry(
      id: 'a',
      seq: 1,
      at: DateTime(2026, 10, 29),
      deviceId: 'd',
      action: AuditAction.settingChanged,
      summary: 'Changed loyalty.stampTarget',
      entityId: 'loyalty.stampTarget',
      details: {'before': '{}', 'after': '{"products":["p1"],"categories":["c1"]}'},
    );
    expect(auditIdsToName(e), {'p1', 'c1'});
    expect(describeAuditDetails(e), isA<SettingChange>().having((s) => s.key, 'key', 'loyalty.stampTarget'));
  });
}
