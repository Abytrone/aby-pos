import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:get/get.dart';
import 'package:qr/qr.dart';

import '../../core/settings.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/order_repository.dart';
import '../../models/enums.dart';
import '../../modules/till/controllers/cart_controller.dart';
import '../settings_service.dart';
import 'display_pages.dart';

/// What the customer display shows.
enum DisplayStage { idle, cart, paying, done }

/// The customer display (SEL-12), the prep screen and "Now serving"
/// (SEL-11), served by the till to any browser on the shop's network: a
/// tablet, a TV or a second monitor. Links carry a secret token, so only
/// someone given the link can open them.
class DisplayService extends GetxService {
  DisplayService(this._db, this._settings);

  final AppDatabase _db;
  final SettingsService _settings;

  static const _tokenKey = 'display.token';

  HttpServer? _server;
  String? token;

  /// Set by checkout.
  final stage = DisplayStage.idle.obs;
  int _due = 0;
  String? _payToName;
  String? _payToNumber;
  int _paidTotal = 0;
  int _change = 0;
  String? _order;
  Timer? _backToIdle;

  /// Promotion names for the idle slideshow, kept by the cart.
  List<String> Function() promotions = () => const [];

  bool get running => _server != null;
  int? get port => _server?.port;

  @override
  void onClose() {
    _backToIdle?.cancel();
    unawaited(stop());
    super.onClose();
  }

  /// Starts or stops the server to match the setting.
  Future<void> apply() async {
    if (_settings.get(AppSettings.displayServer)) {
      await start(port: _settings.get(AppSettings.displayPort));
    } else {
      await stop();
    }
  }

