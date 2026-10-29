import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../../core/settings.dart';
import '../../data/repositories/audit_repository.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../domain/receipt/escpos.dart';
import '../../domain/receipt/receipt_builder.dart';
import '../../domain/receipt/receipt_doc.dart';
import '../../models/audit.dart';
import '../../models/enums.dart';
import '../../models/order.dart';
import '../../models/receipt.dart';
import '../../models/staff.dart';
import '../money.dart';
import '../device_service.dart';
import '../settings_service.dart';
import '../training_service.dart';
import 'printer_link.dart';

/// This device's printer service, or null where none is set up (some tests).
/// Printing never stops a sale, so callers skip it when absent.
PrintService? get printService => Get.isRegistered<PrintService>() ? Get.find<PrintService>() : null;

/// Something waiting for the printer.
class PrintJob {
  PrintJob(this.title, this.bytes, {this.target});

  final String title;
  final Uint8List bytes;

  /// Another printer than the receipt printer (kitchen tickets).
  final PrinterTarget? target;
  int attempts = 0;

  /// Why the last try failed.
  String? error;
}

/// This device's receipt printer and cash drawer. Jobs queue up and retry
/// on their own when the printer is off or out of paper, so a sale is never
/// held up by the printer.
class PrintService extends GetxService {
  PrintService(
    this._settings,
    this._receipts,
    this._device, {
    PrinterLink Function(PrinterTarget)? links,
    this.retryAfter = const Duration(seconds: 15),
    this._audit,
    this._signedIn,
  }) : _links = links ?? linkFor;

  final SettingsService _settings;
  final ReceiptRepository _receipts;
  final DeviceInfo _device;
  final PrinterLink Function(PrinterTarget) _links;

  /// Reprints go in the activity log: a second copy of a paid receipt is
  /// how a sale gets "rung up" twice.
  final AuditRepository? _audit;
  final Staff? Function()? _signedIn;
  final Duration retryAfter;

  final queue = <PrintJob>[].obs;

  /// The last sale finished on this device since the app started.
  String? _lastSaleId;
  bool _busy = false;
  Timer? _retry;

  PrinterTarget? get printer => PrinterTarget.decode(_settings.get(AppSettings.receiptPrinter));
  bool get hasPrinter => printer != null;
  Paper get paper => Paper.fromMillimetres(_settings.get(AppSettings.paperWidth));
  bool get hasDrawer => hasPrinter && _settings.get(AppSettings.cashDrawer);

  /// Kitchen tickets print here, or on the receipt printer.
  PrinterTarget? get kitchenPrinter => PrinterTarget.decode(_settings.get(AppSettings.kitchenPrinter)) ?? printer;

  /// The first job's error, when the queue is stuck.
  String? get problem => queue.firstOrNull?.error;

  @override
  void onClose() {
    _retry?.cancel();
    super.onClose();
  }

  ReceiptDesign design() {
    final logo = _settings.get(AppSettings.receiptLogo);
    return ReceiptDesign(
      shopName: _settings.get(AppSettings.shopName),
      address: _settings.get(AppSettings.shopAddress),
      phone: _settings.get(AppSettings.shopPhone),
      header: _settings.get(AppSettings.receiptHeader),
      footer: _settings.get(AppSettings.receiptFooter),
      momoNumber: _settings.get(AppSettings.receiptMomo),
      logo: logo.isEmpty ? null : base64Decode(logo),
      showCashier: _settings.get(AppSettings.receiptShowCashier),
      showCustomer: _settings.get(AppSettings.receiptShowCustomer),
      showTax: _settings.get(AppSettings.receiptShowTax),
      showQr: _settings.get(AppSettings.receiptShowQr),
      copies: ReceiptDesign.decodeCopies(_settings.get(AppSettings.receiptCopies)),
      loyaltyStyle: _settings.get(AppSettings.loyaltyStyle),
      stampsForReward: _settings.get(AppSettings.loyaltyStamps),
      orderPrefix: _settings.get(AppSettings.orderPrefix),
      training: Get.isRegistered<TrainingService>() && Get.find<TrainingService>().active.value,
    );
  }

  /// The receipt as it would print (for sending, or the preview).
  Future<ReceiptDoc?> saleDoc(String saleId, {bool reprint = false}) async {
    final data = await _receipts.sale(saleId);
    return data == null ? null : ReceiptBuilder.sale(data, design(), reprint: reprint);
  }

  /// Called once a sale is saved: prints it when this device prints
  /// automatically, and opens the drawer for cash.
  /// [prep] are the lines for the kitchen ticket, when the sale got a
  /// queue number.
  Future<void> afterSale(String saleId, {List<OrderLine> prep = const []}) async {
    _lastSaleId = saleId;
    final data = await _receipts.sale(saleId);
    if (data == null) return;
    if (data.orderNumber != null && prep.isNotEmpty) printKitchenTicket(data.orderNumber!, data.at, prep, note: data.note, orderType: data.orderType);
    if (!hasPrinter) return;
    final kick = hasDrawer && data.paidCash;
    if (_settings.get(AppSettings.autoPrint)) {
      _enqueueSale(data, kick: kick, reprint: false);
    } else if (kick) {
      _enqueue('Cash drawer', EscPos.kickOnly());
    }
  }

