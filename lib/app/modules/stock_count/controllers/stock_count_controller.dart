import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/units.dart';
import '../../../data/repositories/stock_count_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../models/enums.dart';
import '../../../models/purchasing.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';

/// Counting stock: type what is on the shelf, item by item; then someone
/// allowed reviews the differences and posts them.
class StockCountController extends GetxController {
  final StockCountRepository _counts = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();

  final String countId = Get.arguments as String;

  final count = Rxn<StockCount>();
  final lines = <StockCountLine>[].obs;
  final query = ''.obs;
  final message = RxnString();

  /// Typed amounts, in each item's bulk unit (kg, L, pcs).
  final fields = <String, TextEditingController>{};

  bool get isOpen => count.value?.status == StockCountStatus.open;

  /// Blind counts hide what the till expects from counters.
  bool get showExpected => !(count.value?.blind ?? true) || _auth.can(Permission.approveStockCount) || !isOpen;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final f in fields.values) {
      f.dispose();
    }
    super.onClose();
  }

  Future<void> load() async {
    count.value = await _counts.find(countId);
    lines.assignAll(await _counts.lines(countId));
    for (final l in lines) {
      final unit = DisplayUnit.bulk(l.unit);
      fields.putIfAbsent(l.stockItemId, TextEditingController.new).text =
          l.counted == null ? '' : quantityIn(l.counted!, unit);
    }
  }

  List<StockCountLine> get visible {
    final q = query.value.trim().toLowerCase();
    return q.isEmpty ? lines : lines.where((l) => l.name.toLowerCase().contains(q)).toList();
  }

  int get countedCount => lines.where((l) => l.counted != null).length;

  /// Pesewas: + found, − short, for the lines counted so far.
  int get differenceValue => lines.fold(0, (s, l) => s + (l.difference == null ? 0 : costOf(l.difference!, l.costMilli)));

  Future<void> saveLine(StockCountLine line) async {
    final text = fields[line.stockItemId]?.text ?? '';
    if (text.trim().isEmpty) return;
    final qty = parseQuantity(text, DisplayUnit.bulk(line.unit));
    if (qty == null) {
      message.value = appL10n().stockQuantityInvalid;
      return;
    }
    try {
      await _counts.setCount(countId, line.stockItemId, qty, by: _auth.user);
      final updated = (await _counts.lines(countId)).firstWhere((l) => l.stockItemId == line.stockItemId);
      final i = lines.indexWhere((l) => l.stockItemId == line.stockItemId);
      lines[i] = updated;
    } on StockException catch (e) {
      message.value = e.message;
    }
  }

  /// Returns true when posted.
  Future<bool> post() async {
    final l = appL10n();
    final auth = await _permissions.authorize(Permission.approveStockCount, reason: l.countPostReason);
    if (auth == null) return false;
    try {
      final value = await _counts.post(countId, by: auth.authority);
      message.value = value == 0
          ? l.countPostedSame
          : value > 0
              ? l.countPostedFound(formatMoney(value))
              : l.countPostedShort(formatMoney(-value));
      await load();
      return true;
    } on StockException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  Future<void> cancel() async {
    await _counts.cancel(countId, by: _auth.user);
    await load();
  }
}
