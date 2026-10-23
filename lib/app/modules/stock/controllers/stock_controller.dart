import 'dart:async';

import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/catalogue_io.dart';
import '../../../models/drafts.dart';
import '../../../models/staff.dart';
import '../../../models/stock.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import '../../../ui/files.dart';
import '../../../ui/l10n.dart';

enum StockFilter { all, low, retired }

/// Manage → Stock: stock items, what is on hand and what it is worth.
class StockController extends GetxController {
  final StockRepository _stock = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();

  final loading = true.obs;
  final items = <StockItem>[].obs;
  final query = ''.obs;
  final filter = StockFilter.all.obs;
  final message = RxnString();

  StreamSubscription<void>? _sub;
  Timer? _debounce;

  bool get canEdit => _auth.can(Permission.editProducts) || _auth.can(Permission.adjustStock);
  bool get canSeeCost => _auth.can(Permission.viewCostAndProfit);

  @override
  void onInit() {
    super.onInit();
    load();
    _sub = _stock.watchChanges().listen((_) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 300), load);
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    items.assignAll(await _stock.items(includeInactive: true));
    loading.value = false;
  }

  List<StockItem> get visible {
    final q = query.value.trim().toLowerCase();
    return [
      for (final i in items)
        if (switch (filter.value) {
              StockFilter.all => i.active,
              StockFilter.low => i.active && i.isLow,
              StockFilter.retired => !i.active,
            } &&
            (q.isEmpty || i.name.toLowerCase().contains(q)))
          i,
    ];
  }

  int get lowCount => items.where((i) => i.active && i.isLow).length;

  /// Pesewas, everything on hand at cost.
  int get totalValue => items.where((i) => i.active).fold(0, (s, i) => s + i.value);

  Future<void> openItem(StockItem item) async {
    await Get.toNamed<void>(Routes.stockItem, arguments: item.id);
    await load();
  }

  /// Returns true when saved.
  Future<bool> saveItem(StockItemDraft d) async {
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

  Staff get me => _auth.user;

  Future<void> exportStock() async {
    final csv = Get.find<CatalogueIo>().exportStock(items);
    await shareOrSaveText('stock-${DateTime.now().toIso8601String().substring(0, 10)}.csv', csv);
  }
}
