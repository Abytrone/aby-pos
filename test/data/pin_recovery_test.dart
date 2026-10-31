import 'dart:math';

import 'package:aby_pos/app/core/license.dart';
import 'package:aby_pos/app/core/permissions.dart';
import 'package:aby_pos/app/core/pin_reset.dart';
import 'package:aby_pos/app/data/database/app_database.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/services/auth_service.dart';
import 'package:aby_pos/app/services/pin_recovery_service.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

void main() {
  late AppDatabase db;
  late Repos r;
  late AuthService auth;
  late Staff kofi;
  late Staff ama;

  // A test key in place of Aby's real licence key.
  final seed = List.generate(32, (i) => i * 7 % 256);
  late String publicKey;
  const device = 'K7QM-2XRA-PL3D-9WEH';

  PinRecoveryService service() =>
      PinRecoveryService(db, r.staff, auth, deviceCode: () async => device, publicKey: publicKey);

  setUpAll(() async => publicKey = await LicenseCodec.publicKeyOf(seed));

  setUp(() async {
    db = memoryDb();
    r = await Repos.open(db);
    auth = AuthService(r.staff, r.audit);
    kofi = await r.staff.create(name: 'Kofi', roleId: BuiltInRole.owner.id, pin: '1234');
    ama = await r.staff.create(name: 'Ama', roleId: BuiltInRole.cashier.id, pin: '5678', by: kofi);
  });
  tearDown(() => db.close());

  group('codes', () {
    test('recovery codes are twelve unambiguous characters in threes of four', () {
      final code = RecoveryCode.generate();
      expect(code, matches(RegExp(r'^[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}-[A-HJ-NP-Z2-9]{4}$')));
      expect(RecoveryCode.normalize(' ${code.toLowerCase()} '), code.replaceAll('-', ''));
    });

    test('a request code reads back with or without dashes', () {
      final request = PinResetRequest.create(device, '101');
      expect(request.code, matches(RegExp(r'^K7QM-2XRA-PL3D-9WEH-101-[A-Z2-9]{4}-[A-Z2-9]{4}$')));
      for (final typed in [request.code, request.code.replaceAll('-', '').toLowerCase()]) {
        final back = PinResetRequest.parse(typed)!;
        expect((back.device, back.staffNumber, back.nonce), (request.device, request.staffNumber, request.nonce));
      }
      expect(PinResetRequest.parse('K7QM-2XRA-101'), isNull);
    });

    test('a reset code answers only the request it was made for, with the right key', () async {
      final request = PinResetRequest.create(device, '101');
      final code = await PinResetCodec.sign(request, seed);
      expect(await PinResetCodec.verify(code, request, publicKey: publicKey), isTrue);
      expect(await PinResetCodec.verify(code.replaceRange(20, 22, '\n '), request, publicKey: publicKey), isFalse);
      expect(await PinResetCodec.verify(' $code\n', request, publicKey: publicKey), isTrue, reason: 'spaces from chat apps');
      final other = PinResetRequest.create(device, '101');
      expect(await PinResetCodec.verify(code, other, publicKey: publicKey), isFalse, reason: 'another request');
      final otherKey = await PinResetCodec.sign(request, List.generate(32, (_) => Random().nextInt(256)));
      expect(await PinResetCodec.verify(otherKey, request, publicKey: publicKey), isFalse, reason: 'not Aby\'s key');
      expect(await PinResetCodec.verify('ABYP.nonsense', request, publicKey: publicKey), isFalse);
      expect(await PinResetCodec.verify(code, request), isFalse, reason: 'the real key did not sign it');
    });
  });

  group('recovery codes', () {
    test('only owners have one; a new code replaces the old', () async {
      expect((await r.staff.profile(kofi.id))!.hasRecoveryCode, isFalse);
      final first = await r.staff.newRecoveryCode(kofi.id, by: kofi);
      expect((await r.staff.profile(kofi.id))!.hasRecoveryCode, isTrue);
      expect(await r.staff.ownerWithRecoveryCode('101', first.toLowerCase()), kofi);
      final second = await r.staff.newRecoveryCode(kofi.id, by: kofi);
      expect(await r.staff.ownerWithRecoveryCode('101', first), isNull);
      expect(await r.staff.ownerWithRecoveryCode('101', second), kofi);
      expect(await r.staff.ownerWithRecoveryCode('102', second), isNull, reason: 'the number must match');
      await expectLater(r.staff.newRecoveryCode(ama.id, by: kofi), throwsA(isA<StaffException>()));
      expect((await r.audit.list()).map((e) => e.action), contains(AuditAction.staffRecoveryCodeMade));
    });

    test('a recovery code sets a new PIN, signs in, and is used up', () async {
      final code = await r.staff.newRecoveryCode(kofi.id, by: kofi);
      final recovery = service();
      final owner = await recovery.withRecoveryCode('101', code);
      expect(owner, kofi);
      final next = await recovery.setNewPin(owner!, '4321', bySupplier: false);
      expect(auth.user, kofi);
      expect(await r.staff.verifyPin(kofi.id, '4321'), isTrue);
      expect(await r.staff.ownerWithRecoveryCode('101', code), isNull, reason: 'used up');
      expect(await r.staff.ownerWithRecoveryCode('101', next), kofi);
      expect((await r.audit.list()).map((e) => e.action), contains(AuditAction.staffPinReset));
    });

    test('wrong recovery codes lock out guessing', () async {
      final code = await r.staff.newRecoveryCode(kofi.id, by: kofi);
      for (var i = 1; i < AuthService.maxAttempts; i++) {
        expect(await auth.ownerWithRecoveryCode('101', 'AAAA-AAAA-AAAA'), isNull);
      }
      await expectLater(auth.ownerWithRecoveryCode('101', 'AAAA-AAAA-AAAA'), throwsA(isA<LockedOutException>()));
      await expectLater(auth.ownerWithRecoveryCode('101', code), throwsA(isA<LockedOutException>()));
    });
  });

  group('supplier reset', () {
    test('the supplier signs the request; the code resets that owner once', () async {
      final recovery = service();
      final request = await recovery.request('101');
      expect(request.device, device);
      expect((await recovery.request('101')).nonce, request.nonce, reason: 'the same request while it waits');

      final code = await PinResetCodec.sign(PinResetRequest.parse(request.code)!, seed);
      expect(await recovery.redeem('ABYP.wrong'), isNull);
      final owner = await recovery.redeem(code);
      expect(owner, kofi);
      final next = await recovery.setNewPin(owner!, '9999', bySupplier: true);
      expect(await r.staff.verifyPin(kofi.id, '9999'), isTrue);
      expect(await r.staff.ownerWithRecoveryCode('101', next), kofi);
      expect(await recovery.redeem(code), isNull, reason: 'a reset code works once');
    });

    test('a request for a cashier\'s number resets nobody', () async {
      final recovery = service();
      final request = await recovery.request('102');
      expect(await recovery.redeem(await PinResetCodec.sign(request, seed)), isNull);
    });

    test('asking for another number makes a new request; old requests expire', () async {
      final recovery = service();
      final first = await recovery.request('101');
      final second = await recovery.request('103');
      expect(second.nonce, isNot(first.nonce));
      expect(await recovery.redeem(await PinResetCodec.sign(first, seed)), isNull, reason: 'replaced');

      final request = await recovery.request('101');
      final code = await PinResetCodec.sign(request, seed);
      await withClock(Clock.fixed(DateTime.now().add(PinRecoveryService.requestLife + const Duration(hours: 1))), () async {
        expect(await recovery.redeem(code), isNull);
      });
    });
  });

  test('confirmOwnPin checks the signed-in person and shares their lockout', () async {
    expect(await auth.signIn('101', '1234'), SignInResult.ok);
    expect(await auth.confirmOwnPin('1234'), SignInResult.ok);
    for (var i = 1; i < AuthService.maxAttempts; i++) {
      expect(await auth.confirmOwnPin('0000'), SignInResult.wrongPin);
    }
    expect(await auth.confirmOwnPin('0000'), SignInResult.lockedOut);
    expect(await auth.signIn('101', '1234'), SignInResult.lockedOut);
    expect(auth.can(Permission.manageStaff), isTrue, reason: 'still signed in');
  });
}
