import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';
import 'app_routes.dart';

/// Sends anyone not signed in to the sign-in screen. What each person can
/// see inside is decided by permissions (ShellSection, PermissionService).
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) =>
      Get.find<AuthService>().isSignedIn ? null : const RouteSettings(name: Routes.signIn);
}
