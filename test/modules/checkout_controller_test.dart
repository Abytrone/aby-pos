import 'package:aby_pos/app/core/tax.dart';
import 'package:aby_pos/app/data/repositories/audit_repository.dart';
import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/domain/settlement.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/modules/checkout/controllers/checkout_controller.dart';
import 'package:aby_pos/app/modules/till/controllers/cart_controller.dart';
import 'package:aby_pos/app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

class FakeSaleRepository implements SaleRepository {
  final calls = <(List<PaymentInput>, Staff)>[];
  SaleException? failWith;

  @override
  Future<CompletedSale> completeSale({
    required List<CartLine> lines,
    PaymentInput? payment,
    List<PaymentInput> payments = const [],
    required Staff cashier,
    TaxMode taxMode = TaxMode.off,
    Discount? orderDiscount,
    String? note,
    OrderType? orderType,
    int roundTo = 0,
    ExchangeInput? exchange,
    Customer? customer,
    bool changeToWallet = false,
    Staff? creditApprover,
  }) async {
    if (failWith != null) throw failWith!;
    final all = [...payments, ?payment];
    calls.add((all, cashier));
    final total = lines.fold(0, (sum, l) => sum + l.lineTotal);
    final settled = Settlement.of(total, all, roundTo: roundTo);
    return CompletedSale(
      saleId: 's1',
      number: 7,
      total: total,
      method: all.last.method,
      changeDue: settled.change,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeAuditRepository implements AuditRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStaffRepository implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Lets the controller load its payment methods.
Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakeSaleRepository sales;
  late CartController cart;
  late CheckoutController checkout;

  setUp(() {
    Get.testMode = true;
    sales = Get.put<SaleRepository>(FakeSaleRepository()) as FakeSaleRepository;
    Get.put(AuthService(FakeStaffRepository(), FakeAuditRepository())).signInAsNew(cashier);
    cart = Get.put(CartController());
    cart.add(vanillaCone, variant: double_, options: [sprinkles]); // 25.00
    checkout = Get.put(CheckoutController());
  });

  tearDown(Get.reset);

  test('cash: needs enough cash, shows change, saves and clears the cart', () async {
    await settle();
    checkout.tenderedField.text = '20';
    expect(checkout.cashShort, isTrue);
    expect(checkout.canComplete, isFalse);
    expect(checkout.canTakePart, isTrue, reason: 'GH₵ 20 now, the rest another way');

    checkout.tenderedField.text = '50';
    expect(checkout.changeDue, 2500);
    expect(checkout.canComplete, isTrue);

    await checkout.complete();

    expect(sales.calls.single.$1.single.tendered, 5000);
    expect(sales.calls.single.$2, cashier, reason: 'the signed-in person rang it up');
    expect(checkout.completed.value!.changeDue, 2500);
    expect(checkout.completed.value!.displayNumber, '#00007');
    expect(cart.isEmpty, isTrue);
  });

  test('momo: needs a reference', () async {
    await settle();
    checkout.selectMethod(PaymentMethod.momo);
    expect(checkout.selected.value!.name, 'MTN MoMo');
    expect(checkout.canComplete, isFalse);
    checkout.referenceField.text = 'MP2410.1234';
    expect(checkout.canComplete, isTrue);
    await checkout.complete();
    expect(sales.calls.single.$1.single.reference, 'MP2410.1234');
    expect(sales.calls.single.$1.single.methodName, 'MTN MoMo');
  });

  test('credit: needs a customer attached', () async {
    await settle();
    checkout.selectMethod(PaymentMethod.credit);
    expect(checkout.needsCustomer, isTrue);
    expect(checkout.canComplete, isFalse);
    cart.customer.value = const Customer(id: 'c1', name: 'Auntie Akos');
    expect(checkout.canComplete, isTrue);
    await checkout.complete();
    expect(sales.calls.single.$1.single.customer, 'Auntie Akos');
  });

  test('wallet: no more than it holds', () async {
    await settle();
    cart.customer.value = const Customer(id: 'c1', name: 'Auntie Akos', wallet: 1000);
    checkout.selectMethod(PaymentMethod.wallet);
    expect(checkout.amount, 1000, reason: 'the wallet, not the 25.00 total');
    expect(checkout.canComplete, isFalse);
    expect(checkout.canTakePart, isTrue);
    checkout.amountField.text = '12';
    expect(checkout.canTakePart, isFalse, reason: 'more than the wallet holds');
  });

  test('split: part by MoMo, the rest in cash', () async {
    await settle();
    checkout.selectMethod(PaymentMethod.momo);
    checkout.amountField.text = '10';
    checkout.referenceField.text = 'TX-1';
    expect(checkout.canTakePart, isTrue);
    checkout.takePart();
    expect(checkout.remaining, 1500);
    expect(checkout.taken.single.amount, 1000);

    checkout.selectMethod(PaymentMethod.cash);
    checkout.tenderedField.text = '20';
    expect(checkout.changeDue, 500);
    await checkout.complete();
    final payments = sales.calls.single.$1;
    expect(payments.map((p) => p.method), [PaymentMethod.momo, PaymentMethod.cash]);
    expect(payments.first.amount, 1000);
    expect(payments.last.amount, isNull, reason: 'the last pays the rest');
    expect(checkout.completed.value!.changeDue, 500);
  });

  test('keeps the cart and shows the message when saving fails', () async {
    await settle();
    sales.failWith = const SaleException('This reference was already used on sale #00003.');
    checkout.tenderedField.text = '25';
    await checkout.complete();
    expect(checkout.error.value, 'This reference was already used on sale #00003.');
    expect(checkout.completed.value, isNull);
    expect(cart.isEmpty, isFalse);
  });

  test('quick cash offers the exact amount and round notes above it', () async {
    await settle();
    expect(checkout.quickCash, [2500, 3000, 4000, 5000]);
    checkout.setTendered(3000);
    expect(checkout.tendered, 3000);
  });
}
