import 'package:get/get.dart';

import '../../../data/repositories/catalog_repository.dart';
import '../../../models/catalog.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_service.dart';
import '../../../services/sync_service.dart';
import 'cart_controller.dart';

/// The till screen: menu, category filter, and the size/topping picker.
class TillController extends GetxController {
  final CatalogRepository _catalog = Get.find();
  final DeviceService _device = Get.find();
  final SyncService sync = Get.find();
  final AuthService auth = Get.find();
  final CartController cart = Get.find();

  final loading = true.obs;
  final shopName = ''.obs;
  final categories = <Category>[].obs;
  final products = <Product>[].obs;

  /// Null shows every category.
  final selectedCategoryId = RxnString();

  // The open picker sheet.
  final pickerProduct = Rxn<Product>();
  final pickerVariant = Rxn<Variant>();
  final pickerAddons = <Addon>[].obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    await _device.ready;
    shopName.value = _device.shopName;
    categories.assignAll(await _catalog.categories());
    products.assignAll(await _catalog.products());
    loading.value = false;
  }

  List<Product> get visibleProducts {
    final id = selectedCategoryId.value;
    return id == null
        ? products
        : products.where((p) => p.categoryId == id).toList();
  }

  Category? categoryOf(Product product) =>
      categories.firstWhereOrNull((c) => c.id == product.categoryId);

  void selectCategory(String? id) => selectedCategoryId.value = id;

  /// One tap: add straight away, or open the picker for products with sizes.
  /// Returns true when the picker should be shown.
  bool tapProduct(Product product) {
    if (product.hasVariants) {
      openPicker(product);
      return true;
    }
    cart.add(product);
    return false;
  }

  /// Long press: open the picker for any product with sizes or toppings.
  bool longPressProduct(Product product) {
    if (!product.hasOptions) return false;
    openPicker(product);
    return true;
  }

  void openPicker(Product product) {
    pickerProduct.value = product;
    pickerVariant.value = product.hasVariants ? product.variants.first : null;
    pickerAddons.clear();
  }

  void pickVariant(Variant variant) => pickerVariant.value = variant;

  void toggleAddon(Addon addon) {
    if (pickerAddons.any((a) => a.id == addon.id)) {
      pickerAddons.removeWhere((a) => a.id == addon.id);
    } else {
      pickerAddons.add(addon);
    }
  }

  bool isAddonPicked(Addon addon) => pickerAddons.any((a) => a.id == addon.id);

  /// Pesewas for one of the current pick.
  int get pickerPrice {
    final product = pickerProduct.value;
    if (product == null) return 0;
    return (pickerVariant.value?.price ?? product.basePrice) +
        pickerAddons.fold(0, (sum, a) => sum + a.price);
  }

  void confirmPick() {
    final product = pickerProduct.value;
    if (product == null) return;
    cart.add(product, variant: pickerVariant.value, addons: pickerAddons);
    closePicker();
  }

  void closePicker() {
    pickerProduct.value = null;
    pickerVariant.value = null;
    pickerAddons.clear();
  }

  void pay() {
    if (cart.isEmpty) return;
    Get.toNamed<void>(Routes.checkout);
  }

  void openToday() => Get.toNamed<void>(Routes.today);

  /// Back to "Who's on the till?". The cart is kept for whoever signs in.
  void lock() {
    auth.signOut();
    Get.offAllNamed<void>(Routes.signIn);
  }
}
