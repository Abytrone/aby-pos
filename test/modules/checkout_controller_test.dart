import 'package:aby_pos/app/data/repositories/sale_repository.dart';
import 'package:aby_pos/app/data/repositories/staff_repository.dart';
import 'package:aby_pos/app/models/models.dart';
import 'package:aby_pos/app/modules/checkout/controllers/checkout_controller.dart';
import 'package:aby_pos/app/modules/till/controllers/cart_controller.dart';
import 'package:aby_pos/app/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../helpers.dart';

class FakeSaleRepository implements SaleRepository {
  final calls = <(List<CartLine>, PaymentInput, Staff)>[];
  SaleException? failWith;

  @override
  Future<CompletedSale> completeSale({
    required List<CartLine> lines,
    required PaymentInput payment,
    required Staff cashier,
  }) async {
    if (failWith != null) throw failWith!;
    calls.add((lines, payment, cashier));
    final total = lines.fold(0, (sum, l) => sum + l.lineTotal);
    return CompletedSale(
      saleId: 's1',
      number: 7,
      total: total,
      method: payment.method,
      changeDue: payment.tendered == null ? 0 : payment.tendered! - total,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeStaffRepository implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeSaleRepository sales;
  late CartController cart;
  late CheckoutController checkout;

  setUp(() {
    Get.testMode = true;
    sales = Get.put<SaleRepository>(FakeSaleRepository()) as FakeSaleRepository;
    Get.put(AuthService(FakeStaffRepository())).signInAsNew(cashier);
    cart = Get.put(CartController());
    cart.add(vanillaCone, variant: double_, addons: [sprinkles]); // 25.00
    checkout = Get.put(CheckoutController());
  });

  tearDown(Get.reset);

  test('cash: needs enough cash, shows change, saves and clears the cart', () async {
    checkout.tenderedField.text = '20';
    expect(checkout.cashShort, isTrue);
    expect(checkout.canComplete, isFalse);

    checkout.tenderedField.text = '50';
    expect(checkout.changeDue, 2500);
    expect(checkout.canComplete, isTrue);

    await checkout.complete();

    expect(sales.calls.single.$2.tendered, 5000);
    expect(sales.calls.single.$3, cashier, reason: 'the signed-in person rang it up');
    expect(checkout.completed.value!.changeDue, 2500);
    expect(checkout.completed.value!.displayNumber, '#00007');
    expect(cart.isEmpty, isTrue);
  });

  test('momo: needs a reference', () async {
    checkout.selectMethod(PaymentMethod.momo);
    expect(checkout.canComplete, isFalse);
    checkout.momoField.text = 'MP2410.1234';
    expect(checkout.canComplete, isTrue);
    await checkout.complete();
    expect(sales.calls.single.$2.momoReference, 'MP2410.1234');
  });

  test('credit: needs a customer', () async {
    checkout.selectMethod(PaymentMethod.credit);
    expect(checkout.canComplete, isFalse);
    checkout.customerField.text = 'Auntie Akos';
    await checkout.complete();
    expect(sales.calls.single.$2.customer, 'Auntie Akos');
  });

  test('keeps the cart and shows the message when saving fails', () async {
    sales.failWith = const SaleException('Cash given is less than the total.');
    checkout.tenderedField.text = '25';
    await checkout.complete();
    expect(checkout.error.value, 'Cash given is less than the total.');
    expect(checkout.completed.value, isNull);
    expect(cart.isEmpty, isFalse);
  });

  test('quick cash offers the exact amount and round notes above it', () {
    expect(checkout.quickCash, [2500, 3000, 4000, 5000]);
    checkout.setTendered(3000);
    expect(checkout.tendered, 3000);
  });
}
