import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/barcode_scanner.dart';
import '../../../ui/l10n.dart';
import '../../../ui/staff_pin_entry.dart';
import '../controllers/sign_in_controller.dart';

class SignInView extends GetView<SignInController> {
  const SignInView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Scaffold(
      body: SafeArea(
        child: Obx(() {
          if (controller.loading.value) {
            return const Center(child: CircularProgressIndicator());
          }
          final known = controller.known.value;
          final fromBadge = controller.fromBadge.value;
          final muted = AbyText.body.copyWith(color: c.inkMuted);
          final intro = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                const AbyMark(size: 40),
                const SizedBox(width: AbySpace.s3),
                Flexible(
                  child: Text(controller.shopName,
                      style: AbyText.title.copyWith(color: c.ink)),
                ),
              ]),
              const SizedBox(height: AbySpace.s6),
              Row(children: [
                Expanded(child: Text(context.l10n.signInWho, style: AbyText.heading.copyWith(color: c.ink))),
                ?cameraScanButton(controller.scannedBadge),
              ]),
              const SizedBox(height: AbySpace.s2),
              if (fromBadge)
                Text(context.l10n.signInBadgeRead, style: muted)
              else if (known == null) ...[
                Text(context.l10n.signInHow, style: muted),
                const SizedBox(height: AbySpace.s2),
                Text(context.l10n.signInForgotNumber, style: AbyText.caption.copyWith(color: c.inkMuted)),
              ],
              if (controller.badgeError.value != null)
                Text(controller.badgeError.value!, style: AbyText.caption.copyWith(color: c.danger)),
            ],
          );
          final pad = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StaffPinEntry(
                // A fresh pad (cleared digits) after each badge scan.
                key: ValueKey('${known?.id}-${controller.padKey.value}'),
                knownPerson: known != null,
                onSubmit: controller.submit,
              ),
              if (fromBadge)
                TextButton(onPressed: controller.useNumber, child: Text(context.l10n.signInUseNumber)),
              TextButton(onPressed: controller.forgotPin, child: Text(context.l10n.forgotPinLink)),
            ],
          );
          return LayoutBuilder(builder: (context, constraints) {
            final wide = constraints.maxWidth >= 720;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(AbySpace.s6),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - AbySpace.s6 * 2),
                child: wide
                    ? Row(
                        children: [
                          Expanded(child: intro),
                          const SizedBox(width: AbySpace.s8),
                          Expanded(child: Center(child: pad)),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          intro,
                          const SizedBox(height: AbySpace.s6),
                          Center(child: pad),
                        ],
                      ),
              ),
            );
          });
        }),
      ),
    );
  }
}
