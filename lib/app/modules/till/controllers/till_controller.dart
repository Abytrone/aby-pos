import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/scale_barcode.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/cash_event_repository.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/discount_repository.dart';
import '../../../data/repositories/parked_order_repository.dart';
import '../../../data/repositories/sale_repository.dart';
import '../../../domain/receipt/receipt_code.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/catalogue_rules.dart';
import '../../../models/cart_line.dart';
import '../../../models/catalog.dart';
import '../../../models/discount.dart';
import '../../../models/enums.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/l10n.dart';
import '../../shell/controllers/shell_controller.dart';
import 'cart_controller.dart';

/// The tabs above the grid: Quick, All, a category, or Recent.
sealed class TillTab {
  const TillTab();
}

class QuickTab extends TillTab {
  const QuickTab();
}

class AllTab extends TillTab {
  const AllTab();
}

class RecentTab extends TillTab {
  const RecentTab();
}

class CategoryTab extends TillTab {
  const CategoryTab(this.id);
  final String id;

  @override
  bool operator ==(Object other) => other is CategoryTab && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// What a tap on a tile needs from the screen before it can go in the cart.
enum TapResult { added, picker, entry, blocked }

/// What submitting the search / scan box did.
sealed class CodeResult {
  const CodeResult();
}

class CodeAdded extends CodeResult {
  const CodeAdded(this.product);
  final Product product;
}

/// The product needs a choice or a typed value: the screen opens it.
class CodeNeedsInput extends CodeResult {
  const CodeNeedsInput(this.product, this.result);
  final Product product;
  final TapResult result;
}

class CodeNotFound extends CodeResult {
  const CodeNotFound(this.code, {required this.canCreate});
  final String code;

  /// Looks like a barcode and the person may add products.
  final bool canCreate;
}

/// A receipt's QR code: the screen opens the sale for a refund or reprint.
class CodeReceipt extends CodeResult {
  const CodeReceipt(this.saleId);
  final String saleId;
}

class CodeNothing extends CodeResult {
  const CodeNothing();
}

/// The till screen: menu, tabs, search and scanning, the picker, line edits
/// and parked orders. Reloads by itself when the menu or stock changes.
class TillController extends GetxController {
  final CatalogRepository _catalog = Get.find();
  final CatalogueRules _rules = Get.find();
  final StockRepository _stock = Get.find();
  final SaleRepository _sales = Get.find();
  final ParkedOrderRepository _parked = Get.find();
  final DiscountRepository _discounts = Get.find();
  final DeviceService _device = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();
  final SettingsService _settings = Get.find();
  final CartController cart = Get.find();

  final loading = true.obs;
  final categories = <Category>[].obs;
  final products = <Product>[].obs;
  final recentIds = <String>[].obs;
  final parkedOrders = <ParkedOrder>[].obs;
  final savedDiscounts = <SavedDiscount>[].obs;
  final discountReasons = <Reason>[].obs;
  final noSaleReasons = <Reason>[].obs;
  final photos = <String, ImageProvider>{}.obs;

  /// Stock on hand per stock item (base units).
  final onHand = <String, int>{}.obs;

  final tab = Rx<TillTab>(const AllTab());

  /// The search / scan box. Digits alone are a quantity for the next tap
  /// (or a code, with Enter).
  final search = TextEditingController();
  final searchFocus = FocusNode(debugLabel: 'till search');
  final query = ''.obs;

  /// For the screen to show once (dropped lines, out-of-stock warnings).
  final message = RxnString();

  // The open picker sheet.
  final pickerProduct = Rxn<Product>();
  final pickerVariant = Rxn<Variant>();

  /// Picked options; an option picked twice appears twice.
  final pickerOptions = <Option>[].obs;

  /// The cart line the picker is changing, when it was opened from a line.
  String? pickerLineKey;

  /// Quantity for the picker's line (from the typed quantity).
  int _pickerQuantity = 1;

  StreamSubscription<void>? _catalogueSub;
  StreamSubscription<void>? _stockSub;
  StreamSubscription<List<ParkedOrder>>? _parkedSub;
  Timer? _debounce;
  var _chosenTab = false;