  /// Prints a sale's receipt again (or for the first time, when printing
  /// is not automatic). False when there is no printer or no such sale.
  Future<bool> printSale(String saleId, {bool reprint = true}) async {
    if (!hasPrinter) return false;
    final data = await _receipts.sale(saleId);
    if (data == null) return false;
    _enqueueSale(data, kick: false, reprint: reprint);
    if (reprint) {
      await _audit?.record(
        action: AuditAction.receiptReprinted,
        actor: _signedIn?.call(),
        entity: 'sales',
        entityId: saleId,
        summary: '${data.displayNumber} printed again (${formatMoney(data.total)})',
      );
    }
    return true;
  }

  /// The last sale on this device, again.
  Future<bool> reprintLast() async {
    final id = _lastSaleId ?? await _receipts.lastSaleId(_device.deviceId);
    return id != null && await printSale(id);
  }

  void _enqueueSale(ReceiptData data, {required bool kick, required bool reprint}) {
    final d = design();
    final copies = reprint ? 1 : d.copiesFor(data.payments.map((p) => p.method));
    for (var i = 0; i < copies; i++) {
      final copy = copies == 1 ? ReceiptCopy.only : (i == 0 ? ReceiptCopy.customer : ReceiptCopy.shop);
      final doc = ReceiptBuilder.sale(data, d, copy: copy, reprint: reprint);
      _enqueue(doc.title, EscPos.encode(doc, paper, kickDrawer: kick && i == 0));
    }
  }

  /// After a refund: the slip (when printing is automatic) and the drawer
  /// for cash handed back.
  Future<void> afterRefund(String refundId, {bool print = false}) async {
    if (!hasPrinter) return;
    final data = await _receipts.refund(refundId);
    if (data == null) return;
    final kick = hasDrawer && data.paidCash;
    if (print || _settings.get(AppSettings.autoPrint)) {
      final doc = ReceiptBuilder.refund(data, design());
      _enqueue(doc.title, EscPos.encode(doc, paper, kickDrawer: kick));
    } else if (kick) {
      _enqueue('Cash drawer', EscPos.kickOnly());
    }
  }

  /// The refund slip as it would print (for a PDF).
  Future<ReceiptDoc?> refundDoc(String refundId) async {
    final data = await _receipts.refund(refundId);
    return data == null ? null : ReceiptBuilder.refund(data, design());
  }

  Future<bool> printRefund(String refundId) async {
    if (!hasPrinter) return false;
    final data = await _receipts.refund(refundId);
    if (data == null) return false;
    final doc = ReceiptBuilder.refund(data, design());
    _enqueue(doc.title, EscPos.encode(doc, paper));
    return true;
  }

  /// A report or statement on the receipt printer.
  bool printDoc(ReceiptDoc doc) {
    if (!hasPrinter) return false;
    _enqueue(doc.title, EscPos.encode(doc, paper));
    return true;
  }

  /// The kitchen / prep ticket for an order. False when there is no printer.
  bool printKitchenTicket(int number, DateTime at, List<OrderLine> lines, {String? note, OrderType? orderType, String? customerName}) {
    final target = kitchenPrinter;
    if (target == null) return false;
    final paper = PrinterTarget.decode(_settings.get(AppSettings.kitchenPrinter)) == null ? this.paper : Paper.mm80;
    final doc = ReceiptBuilder.kitchenTicket(
      number: '${_settings.get(AppSettings.orderPrefix)}$number',
      at: at,
      lines: lines,
      note: note,
      orderType: orderType,
      customerName: customerName,
    );
    _enqueue(doc.title, EscPos.encode(doc, paper), target: target);
    return true;
  }

  /// Opens the cash drawer (no-sale, pay in or out), when there is one.
  void openDrawer() {
    if (hasDrawer) _enqueue('Cash drawer', EscPos.kickOnly());
  }

  /// Sends a test page straight to [target], not through the queue.
  /// Returns the problem, or null when it went.
  Future<String?> test(PrinterTarget target, Paper paper, {bool drawer = false}) async {
    final doc = ReceiptBuilder.testPage(_settings.get(AppSettings.shopName), paper, target.name);
    try {
      await _links(target).send(EscPos.encode(doc, paper, kickDrawer: drawer));
      return null;
    } on PrinterException catch (e) {
      return e.message;
    }
  }

  void _enqueue(String title, Uint8List bytes, {PrinterTarget? target}) {
    queue.add(PrintJob(title, bytes, target: target));
    unawaited(_pump());
  }

  /// Tries the stuck jobs now instead of waiting.
  Future<void> retryNow() {
    _retry?.cancel();
    return _pump();
  }

  void clearQueue() {
    _retry?.cancel();
    queue.clear();
  }

  Future<void> _pump() async {
    if (_busy) return;
    _busy = true;
    try {
      while (queue.isNotEmpty) {
        final job = queue.first;
        final target = job.target ?? printer;
        if (target == null) {
          queue.removeAt(0);
          continue;
        }
        try {
          await _links(target).send(job.bytes);
          queue.removeAt(0);
        } on PrinterException catch (e) {
          job
            ..attempts += 1
            ..error = e.message;
          queue.refresh();
          _retry?.cancel();
          _retry = Timer(retryAfter, () => unawaited(_pump()));
          break;
        }
      }
    } finally {
      _busy = false;
    }
  }
}