  Future<void> start({int port = 8080}) async {
    if (_server != null) return;
    token = await _db.readMeta(_tokenKey);
    if (token == null) await newToken();
    _server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen((r) => unawaited(_handle(r)));
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  /// A new secret: old links stop working.
  Future<void> newToken() async {
    const chars = 'abcdefghjkmnpqrstuvwxyz23456789';
    final random = Random.secure();
    token = List.generate(10, (_) => chars[random.nextInt(chars.length)]).join();
    await _db.writeMeta(_tokenKey, token!);
  }

  /// This device's addresses on the network, for the links.
  static Future<List<String>> addresses() async {
    final out = <String>[];
    for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4)) {
      for (final a in i.addresses) {
        if (!a.isLoopback) out.add(a.address);
      }
    }
    return out;
  }

  /// The three links on [address].
  ({String customer, String prep, String serving}) links(String address) {
    final base = 'http://$address:${port ?? _settings.get(AppSettings.displayPort)}';
    return (customer: '$base/c/$token', prep: '$base/k/$token', serving: '$base/s/$token');
  }

  // Checkout tells the display what is happening.

  void paying({required int due, String? payToName, String? payToNumber}) {
    _backToIdle?.cancel();
    _due = due;
    _payToName = payToName;
    _payToNumber = payToNumber;
    stage.value = DisplayStage.paying;
  }

  void done({required int total, required int change, String? order}) {
    _paidTotal = total;
    _change = change;
    _order = order;
    stage.value = DisplayStage.done;
    _backToIdle?.cancel();
    _backToIdle = Timer(const Duration(seconds: 20), () => stage.value = DisplayStage.idle);
  }

  void cancelPaying() {
    if (stage.value == DisplayStage.paying) stage.value = DisplayStage.idle;
  }

  Map<String, dynamic> customerState() {
    final cart = Get.isRegistered<CartController>() ? Get.find<CartController>() : null;
    final logo = _settings.get(AppSettings.receiptLogo);
    var s = stage.value;
    if (s == DisplayStage.idle && cart != null && !cart.isEmpty) s = DisplayStage.cart;
    final pricing = cart?.pricing;
    return {
      'stage': s.name,
      'shop': _settings.get(AppSettings.shopName),
      'logo': logo.isEmpty ? null : 'data:image/png;base64,$logo',
      'promotions': promotions(),
      if (pricing != null && s != DisplayStage.done) ...{
        'lines': [
          for (final p in pricing.lines)
            {
              'title': p.line.title,
              'quantity': p.line.quantityText,
              'options': p.line.optionsLine,
              'amount': p.lineNet,
              'deal': p.promotionNames.join(', '),
            },
        ],
        'discount': pricing.discountTotal,
        'total': pricing.total,
      },
      if (s == DisplayStage.paying) ...{
        'due': _due,
        'payToName': _payToName,
        'payToNumber': _payToNumber,
        'qr': _payToNumber == null ? null : qrSvg(_payToNumber!),
      },
      if (s == DisplayStage.done) ...{'paid': _paidTotal, 'change': _change, 'order': _order},
    };
  }

  Future<List<Map<String, dynamic>>> _orders() async {
    final prefix = _settings.get(AppSettings.orderPrefix);
    return [
      for (final o in await Get.find<OrderRepository>().open())
        {
          'id': o.saleId,
          'number': '$prefix${o.number}',
          'status': o.status.name,
          'at': o.at.millisecondsSinceEpoch,
          'customer': o.customerName,
          'note': o.note,
          'lines': [
            for (final l in o.lines) {'title': l.title, 'quantity': l.quantity, 'options': l.options.join(', '), 'note': l.note},
          ],
        },
    ];
  }

  Future<void> _handle(HttpRequest r) async {
    final res = r.response;
    try {
      final parts = r.uri.pathSegments;
      // /c/<token>, /k/<token>, /s/<token>, plus /state, /orders, /orders/<id>/<status>
      if (parts.length < 2 || parts[1] != token) {
        res.statusCode = HttpStatus.notFound;
        res.write('Not found');
        return;
      }
      final page = parts[0];
      final rest = parts.sublist(2);
      if (rest.isEmpty && r.method == 'GET') {
        final html = switch (page) {
          'c' => customerPage,
          'k' => prepPage,
          's' => servingPage,
          _ => null,
        };
        if (html == null) {
          res.statusCode = HttpStatus.notFound;
          return;
        }
        res.headers.contentType = ContentType.html;
        res.write(html);
        return;
      }
      res.headers.contentType = ContentType.json;
      res.headers.set('Cache-Control', 'no-store');
      if (page == 'c' && rest.single == 'state') {
        res.write(jsonEncode(customerState()));
      } else if ((page == 'k' || page == 's') && rest.first == 'orders' && rest.length == 1) {
        res.write(jsonEncode(await _orders()));
      } else if (page == 'k' && rest.first == 'orders' && rest.length == 3 && r.method == 'POST') {
        final status = OrderStatus.values.asNameMap()[rest[2]];
        if (status == null) {
          res.statusCode = HttpStatus.badRequest;
        } else {
          await Get.find<OrderRepository>().setStatus(rest[1], status);
          res.write('{"ok":true}');
        }
      } else {
        res.statusCode = HttpStatus.notFound;
      }
    } on Object catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      res.write(jsonEncode({'error': '$e'}));
    } finally {
      await res.close();
    }
  }
}

/// A QR code as an SVG, for the MoMo number on the customer display.
String qrSvg(String data) {
  final code = QrImage(QrCode.fromData(data: data, errorCorrectLevel: QrErrorCorrectLevel.M));
  final n = code.moduleCount;
  final b = StringBuffer('<svg xmlns="http://www.w3.org/2000/svg" viewBox="-4 -4 ${n + 8} ${n + 8}" shape-rendering="crispEdges">'
      '<rect x="-4" y="-4" width="${n + 8}" height="${n + 8}" fill="#fff"/><path fill="#000" d="');
  for (var y = 0; y < n; y++) {
    for (var x = 0; x < n; x++) {
      if (code.isDark(y, x)) b.write('M$x ${y}h1v1h-1z');
    }
  }
  b.write('"/></svg>');
  return b.toString();
}