  @override
  void onInit() {
    super.onInit();
    search.addListener(() => query.value = search.text);
    _load();
    _catalogueSub = _catalog.watchChanges().listen((_) => _reloadSoon());
    _stockSub = _stock.watchChanges().listen((_) => _reloadSoon(stockOnly: true));
    _parkedSub = _parked.watchParked().listen(parkedOrders.assignAll);
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _catalogueSub?.cancel();
    _stockSub?.cancel();
    _parkedSub?.cancel();
    _debounce?.cancel();
    search.dispose();
    searchFocus.dispose();
    super.onClose();
  }

  Future<void> _load() async {
    await _device.ready;
    final catalogue = await _catalog.load();
    categories.assignAll(catalogue.categories);
    products.assignAll(catalogue.products);
    onHand.assignAll(await _stock.onHandAll());
    recentIds.assignAll(await _sales.recentProductIds());
    savedDiscounts.assignAll(await _discounts.discounts());
    discountReasons.assignAll(await _discounts.reasons(ReasonKind.discount));
    noSaleReasons.assignAll(await _discounts.reasons(ReasonKind.noSale));
    photos.assignAll({for (final e in (await _catalog.allPhotos()).entries) e.key: MemoryImage(e.value)});
    cart.refreshProducts(catalogue.products);
    final dropped = await cart.restoreSaved(catalogue.products);
    if (dropped != null && dropped > 0) message.value = appL10n().cartDropped(dropped);
    if (!_chosenTab) tab.value = quickProducts.isNotEmpty ? const QuickTab() : const AllTab();
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

  /// After a sale: the Recent tab changes.
  Future<void> refreshRecent() async => recentIds.assignAll(await _sales.recentProductIds());

  /// A keyboard or barcode scanner types straight into the search box while
  /// the till is showing and nothing else is being typed into. Enter in the
  /// box submits it (the screen handles that).
  bool _onHardwareKey(KeyEvent event) {
    if (event is! KeyDownEvent || !_tillShowing) return false;
    final focus = FocusManager.instance.primaryFocus;
    if (focus == searchFocus) return false;
    if (focus?.context?.findAncestorWidgetOfExactType<EditableText>() != null) return false;
    if (event.logicalKey == LogicalKeyboardKey.escape && query.value.isNotEmpty) {
      clearSearch();
      return true;
    }
    final char = event.character;
    if (char == null || char.isEmpty || char.codeUnitAt(0) < 32) return false;
    search.value = TextEditingValue(
      text: search.text + char,
      selection: TextSelection.collapsed(offset: search.text.length + 1),
    );
    searchFocus.requestFocus();
    return true;
  }

  bool get _tillShowing =>
      !loading.value &&
      Get.isDialogOpen != true &&
      Get.isBottomSheetOpen != true &&
      Get.currentRoute == Routes.shell &&
      (!Get.isRegistered<ShellController>() || Get.find<ShellController>().section.value == ShellSection.sell);

  // ---------------------------------------------------------------------------
  // What the grid shows

  List<Category> get topCategories => categories.where((c) => c.parentId == null).toList();

  List<Product> get quickProducts =>
      products.where((p) => p.quickOrder != null).toList()..sort((a, b) => a.quickOrder!.compareTo(b.quickOrder!));

  List<Product> get recentProducts {
    final byId = {for (final p in products) p.id: p};
    return [for (final id in recentIds) ?byId[id]];
  }

  /// Digits alone in the box: a quantity for the next tap (1 to 999).
  int? get pendingQuantity {
    final q = query.value.trim();
    if (!RegExp(r'^\d{1,3}$').hasMatch(q)) return null;
    final n = int.parse(q);
    return n >= 1 ? n : null;
  }

  /// Text to filter by (not a quantity).
  String get filterText => pendingQuantity == null ? query.value.trim().toLowerCase() : '';

  List<Product> get visibleProducts {
    final text = filterText;
    if (text.isNotEmpty) {
      return products
          .where((p) => p.name.toLowerCase().contains(text) || (p.detail ?? '').toLowerCase().contains(text))
          .toList();
    }
    return switch (tab.value) {
      QuickTab() => quickProducts,
      RecentTab() => recentProducts,
      AllTab() => products,
      CategoryTab(:final id) => () {
          final ids = {id, for (final c in categories) if (c.parentId == id) c.id};
          return products.where((p) => ids.contains(p.categoryId)).toList();
        }(),
    };
  }

  Category? categoryOf(Product product) => categories.firstWhereOrNull((c) => c.id == product.categoryId);

  /// How many can still be made, when one stock item limits it (a tub, a
  /// waffle's mix). Null when the till cannot tell.
  int? leftOf(Product product) {
    if (product.variants.length != 1 || product.weighed) return null;
    final sole = product.variants.single.soleStockItem;
    if (sole == null || sole.quantity <= 0) return null;
    final have = onHand[sole.stockItemId] ?? 0;
    return have <= 0 ? 0 : have ~/ sole.quantity;
  }

  void selectTab(TillTab value) {
    _chosenTab = true;
    tab.value = value;
    clearSearch();
  }

  void clearSearch() => search.clear();

  bool get canEditProducts => _auth.can(Permission.editProducts);
  bool get canOverridePrice => _auth.can(Permission.overridePrice);
  bool get orderTypesOn => _settings.get(AppSettings.orderTypes);

  // ---------------------------------------------------------------------------
  // Adding

  /// One tap. Adds straight away when nothing needs choosing; otherwise the
  /// screen opens the picker or the price / weight entry.
  TapResult tapProduct(Product product, {Variant? variant}) {
    final qty = pendingQuantity ?? 1;
    if (_blockedOut(product)) return TapResult.blocked;
    if (product.needsEntry) {
      _pickerQuantity = qty;
      pickerProduct.value = product;
      pickerVariant.value = variant ?? product.variants.first;
      return TapResult.entry;
    }
    if (variant == null && !product.oneTap) {
      openPicker(product, quantity: qty);
      return TapResult.picker;
    }
    if (variant != null && product.groups.any((g) => g.required && !g.accepts(g.defaults.length))) {
      openPicker(product, quantity: qty, variant: variant);
      return TapResult.picker;
    }
    cart.add(product, variant: variant, options: [for (final g in product.groups) ...g.defaults], quantity: qty);
    clearSearch();
    return TapResult.added;
  }

  /// Long press: the picker for any product with something to choose.
  bool longPressProduct(Product product) {
    if (!product.hasChoices || product.needsEntry) return false;
    openPicker(product, quantity: pendingQuantity ?? 1);
    return true;
  }

  /// Out of stock: allowed with a warning, or refused, by the shop setting.
  bool _blockedOut(Product product) {
    final left = leftOf(product);
    if (left == null || left > cart.countFor(product.id)) return false;
    final l = appL10n();
    if (!_settings.get(AppSettings.allowNegativeStock)) {
      message.value = l.tillOutBlocked(product.name);
      return true;
    }
    message.value = l.tillOutWarning(product.name);
    return false;
  }

  /// The price typed for an open-price product, or the weight for a weighed
  /// one ([amount] in pesewas, or grams / ml). Returns an error to show.
  String? confirmEntry({int? price, int? amount}) {
    final product = pickerProduct.value;
    final variant = pickerVariant.value;
    if (product == null || variant == null) return null;
    final l = appL10n();
    if (product.openPrice) {
      if (price == null || price < 0) return l.tillPriceInvalid;
      if (product.minPrice != null && price < product.minPrice!) return l.tillPriceLow(formatMoney(product.minPrice!));
      if (product.maxPrice != null && price > product.maxPrice!) return l.tillPriceHigh(formatMoney(product.maxPrice!));
    }
    if (product.weighed && (amount == null || amount <= 0)) return l.tillWeightInvalid;
    cart.add(
      product,
      variant: variant,
      options: [for (final g in product.groups) ...g.defaults],
      quantity: product.weighed ? amount! : _pickerQuantity,
      customPrice: product.openPrice ? price : null,
    );
    closePicker();
    clearSearch();
    return null;
  }

  /// Enter in the search / scan box: a barcode or PLU code, a scale barcode,
  /// or the only product the search matches.
  Future<CodeResult> submitCode() async {
    final text = query.value.trim();
    if (text.isEmpty) return const CodeNothing();
    final receipt = ReceiptCode.parse(text);
    if (receipt != null) {
      search.clear();
      return CodeReceipt(receipt);
    }
    final byId = {for (final p in products) p.id: p};

    Future<(Product, Variant)?> lookup(String code) async {
      final hit = await _catalog.findBarcode(code);
      final p = hit == null ? null : byId[hit.$1];
      final v = p?.variants.where((v) => v.id == hit!.$2).firstOrNull;
      return p == null || v == null ? null : (p, v);
    }

    final found = await lookup(text);
    if (found != null) {
      final (product, variant) = found;
      search.clear();
      final result = tapProduct(product, variant: variant);
      return result == TapResult.added ? CodeAdded(product) : CodeNeedsInput(product, result);
    }

    final scale = ScaleBarcode.parse(text, prefix: _settings.get(AppSettings.scalePrefix));
    if (scale != null) {
      final hit = await lookup(scale.itemCode) ?? await lookup(scale.shortCode);
      if (hit != null) {
        final (product, variant) = hit;
        search.clear();
        if (!product.weighed) {
          cart.add(product, variant: variant);
        } else if (_settings.get(AppSettings.scaleValue) == 'price') {
          // The label shows the price: work the weight out from it.
          final perKg = variant.price;
          final grams = perKg <= 0 ? 0 : (scale.value * 1000 + perKg ~/ 2) ~/ perKg;
          cart.add(product, variant: variant, quantity: grams < 1 ? 1 : grams);
        } else {
          cart.add(product, variant: variant, quantity: scale.value < 1 ? 1 : scale.value);
        }
        return CodeAdded(product);
      }
    }

    final matches = visibleProducts;
    if (filterText.isNotEmpty && matches.length == 1) {
      final product = matches.single;
      final result = tapProduct(product);
      return result == TapResult.added ? CodeAdded(product) : CodeNeedsInput(product, result);
    }
    final looksLikeBarcode = RegExp(r'^[0-9A-Za-z-]{4,}$').hasMatch(text) && RegExp(r'\d').hasMatch(text);
    return CodeNotFound(text, canCreate: looksLikeBarcode && canEditProducts);
  }

  /// Unknown barcode: a new product with it, for people who may add them.
  void newProductWithBarcode(String code) {
    search.clear();
    Get.toNamed<void>(Routes.productEditor, arguments: {'barcode': code});
  }

  // ---------------------------------------------------------------------------
  // The picker

  void openPicker(Product product, {int quantity = 1, Variant? variant, CartLine? editing}) {
    _pickerQuantity = quantity;
    pickerLineKey = editing?.key;
    pickerProduct.value = product;
    pickerVariant.value = editing?.variant ?? variant ?? product.variants.first;
    pickerOptions.assignAll(editing?.options ?? [for (final g in product.groups) ...g.defaults]);
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
    final variant = pickerVariant.value;
    if (product == null || variant == null || !pickerValid) return;
    final editing = pickerLineKey;
    if (editing != null) {
      cart.replacePick(editing, variant: variant, options: pickerOptions.toList());
    } else {
      cart.add(product, variant: variant, options: pickerOptions.toList(), quantity: _pickerQuantity);
      clearSearch();
    }
    closePicker();
  }

  void closePicker() {
    pickerProduct.value = null;
    pickerVariant.value = null;
    pickerLineKey = null;
    pickerOptions.clear();
    _pickerQuantity = 1;
  }

  // ---------------------------------------------------------------------------
  // Line and order changes that need someone's say-so

  /// Discounts within the person's limit go straight on; bigger ones need a
  /// PIN from someone whose limit covers them. Returns false if refused.
  Future<bool> setLineDiscount(String key, Discount? discount) async {
    final line = cart.line(key);
    if (line == null) return false;
    if (discount == null) {
      cart.setLineDiscount(key, null);
      return true;
    }
    final approved = await _approveDiscount(discount, base: line.lineTotal, what: line.title);
    if (approved == null) return false;
    cart.setLineDiscount(key, approved);
    return true;
  }

  Future<bool> setOrderDiscount(Discount? discount) async {
    if (discount == null) {
      cart.orderDiscount.value = null;
      return true;
    }
    final base = cart.pricing.lines.fold(0, (s, l) => s + l.line.netTotal);
    final approved = await _approveDiscount(discount, base: base, what: appL10n().cartWholeOrder);
    if (approved == null) return false;
    cart.orderDiscount.value = approved;
    return true;
  }

  Future<Discount?> _approveDiscount(Discount discount, {required int base, required String what}) async {
    final percent = Discount.percentOf(discount.amountOn(base), base);
    final auth = await _permissions.authorizeDiscount(
      percent,
      reason: appL10n().discountApprovalReason(discount.label, what),
    );
    if (auth == null) return null;
    return auth.approver == null ? discount : discount.copyWith(approvedBy: auth.approver!.name);
  }

  /// A price override needs the overridePrice permission (or a PIN). Open
  /// prices are typed freely within the product's limits.
  Future<String?> setLinePrice(String key, int? price) async {
    final line = cart.line(key);
    if (line == null) return null;
    final l = appL10n();
    if (price != null && price < 0) return l.tillPriceInvalid;
    if (line.product.openPrice) {
      final p = line.product;
      if (price == null) return l.tillPriceInvalid;
      if (p.minPrice != null && price < p.minPrice!) return l.tillPriceLow(formatMoney(p.minPrice!));
      if (p.maxPrice != null && price > p.maxPrice!) return l.tillPriceHigh(formatMoney(p.maxPrice!));
      cart.setLinePrice(key, price);
      return null;
    }
    if (price == null || price == line.listPrice) {
      cart.setLinePrice(key, null);
      return null;
    }
    final auth = await _permissions.authorize(
      Permission.overridePrice,
      reason: l.overrideReason(line.title, formatMoney(price)),
    );
    if (auth == null) return l.overrideRefused;
    cart.setLinePrice(key, price, by: auth.authority.name);
    return null;
  }

  // ---------------------------------------------------------------------------
  // Parked orders

  String get suggestedParkName => cart.parkedName.value ?? appL10n().parkDefaultName(parkedOrders.length + 1);

  /// Puts the cart aside under [name] and empties it.
  Future<void> park(String name) async {
    if (cart.isEmpty) return;
    final clean = name.trim().isEmpty ? suggestedParkName : name.trim();
    await _parked.park(
      name: clean,
      cart: cart.snapshot(),
      total: cart.total,
      itemCount: cart.itemCount,
      by: _auth.user,
    );
    cart.reset();
  }

  /// Brings a parked order back. Whatever is in the cart is parked first.
  Future<void> resume(ParkedOrder order) async {
    if (!await _parked.take(order.id)) {
      message.value = appL10n().parkGone;
      return;
    }
    if (!cart.isEmpty) {
      await _parked.park(
        name: suggestedParkName,
        cart: cart.snapshot(),
        total: cart.total,
        itemCount: cart.itemCount,
        by: _auth.user,
      );
    }
    final dropped = cart.load(order.cart, products, parkedAs: order.name);
    if (dropped > 0) message.value = appL10n().cartDropped(dropped);
  }

  /// Adds a parked order's lines to the cart ("merge the two tables").
  Future<void> mergeIntoCart(ParkedOrder order) async {
    if (!await _parked.take(order.id)) {
      message.value = appL10n().parkGone;
      return;
    }
    final dropped = cart.merge(order.cart, products);
    if (dropped > 0) message.value = appL10n().cartDropped(dropped);
  }

  Future<void> renameParked(ParkedOrder order, String name) => _parked.rename(order.id, name);

  /// Throwing a parked order away is recorded; it needs voidSale (or a PIN).
  Future<void> discardParked(ParkedOrder order) async {
    final auth = await _permissions.authorize(
      Permission.voidSale,
      reason: appL10n().parkDiscardReason(order.name),
    );
    if (auth == null) return;
    await _parked.discard(order.id, actor: auth.actor, approver: auth.approver);
  }

  // ---------------------------------------------------------------------------
  // The drawer

  /// Opening the drawer without a sale needs noSale (or a PIN) and a reason.
  Future<bool> noSale(String reason) async {
    final auth = await _permissions.authorize(Permission.noSale, reason: appL10n().noSaleApprovalReason);
    if (auth == null) return false;
    await Get.find<CashEventRepository>().noSale(reason: reason, actor: auth.actor, approver: auth.approver);
    printService?.openDrawer();
    message.value = appL10n().noSaleDone;
    return true;
  }

  // ---------------------------------------------------------------------------
  // Quick tab

  Future<void> arrangeQuickTab(List<String> productIds) async {
    final auth = await _permissions.authorize(Permission.editProducts, reason: appL10n().quickArrangeReason);
    if (auth == null) return;
    await _rules.setQuickTab(productIds);
  }

  void pay() {
    if (cart.isEmpty) return;
    Get.toNamed<void>(Routes.checkout);
  }
}
