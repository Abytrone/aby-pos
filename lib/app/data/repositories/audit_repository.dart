import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../database/app_database.dart';

/// The tamper-evident audit log. Every entry stores the hash of the one
/// before it (per device), so editing or removing a row in the database file
/// breaks the chain and [verifyChain] finds it.
class AuditRepository {
  AuditRepository(this._db, this._device);

  final AppDatabase _db;
  final DeviceInfo _device;

  static final genesisHash = '0' * 64;

  /// Appends an entry. Call inside the transaction of the action it records,
  /// so the action and its entry are saved together.
  Future<AuditEntry> record({
    required AuditAction action,
    required String summary,
    Staff? actor,
    String? actorId,
    String? actorName,
    Staff? approver,
    String? entity,
    String? entityId,
    Map<String, dynamic>? details,
  }) {
    return _db.transaction(() async {
      final last = await (_db.select(_db.auditLog)
            ..where((a) => a.deviceId.equals(_device.deviceId))
            ..orderBy([(a) => OrderingTerm(expression: a.seq, mode: OrderingMode.desc)])
            ..limit(1))
          .getSingleOrNull();
      final now = DateTime.now();
      final fields = _HashFields(
        seq: (last?.seq ?? 0) + 1,
        deviceId: _device.deviceId,
        atMs: now.toUtc().millisecondsSinceEpoch,
        action: action.name,
        actorId: actor?.id ?? actorId,
        actorName: actor?.name ?? actorName,
        approverId: approver?.id,
        approverName: approver?.name,
        entity: entity,
        entityId: entityId,
        summary: summary,
        details: details == null ? null : jsonEncode(details),
        prevHash: last?.hash ?? genesisHash,
      );
      final row = await _db.insertTracked(
        _db.auditLog,
        AuditLogCompanion.insert(
          id: newId(),
          createdAt: now,
          updatedAt: now,
          deviceId: fields.deviceId,
          seq: fields.seq,
          atMs: fields.atMs,
          action: action,
          actorId: Value(fields.actorId),
          actorName: Value(fields.actorName),
          approverId: Value(fields.approverId),
          approverName: Value(fields.approverName),
          entity: Value(fields.entity),
          entityId: Value(fields.entityId),
          summary: summary,
          details: Value(fields.details),
          prevHash: fields.prevHash,
          hash: fields.hash(),
        ),
      );
      return _toEntry(row);
    });
  }

  /// Newest first.
  Future<List<AuditEntry>> list({
    String? actorId,
    Set<AuditAction>? actions,
    DateTime? from,
    DateTime? to,
    int limit = 200,
  }) async {
    final query = _db.select(_db.auditLog)
      ..orderBy([
        (a) => OrderingTerm(expression: a.atMs, mode: OrderingMode.desc),
        (a) => OrderingTerm(expression: a.seq, mode: OrderingMode.desc),
      ])
      ..limit(limit);
    if (actorId != null) {
      query.where((a) => a.actorId.equals(actorId) | a.approverId.equals(actorId));
    }
    if (actions != null && actions.isNotEmpty) {
      query.where((a) => a.action.isIn(actions.map((e) => e.name)));
    }
    if (from != null) {
      query.where((a) => a.atMs.isBiggerOrEqualValue(from.toUtc().millisecondsSinceEpoch));
    }
    if (to != null) {
      query.where((a) => a.atMs.isSmallerThanValue(to.toUtc().millisecondsSinceEpoch));
    }
    return (await query.get()).map(_toEntry).toList();
  }

  /// Walks every device's chain in order. Reports the first entry whose
  /// hash does not match its contents, whose link does not match the entry
  /// before, or that is missing from the sequence.
  Future<AuditChainStatus> verifyChain() async {
    final rows = await (_db.select(_db.auditLog)
          ..orderBy([
            (a) => OrderingTerm(expression: a.deviceId),
            (a) => OrderingTerm(expression: a.seq),
          ]))
        .get();
    String? device;
    var expectedSeq = 1;
    var prev = genesisHash;
    for (final r in rows) {
      if (r.deviceId != device) {
        device = r.deviceId;
        expectedSeq = 1;
        prev = genesisHash;
      }
      final recomputed = _HashFields(
        seq: r.seq,
        deviceId: r.deviceId,
        atMs: r.atMs,
        action: r.action.name,
        actorId: r.actorId,
        actorName: r.actorName,
        approverId: r.approverId,
        approverName: r.approverName,
        entity: r.entity,
        entityId: r.entityId,
        summary: r.summary,
        details: r.details,
        prevHash: r.prevHash,
      ).hash();
      if (r.seq != expectedSeq || r.prevHash != prev || r.hash != recomputed) {
        return AuditChainStatus.broken(rows.length, r.seq);
      }
      prev = r.hash;
      expectedSeq++;
    }
    return AuditChainStatus.ok(rows.length);
  }

  AuditEntry _toEntry(AuditRow r) => AuditEntry(
        id: r.id,
        seq: r.seq,
        at: DateTime.fromMillisecondsSinceEpoch(r.atMs, isUtc: true).toLocal(),
        deviceId: r.deviceId,
        action: r.action,
        actorId: r.actorId,
        actorName: r.actorName,
        approverId: r.approverId,
        approverName: r.approverName,
        entity: r.entity,
        entityId: r.entityId,
        summary: r.summary,
        details: r.details == null
            ? null
            : Map<String, dynamic>.from(jsonDecode(r.details!) as Map),
      );
}

class _HashFields {
  _HashFields({
    required this.seq,
    required this.deviceId,
    required this.atMs,
    required this.action,
    required this.actorId,
    required this.actorName,
    required this.approverId,
    required this.approverName,
    required this.entity,
    required this.entityId,
    required this.summary,
    required this.details,
    required this.prevHash,
  });

  final int seq;
  final String deviceId;
  final int atMs;
  final String action;
  final String? actorId;
  final String? actorName;
  final String? approverId;
  final String? approverName;
  final String? entity;
  final String? entityId;
  final String summary;
  final String? details;
  final String prevHash;

  /// SHA-256 over the fields joined with a unit separator, which cannot
  /// appear in names or JSON.
  String hash() => sha256
      .convert(utf8.encode([
        'v1',
        seq,
        deviceId,
        atMs,
        action,
        actorId ?? '',
        actorName ?? '',
        approverId ?? '',
        approverName ?? '',
        entity ?? '',
        entityId ?? '',
        summary,
        details ?? '',
        prevHash,
      ].join('\u001f')))
      .toString();
}
