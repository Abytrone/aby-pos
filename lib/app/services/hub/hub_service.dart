import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show OrderingTerm, UpdateKind, Value, Variable;
import 'package:get/get.dart' hide Value;

import '../../data/database/app_database.dart';
import '../../data/sync/row_store.dart';
import '../device_service.dart';
import '../sync_service.dart';
import 'sealed_box.dart';

enum HubRole { none, hub, member }

/// A one-time offer to join the hub: shown as a QR code (and typed by hand
/// when there is no camera).
class PairingOffer {
  const PairingOffer({required this.code, required this.hubId, required this.urls, required this.expires});

  final String code;
  final String hubId;
  final List<String> urls;
  final DateTime expires;

  static const _prefix = 'ABY-HUB:';

  String get qr => '$_prefix${jsonEncode({'u': urls, 'c': code, 'h': hubId})}';

  /// The letters pairing codes are made of: no 0/O or 1/I/L to mix up.
  static const codeChars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static const codeLength = 8;

  /// A typed code as the hub made it: capitals, without the dash or
  /// spaces people type ("abcd-efgh" is "ABCDEFGH").
  static String normalizeCode(String typed) => typed.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');

  /// "ABCD-EFGH": easier to read out across a counter.
  static String formatCode(String code) {
    final c = normalizeCode(code);
    return c.length <= 4 ? c : '${c.substring(0, 4)}-${c.substring(4)}';
  }

  /// (addresses, code, hub ID) from a scanned QR code, or null.
  static (List<String>, String, String)? parse(String text) {
    final t = text.trim();
    if (!t.startsWith(_prefix)) return null;
    try {
      final m = jsonDecode(t.substring(_prefix.length)) as Map<String, dynamic>;
      return ((m['u'] as List).cast<String>(), m['c'] as String, m['h'] as String);
    } on Object {
      return null;
    }
  }
}

/// A hub heard on this Wi-Fi: where it is, and the shop it belongs to.
class FoundHub {
  const FoundHub({required this.id, required this.url, required this.name});

  final String id;
  final String url;
  final String name;

  /// "192.168.1.20:8787"
  String get address => url.replaceFirst('http://', '');
}

/// What went wrong between a device and its hub; shown in the device's
/// language, so it goes over the wire by name.
enum HubError { alreadyLinked, noCode, tooManyTries, wrongCode, notPaired, revoked, unreachable, refused }

class HubException implements Exception {
  const HubException(this.error);

  factory HubException.from(String body) {
    try {
      return HubException(HubError.values.asNameMap()[(jsonDecode(body) as Map)['error']] ?? HubError.refused);
    } on Object {
      return const HubException(HubError.refused);
    }
  }

  final HubError error;

  @override
  String toString() => 'HubException(${error.name})';
}

/// The local hub (MDV-01): one device serves the others over the shop's
/// Wi-Fi, no internet needed. Members send their outbox and pull everyone
/// else's changes; the hub keeps the change log. Everything after pairing
/// is sealed with the device's own secret. When the network drops, each
/// device carries on and catches up later.
class HubService extends GetxService {
  HubService(this._db, this._device,
      {this.sync, this.port = 8787, this.beaconPort = 47878, this.every = const Duration(seconds: 3)})
      : store = RowStore(_db);

  /// Shown in the header and status centre.
  final SyncService? sync;

  final AppDatabase _db;
  final DeviceInfo _device;
  final RowStore store;

  /// Where the hub listens, and where it announces itself.
  final int port;
  final int beaconPort;
  final Duration every;

  static const appVersion = '1.0.0';
  static const _kRole = 'hub.role', _kUrl = 'hub.url', _kSecret = 'hub.secret', _kId = 'hub.id', _kCursor = 'hub.cursor';
  static const _kName = 'hub.name';

  final role = HubRole.none.obs;
  final online = false.obs;
  final lastSync = Rxn<DateTime>();
  final problem = Rxn<HubError>();

  /// The pairing code on offer (hub), if any.
  final offer = Rxn<PairingOffer>();
  int _pairTries = 0;

  HttpServer? _server;
  RawDatagramSocket? _beacon;
  Timer? _timer;
  bool _busy = false;

  int? get boundPort => _server?.port;

  final _workers = <Worker>[];

  @override
  void onInit() {
    super.onInit();
    final s = sync;
    if (s == null) return;
    _workers.addAll([
      ever(role, (HubRole r) => s.linked.value = r != HubRole.none),
      ever(online, (bool o) => s.online.value = o),
      ever(problem, (HubError? p) => s.problem.value = p?.name),
    ]);
  }

