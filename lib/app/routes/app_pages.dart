import 'package:get/get.dart';

import '../modules/checkout/bindings/checkout_binding.dart';
import '../modules/checkout/views/checkout_view.dart';
import '../modules/close_day/bindings/close_day_binding.dart';
import '../modules/close_day/views/close_day_view.dart';
import '../modules/setup/bindings/setup_binding.dart';
import '../modules/setup/views/setup_view.dart';
import '../modules/sign_in/bindings/sign_in_binding.dart';
import '../modules/sign_in/views/sign_in_view.dart';
import '../modules/staff/bindings/staff_binding.dart';
import '../modules/staff/views/staff_view.dart';
import '../modules/start/bindings/start_binding.dart';
import '../modules/start/views/start_view.dart';
import '../modules/till/bindings/till_binding.dart';
import '../modules/till/views/till_view.dart';
import '../modules/today/bindings/today_binding.dart';
import '../modules/today/views/today_view.dart';
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
    GetPage<void>(
      name: Routes.till,
      page: () => const TillView(),
      binding: TillBinding(),
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
      name: Routes.today,
      page: () => const TodayView(),
      binding: TodayBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<void>(
      name: Routes.closeDay,
      page: () => const CloseDayView(),
      binding: CloseDayBinding(),
      middlewares: [AuthMiddleware()],
    ),
    GetPage<void>(
      name: Routes.staff,
      page: () => const StaffView(),
      binding: StaffBinding(),
      middlewares: [OwnerMiddleware()],
    ),
  ];
}
