import 'package:aby_pos/app/domain/settlement.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

const mtn = PayMethod(id: 'm-mtn', name: 'MTN MoMo', kind: PaymentMethod.momo, needsReference: true);
const mtnShort = PayMethod(id: 'm-mtn', name: 'MTN MoMo', kind: PaymentMethod.momo, needsReference: true, shortReference: true);
const card = PayMethod(id: 'm-card', name: 'Card', kind: PaymentMethod.card);

void main() {
  test('one cash payment gives change', () {
    final s = Settlement.of(2500, [const PaymentInput.cash(tendered: 5000)]);
    expect(s.payments.single.amount, 2500);
    expect(s.change, 2500);
    expect(s.rounding, 0);
    expect(() => Settlement.of(2500, [const PaymentInput.cash(tendered: 2000)]), throwsA(isA<PaymentException>()));
  });

  test('cash rounds to the nearest 10 or 50 pesewas, up or down', () {
    final down = Settlement.of(1234, [const PaymentInput.cash(tendered: 2000)], roundTo: 10);
    expect(down.payments.single.amount, 1230);
    expect(down.rounding, -4);
    expect(down.change, 770);
    final up = Settlement.of(1236, [const PaymentInput.cash(tendered: 1240)], roundTo: 10);
    expect(up.rounding, 4);
    expect(up.change, 0);
    expect(Settlement.of(1224, [const PaymentInput.cash(tendered: 1200)], roundTo: 50).payments.single.amount, 1200);
    expect(Settlement.of(3, [const PaymentInput.cash(tendered: 3)], roundTo: 10).payments.single.amount, 3,
        reason: 'never rounds to nothing');
    expect(Settlement.roundCash(1225, 50), 1250);
  });

  test('only cash at the end is rounded; MoMo is exact', () {
    final s = Settlement.of(1234, [PaymentInput.from(mtn, reference: 'TX9')], roundTo: 10);
    expect(s.payments.single.amount, 1234);
    expect(s.rounding, 0);
  });

  test('split: part by MoMo, the rest in cash with change', () {
    final s = Settlement.of(2500, [
      PaymentInput.from(mtn, amount: 1000, reference: 'tx 1'),
      const PaymentInput.cash(tendered: 2000),
    ]);
    expect(s.payments.map((p) => p.amount), [1000, 1500]);
    expect(s.change, 500);
    expect(s.paid, 2500);
    expect(Settlement.cleanReference('tx 1'), 'TX1');
  });

  test('cash in the middle of a split gives no change', () {
    expect(
      () => Settlement.of(2500, [
        const PaymentInput.cash(tendered: 2000, amount: 1000),
        PaymentInput.from(card),
      ]),
      throwsA(isA<PaymentException>()),
    );
    final ok = Settlement.of(2500, [const PaymentInput.cash(tendered: 1000), PaymentInput.from(card)]);
    expect(ok.payments.map((p) => p.amount), [1000, 1500]);
  });

  test('refuses overpaying by card, short payments, and missing details', () {
    expect(() => Settlement.of(1000, [PaymentInput.from(card, amount: 1500)]), throwsA(isA<PaymentException>()));
    expect(() => Settlement.of(1000, [PaymentInput.from(card, amount: 600)]), throwsA(isA<PaymentException>()));
    expect(() => Settlement.of(1000, [PaymentInput.from(mtn)]), throwsA(isA<PaymentException>()), reason: 'no reference');
    expect(() => Settlement.of(1000, [PaymentInput.from(mtnShort, reference: '12')]), throwsA(isA<PaymentException>()));
    expect(Settlement.of(1000, [PaymentInput.from(mtnShort, reference: '1234')]).paid, 1000);
    expect(() => Settlement.of(1000, [const PaymentInput.credit(customer: ' ')]), throwsA(isA<PaymentException>()));
    expect(() => Settlement.of(1000, const []), throwsA(isA<PaymentException>()));
  });

  test('a free sale (100% off) takes a zero payment', () {
    expect(Settlement.of(0, [const PaymentInput.cash(tendered: 0)]).paid, 0);
  });
}
