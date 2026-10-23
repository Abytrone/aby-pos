import 'dart:async';

import 'package:get/get.dart';

import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../models/catalog.dart';
import '../../../routes/app_routes.dart';
import '../../../services/device_service.dart';
import 'cart_controller.dart';

/// The till screen: menu, category filter, and the size/options picker.
/// Reloads by itself when the menu or stock changes.
class TillController extends GetxController {
  final CatalogRepository _catalog = Get.find();
  final StockRepository _stock = Get.find();
  final DeviceService _device = Get.find();
  final CartController cart = Get.find();

  final loading = true.obs;
  final categories = <Category>[].obs;
  final products = <Product>[].obs;

  /// Stock on hand per stock item (base units).
  final onHand = <String, int>{}.obs;

  /// Top-level category; null shows everything.
  final selectedCategoryId = RxnString();

  // The open picker sheet.
  final pickerProduct = Rxn<Product>();
  final pickerVariant = Rxn<Variant>();

  /// Picked options; an option picked twice appears twice.
  final pickerOptions = <Option>[].obs;

  StreamSubscription<void>? _catalogueSub;
  StreamSubscription<void>? _stockSub;
  Timer? _debounce;

  @override
  void onInit() {
    super.onInit();
    _load();
    _catalogueSub = _catalog.watchChanges().listen((_) => _reloadSoon());
    _stockSub = _stock.watchChanges().listen((_) => _reloadSoon(stockOnly: true));
  }

  @override
  void onClose() {
    _catalogueSub?.cancel();
    _stockSub?.cancel();
    _debounce?.cancel();
    super.onClose();
  }

  Future<void> _load() async {
    await _device.ready;
    final catalogue = await _catalog.load();
    categories.assignAll(catalogue.categories);
    products.assignAll(catalogue.products);
    onHand.assignAll(await _stock.onHandAll());
    cart.refreshProducts(catalogue.products);
    loading.value = false;
  }

  var _stockOnly = true;
  void _reloadSoon({bool stockOnly = false}) {
    _stockOnly = _stockOnly && stockOnly;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (_stockOnly) {
        onHand.assignAll(await _stock.onHandAll());
      } else {
        await _load();
      }
      _stockOnly = true;
    });
  }

  List<Category> get topCategories => categories.where((c) => c.parentId == null).toList();

  List<Product> get visibleProducts {
    final id = selectedCategoryId.value;
    if (id == null) return products;
    final ids = {id, for (final c in categories) if (c.parentId == id) c.id};
    return products.where((p) => ids.contains(p.categoryId)).toList();
  }

  Category? categoryOf(Product product) =>
      categories.firstWhereOrNull((c) => c.id == product.categoryId);

  /// How many can still be made, when one stock item limits it (a tub, a
  /// waffle's mix). Null when the till cannot tell.
  int? leftOf(Product product) {
    if (product.variants.length != 1) return null;
    final sole = product.variants.single.soleStockItem;
    if (sole == null || sole.quantity <= 0) return null;
    final have = onHand[sole.stockItemId] ?? 0;
    return have <= 0 ? 0 : have ~/ sole.quantity;
  }

  void selectCategory(String? id) => selectedCategoryId.value = id;

  /// One tap: add straight away when nothing needs choosing, otherwise open
  /// the picker. Returns true when the picker should be shown.
  bool tapProduct(Product product) {
    if (!product.oneTap) {
      openPicker(product);
      return true;
    }
    cart.add(product, options: [for (final g in product.groups) ...g.defaults]);
    return false;
  }

  /// Long press: the picker for any product with something to choose.
  bool longPressProduct(Product product) {
    if (!product.hasChoices) return false;
    openPicker(product);
    return true;
  }

  void openPicker(Product product) {
    pickerProduct.value = product;
    pickerVariant.value = product.variants.first;
    pickerOptions.assignAll([for (final g in product.groups) ...g.defaults]);
  }

  void pickVariant(Variant variant) => pickerVariant.value = variant;

  int countOf(Option option) => pickerOptions.where((o) => o.id == option.id).length;

  int countIn(OptionGroup group) => pickerOptions.where((o) => o.groupId == group.id).length;

  /// Tap an option: picks it, or (for groups without repeats) unpicks it.
  /// A group that allows one choice swaps instead.
  void tapOption(OptionGroup group, Option option) {
    final picked = countOf(option);
    final full = group.maxSelect != null && countIn(group) >= group.maxSelect!;
    if (!group.allowRepeat && picked > 0) {
      pickerOptions.removeWhere((o) => o.id == option.id);
      return;
    }
    if (full) {
      if (group.maxSelect == 1) {
        pickerOptions.removeWhere((o) => o.groupId == group.id);
        pickerOptions.add(option);
      }
      return;
    }
    pickerOptions.add(option);
  }

  /// Takes one of a repeated option away.
  void removeOneOption(Option option) {
    final index = pickerOptions.indexWhere((o) => o.id == option.id);
    if (index != -1) pickerOptions.removeAt(index);
  }

  /// Every group's rules are met.
  bool get pickerValid {
    final product = pickerProduct.value;
    if (product == null) return false;
    return product.groups.every((g) => g.accepts(countIn(g)));
  }

  /// Pesewas for one of the current pick.
  int get pickerPrice {
    final variant = pickerVariant.value;
    if (variant == null) return 0;
    return variant.price + pickerOptions.fold(0, (sum, o) => sum + o.priceDelta);
  }

  void confirmPick() {
    final product = pickerProduct.value;
    if (product == null || !pickerValid) return;
    cart.add(product, variant: pickerVariant.value, options: pickerOptions.toList());
    closePicker();
  }

  void closePicker() {
    pickerProduct.value = null;
    pickerVariant.value = null;
    pickerOptions.clear();
  }

  void pay() {
    if (cart.isEmpty) return;
    Get.toNamed<void>(Routes.checkout);
  }
}
