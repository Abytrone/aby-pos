import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/units.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/inventory.dart';
import '../../../models/drafts.dart';
import '../../../models/enums.dart';
import '../../../models/stock.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';

/// One stock item: on hand, what uses it, its movements, and corrections.
class StockItemController extends GetxController {
  final StockRepository _stock = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();

  final String itemId = Get.arguments as String;

  final item = Rxn<StockItem>();
  final movements = <StockMovement>[].obs;
  final usedBy = <String>[].obs;

  /// Base units used by sales and waste in the last 28 days.
  final used28 = 0.obs;
  final message = RxnString();

  bool get canSeeCost => _auth.can(Permission.viewCostAndProfit);
  bool get canEdit => _auth.can(Permission.editProducts) || _auth.can(Permission.adjustStock);

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    item.value = await _stock.item(itemId);
    movements.assignAll(await _stock.movements(itemId));
    usedBy.assignAll(await _stock.usedBy(itemId));
    used28.value = (await _stock.usedSince(DateTime.now().subtract(const Duration(days: 28))))[itemId] ?? 0;
  }

  /// [amount] typed in [unit]; [add] true for "found more", false for "less".
  Future<bool> adjust(String amount, DisplayUnit unit, {required bool add, required String note}) async {
    final l = appL10n();
    final qty = parseQuantity(amount, unit);
    if (qty == null || qty == 0) {
      message.value = l.stockQuantityInvalid;
      return false;
    }
    final auth = await _permissions.authorize(Permission.adjustStock, reason: l.stockAdjustReason(item.value!.name));
    if (auth == null) return false;
    try {
      await _stock.adjust(itemId, add ? qty : -qty, note: note, by: auth.authority);
      message.value = l.stockAdjusted;
      await load();
      return true;
    } on StockException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  Future<bool> logWaste(String amount, DisplayUnit unit, {required WasteReason reason, String? note}) async {
    final l = appL10n();
    final qty = parseQuantity(amount, unit);
    if (qty == null || qty <= 0) {
      message.value = l.stockQuantityInvalid;
      return false;
    }
    // Recording a loss is allowed for anyone who handles stock.
    final auth = await _permissions.authorize(Permission.adjustStock, reason: l.stockWasteReason(item.value!.name));
    if (auth == null) return false;
    try {
      await _stock.logWaste(itemId, qty, reason: reason, note: note, by: auth.authority);
      message.value = l.stockWasted;
      await load();
      return true;
    } on StockException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  Future<bool> save(StockItemDraft d) async {
    final auth = await _permissions.authorize(Permission.editProducts, reason: appL10n().stockEditReason);
    if (auth == null) return false;
    try {
      await _stock.saveItem(d, by: auth.authority);
      message.value = appL10n().settingsSaved;
      await load();
      return true;
    } on StockException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  int? get suggestedLowLevel => Inventory.suggestReorderPoint(used: used28.value);

  double? get daysLeft => Inventory.daysLeft(onHand: item.value?.onHand ?? 0, used: used28.value);

  /// Sets the low level to the suggestion (and the usual order to a week's use
  /// when none is set).
  Future<void> useSuggestion() async {
    final i = item.value;
    final s = suggestedLowLevel;
    if (i == null || s == null) return;
    await save(StockItemDraft(
      id: i.id,
      name: i.name,
      unit: i.unit,
      costMilli: i.costMilli,
      reorderPoint: s,
      reorderQty: i.reorderQty ?? (used28.value / 4).ceil(),
      supplierId: i.supplierId,
    ));
  }

  Future<void> setActive(bool active) async {
    final auth = await _permissions.authorize(Permission.editProducts, reason: appL10n().stockEditReason);
    if (auth == null) return;
    await _stock.setItemActive(itemId, active: active, by: auth.authority);
    await load();
  }
}
