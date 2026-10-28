import 'dart:math';

import 'package:drift/drift.dart';

import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/sale.dart';
import '../../models/staff.dart';
import '../../services/device_service.dart';
import '../../services/ids.dart';
import '../../services/money.dart';
import '../database/app_database.dart';
import 'audit_repository.dart';

class VoucherException implements Exception {
  const VoucherException(this.message);

  final String message;

  @override
  String toString() => message;
}

class GiftVoucher {
  const GiftVoucher({
    required this.id,
    required this.code,
    required this.amount,
    required this.balance,
    required this.issuedAt,
    required this.byName,
    this.expiresOn,
    this.customerId,
    this.note,
  });

  final String id;
  final String code;

  /// Pesewas it was sold for, and what is left.
  final int amount;
  final int balance;
  final DateTime issuedAt;
  final String byName;
  final DateTime? expiresOn;
  final String? customerId;
  final String? note;

  /// Past its last day.
  bool expiredAt(DateTime at) {
    final last = expiresOn;
    if (last == null) return false;
    return DateTime(at.year, at.month, at.day).isAfter(DateTime(last.year, last.month, last.day));
  }
}

/// Gift vouchers (CUS-05): sold as money in, spent as a payment. Each
/// voucher's balance is the sum of its entries.
class VoucherRepository {
  VoucherRepository(this._db, this._device, this._audit, {Random? random}) : _random = random ?? Random.secure();

  final AppDatabase _db;
  final DeviceInfo _device;
  final AuditRepository _audit;
  final Random _random;

  // No 0 / O or 1 / I / L: codes are read aloud and typed at the till.
  static const _alphabet = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

  /// "SCP-7KQ4": three letters of the shop's name and four random ones.
  String newCode(String shopName) {
    final letters = '${shopName.toUpperCase().replaceAll(RegExp('[^A-Z]'), '')}ABY';
    final random = List.generate(4, (_) => _alphabet[_random.nextInt(_alphabet.length)]).join();
    return '${letters.substring(0, 3)}-$random';
  }

  /// Codes as typed or scanned: case and spaces do not matter.
  static String normalise(String code) => code.trim().toUpperCase().replaceAll(' ', '');

  Future<Map<String, int>> _balances([String? voucherId]) async {
    final rows = await _db.customSelect(
      'SELECT voucher_id AS id, COALESCE(SUM(amount), 0) AS b FROM voucher_entries WHERE deleted_at IS NULL '
      '${voucherId == null ? '' : 'AND voucher_id = ?'} GROUP BY voucher_id',
      variables: [if (voucherId != null) Variable.withString(voucherId)],
      readsFrom: {_db.voucherEntries},
    ).get();
    return {for (final r in rows) r.read<String>('id'): r.read<int>('b')};
  }

  GiftVoucher _toModel(GiftVoucherRow r, int balance) => GiftVoucher(
        id: r.id,
        code: r.code,
        amount: r.amount,
        balance: balance,
        issuedAt: r.createdAt,
        byName: r.byName,
        expiresOn: r.expiresOn,
        customerId: r.customerId,
        note: r.note,
      );

  Future<List<GiftVoucher>> list() async {
    final rows = await (_db.select(_db.giftVouchers)
          ..where((v) => v.deletedAt.isNull())
          ..orderBy([(v) => OrderingTerm.desc(v.createdAt), (v) => OrderingTerm.desc(v.id)]))
        .get();
    final balances = await _balances();
    return [for (final r in rows) _toModel(r, balances[r.id] ?? 0)];
  }

  Future<GiftVoucher?> find(String code) async {
    final row = await (_db.select(_db.giftVouchers)
          ..where((v) => v.code.equals(normalise(code)) & v.deletedAt.isNull()))
        .getSingleOrNull();
    return row == null ? null : _toModel(row, (await _balances(row.id))[row.id] ?? 0);
  }

