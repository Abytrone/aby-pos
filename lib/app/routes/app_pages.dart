import 'package:get/get.dart';

import '../modules/checkout/bindings/checkout_binding.dart';
import '../modules/checkout/views/checkout_view.dart';
import '../modules/close_day/bindings/close_day_binding.dart';
import '../modules/close_day/views/close_day_view.dart';
import '../modules/product_editor/bindings/product_editor_binding.dart';
import '../modules/product_editor/views/product_editor_view.dart';
import '../modules/receive/bindings/receive_binding.dart';
import '../modules/receive/views/receive_view.dart';
import '../modules/setup/bindings/setup_binding.dart';
import '../modules/setup/views/setup_view.dart';
import '../modules/shell/bindings/shell_binding.dart';
import '../modules/shell/views/shell_view.dart';
import '../modules/sign_in/bindings/sign_in_binding.dart';
import '../modules/sign_in/views/sign_in_view.dart';
import '../modules/staff_profile/bindings/staff_profile_binding.dart';
import '../modules/staff_profile/views/staff_profile_view.dart';
import '../modules/start/bindings/start_binding.dart';
import '../modules/stock_count/bindings/stock_count_binding.dart';
import '../modules/stock_count/views/stock_count_view.dart';
import '../modules/stock_item/bindings/stock_item_binding.dart';
import '../modules/stock_item/views/stock_item_view.dart';
import '../modules/start/views/start_view.dart';
import '../modules/supplier/bindings/supplier_binding.dart';
import '../modules/supplier/views/supplier_view.dart';
import 'app_routes.dart';
import 'auth_middleware.dart';

abstract final class AppPages {
  static const initial = Routes.start;

  static final routes = [
    GetPage<void>(
      name: Routes.start,
      page: () => const StartView(),
      binding: StartBinding(),
    ),
    GetPage<void>(
      name: Routes.setup,
      page: () => const SetupView(),
      binding: SetupBinding(),
    ),
    GetPage<void>(
      name: Routes.signIn,
      page: () => const SignInView(),
      binding: SignInBinding(),
    ),
    // Everything after sign-in lives in the shell (Sell and Manage).
    GetPage<void>(
      name: Routes.shell,
      page: () => const ShellView(),
      binding: ShellBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // Drawn as a sheet over the till, so the route is see-through.
    GetPage<void>(
      name: Routes.checkout,
      page: () => const CheckoutView(),
      binding: CheckoutBinding(),
      middlewares: [AuthMiddleware()],
      opaque: false,
      transition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 180),
    ),
    GetPage<void>(
      name: Routes.closeDay,
      page: () => const CloseDayView(),
      binding: CloseDayBinding(),
      middlewares: [AuthMiddleware()],
    ),
    // Who may see or change what is decided inside (own profile, or
    // "Manage staff").
    GetPage<void>(
      name: Routes.staffProfile,
      page: () => const StaffProfileView(),
      binding: StaffProfileBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<void>(
      name: Routes.productEditor,
      page: () => const ProductEditorView(),
      binding: ProductEditorBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<void>(
      name: Routes.stockItem,
      page: () => const StockItemView(),
      binding: StockItemBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<void>(
      name: Routes.receive,
      page: () => const ReceiveView(),
      binding: ReceiveBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<void>(
      name: Routes.stockCount,
      page: () => const StockCountView(),
      binding: StockCountBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<void>(
      name: Routes.supplier,
      page: () => const SupplierView(),
      binding: SupplierBinding(),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
