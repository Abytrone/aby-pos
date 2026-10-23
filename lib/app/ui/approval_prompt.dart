import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/staff.dart';
import '../services/auth_service.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';
import 'l10n.dart';
import 'pin_pad.dart';
import 'permission_labels.dart';

/// The approval ("manager override") prompt: someone allowed to do
/// [permission] enters their PIN. Registered as PermissionService.prompter.
Future<Staff?> showApprovalPrompt(ApprovalNeed need, String reason) {
  final permission = need.permission;
  final auth = Get.find<AuthService>();
  return Get.dialog<Staff>(
    Builder(builder: (context) {
      final c = Theme.of(context).extension<AbyColors>()!;
      final l10n = context.l10n;
      return AlertDialog(
        title: Text(l10n.approvalTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reason, textAlign: TextAlign.center, style: AbyText.body.copyWith(color: c.ink)),
              const SizedBox(height: AbySpace.s1),
              Text(
                need.discountPercent == null
                    ? l10n.approvalNeeds(permissionLabel(l10n, permission))
                    : l10n.approvalNeedsDiscount(need.discountPercent!),
                textAlign: TextAlign.center,
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AbySpace.s4),
              PinPad(
                title: l10n.approvalPinTitle,
                onSubmit: (pin) async {
                  final Staff? approver;
                  try {
                    approver = await auth.approveWithPin(pin, permission, discountPercent: need.discountPercent);
                  } on LockedOutException catch (e) {
                    return l10n.pinTooManyTries(e.wait.inSeconds);
                  }
                  if (approver == null) return l10n.approvalWrongPin;
                  Get.back(result: approver);
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(onPressed: () => Get.back<Staff>(), child: Text(l10n.commonCancel)),
        ],
      );
    }),
  );
}
