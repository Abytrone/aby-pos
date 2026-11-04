import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/sync/row_store.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase a, b;
  late Repos ra, rb;
  late RowStore sa, sb;

  setUp(() async {
    a = memoryDb();
    b = memoryDb(seed: false);
    ra = await Repos.open(a);
    rb = await Repos.open(b);
    sa = RowStore(a);
    sb = RowStore(b);
  });
  tearDown(() async {
    await a.close();
    await b.close();
  });

  test('synced tables are found by their columns; local ones are not', () {
    expect(
      sa.synced.keys,
      containsAll(['sales', 'customers', 'products', 'audit_log', 'settings']),
    );
    expect(sa.synced.keys, isNot(contains('outbox')));
    expect(sa.synced.keys, isNot(contains('meta')));
    expect(sa.synced.keys, isNot(contains('hub_changes')));
  });

  test('a change goes across without going into the other outbox; the later edit wins', () async {
    final id = await ra.customers.save(
      const CustomerDraft(name: 'Ama'),
      by: owner,
    );
    final batch = await sa.pending();
    final row = batch.rows.firstWhere(
      (r) => r.entity == 'customers' && r.id == id,
    );
    expect(await sb.apply(WireRow.fromJson(row.toJson())), isTrue);
    expect((await rb.customers.find(id))!.name, 'Ama');
    expect(
      await b.select(b.outbox).get(),
      isEmpty,
      reason: 'came from elsewhere',
    );
    await sa.acknowledge(batch.outboxSeqs);
    expect(await a.select(a.outbox).get(), isEmpty);

    // B renames her later; A's older copy does not win back.
    await b.customStatement(
      "UPDATE customers SET name = 'Ama Mensah', updated_at = updated_at + 10 WHERE id = ?",
      [id],
    );
    final newer = WireRow('customers', id, (await sb.read('customers', id))!);
    expect(await sa.apply(newer), isTrue);
    expect((await ra.customers.find(id))!.name, 'Ama Mensah');
    final older = WireRow('customers', id, {
      ...newer.row,
      'name': 'Old',
      'updated_at': (newer.row['updated_at']! as int) - 100,
    });
    expect(await sa.apply(older), isFalse);
    expect((await ra.customers.find(id))!.name, 'Ama Mensah');
    expect(
      await sa.apply(newer),
      isFalse,
      reason: 'the same row again changes nothing',
    );
  });

  test('synced product and stock name collisions are renamed without losing either ID', () async {
    final product = (await ra.catalog.load()).products.firstWhere(
      (p) => p.name == 'Vanilla cone',
    );
    final productRow = await sa.read('products', product.id);
    final incomingProduct = WireRow('products', 'remote-product', {
      ...productRow!,
      'id': 'remote-product',
    });
    final normalizedProduct = await sa.uniqueNameRow(incomingProduct);
    expect(normalizedProduct.row['name'], 'Vanilla cone (2)');
    expect(await sa.apply(normalizedProduct), isTrue);
    expect(
      await sa.read('products', 'remote-product').then((r) => r!['name']),
      'Vanilla cone (2)',
    );

    final stock = (await ra.stock.items()).firstWhere(
      (s) => s.name == 'Wafer cones',
    );
    final stockRow = await sa.read('stock_items', stock.id);
    final incomingStock = WireRow('stock_items', 'remote-stock', {
      ...stockRow!,
      'id': 'remote-stock',
    });
    final normalizedStock = await sa.uniqueNameRow(incomingStock);
    expect(normalizedStock.row['name'], 'Wafer cones (2)');
    expect(await sa.apply(normalizedStock), isTrue);
    expect(
      await sa.read('stock_items', 'remote-stock').then((r) => r!['name']),
      'Wafer cones (2)',
    );
  });

  test(
    'joining: everything goes into the outbox; unknown tables are ignored',
    () async {
      final n = await sa.enqueueEverything();
      expect(n, greaterThan(50));
      var moved = 0;
      while (true) {
        final batch = await sa.pending();
        if (batch.isEmpty) break;
        for (final r in batch.rows) {
          if (await sb.apply(r)) moved++;
        }
        await sa.acknowledge(batch.outboxSeqs);
      }
      expect(moved, greaterThan(50));
      expect(
        (await rb.catalog.load()).products.map((p) => p.name),
        contains('Vanilla cone'),
      );
      expect(
        await sb.apply(const WireRow('nothing', 'x', {'id': 'x'})),
        isFalse,
      );
    },
  );
}