  /// Sells a voucher worth [amount], paid by [method]. Returns it with its
  /// new code.
  Future<GiftVoucher> issue({
    required int amount,
    required PayMethod method,
    required String shopName,
    required Staff by,
    String? reference,
    DateTime? expiresOn,
    String? customerId,
    String? note,
  }) async {
    if (amount <= 0) throw const VoucherException('A voucher needs a value.');
    if (const {PaymentMethod.voucher, PaymentMethod.credit, PaymentMethod.wallet, PaymentMethod.exchange}
        .contains(method.kind)) {
      throw VoucherException('A voucher cannot be paid for by ${method.name}.');
    }
    return _db.transaction(() async {
      var code = newCode(shopName);
      while (await find(code) != null) {
        code = newCode(shopName);
      }
      final now = DateTime.now();
      final id = newId();
      await _db.insertTracked(
        _db.giftVouchers,
        GiftVouchersCompanion.insert(
          id: id,
          createdAt: now,
          updatedAt: now,
          deviceId: _device.deviceId,
          code: code,
          amount: amount,
          expiresOn: Value(expiresOn),
          customerId: Value(customerId),
          note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
          byName: by.name,
        ),
      );
      await _entry(id, VoucherEntryKind.issued, amount, byName: by.name, method: method, reference: reference);
      // Selling vouchers means taking them as payment: switch that method on.
      final payBy = await (_db.select(_db.payMethods)
            ..where((m) => m.kind.equalsValue(PaymentMethod.voucher) & m.active.equals(false) & m.deletedAt.isNull()))
          .get();
      for (final m in payBy) {
        await _db.updateTracked(_db.payMethods, m.copyWith(active: true, updatedAt: now));
      }
      await _audit.record(
        action: AuditAction.voucherIssued,
        actor: by,
        entity: 'gift_vouchers',
        entityId: id,
        summary: 'Sold gift voucher $code for ${formatMoney(amount)} by ${method.name}',
      );
      return (await find(code))!;
    });
  }

  Future<void> _entry(
    String voucherId,
    VoucherEntryKind kind,
    int amount, {
    required String byName,
    String? saleId,
    PayMethod? method,
    String? reference,
  }) {
    final now = DateTime.now();
    final ref = reference?.trim();
    return _db.insertTracked(
      _db.voucherEntries,
      VoucherEntriesCompanion.insert(
        id: newId(),
        createdAt: now,
        updatedAt: now,
        deviceId: _device.deviceId,
        voucherId: voucherId,
        kind: kind,
        amount: amount,
        saleId: Value(saleId),
        method: Value(method?.kind),
        methodName: Value(method?.name),
        reference: Value(ref == null || ref.isEmpty ? null : ref),
        byName: byName,
      ),
    );
  }

  /// Checks a voucher can pay [amount] now. Returns it, or throws.
  Future<GiftVoucher> check(String code, int amount, {DateTime? at}) async {
    final v = await find(code);
    if (v == null) throw VoucherException('No gift voucher ${normalise(code)}.');
    if (v.expiredAt(at ?? DateTime.now())) throw VoucherException('Gift voucher ${v.code} has expired.');
    if (v.balance < amount) throw VoucherException('Gift voucher ${v.code} has ${formatMoney(v.balance)} left.');
    return v;
  }

  /// Takes [amount] off the voucher for a sale. Call inside the sale's
  /// transaction.
  Future<void> spend(String code, int amount, {required String saleId, required String byName}) async {
    final v = await check(code, amount);
    await _entry(v.id, VoucherEntryKind.spent, -amount, byName: byName, saleId: saleId);
  }

  /// A voided sale's voucher payments go back on the vouchers.
  Future<void> reverseSale(String saleId, {required String byName}) async {
    final spent = await (_db.select(_db.voucherEntries)
          ..where((e) => e.saleId.equals(saleId) & e.kind.equalsValue(VoucherEntryKind.spent) & e.deletedAt.isNull()))
        .get();
    for (final e in spent) {
      await _entry(e.voucherId, VoucherEntryKind.voidReturn, -e.amount, byName: byName, saleId: saleId);
    }
  }

  /// Money taken for vouchers sold since [from], per kind of payment (for
  /// the drawer at close).
  Future<Map<PaymentMethod, int>> moneyInSince(DateTime? from) async {
    final rows = await _db.customSelect(
      "SELECT method, COALESCE(SUM(amount), 0) AS total FROM voucher_entries WHERE kind = 'issued' AND device_id = ? "
      'AND deleted_at IS NULL AND method IS NOT NULL ${from == null ? '' : 'AND created_at > ?'} GROUP BY method',
      variables: [Variable.withString(_device.deviceId), if (from != null) Variable.withDateTime(from)],
      readsFrom: {_db.voucherEntries},
    ).get();
    return {for (final r in rows) PaymentMethod.values.byName(r.read<String>('method')): r.read<int>('total')};
  }
}
