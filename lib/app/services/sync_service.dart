import 'dart:async';

import 'package:get/get.dart';

import '../data/repositories/outbox_repository.dart';

/// What the header and status centre show about sync: what is waiting, and
/// whether this device reaches its hub (MDV-01). The hub service fills
/// [linked], [online] and [problem]; the cloud later will too.
class SyncService extends GetxService {
  SyncService(this._outbox);

  final OutboxRepository _outbox;

  /// Sales saved on this device and not yet on the server.
  final waitingSales = 0.obs;

  /// Whether this device syncs with anything (it is a hub or a member).
  final linked = false.obs;

  /// Whether the last sync went through.
  final online = false.obs;

  /// Why the last sync failed.
  final problem = RxnString();

  StreamSubscription<int>? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = _outbox.watchPendingSalesCount().listen(waitingSales.call);
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
