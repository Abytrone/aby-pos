import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../domain/catalogue_rules.dart';
import '../../../models/catalog.dart';
import '../../../models/drafts.dart';
import '../../../models/enums.dart';
import '../../../models/stock.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/staff_photo_service.dart' show shrinkImage;
import '../../../ui/l10n.dart';
import '../../products/controllers/catalogue_controller.dart';
import '../../products/widgets/recipe_lines.dart';

/// One price row in the editor.
class VariantForm {
  VariantForm({this.id, String name = '', String price = '', String cost = '', List<String>? barcodes, List<RecipeLineForm>? recipe})
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price),
        cost = TextEditingController(text: cost),
        barcodes = barcodes ?? [],
        recipe = recipe ?? [];

  final String? id;
  final TextEditingController name;
  final TextEditingController price;

  /// Manual cost, used when there is no recipe.
  final TextEditingController cost;
  final List<String> barcodes;
  final List<RecipeLineForm> recipe;

  /// Originally saved price (pesewas), to spot price changes.
  int? savedPrice;

  void dispose() {
    name.dispose();
    price.dispose();
    cost.dispose();
    for (final r in recipe) {
      r.dispose();
    }
  }
}

/// Add or change a product: details, prices (variants), what each uses
/// (recipes), barcodes, options, taxes and photo. Uses GetBuilder: the form
/// rebuilds when the controller says so.
class ProductEditorController extends GetxController {
  final CatalogRepository _catalog = Get.find();
  final StockRepository _stock = Get.find();
  final CatalogueRules _rules = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();

  /// A product ID to change it; nothing, or {'barcode': code} from the till's
  /// "new product with this barcode", for a new one.
  final String? productId = Get.arguments is String ? Get.arguments as String : null;
  final String? newBarcode = Get.arguments is Map ? (Get.arguments as Map)['barcode'] as String? : null;

  bool loading = true;
  bool saving = false;
  String? error;
  Catalogue? catalogue;
  List<StockItem> stockItems = const [];
  Product? original;

  /// Prices waiting for their day.
  List<ScheduledPrice> scheduled = const [];

  final name = TextEditingController();
  final detail = TextEditingController();
  final description = TextEditingController();
  String? categoryId;
  bool active = true;
  SellBy sellBy = SellBy.each;
  bool openPrice = false;
  final minPrice = TextEditingController();
  final maxPrice = TextEditingController();
  bool onQuickTab = false;
  final variants = <VariantForm>[];
  final groupIds = <String>[];
  final taxIds = <String>{};

  /// The photo as it will be saved (null: none).
  Uint8List? photo;
  bool photoChanged = false;

  bool get isNew => productId == null;
  bool get canSeeCost => _auth.can(Permission.viewCostAndProfit);

  /// One unnamed price: shown as a single "Price" field.
  bool get isSimple => variants.length == 1 && variants.single.name.text.trim().isEmpty;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  @override
  void onClose() {
    name.dispose();
    detail.dispose();
    description.dispose();
    minPrice.dispose();
    maxPrice.dispose();
    for (final v in variants) {
      v.dispose();
    }
    super.onClose();
  }

  Future<void> _load() async {
    catalogue = await _catalog.load(includeInactive: true, includeArchived: true);
    stockItems = await _stock.items(includeInactive: true);
    final p = isNew ? null : catalogue!.products.where((x) => x.id == productId).firstOrNull;
    original = p;
    if (p != null) {
      name.text = p.name;
      detail.text = p.detail ?? '';
      description.text = p.description ?? '';
      categoryId = p.categoryId;
      active = p.active;
      sellBy = p.sellBy;
      openPrice = p.openPrice;
      minPrice.text = p.minPrice == null ? '' : _plain(p.minPrice!);
      maxPrice.text = p.maxPrice == null ? '' : _plain(p.maxPrice!);
      onQuickTab = p.quickOrder != null;
      for (final v in p.variants) {
        variants.add(VariantForm(
          id: v.id,
          name: v.name ?? '',
          price: _plain(v.price),
          cost: v.manualCost == null ? '' : _plain(v.manualCost!),
          barcodes: [...v.barcodes],
          recipe: [for (final r in v.recipe) RecipeLineForm.from(r)],
        )..savedPrice = v.price);
      }
      groupIds.addAll(p.groups.map((g) => g.id));
      taxIds.addAll(p.taxes.map((t) => t.id));
      final bytes = await _catalog.photo(p.id);
      photo = bytes;
      scheduled = await _catalog.scheduledPrices(productId: p.id);
    } else {
      categoryId = catalogue!.categories.where((c) => c.active).firstOrNull?.id;
      variants.add(VariantForm(barcodes: [?newBarcode]));
    }
    loading = false;
    update();
  }

  static String _plain(int pesewas) => '${pesewas ~/ 100}.${(pesewas % 100).toString().padLeft(2, '0')}';

  void changed() => update();

  void addVariant() {
    // Turning a simple product into sizes: the first price needs a name.
    variants.add(VariantForm());
    update();
  }

  void removeVariant(VariantForm v) {
    if (variants.length == 1) return;
    variants.remove(v);
    v.dispose();
    update();
  }

  void moveVariant(VariantForm v, int by) {
    final i = variants.indexOf(v);
    final j = (i + by).clamp(0, variants.length - 1);
    if (i == j) return;
    variants
      ..removeAt(i)
      ..insert(j, v);
    update();
  }

  void addBarcode(VariantForm v, String code) {
    final c = code.trim();
    if (c.isEmpty || v.barcodes.contains(c)) return;
    v.barcodes.add(c);
    update();
  }

  void removeBarcode(VariantForm v, String code) {
    v.barcodes.remove(code);
    update();
  }