  @override
  void onClose() {
    for (final w in _workers) {
      w.dispose();
    }
    unawaited(stop());
    super.onClose();
  }

  /// On app start: carries on as hub or member.
  Future<void> start() async {
    role.value = HubRole.values.asNameMap()[await _db.readMeta(_kRole)] ?? HubRole.none;
    if (role.value == HubRole.hub) await _startHub();
    if (role.value == HubRole.member) _startMember();
  }

  Future<void> stop() async {
    _timer?.cancel();
    _timer = null;
    _beacon?.close();
    _beacon = null;
    await _server?.close(force: true);
    _server = null;
  }

  // ---------------------------------------------------------------------------
  // The hub

  /// Makes this device the hub: its data starts the change log.
  Future<void> becomeHub() async {
    if (role.value != HubRole.none) throw const HubException(HubError.alreadyLinked);
    final now = DateTime.now();
    await _db.transaction(() async {
      await for (final w in store.everything()) {
        await _db.into(_db.hubChanges).insert(HubChangesCompanion.insert(
              entity: w.entity,
              recordId: w.id,
              row: jsonEncode(w.row),
              originDevice: _device.deviceId,
              at: now,
            ));
      }
      // All of it is in the log now.
      await _db.delete(_db.outbox).go();
      await _db.writeMeta(_kRole, HubRole.hub.name);
      await _db.writeMeta(_kId, _device.deviceId);
    });
    role.value = HubRole.hub;
    await _startHub();
  }

