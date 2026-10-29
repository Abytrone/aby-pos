import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../data/repositories/pay_method_repository.dart';
import '../../../domain/customer_documents.dart';
import '../../../domain/receipt/receipt_builder.dart';
import '../../../models/customer.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/pdf_brand_loader.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/files.dart';
import '../../../ui/l10n.dart';
import '../../../ui/receipt_actions.dart';

/// One customer: balances, credit aging, history, repayments, wallet,
/// write-offs, statements and reminders. Argument: the customer ID.
class CustomerController extends GetxController {
  final CustomerRepository _customers = Get.find();
  final PayMethodRepository _methods = Get.find();
  final PermissionService _permissions = Get.find();
  final AuthService _auth = Get.find();
  final SettingsService _settings = Get.find();

  final String customerId = Get.arguments as String;

  final customer = Rxn<Customer>();
  final aging = const CreditAging().obs;
  final debts = <OpenDebt>[].obs;
  final entries = <CustomerEntry>[].obs;
  final stats = const CustomerStats().obs;
  final sales = <(String, int, DateTime, int, SaleStatus)>[].obs;
  final methods = <PayMethod>[].obs;
  final message = RxnString();

  bool get canManage => _auth.can(Permission.manageCustomers);
  bool get canWriteOff => _auth.can(Permission.writeOffCredit);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    customer.value = await _customers.find(customerId);
    debts.assignAll(await _customers.openDebts(customerId));
    aging.value = CreditAging.of(debts, DateTime.now());
    entries.assignAll(await _customers.ledger(customerId));
    stats.value = await _customers.stats(customerId);
    sales.assignAll(await _customers.sales(customerId));
    methods.assignAll((await _methods.list())
        .where((m) => m.kind != PaymentMethod.credit && m.kind != PaymentMethod.wallet && m.kind != PaymentMethod.exchange));
  }

  Future<bool> save(CustomerDraft d) async {
    final auth = await _permissions.authorize(Permission.manageCustomers, reason: appL10n().customerEditReason);
    if (auth == null) return false;
    try {
      await _customers.save(d, by: auth.authority);
      message.value = appL10n().settingsSaved;
      await load();
      return true;
    } on CustomerException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  /// Returns an error to show, or null when done.
  Future<String?> repay(String amount, PayMethod method, {String? reference, String? forSaleId}) async {
    final l = appL10n();
    final pesewas = parseMoney(amount);
    if (pesewas == null || pesewas <= 0) return l.customerAmountInvalid;
    final auth = await _permissions.authorize(Permission.manageCustomers, reason: l.customerRepayReason(customer.value!.name));
    if (auth == null) return null;
    try {
      await _customers.repay(customerId, amount: pesewas, method: method, reference: reference, forSaleId: forSaleId, by: auth.authority);
      message.value = l.customerRepaid(formatMoney(pesewas));
      await load();
      return null;
    } on CustomerException catch (e) {
      return e.message;
    }
  }

  Future<String?> topUp(String amount, PayMethod method, {String? reference}) async {
    final l = appL10n();
    final pesewas = parseMoney(amount);
    if (pesewas == null || pesewas <= 0) return l.customerAmountInvalid;
    final auth = await _permissions.authorize(Permission.manageCustomers, reason: l.customerTopUpReason(customer.value!.name));
    if (auth == null) return null;
    try {
      await _customers.topUp(customerId, amount: pesewas, method: method, reference: reference, by: auth.authority);
      message.value = l.customerToppedUp(formatMoney(pesewas));
      await load();
      return null;
    } on CustomerException catch (e) {
      return e.message;
    }
  }

  Future<String?> writeOff(String amount, String reason) async {
    final l = appL10n();
    final pesewas = parseMoney(amount);
    if (pesewas == null || pesewas <= 0) return l.customerAmountInvalid;
    final auth = await _permissions.authorize(Permission.writeOffCredit, reason: l.customerWriteOffReason(customer.value!.name));
    if (auth == null) return null;
    try {
      await _customers.writeOff(customerId, amount: pesewas, reason: reason, actor: auth.actor, approver: auth.approver);
      message.value = l.customerWrittenOff(formatMoney(pesewas));
      await load();
      return null;
    } on CustomerException catch (e) {
      return e.message;
    }
  }

  Future<void> setActive(bool active) async {
    final auth = await _permissions.authorize(Permission.manageCustomers, reason: appL10n().customerEditReason);
    if (auth == null) return;
    await _customers.setActive(customerId, active: active, by: auth.authority);
    await load();
  }

  /// A PDF statement of the credit account for [from] to [to], shared or saved.
  Future<void> statement(DateTime from, DateTime to) async {
    final c = customer.value!;
    final end = DateTime(to.year, to.month, to.day).add(const Duration(days: 1));
    final start = DateTime(from.year, from.month, from.day);
    final opening = await _customers.balanceBefore(customerId, CustomerAccount.credit, start);
    final inPeriod = (await _customers.ledger(customerId, account: CustomerAccount.credit, from: start, to: end)).reversed.toList();
    final pdf = await CustomerDocuments.statementPdf(
      shopName: _settings.get(AppSettings.shopName),
      shopPhone: _settings.get(AppSettings.shopPhone),
      customer: c,
      from: start,
      to: to,
      opening: opening,
      entries: inPeriod,
      aging: aging.value,
      brand: await loadPdfBrand(),
      logo: shopLogo(),
    );
    final safe = c.name.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-');
    await shareOrSaveBytes('Statement-$safe.pdf', pdf, text: appL10n().customerStatementText(c.name));
  }

  /// The balance and the last ten credit entries on the receipt printer.
  void printStatement() {
    final recent = entries.where((e) => e.account == CustomerAccount.credit).take(10).toList().reversed.toList();
    printOnPaper(ReceiptBuilder.statement(
      shopName: _settings.get(AppSettings.shopName),
      customer: customer.value!,
      entries: recent,
      at: DateTime.now(),
    ));
  }

  String get reminderText => CustomerDocuments.reminder(
        _settings.get(AppSettings.creditReminder),
        customer: customer.value!,
        shopName: _settings.get(AppSettings.shopName),
        amount: formatMoney(customer.value!.owed),
      );

  /// Opens WhatsApp (or SMS) with the reminder ready to send.
  Future<void> remind(String text, {bool sms = false}) async {
    final phone = customer.value?.phone;
    if (phone == null) {
      message.value = appL10n().customerNoPhone;
      return;
    }
    final uri = sms ? CustomerDocuments.sms(phone, text) : CustomerDocuments.whatsApp(phone, text);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      message.value = appL10n().customerCannotOpen;
    }
  }
}
