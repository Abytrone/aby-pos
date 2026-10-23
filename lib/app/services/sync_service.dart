import 'dart:async';

import 'package:get/get.dart';

import '../data/repositories/outbox_repository.dart';

/// Watches the outbox so the header can show what is waiting to sync.
///
/// TODO(sync): this is a stub. The sync engine will read
/// [OutboxRepository.pending], send batches to the Laravel API, call
/// [OutboxRepository.acknowledge] and pull server changes. Until then nothing
/// leaves the device and [online] stays false; there are no network calls.
class SyncService extends GetxService {
  SyncService(this._outbox);

  final OutboxRepository _outbox;

  /// Sales saved on this device and not yet on the server.
  final waitingSales = 0.obs;

  /// Whether the sync engine can reach the server.
  final online = false.obs;

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