  void toggleGroup(String id, bool on) {
    on ? groupIds.add(id) : groupIds.remove(id);
    update();
  }

  void toggleTax(String id, bool on) {
    on ? taxIds.add(id) : taxIds.remove(id);
    update();
  }

  void setCategory(String? id) {
    categoryId = id;
    update();
  }

  void setActive(bool v) {
    active = v;
    update();
  }

  void setSellBy(SellBy v) {
    sellBy = v;
    update();
  }

  void setOpenPrice(bool v) {
    openPrice = v;
    update();
  }

  void setQuickTab(bool v) {
    onQuickTab = v;
    update();
  }

  /// Pesewas: recipe cost if there is a recipe, else the manual cost.
  int? costOf(VariantForm v) {
    if (v.recipe.any((r) => r.stockItemId != null)) {
      return v.recipe.fold<int>(0, (s, r) => s + r.cost(stockItems));
    }
    return parseMoney(v.cost.text);
  }

  int? marginOf(VariantForm v) {
    final price = parseMoney(v.price.text);
    return price == null ? null : CatalogueController.marginOf(price, costOf(v));
  }

  Future<void> pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    if (file == null) return;
    photo = await shrinkImage(await file.readAsBytes());
    photoChanged = true;
    update();
  }

  void removePhoto() {
    photo = null;
    photoChanged = true;
    update();
  }

  List<ScheduledPrice> scheduledFor(VariantForm v) => scheduled.where((s) => s.variantId == v.id).toList();

  /// A new price from the start of [day]'s business day.
  Future<void> schedulePrice(VariantForm v, String price, DateTime day) async {
    final l = appL10n();
    final pesewas = parseMoney(price);
    if (v.id == null || pesewas == null) {
      error = l.editorPriceMissing;
      update();
      return;
    }
    final auth = await _permissions.authorize(Permission.changePrices, reason: l.editorPriceReason);
    if (auth == null) return;
    final start = Get.find<SettingsService>().get(AppSettings.businessDayStart);
    final effective = DateTime(day.year, day.month, day.day).add(Duration(minutes: start));
    try {
      await _catalog.schedulePrice(v.id!, pesewas, effective, by: auth.authority);
      scheduled = await _catalog.scheduledPrices(productId: productId);
      error = null;
    } on CatalogueException catch (e) {
      error = e.message;
    }
    update();
  }

  Future<void> cancelScheduled(ScheduledPrice s) async {
    final auth = await _permissions.authorize(Permission.changePrices, reason: appL10n().editorPriceReason);
    if (auth == null) return;
    await _catalog.cancelScheduledPrice(s.id, by: auth.authority);
    scheduled = await _catalog.scheduledPrices(productId: productId);
    update();
  }

  Future<bool> get cameraAvailable async => ImagePicker().supportsImageSource(ImageSource.camera);

  /// Checks the form, asks for approval where needed, and saves. Returns
  /// true when saved.
  Future<bool> save() async {
    final l = appL10n();
    error = null;
    final drafts = <VariantDraft>[];
    for (final v in variants) {
      final price = parseMoney(v.price.text);
      if (price == null) {
        error = l.editorPriceMissing;
        update();
        return false;
      }
      final hasRecipe = v.recipe.any((r) => r.stockItemId != null);
      final cost = v.cost.text.trim().isEmpty || hasRecipe ? null : parseMoney(v.cost.text);
      if (!hasRecipe && v.cost.text.trim().isNotEmpty && cost == null) {
        error = l.editorCostInvalid;
        update();
        return false;
      }
      for (final r in v.recipe) {
        if (r.stockItemId != null && r.draft(stockItems) == null) {
          error = l.editorRecipeInvalid;
          update();
          return false;
        }
      }
      drafts.add(VariantDraft(
        id: v.id,
        name: v.name.text,
        price: price,
        manualCost: cost,
        barcodes: v.barcodes,
        recipe: [for (final r in v.recipe) ?r.draft(stockItems)],
      ));
    }
    if (categoryId == null) {
      error = l.editorCategoryMissing;
      update();
      return false;
    }
    final min = minPrice.text.trim().isEmpty ? null : parseMoney(minPrice.text);
    final max = maxPrice.text.trim().isEmpty ? null : parseMoney(maxPrice.text);
    if (openPrice &&
        ((minPrice.text.trim().isNotEmpty && min == null) || (maxPrice.text.trim().isNotEmpty && max == null))) {
      error = l.editorLimitsInvalid;
      update();
      return false;
    }

    final auth = await _permissions.authorize(Permission.editProducts, reason: l.productsEditReason);
    if (auth == null) return false;
    var by = auth.authority;
    final pricesChanged = variants.any((v) => v.savedPrice != null && v.savedPrice != parseMoney(v.price.text));
    if (pricesChanged && !by.can(Permission.changePrices)) {
      final priceAuth = await _permissions.authorize(Permission.changePrices, reason: l.editorPriceReason);
      if (priceAuth == null) return false;
      by = priceAuth.authority;
    }

    saving = true;
    update();
    try {
      final id = await _rules.saveProduct(
        ProductDraft(
          id: productId,
          categoryId: categoryId!,
          name: name.text,
          detail: detail.text,
          description: description.text,
          active: active,
          variants: drafts,
          groupIds: [...groupIds],
          taxIds: [...taxIds],
          sellBy: sellBy,
          openPrice: openPrice,
          minPrice: min,
          maxPrice: max,
          onQuickTab: onQuickTab,
        ),
        by: by,
      );
      if (photoChanged) {
        await _catalog.setPhoto(id, photo);
      }
      return true;
    } on CatalogueException catch (e) {
      error = e.message;
      return false;
    } finally {
      saving = false;
      update();
    }
  }
}
