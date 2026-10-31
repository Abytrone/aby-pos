import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aby_pos/app/core/settings.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/catalog_repository.dart';
import 'package:aby_pos/app/data/repositories/order_repository.dart';
import 'package:aby_pos/app/data/repositories/receipt_repository.dart';
import 'package:aby_pos/app/data/repositories/settings_repository.dart';
import 'package:aby_pos/app/domain/labels.dart';
import 'package:aby_pos/app/domain/orders.dart';
import 'package:aby_pos/app/domain/promotions.dart';
import 'package:aby_pos/app/domain/receipt/escpos.dart';
import 'package:aby_pos/app/domain/receipt/receipt_builder.dart';
import 'package:aby_pos/app/domain/receipt/receipt_doc.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/display/display_service.dart';
import 'package:aby_pos/app/services/printing/print_service.dart';
import 'package:aby_pos/app/services/printing/printer_link.dart';
import 'package:aby_pos/app/services/settings_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

class _Link implements PrinterLink {
  final sent = <Uint8List>[];

  @override
  Future<void> send(Uint8List bytes) async => sent.add(bytes);
}

void main() {
  late AppDatabase db;
  late Repos r;
  late Catalogue menu;
  late OrderConfig orders;

  Product named(String name) => menu.products.firstWhere((p) => p.name == name);

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    menu = await r.catalog.load();
    orders = OrderConfig(prep: PromoTarget(products: {named('Waffle').id, named('Milkshake').id}), prefix: 'A', dayStartMinutes: 0);
  });
  tearDown(() async {
    Get.reset();
    await db.close();
  });

  Future<CompletedSale> sell(List<CartLine> lines) => r.sales.completeSale(
        lines: lines,
        payments: [const PaymentInput.cash(tendered: 100000)],
        cashier: cashier,
        orders: orders,
      );

  test('order numbers: sales with prep items only, counting up, starting again each day', () async {
    final first = await sell([CartLine(product: named('Waffle'))]);
    final cone = await sell([CartLine(product: named('Vanilla cone'))]);
    final second = await sell([CartLine(product: named('Milkshake')), CartLine(product: named('Vanilla cone'))]);
    expect((first.orderNumber, cone.orderNumber, second.orderNumber), (1, null, 2));

    final repo = OrderRepository(db);
    var open = await repo.open();
    expect(open.map((o) => o.number), [1, 2]);
    expect(open.first.status, OrderStatus.fresh);
    expect(open.last.lines.map((l) => l.title), contains('Milkshake'));
    await repo.setStatus(first.saleId, OrderStatus.ready);
    await repo.setStatus(second.saleId, OrderStatus.collected);
    open = await repo.open();
    expect(open.single.status, OrderStatus.ready);

    // The receipt shows the number big.
    final data = (await ReceiptRepository(db).sale(first.saleId))!;
    final text = ReceiptBuilder.sale(data, const ReceiptDesign(shopName: 'S', orderPrefix: 'A')).toText(Paper.mm58);
    expect(text, contains('YOUR ORDER'));
    expect(text, contains('A1'));

    // Yesterday's numbers do not count.
    await db.customStatement('UPDATE sales SET created_at = created_at - 86400');
    expect((await sell([CartLine(product: named('Waffle'))])).orderNumber, 1);
  });

  test('kitchen tickets go to the kitchen printer with the prep lines', () async {
    final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
    await settings.load();
    await settings.set(AppSettings.kitchenPrinter, const PrinterTarget(kind: PrinterKind.network, address: '10.0.0.8').encode(), by: owner);
    final links = <String, _Link>{};
    final print = PrintService(settings, ReceiptRepository(db), r.device, links: (t) => links.putIfAbsent(t.address, _Link.new));
    final sale = await sell([CartLine(product: named('Waffle'), note: 'extra syrup')]);
    await print.afterSale(sale.saleId, prep: const [OrderLine(title: 'Waffle', quantity: 1, note: 'extra syrup')]);
    await Future<void>.delayed(const Duration(milliseconds: 20));
    final ticket = String.fromCharCodes(links['10.0.0.8']!.sent.single.where((b) => b >= 32 && b < 127));
    expect(ticket, contains('A1'));
    expect(ticket, contains('1 x Waffle'));
    expect(ticket, contains('extra syrup'));
    print.onClose();
  });

  test('the display server: pages, the cart state, orders and moving them', () async {
    Get.testMode = true;
    final settings = SettingsService(SettingsRepository(db, r.device, r.audit));
    await settings.load();
    Get.put(settings);
    Get.put(OrderRepository(db));
    final display = DisplayService(db, settings);
    await display.start(port: 0);
    final base = 'http://127.0.0.1:${display.port}';
    final client = HttpClient();
    Future<(int, String)> get(String path, {String method = 'GET'}) async {
      final req = await client.openUrl(method, Uri.parse('$base$path'));
      final res = await req.close();
      return (res.statusCode, await res.transform(utf8.decoder).join());
    }

    expect((await get('/c/wrong')).$1, 404);
    final page = await get('/c/${display.token}');
    expect(page.$1, 200);
    expect(page.$2, contains('<h1>Thank you</h1>'));
    final state = jsonDecode((await get('/c/${display.token}/state')).$2) as Map<String, dynamic>;
    expect(state['stage'], 'idle');
    expect(state['shop'], 'Scoops Tamale');

    display.paying(due: 1200, payToName: 'MTN MoMo', payToNumber: '0241234567');
    final paying = jsonDecode((await get('/c/${display.token}/state')).$2) as Map<String, dynamic>;
    expect(paying['stage'], 'paying');
    expect(paying['qr'], startsWith('<svg'));
    display.done(total: 1200, change: 800, order: 'A1');
    expect((jsonDecode((await get('/c/${display.token}/state')).$2) as Map)['change'], 800);

    final sale = await sell([CartLine(product: named('Waffle'))]);
    final list = jsonDecode((await get('/k/${display.token}/orders')).$2) as List;
    expect((list.single as Map)['number'], 'A1');
    expect((await get('/k/${display.token}/orders/${sale.saleId}/ready', method: 'POST')).$1, 200);
    expect((await OrderRepository(db).open()).single.status, OrderStatus.ready);
    expect((await get('/s/${display.token}')).$2, contains('Ready to collect'));

    final old = display.token;
    await display.newToken();
    expect((await get('/c/$old')).$1, 404);
    client.close(force: true);
    await display.stop();
  });

  test('barcodes for products without one, and labels as PDF and stickers', () async {
    final waffle = named('Waffle').variants.single;
    final shake = named('Milkshake').variants.single;
    final made = await r.catalog.generateBarcodes([waffle.id, shake.id], by: owner);
    expect(made, 2);
    menu = await r.catalog.load();
    expect(named('Waffle').variants.single.barcodes, ['ABY00001']);
    expect(named('Milkshake').variants.single.barcodes, ['ABY00002']);
    expect(await r.catalog.generateBarcodes([waffle.id], by: owner), 0, reason: 'already has one');
    expect((await r.catalog.findBarcode('ABY00001'))?.$2, waffle.id);

    const items = [LabelItem(name: 'Waffle', price: 1200, code: 'ABY00001', count: 30)];
    final sheet = await Labels.pdf(items, LabelFormat.sheet);
    expect(String.fromCharCodes(sheet.sublist(0, 5)), '%PDF-');
    final stickers = Labels.paper(const [LabelItem(name: 'Waffle', price: 1200, code: 'ABY00001', count: 2)]);
    expect(stickers, hasLength(2));
    expect(stickers.first.blocks.whereType<RBarcode>().single.data, 'ABY00001');

    final bars = MonoBitmap.code128('ABY00001', maxWidth: 384);
    expect(bars.width, lessThanOrEqualTo(384));
    expect(bars.dark(0, 0), isTrue, reason: 'Code 128 starts with a bar');
    final bytes = EscPos.encode(stickers.first, Paper.mm58);
    expect(bytes, isNotEmpty);
  });
}
