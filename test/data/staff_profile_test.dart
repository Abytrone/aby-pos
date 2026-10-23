import 'dart:typed_data';

import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/validators.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/data/repositories/staff_stats_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  group('Validators', () {
    test('Ghana phone numbers in any common form', () {
      for (final input in ['0241234567', '024 123 4567', '+233 24 123 4567', '233241234567', '(024) 123-4567']) {
        expect(Validators.normalisePhone(input), '+233241234567', reason: input);
      }
      expect(Validators.normalisePhone('12345'), isNull);
      expect(Validators.normalisePhone('024123456'), isNull);
      expect(Validators.formatPhone('+233241234567'), '024 123 4567');
    });

    test('email', () {
      expect(Validators.normaliseEmail(' Ama@Example.COM '), 'ama@example.com');
      expect(Validators.normaliseEmail('ama@'), isNull);
    });

    test('Ghana Card numbers', () {
      expect(Validators.normaliseGhanaCard('gha 123456789 0'), 'GHA-123456789-0');
      expect(Validators.normaliseGhanaCard('GHA-123456789-0'), 'GHA-123456789-0');
      expect(Validators.normaliseGhanaCard('GHA-12345-0'), isNull);
    });
  });

  group('Profiles', () {
    late AppDatabase db;
    late Repos r;
    late Staff kofi;
    late Staff ama;

    setUp(() async {
      db = memoryDb();
      r = await Repos.open(db);
      kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
      ama = await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
    });

    tearDown(() => db.close());

    test('details are saved and only changes are recorded, with the Ghana Card masked', () async {
      await r.staff.updateDetails(
        ama.id,
        StaffDetails(
          name: 'Ama Mensah',
          phone: '+233241234567',
          email: 'ama@example.com',
          address: '  Behind Lamashegu mosque ',
          emergencyName: 'Kwame (brother)',
          emergencyPhone: '+233201112222',
          idNumber: 'GHA-123456789-0',
          dateOfBirth: DateTime(2000, 3, 14),
          startedOn: DateTime(2026, 1, 5),
          notes: '',
        ),
        by: kofi,
      );
      final p = (await r.staff.profile(ama.id))!;
      expect(p.staff.name, 'Ama Mensah');
      expect(p.address, 'Behind Lamashegu mosque');
      expect(p.notes, isNull, reason: 'blank becomes empty');
      expect(p.dateOfBirth, DateTime(2000, 3, 14));
      expect(p.maskedIdNumber, 'GHA-•••••6789-0');

      final entry = (await r.audit.list(actions: {AuditAction.staffDetailsChanged})).single;
      final after = entry.details!['after'] as Map;
      expect(after['idNumber'], '…89-0', reason: 'never the full number');
      expect(after.containsKey('notes'), isFalse, reason: 'unchanged');
      expect(entry.actorName, 'Kofi');

      // Saving the same again records nothing.
      await r.staff.updateDetails(
        ama.id,
        StaffDetails(
          name: 'Ama Mensah',
          phone: '+233241234567',
          email: 'ama@example.com',
          address: 'Behind Lamashegu mosque',
          emergencyName: 'Kwame (brother)',
          emergencyPhone: '+233201112222',
          idNumber: 'GHA-123456789-0',
          dateOfBirth: DateTime(2000, 3, 14),
          startedOn: DateTime(2026, 1, 5),
        ),
        by: kofi,
      );
      expect(await r.audit.list(actions: {AuditAction.staffDetailsChanged}), hasLength(1));
    });

    test('changing your own PIN needs the current one', () async {
      await expectLater(r.staff.changeOwnPin(ama, '0000', '4321'), throwsA(isA<StaffException>()));
      await r.staff.changeOwnPin(ama, '5678', '4321');
      expect(await r.staff.verifyPin(ama.id, '4321'), isTrue);
    });

    test('photos are stored, replaced and removed', () async {
      final image = Uint8List.fromList([1, 2, 3]);
      await r.staff.setPhoto(ama.id, image, by: ama);
      expect(await r.staff.photo(ama.id), image);
      await r.staff.setPhoto(ama.id, Uint8List.fromList([4]), by: ama);
      expect(await r.staff.photo(ama.id), [4]);
      await r.staff.setPhoto(ama.id, null, by: ama);
      expect(await r.staff.photo(ama.id), isNull);
      final outbox = await (db.select(db.outbox)..where((o) => o.entity.equals('staff_photos'))).get();
      expect(outbox, isEmpty, reason: 'photos stay out of sync payloads');
    });

    test('stats count their sales, voids, closes and sign-ins', () async {
      final waffle = (await r.catalog.products()).firstWhere((x) => x.name == 'Waffle');
      Future<CompletedSale> sell(Staff who, int qty) => r.sales.completeSale(
            lines: [CartLine(product: waffle, quantity: qty)],
            payment: PaymentInput.cash(tendered: 1200 * qty),
            cashier: who,
          );
      await sell(ama, 1);
      await sell(ama, 2);
      final voided = await sell(ama, 1);
      await sell(kofi, 5);
      await r.sales.voidSale(voided.saleId, actor: ama, approver: kofi);
      await r.closes.closeDay(openingFloat: 0, countedCash: 4700, closedBy: ama);
      await r.audit.record(action: AuditAction.signedIn, actor: ama, summary: 'Ama signed in');
      await r.audit.record(action: AuditAction.signInFailed, actor: ama, summary: 'Wrong PIN for Ama');

      final stats = await StaffStatsRepository(db).stats(ama.id, todayStart: DateTime(2000));
      expect(stats.sales30Days, 2, reason: 'voided sale not counted');
      expect(stats.takings30Days, 3600);
      expect(stats.salesToday, 2);
      expect(stats.averageSale30Days, 1800);
      expect(stats.voidsAsked, 1);
      expect(stats.voidsApproved, 0);
      expect(stats.closes, 1);
      // Expected 0 float + 3600 Ama + 6000 Kofi cash = 9600; counted 4700.
      expect(stats.closeDifference, 4700 - 9600);
      expect(stats.failedSignIns30Days, 1);
      expect(stats.lastSignIn, isNotNull);

      final kofiStats = await StaffStatsRepository(db).stats(kofi.id, todayStart: DateTime(2000));
      expect(kofiStats.voidsApproved, 1);
      expect(kofiStats.sales30Days, 1);
    });
  });
}
