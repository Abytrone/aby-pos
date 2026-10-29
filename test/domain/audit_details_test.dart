import 'package:aby_pos/app/domain/audit_details.dart';
import 'package:aby_pos/app/models/audit.dart';
import 'package:aby_pos/app/modules/activity/controllers/activity_controller.dart';
import 'package:flutter_test/flutter_test.dart';

AuditEntry entry(AuditAction action, Map<String, dynamic>? details) => AuditEntry(
      id: 'a',
      seq: 1,
      at: DateTime(2026, 10, 29),
      deviceId: 'd',
      action: action,
      summary: '',
      details: details,
    );

void main() {
  group('describeAuditDetails', () {
    test('bulk prices saved before names were kept still read, biggest change first', () {
      final e = entry(AuditAction.pricesBulkChanged, {
        'v1': {'before': 1000, 'after': 1100},
        'v2': {'before': 2000, 'after': 1500},
      });
      expect(auditIdsToName(e), {'v1', 'v2'});
      final d = describeAuditDetails(e, names: {'v1': 'Cone'}) as PriceChanges;
      expect(d.rows.map((r) => (r.label, r.difference)), [(null, -500), ('Cone', 100)]);
      expect(d.rows.last.percent, 10);
    });

    test('bulk prices saved with names need no lookup', () {
      final e = entry(AuditAction.pricesBulkChanged, {
        'items': [
          {'id': 'v1', 'name': 'Waffle', 'before': 1200, 'after': 1300},
        ],
      });
      expect(auditIdsToName(e), isEmpty);
      expect((describeAuditDetails(e) as PriceChanges).rows.single.label, 'Waffle');
    });

    test('a price is money; a role change shows names, not ids', () {
      final price = describeAuditDetails(entry(AuditAction.priceChanged, {'before': 1200, 'after': 1400})) as FieldChanges;
      expect(price.fields.single.after, isA<MoneyValue>());
      final role = describeAuditDetails(
        entry(AuditAction.staffRoleChanged, {'before': 'r1', 'after': 'r2'}),
        names: {'r1': 'Cashier', 'r2': 'Manager'},
      ) as FieldChanges;
      expect((role.fields.single.before as TextValue).text, 'Cashier');
      expect((role.fields.single.after as TextValue).text, 'Manager');
    });

    test('a role lists permissions gained and lost', () {
      final d = describeAuditDetails(entry(AuditAction.roleUpdated, {
        'before': {'permissions': ['a', 'b'], 'maxDiscountPercent': 10},
        'after': {'permissions': ['b', 'c'], 'maxDiscountPercent': 20},
      })) as PermissionChanges;
      expect(d.added, ['c']);
      expect(d.removed, ['a']);
      expect((d.maxDiscountBefore, d.maxDiscountAfter), (10, 20));
    });

    test('changed fields only; new things show every field', () {
      final changed = describeAuditDetails(entry(AuditAction.taxRateSaved, {
        'before': {'name': 'VAT', 'rateBp': 1500, 'compound': false},
        'after': {'name': 'VAT', 'rateBp': 2000, 'compound': false},
      })) as FieldChanges;
      expect(changed.fields.single.key, 'rateBp');
      expect((changed.fields.single.after as PercentValue).percent, 20);

      final created = describeAuditDetails(entry(AuditAction.taxRateSaved, {
        'after': {'name': 'NHIL', 'rateBp': 250, 'compound': true},
      })) as FieldChanges;
      expect(created.fields.map((f) => f.key), ['name', 'rateBp', 'compound']);
      expect(created.fields.every((f) => f.before == null), isTrue);
    });

    test('entries without before and after show their facts', () {
      final refund = describeAuditDetails(entry(AuditAction.refundGiven, {'total': 3700, 'withoutReceipt': true})) as AuditFacts;
      expect(refund.fields.map((f) => f.after.runtimeType), [MoneyValue, YesNoValue]);

      final count = describeAuditDetails(entry(AuditAction.stockCountPosted, {'counted': 12, 'changed': 3, 'value': -450}))
          as AuditFacts;
      expect((count.fields[0].after as TextValue).text, '12');
      expect(count.fields[2].after, isA<MoneyValue>().having((m) => m.signed, 'signed', isTrue));

      final discount = describeAuditDetails(entry(AuditAction.discountSaved, {'kind': 'percent', 'value': 10, 'scope': 'order'}))
          as AuditFacts;
      expect(discount.fields[1].after, isA<PercentValue>());
    });

    test('quantities without their unit are left to the summary', () {
      final d = describeAuditDetails(entry(AuditAction.stockAdjusted, {'change': -2000, 'value': -900})) as AuditFacts;
      expect(d.fields.map((f) => f.key), ['value']);
    });

    test('nothing to open when there is nothing to show', () {
      expect(describeAuditDetails(entry(AuditAction.backupCreated, null)), isNull);
      expect(describeAuditDetails(entry(AuditAction.backupCreated, {})), isNull);
      expect(
        describeAuditDetails(entry(AuditAction.staffDetailsChanged, {
          'before': {'name': 'Ama'},
          'after': {'name': 'Ama'},
        })),
        isNull,
      );
    });
  });

  test('every action can be found under a filter other than All', () {
    final covered = {
      for (final f in ActivityFilter.values)
        if (f != ActivityFilter.all && f != ActivityFilter.important) ...?f.actions,
    };
    expect(AuditAction.values.toSet().difference(covered), isEmpty);
  });
}
