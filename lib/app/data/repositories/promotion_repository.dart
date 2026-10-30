import 'package:clock/clock.dart';
import 'package:drift/drift.dart';

import '../../domain/promotions.dart';
import '../../models/audit.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

/// Automatic promotions (Settings → Promotions).
class PromotionRepository {
  PromotionRepository(this._db, this._device, this._audit);

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;

  Promotion _from(PromotionRow r) => Promotion(
        id: r.id,
        name: r.name,
        kind: r.kind,
        rule: PromoRule.decode(r.rule),
        startsOn: r.startsOn,
        endsOn: r.endsOn,
        days: r.days,
        fromMinute: r.fromMinute,
        toMinute: r.toMinute,
        stackable: r.stackable,
        active: r.active,
      );

  SimpleSelectStatement<$PromotionsTable, PromotionRow> _query() => _db.select(_db.promotions)
    ..where((p) => p.deletedAt.isNull())
    ..orderBy([(p) => OrderingTerm(expression: p.name)]);

  Future<List<Promotion>> list() async => [for (final r in await _query().get()) _from(r)];

  /// Every promotion, again whenever one changes (the cart keeps it).
  Stream<List<Promotion>> watch() => _query().watch().map((rows) => [for (final r in rows) _from(r)]);

  /// Saves a new promotion ([Promotion.id] empty) or changes one. Returns
  /// its ID.
  Future<String> save(Promotion p, {required Staff by}) {
    final name = p.name.trim();
    if (name.isEmpty) throw ArgumentError('A promotion needs a name.');
    return _db.transaction(() async {
      final now = clock.now();
      final existing = p.id.isEmpty
          ? null
          : await (_db.select(_db.promotions)..where((x) => x.id.equals(p.id))).getSingleOrNull();
      final id = existing?.id ?? newId();
      if (existing == null) {
        await _db.insertTracked(
          _db.promotions,
          PromotionsCompanion.insert(
            id: id,
            createdAt: now,
            updatedAt: now,
            deviceId: _device.deviceId,
            name: name,
            kind: p.kind,
            rule: p.rule.encode(),
            startsOn: Value(p.startsOn),
            endsOn: Value(p.endsOn),
            days: Value(p.days),
            fromMinute: Value(p.fromMinute),
            toMinute: Value(p.toMinute),
            stackable: Value(p.stackable),
            active: Value(p.active),
          ),
        );
      } else {
        await _db.updateTracked(
          _db.promotions,
          existing.copyWith(
            updatedAt: now,
            name: name,
            kind: p.kind,
            rule: p.rule.encode(),
            startsOn: Value(p.startsOn),
            endsOn: Value(p.endsOn),
            days: p.days,
            fromMinute: Value(p.fromMinute),
            toMinute: Value(p.toMinute),
            stackable: p.stackable,
            active: p.active,
          ),
        );
      }
      await _audit.record(
        action: AuditAction.promotionSaved,
        actor: by,
        entity: 'promotions',
        entityId: id,
        summary: '${existing == null ? 'Added' : 'Changed'} the promotion $name${p.active ? '' : ' (off)'}',
      );
      return id;
    });
  }

  Future<void> delete(String id, {required Staff by}) => _db.transaction(() async {
        final row = await (_db.select(_db.promotions)..where((x) => x.id.equals(id))).getSingle();
        final now = clock.now();
        await _db.updateTracked(_db.promotions, row.copyWith(deletedAt: Value(now), updatedAt: now));
        await _audit.record(
          action: AuditAction.promotionSaved,
          actor: by,
          entity: 'promotions',
          entityId: id,
          summary: 'Deleted the promotion ${row.name}',
        );
      });
}
