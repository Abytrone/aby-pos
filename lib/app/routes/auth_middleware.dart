import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';
import 'app_routes.dart';

/// Sends anyone not signed in to the sign-in screen.
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<AuthService>().isSignedIn ? null : const RouteSettings(name: Routes.signIn);
}

/// Owner-only screens.
class OwnerMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = Get.find<AuthService>();
    if (!auth.isSignedIn) return const RouteSettings(name: Routes.signIn);
    return auth.isOwner ? null : const RouteSettings(name: Routes.till);
  }
}
