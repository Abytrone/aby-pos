import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/permission_labels.dart';
import '../controllers/roles_controller.dart';

/// Name, discount limit, and one switch per permission, grouped by area.
class RoleEditor extends GetView<RolesController> {
  const RoleEditor({super.key});

  static const discountSteps = [0, 5, 10, 15, 20, 25, 50, 100];

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final readOnly = controller.editingOwner;
    return SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (readOnly)
              Padding(
                padding: const EdgeInsets.only(bottom: AbySpace.s4),
                child: Text(l.rolesOwnerFixed, style: AbyText.body.copyWith(color: c.inkMuted)),
              )
            else ...[
              TextField(
                controller: controller.nameField,
                autofocus: controller.editing.value == null,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(labelText: l.rolesName),
              ),
              const SizedBox(height: AbySpace.s4),
              Text(l.rolesMaxDiscount.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s2),
              Obx(() => Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                    for (final pct in discountSteps)
                      ChoiceChip(
                        label: Text('$pct%'),
                        selected: controller.maxDiscount.value == pct,
                        onSelected: (_) => controller.maxDiscount.value = pct,
                      ),
                  ])),
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s1),
                child: Text(l.rolesMaxDiscountHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
              ),
            ],
            for (final group in PermissionGroup.values) ...[
              const SizedBox(height: AbySpace.s4),
              Text(permissionGroupLabel(l, group).toUpperCase(),
                  style: AbyText.label.copyWith(color: c.inkMuted)),
              for (final p in Permission.values.where((p) => p.group == group))
                // The Owner role is fixed: nothing to observe, so no Obx.
                readOnly
                    ? SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        minTileHeight: AbySize.tapPos,
                        title: Text(permissionLabel(l, p)),
                        value: true,
                        onChanged: null,
                      )
                    : Obx(() => SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          minTileHeight: AbySize.tapPos,
                          title: Text(permissionLabel(l, p)),
                          value: controller.permissions.contains(p),
                          onChanged: (on) => controller.toggle(p, on),
                        )),
            ],
            Obx(() => Padding(
                  padding: const EdgeInsets.only(top: AbySpace.s3),
                  child: Text(controller.formError.value ?? '',
                      style: AbyText.caption.copyWith(color: c.danger)),
                )),
          ],
        ),
      ),
    );
  }
}
