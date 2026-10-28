import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// A drawer event that is not a sale.
class CashEvent {
  const CashEvent({
    required this.id,
    required this.at,
    required this.kind,
    required this.amount,
    required this.reason,
    required this.staffName,
    this.note,
    this.approverName,
    this.hasPhoto = false,
  });

  final String id;
  final DateTime at;
  final CashEventKind kind;

  /// Pesewas: + into the drawer, − out of it; 0 for a no-sale.
  final int amount;
  final String reason;
  final String staffName;
  final String? note;
  final String? approverName;
  final bool hasPhoto;
}

/// Totals of drawer events over a period, for the X and Z reports.
class CashEventTotals {
  const CashEventTotals({this.payIns = 0, this.payOuts = 0, this.safeDrops = 0});

  /// Pesewas, all positive.
  final int payIns;
  final int payOuts;
  final int safeDrops;
}

/// The drawer opened without a sale, cash put in or taken out, and cash
/// dropped to the safe. Recorded with a reason; counted at close day.
class CashEventRepository {
  CashEventRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Future<void> noSale({required String reason, required Staff actor, Staff? approver}) async {
    final clean = reason.trim();
    if (clean.isEmpty) throw ArgumentError('A no-sale needs a reason.');
    await _db.transaction(() async {
      final id = await record(kind: CashEventKind.noSale, amount: 0, reason: clean, actor: actor, approver: approver);
      // The screen opens the drawer (PrintService.openDrawer) once saved.
      await _audit.record(
        action: AuditAction.noSale,
        actor: actor,
        approver: approver,
        entity: 'cash_events',
        entityId: id,
        summary: 'Opened the drawer without a sale: $clean',
      );
    });
  }

  /// Cash into ([payIn]) or out of the drawer that is not a sale. [amount]
  /// is positive either way.
  Future<void> payInOrOut({
    required bool payIn,
    required int amount,
    required String reason,
    String? note,
    Uint8List? photo,
    required Staff actor,
    Staff? approver,
  }) async {
    if (amount <= 0) throw ArgumentError('Enter the amount.');
    if (reason.trim().isEmpty) throw ArgumentError('Pick a reason.');
    await _db.transaction(() async {
      final id = await record(
        kind: payIn ? CashEventKind.payIn : CashEventKind.payOut,
        amount: payIn ? amount : -amount,
        reason: reason.trim(),
        note: note,
        actor: actor,
        approver: approver,
      );
      if (photo != null) await savePhoto(id, photo);
      // The screen opens the drawer (PrintService.openDrawer) once saved.
      await _audit.record(
        action: payIn ? AuditAction.cashPaidIn : AuditAction.cashPaidOut,
        actor: actor,
        approver: approver,
        entity: 'cash_events',
        entityId: id,
        summary: '${payIn ? 'Put' : 'Took'} ${formatMoney(amount)} ${payIn ? 'into' : 'out of'} the drawer: '
            '${reason.trim()}${note == null || note.trim().isEmpty ? '' : ' (${note.trim()})'}',
      );
    });
  }

  /// Writes the event inside the caller's transaction. Returns its ID.
  Future<String> record({
    required CashEventKind kind,
    required int amount,
    required String reason,
    String? note,
    required Staff actor,
    Staff? approver,
  }) async {
    final now = DateTime.now();
    final id = newId();
    await _db.insertTracked(
      _db.cashEvents,
      CashEventsCompanion.insert(
        id: id,
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        kind: kind,
        amount: Value(amount),
        reason: reason,
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
        staffId: actor.id,
        staffName: actor.name,
        approverName: Value(approver?.name),
      ),
    );
    return id;
  }

  Future<void> savePhoto(String ownerId, Uint8List image) => _db.into(_db.receiptPhotos).insertOnConflictUpdate(
        ReceiptPhotosCompanion.insert(ownerId: ownerId, image: image, updatedAt: DateTime.now()),
      );

  Future<Uint8List?> photo(String ownerId) async =>
      (await (_db.select(_db.receiptPhotos)..where((p) => p.ownerId.equals(ownerId))).getSingleOrNull())?.image;

  /// This device's events since [from] (all when null), newest first.
  Future<List<CashEvent>> since(DateTime? from) async {
    final q = _db.select(_db.cashEvents)
      ..where((e) =>
          e.deviceId.equals(_device.deviceId) &
          e.deletedAt.isNull() &
          (from == null ? const Constant(true) : e.createdAt.isBiggerThanValue(from)))
      ..orderBy([
        (e) => OrderingTerm(expression: e.createdAt, mode: OrderingMode.desc),
        (e) => OrderingTerm(expression: e.id, mode: OrderingMode.desc),
      ]);
    final rows = await q.get();
    final photos = rows.isEmpty
        ? const <String>{}
        : {
            for (final p in await (_db.selectOnly(_db.receiptPhotos)
                  ..addColumns([_db.receiptPhotos.ownerId])
                  ..where(_db.receiptPhotos.ownerId.isIn(rows.map((r) => r.id))))
                .get())
              p.read(_db.receiptPhotos.ownerId)!,
          };
    return [
      for (final r in rows)
        CashEvent(
          id: r.id,
          at: r.createdAt,
          kind: r.kind,
          amount: r.amount,
          reason: r.reason,
          staffName: r.staffName,
          note: r.note,
          approverName: r.approverName,
          hasPhoto: photos.contains(r.id),
        ),
    ];
  }

  Future<CashEventTotals> totalsSince(DateTime? from) async {
    var payIns = 0, payOuts = 0, drops = 0;
    for (final e in await since(from)) {
      switch (e.kind) {
        case CashEventKind.payIn:
          payIns += e.amount;
        case CashEventKind.payOut:
          payOuts -= e.amount;
        case CashEventKind.safeDrop:
          drops -= e.amount;
        case CashEventKind.noSale:
          break;
      }
    }
    return CashEventTotals(payIns: payIns, payOuts: payOuts, safeDrops: drops);
  }

  /// No-sales on this device since [from] (all time when null), per person.
  Future<Map<String, int>> noSalesSince(DateTime? from) async {
    final out = <String, int>{};
    for (final e in (await since(from)).where((e) => e.kind == CashEventKind.noSale)) {
      out[e.staffName] = (out[e.staffName] ?? 0) + 1;
    }
    return out;
  }
}