  Future<void> _startHub() async {
    _server ??= await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
    _server!.listen((r) => unawaited(_handle(r)));
    try {
      _beacon ??= await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0)..broadcastEnabled = true;
    } on SocketException {
      _beacon = null;
    }
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => unawaited(_hubTick()));
    online.value = true;
  }

  /// The hub's own changes go into the log; it says where it is.
  Future<void> _hubTick() async {
    if (_busy) return;
    _busy = true;
    try {
      await drainOwnOutbox();
      final b = _beacon;
      if (b != null) {
        final msg = utf8.encode(jsonEncode({'aby': 'hub', 'h': _device.deviceId, 'p': boundPort}));
        try {
          b.send(msg, InternetAddress('255.255.255.255'), beaconPort);
        } on Object {
          // No broadcast on this network: members use the saved address.
        }
      }
    } finally {
      _busy = false;
    }
  }

  /// Moves the hub's own changes into the change log.
  Future<void> drainOwnOutbox() async {
    while (true) {
      final batch = await store.pending();
      if (batch.isEmpty) return;
      final now = DateTime.now();
      await _db.transaction(() async {
        for (final w in batch.rows) {
          await _db.into(_db.hubChanges).insert(HubChangesCompanion.insert(
                entity: w.entity,
                recordId: w.id,
                row: jsonEncode(w.row),
                originDevice: _device.deviceId,
                at: now,
              ));
        }
        await store.acknowledge(batch.outboxSeqs);
      });
      lastSync.value = now;
    }
  }

  /// A one-time code for a new device, good for 10 minutes.
  Future<PairingOffer> offerPairing() async {
    const chars = PairingOffer.codeChars;
    final r = Random.secure();
    final code = List.generate(PairingOffer.codeLength, (_) => chars[r.nextInt(chars.length)]).join();
    final p = boundPort ?? port;
    final urls = [for (final a in await addresses()) 'http://$a:$p'];
    _pairTries = 0;
    return offer.value = PairingOffer(code: code, hubId: _device.deviceId, urls: urls, expires: DateTime.now().add(const Duration(minutes: 10)));
  }

  static Future<List<String>> addresses() async => [
        for (final i in await NetworkInterface.list(type: InternetAddressType.IPv4))
          for (final a in i.addresses)
            if (!a.isLoopback) a.address,
      ];

  Future<List<HubDeviceRow>> devices() => (_db.select(_db.hubDevices)..orderBy([(d) => OrderingTerm(expression: d.pairedAt)])).get();

  Future<void> updateDevice(String deviceId, {String? name, String? role}) async {
    final d = await (_db.select(_db.hubDevices)..where((x) => x.deviceId.equals(deviceId))).getSingle();
    await _db.update(_db.hubDevices).replace(d.copyWith(name: name ?? d.name, role: role ?? d.role));
  }

  /// A lost device can no longer reach the hub; what it sent is kept.
  Future<void> revoke(String deviceId) async {
    final d = await (_db.select(_db.hubDevices)..where((x) => x.deviceId.equals(deviceId))).getSingle();
    await _db.update(_db.hubDevices).replace(d.copyWith(revokedAt: Value(DateTime.now())));
  }

  Future<void> _handle(HttpRequest r) async {
    final res = r.response;
    res.headers.contentType = ContentType.json;
    try {
      final path = r.uri.path;
      if (r.method == 'GET' && path == '/hello') {
        res.write(jsonEncode({'aby': 'hub', 'h': _device.deviceId, 'name': await _db.readMeta('shop_name') ?? 'Aby', 'v': appVersion}));
        return;
      }
      final body = await utf8.decoder.bind(r).join();
      final deviceId = r.headers.value('x-aby-device') ?? '';
      if (r.method == 'POST' && path == '/pair') {
        res.write(await _pair(deviceId, body));
      } else if (r.method == 'POST' && path == '/sync') {
        res.write(await _sync(deviceId, body));
      } else {
        res.statusCode = HttpStatus.notFound;
      }
    } on HubException catch (e) {
      res.statusCode = HttpStatus.forbidden;
      res.write(jsonEncode({'error': e.error.name}));
    } on Object catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      res.write(jsonEncode({'error': '$e'}));
    } finally {
      await res.close();
    }
  }

  Future<String> _pair(String deviceId, String body) async {
    final o = offer.value;
    if (o == null || DateTime.now().isAfter(o.expires)) throw const HubException(HubError.noCode);
    if (++_pairTries > 5) {
      offer.value = null;
      throw const HubException(HubError.tooManyTries);
    }
    final key = await SealedBox.keyFromCode(o.code, o.hubId);
    final Map<String, dynamic> hello;
    try {
      hello = (await SealedBox.open(body, key))! as Map<String, dynamic>;
    } on Object {
      throw const HubException(HubError.wrongCode);
    }
    if (hello['d'] != deviceId) throw const HubException(HubError.wrongCode);
    final secret = SealedBox.newSecret();
    final now = DateTime.now();
    await _db.into(_db.hubDevices).insertOnConflictUpdate(HubDevicesCompanion.insert(
          deviceId: deviceId,
          name: (hello['n'] as String?)?.trim().isNotEmpty ?? false ? hello['n'] as String : 'Device',
          secret: secret,
          pairedAt: now,
          lastSeenAt: Value(now),
          appVersion: Value(hello['v'] as String?),
          revokedAt: const Value(null),
        ));
    offer.value = null;
    return SealedBox.seal({'s': secret, 'h': _device.deviceId}, key);
  }

  Future<String> _sync(String deviceId, String body) async {
    final d = await (_db.select(_db.hubDevices)..where((x) => x.deviceId.equals(deviceId))).getSingleOrNull();
    if (d == null) throw const HubException(HubError.notPaired);
    if (d.revokedAt != null) throw const HubException(HubError.revoked);
    final req = (await SealedBox.open(body, d.secret))! as Map<String, dynamic>;
    final push = [for (final j in (req['push'] as List? ?? const [])) WireRow.fromJson((j as Map).cast<String, dynamic>())];
    final since = req['since'] as int? ?? 0;
    final now = DateTime.now();
    var rejected = 0;
    await _db.transaction(() async {
      for (final w in push) {
        try {
          await store.apply(w);
        } on Object {
          rejected++;
        }
        // Every version goes in the log, the losing ones too (history).
        await _db.into(_db.hubChanges).insert(HubChangesCompanion.insert(
              entity: w.entity,
              recordId: w.id,
              row: jsonEncode(w.row),
              originDevice: deviceId,
              at: now,
            ));
      }
      await _db.update(_db.hubDevices).replace(d.copyWith(lastSeenAt: Value(now), appVersion: Value(req['v'] as String? ?? d.appVersion)));
    });
    final rows = await _db.customSelect(
      'SELECT * FROM hub_changes WHERE seq > ? ORDER BY seq LIMIT 400',
      variables: [Variable.withInt(since)],
      readsFrom: {_db.hubChanges},
    ).get();
    final pull = [
      for (final r in rows)
        if (r.read<String>('origin_device') != deviceId)
          WireRow(r.read<String>('entity'), r.read<String>('record_id'), (jsonDecode(r.read<String>('row')) as Map).cast<String, Object?>())
              .toJson(),
    ];
    final cursor = rows.isEmpty ? since : rows.last.read<int>('seq');
    return SealedBox.seal({'pull': pull, 'cursor': cursor, 'more': rows.length == 400, 'rejected': rejected}, d.secret);
  }

  // ---------------------------------------------------------------------------
  // A member

  /// Joins the hub at one of [urls] with its one-time [code]. Everything on
  /// this device is then sent to the hub (merge), and the hub's data comes
  /// back, except shop settings: the shop's are the hub's, so this device's
  /// own are dropped rather than sent. Returns nothing, or throws
  /// [HubException].
  ///
  /// [fresh]: a new install joining from its first screen. It has only the
  /// starting defaults, which would otherwise win over the hub's edits (they
  /// are newer) or appear twice, so they are cleared and nothing is sent.
  Future<void> join(List<String> urls, String code, {String? hubId, String? deviceName, bool fresh = false}) async {
    if (role.value != HubRole.none) throw const HubException(HubError.alreadyLinked);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      String? url;
      String? id = hubId;
      for (final u in urls) {
        try {
          final hello = jsonDecode(await _get(client, '$u/hello')) as Map<String, dynamic>;
          if (hello['aby'] == 'hub' && (id == null || hello['h'] == id)) {
            url = u;
            id = hello['h'] as String;
            break;
          }
        } on Object {
          continue;
        }
      }
      if (url == null || id == null) throw const HubException(HubError.unreachable);
      final key = await SealedBox.keyFromCode(PairingOffer.normalizeCode(code), id);
      final body = await SealedBox.seal({'d': _device.deviceId, 'n': deviceName ?? '', 'v': appVersion}, key);
      final (status, text) = await _post(client, '$url/pair', body, deviceId: _device.deviceId);
      if (status != 200) throw HubException.from(text);
      final reply = (await SealedBox.open(text, key))! as Map<String, dynamic>;
      // Set up more recently, they would otherwise win over the hub's.
      await _db.customUpdate("DELETE FROM settings WHERE scope = 'shop'", updates: {_db.settings}, updateKind: UpdateKind.delete);
      if (fresh) {
        await _clearDefaults();
      } else {
        await store.enqueueEverything();
      }
      await _db.writeMeta(_kUrl, url);
      await _db.writeMeta(_kId, id);
      await _db.writeMeta(_kSecret, reply['s'] as String);
      await _db.writeMeta(_kCursor, '0');
      if (deviceName != null) await _db.writeMeta(_kName, deviceName);
      await _db.writeMeta(_kRole, HubRole.member.name);
      role.value = HubRole.member;
    } finally {
      client.close(force: true);
    }
    _startMember();
    await syncNow();
  }

  /// Empties every synced table but this device's own settings, so the hub's
  /// rows come in as they are.
  Future<void> _clearDefaults() async {
    await _db.customStatement('PRAGMA foreign_keys = OFF');
    try {
      await _db.transaction(() async {
        for (final name in store.synced.keys) {
          if (name != _db.settings.actualTableName) await _db.customStatement('DELETE FROM $name');
        }
        await _db.delete(_db.outbox).go();
      });
    } finally {
      await _db.customStatement('PRAGMA foreign_keys = ON');
    }
  }

  void _startMember() {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => unawaited(syncNow()));
  }

  /// Sends what is waiting and takes what is new, until both are done.
  Future<void> syncNow() async {
    if (_busy || role.value != HubRole.member) return;
    _busy = true;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final url = await _db.readMeta(_kUrl);
      final secret = await _db.readMeta(_kSecret);
      if (url == null || secret == null) return;
      var more = true;
      while (more) {
        final batch = await store.pending();
        final since = int.tryParse(await _db.readMeta(_kCursor) ?? '0') ?? 0;
        final body = await SealedBox.seal({'push': [for (final w in batch.rows) w.toJson()], 'since': since, 'v': appVersion}, secret);
        final (status, text) = await _post(client, '$url/sync', body, deviceId: _device.deviceId);
        if (status != 200) throw HubException.from(text);
        final reply = (await SealedBox.open(text, secret))! as Map<String, dynamic>;
        final pull = [for (final j in reply['pull'] as List) WireRow.fromJson((j as Map).cast<String, dynamic>())];
        await _db.transaction(() async {
          for (final w in pull) {
            try {
              await store.apply(w);
            } on Object {
              // A row this device cannot take (a newer version of Aby, say).
            }
          }
          await store.acknowledge(batch.outboxSeqs);
          await _db.writeMeta(_kCursor, '${reply['cursor']}');
        });
        more = reply['more'] == true || batch.outboxSeqs.length >= 300;
      }
      online.value = true;
      problem.value = null;
      lastSync.value = DateTime.now();
    } on HubException catch (e) {
      online.value = false;
      problem.value = e.error;
    } on Object {
      online.value = false;
      problem.value = HubError.unreachable;
      unawaited(_findHub());
    } finally {
      client.close(force: true);
      _busy = false;
    }
  }

  /// Hubs announcing themselves on this Wi-Fi, heard for up to [listen]
  /// (a hub calls out every few seconds). Each is checked by asking it to
  /// say hello, so only a hub that answers is offered. Empty when none is
  /// heard, or when this network blocks broadcasts.
  Future<List<FoundHub>> discover({Duration listen = const Duration(seconds: 4)}) async {
    final heard = <String, String>{};
    RawDatagramSocket? s;
    try {
      s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, beaconPort, reuseAddress: true);
      final socket = s;
      final done = Completer<void>();
      final timer = Timer(listen, () => done.isCompleted ? null : done.complete());
      socket.listen((e) {
        if (e != RawSocketEvent.read) return;
        final d = socket.receive();
        if (d == null) return;
        try {
          final m = jsonDecode(utf8.decode(d.data)) as Map<String, dynamic>;
          final id = m['h'];
          if (m['aby'] == 'hub' && id is String && id != _device.deviceId) {
            heard[id] = 'http://${d.address.address}:${m['p']}';
          }
        } on Object {
          // Not a hub.
        }
      });
      await done.future;
      timer.cancel();
    } on Object {
      // Cannot listen on this device or network.
    } finally {
      s?.close();
    }
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
    try {
      final found = <FoundHub>[];
      for (final MapEntry(key: id, value: url) in heard.entries) {
        try {
          final hello = jsonDecode(await _get(client, '$url/hello')) as Map<String, dynamic>;
          if (hello['aby'] == 'hub' && hello['h'] == id) {
            found.add(FoundHub(id: id, url: url, name: hello['name'] as String? ?? 'Aby'));
          }
        } on Object {
          continue;
        }
      }
      return found;
    } finally {
      client.close(force: true);
    }
  }

  /// The hub moved (a new address on the Wi-Fi): listen for its beacon.
  Future<void> _findHub() async {
    final hubId = await _db.readMeta(_kId);
    if (hubId == null) return;
    RawDatagramSocket? s;
    try {
      s = await RawDatagramSocket.bind(InternetAddress.anyIPv4, beaconPort, reuseAddress: true);
      final found = Completer<String?>();
      s.listen((e) {
        if (e != RawSocketEvent.read || found.isCompleted) return;
        final d = s!.receive();
        if (d == null) return;
        try {
          final m = jsonDecode(utf8.decode(d.data)) as Map<String, dynamic>;
          if (m['aby'] == 'hub' && m['h'] == hubId) found.complete('http://${d.address.address}:${m['p']}');
        } on Object {
          // Not ours.
        }
      });
      final url = await found.future.timeout(const Duration(seconds: 8), onTimeout: () => null);
      if (url != null) await _db.writeMeta(_kUrl, url);
    } on Object {
      // Cannot listen here; try again next time.
    } finally {
      s?.close();
    }
  }

  /// Stops syncing. This device keeps its data and works alone.
  Future<void> leave() async {
    await stop();
    for (final k in [_kRole, _kUrl, _kSecret, _kId, _kCursor, _kName]) {
      await _db.deleteMeta(k);
    }
    role.value = HubRole.none;
    online.value = false;
  }

  /// Names that appear twice after merging (products, customers, staff), to
  /// tidy up by hand.
  Future<List<(String, String)>> duplicates() async {
    final out = <(String, String)>[];
    for (final (table, kind) in [('products', 'product'), ('customers', 'customer'), ('staff', 'staff')]) {
      final rows = await _db.customSelect(
        'SELECT MIN(name) AS name FROM $table WHERE deleted_at IS NULL GROUP BY LOWER(TRIM(name)) HAVING COUNT(*) > 1',
      ).get();
      out.addAll([for (final r in rows) (kind, r.read<String>('name'))]);
    }
    return out;
  }

  static Future<String> _get(HttpClient c, String url) async {
    final req = await c.getUrl(Uri.parse(url)).timeout(const Duration(seconds: 5));
    final res = await req.close().timeout(const Duration(seconds: 10));
    return utf8.decoder.bind(res).join();
  }

  static Future<(int, String)> _post(HttpClient c, String url, String body, {String? deviceId}) async {
    final req = await c.postUrl(Uri.parse(url)).timeout(const Duration(seconds: 5));
    req.headers.contentType = ContentType.json;
    if (deviceId != null) req.headers.set('x-aby-device', deviceId);
    req.write(body);
    final res = await req.close().timeout(const Duration(seconds: 30));
    return (res.statusCode, await utf8.decoder.bind(res).join());
  }
}
