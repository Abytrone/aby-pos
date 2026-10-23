import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../models/staff.dart';
import '../services/auth_service.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';
import 'pin_pad.dart';

/// Asks an owner to enter their PIN. Returns the approving owner, or null
/// if cancelled. [findOwner] checks the PIN (a controller method) and may
/// throw [LockedOutException].
Future<Staff?> askOwnerApproval({
  required String reason,
  required Future<Staff?> Function(String pin) findOwner,
}) {
  return Get.dialog<Staff>(
    Builder(builder: (context) {
      final c = Theme.of(context).extension<AbyColors>()!;
      return AlertDialog(
        title: const Text('Owner approval'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(reason, style: AbyText.body.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s4),
              PinPad(
                title: 'Owner PIN',
                onSubmit: (pin) async {
                  final Staff? owner;
                  try {
                    owner = await findOwner(pin);
                  } on LockedOutException catch (e) {
                    return 'Too many tries. Wait ${e.wait.inSeconds} seconds.';
                  }
                  if (owner == null) return 'That is not an owner PIN.';
                  Get.back(result: owner);
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Get.back<Staff>(),
            child: const Text('Cancel'),
          ),
        ],
      );
    }),
  );
}
