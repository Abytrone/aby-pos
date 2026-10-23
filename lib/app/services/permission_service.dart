import 'package:get/get.dart';

import '../core/permissions.dart';
import '../models/staff.dart';
import 'auth_service.dart';

/// Shows the "someone allowed must enter their PIN" prompt. Registered by
/// the UI shell; returns the approver, or null if cancelled.
typedef ApprovalPrompter = Future<Staff?> Function(Permission permission, String reason);

/// Checks permissions for the signed-in person and runs the approval flow
/// ("manager override") when they lack one.
class PermissionService extends GetxService {
  PermissionService(this._auth);

  final AuthService _auth;

  /// Set by the app shell. Without it, approvals are refused.
  ApprovalPrompter? prompter;

  bool can(Permission permission) => _auth.can(permission);

  /// The person who authorises [permission]: the signed-in person if they
  /// have it, otherwise whoever approves with their PIN. Null if nobody
  /// does (cancelled, or no prompter). [reason] is shown in the prompt.
  Future<Authorization?> authorize(Permission permission, {required String reason}) async {
    final user = _auth.currentUser.value;
    if (user == null) return null;
    if (user.can(permission)) return Authorization(actor: user);
    final approver = await prompter?.call(permission, reason);
    return approver == null ? null : Authorization(actor: user, approver: approver);
  }
}

/// Who did something and, when they needed it, who approved it.
class Authorization {
  const Authorization({required this.actor, this.approver});

  final Staff actor;
  final Staff? approver;

  /// The person whose permission was used.
  Staff get authority => approver ?? actor;
}
