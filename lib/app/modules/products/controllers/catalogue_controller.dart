import 'dart:async';
import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../core/tax.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/catalogue_rules.dart';
import '../../../models/catalog.dart';
import '../../../models/drafts.dart';
import '../../../models/enums.dart';
import '../../../models/staff.dart';
import '../../../models/stock.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/l10n.dart';

enum ProductFilter { all, onTill, offTill, belowMargin, archived }

/// Manage → Products: the product list, categories, option groups and taxes.
class CatalogueController extends GetxController {
  final CatalogRepository _catalog = Get.find();
  final CatalogueRules _rules = Get.find();
  final StockRepository _stock = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();
  final SettingsService _settings = Get.find();

  final loading = true.obs;
  final catalogue = Rxn<Catalogue>();
  final stockItems = <StockItem>[].obs;
  final photos = <String, Uint8List>{}.obs;
  final message = RxnString();

  final query = ''.obs;
  final filter = ProductFilter.all.obs;
  final categoryId = RxnString();

  StreamSubscription<void>? _sub;
  Timer? _debounce;

  bool get canEdit => _auth.can(Permission.editProducts);
  bool get canSeeCost => _auth.can(Permission.viewCostAndProfit);
  int get targetMargin => _settings.get(AppSettings.targetMarginPercent);
  TaxMode get taxMode => TaxMode.fromName(_settings.get(AppSettings.taxMode));

  @override
  void onInit() {
    super.onInit();
    load();
    _sub = _catalog.watchChanges().listen((_) {
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
    catalogue.value = await _catalog.load(includeInactive: true, includeArchived: true);
    stockItems.assignAll(await _stock.items(includeInactive: true));
    photos.assignAll(await _catalog.allPhotos());
    loading.value = false;
  }

  List<Category> get categories => catalogue.value?.categories ?? const [];
  List<OptionGroup> get groups => catalogue.value?.groups ?? const [];
  List<TaxRate> get taxRates => catalogue.value?.taxRates ?? const [];

  /// Gross margin as a whole percent, or null when the cost is unknown.
  static int? marginOf(int price, int? cost) =>
      cost == null || price <= 0 ? null : ((price - cost) * 100 / price).round();

  bool belowTarget(Product p) =>
      p.variants.any((v) => (marginOf(v.price, v.cost) ?? 100) < targetMargin);

  List<Product> get visibleProducts {
    final all = catalogue.value?.products ?? const <Product>[];
    final q = query.value.trim().toLowerCase();
    final cat = categoryId.value;
    final inCategory = cat == null ? null : {cat, for (final c in categories) if (c.parentId == cat) c.id};
    return [
      for (final p in all)
        if (switch (filter.value) {
              ProductFilter.all => !p.archived,
              ProductFilter.onTill => !p.archived && p.active,
              ProductFilter.offTill => !p.archived && !p.active,
              ProductFilter.belowMargin => !p.archived && belowTarget(p),
              ProductFilter.archived => p.archived,
            } &&
            (inCategory == null || inCategory.contains(p.categoryId)) &&
            (q.isEmpty ||
                p.name.toLowerCase().contains(q) ||
                p.variants.any((v) => v.barcodes.any((b) => b.contains(q)))))
          p,
    ];
  }

  Category? categoryOf(String id) => catalogue.value?.category(id);

  // ---------------------------------------------------------------------------
  // Products

  Future<void> openEditor([Product? product]) async {
    await Get.toNamed<void>(Routes.productEditor, arguments: product?.id);
    await load();
  }

  Future<void> duplicate(Product p) => _run(Permission.editProducts, appL10n().productsDuplicateReason, (by) async {
        await _rules.duplicateProduct(p, by: by);
        message.value = appL10n().productsDuplicated(p.name);
      });

  Future<void> setArchived(Product p, bool archived) =>
      _run(Permission.editProducts, appL10n().productsArchiveReason, (by) async {
        await _catalog.setArchived(p.id, archived: archived, by: by);
        message.value = archived ? appL10n().productsArchived(p.name) : appL10n().productsRestored(p.name);
      });

  // ---------------------------------------------------------------------------
  // Categories

  Future<bool> saveCategory(CategoryDraft d) => _run(Permission.editProducts, appL10n().productsEditReason, (by) async {
        await _rules.saveCategory(d, by: by);
        message.value = appL10n().settingsSaved;
      });

  Future<void> setCategoryActive(Category c, bool active) =>
      _run(Permission.editProducts, appL10n().productsEditReason, (by) => _catalog.setCategoryActive(c.id, active: active, by: by));

  Future<int> productCount(Category c) => _catalog.productCount(c.id);

  // ---------------------------------------------------------------------------
  // Option groups

  Future<bool> saveOptionGroup(OptionGroupDraft d) =>
      _run(Permission.editProducts, appL10n().productsEditReason, (by) async {
        await _rules.saveOptionGroup(d, by: by);
        message.value = appL10n().settingsSaved;
      });

  Future<void> setGroupActive(OptionGroup g, bool active) =>
      _run(Permission.editProducts, appL10n().productsEditReason, (by) => _catalog.setOptionGroupActive(g.id, active: active, by: by));

  /// Products using a group, by name.
  List<String> productsUsing(OptionGroup g) => [
        for (final p in catalogue.value?.products ?? const <Product>[])
          if (!p.archived && p.groups.any((x) => x.id == g.id)) p.name,
      ];

  // ---------------------------------------------------------------------------
  // Taxes

  Future<bool> saveTaxRate(TaxRateDraft d) => _run(Permission.changeSettings, appL10n().taxApprovalReason, (by) async {
        await _rules.saveTaxRate(d, by: by);
        message.value = appL10n().settingsSaved;
      });

  Future<void> setTaxActive(TaxRate t, bool active) =>
      _run(Permission.changeSettings, appL10n().taxApprovalReason, (by) => _catalog.setTaxRateActive(t.id, active: active, by: by));

  Future<void> setTaxMode(TaxMode mode) => _run(Permission.changeSettings, appL10n().taxApprovalReason, (by) async {
        await _settings.set(AppSettings.taxMode, mode.name, by: by);
        message.value = appL10n().settingsSaved;
      });

  /// What a GH₵ 100.00 sale looks like with [rates], for the taxes screen.
  String taxExample(List<TaxRate> rates) {
    final mode = taxMode == TaxMode.off ? TaxMode.inclusive : taxMode;
    final r = computeTax(10000, [for (final t in rates) t.spec], mode);
    return appL10n().taxExample(formatMoney(r.base), formatMoney(r.taxTotal), formatMoney(r.total));
  }

  /// Runs [action] once someone allowed has authorised it. Returns true on
  /// success; rule failures become [message].
  Future<bool> _run(Permission p, String reason, Future<void> Function(Staff by) action) async {
    final auth = await _permissions.authorize(p, reason: reason);
    if (auth == null) return false;
    try {
      await action(auth.authority);
      await load();
      return true;
    } on CatalogueException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  /// "15" or "2.5" (percent) into basis points (1500, 250). Percent with two
  /// decimals has the same shape as cedis with pesewas, so reuse that parser.
  static int? parsePercent(String input) => parseMoney(input.replaceAll('%', ''));

  /// Colour tones offered for categories.
  static const tones = CategoryTone.values;

  /// Stock item by ID.
  StockItem? stockItem(String id) => stockItems.firstWhereOrNull((s) => s.id == id);
}
