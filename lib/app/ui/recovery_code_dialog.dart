import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';
import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';
import 'dialogs.dart';
import 'l10n.dart';
import 'pin_pad.dart';

/// Shows an owner's new recovery code, the only time it is ever shown.
/// Done stays off until they say they have written it down.
Future<void> showRecoveryCode(String code) async {
  final written = false.obs;
  await Get.dialog<void>(
    Builder(builder: (context) {
      final c = Theme.of(context).extension<AbyColors>()!;
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.recoveryCodeTitle),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l.recoveryCodeIntro, style: AbyText.body.copyWith(color: c.ink)),
                const SizedBox(height: AbySpace.s4),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: AbySpace.s4, horizontal: AbySpace.s3),
                  decoration: BoxDecoration(
                    color: c.surfaceSunken,
                    borderRadius: BorderRadius.circular(AbyRadius.md),
                    border: Border.all(color: c.lineStrong, width: 1.5),
                  ),
                  child: Row(children: [
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: SelectableText(
                          code,
                          style: AbyText.title.copyWith(color: c.ink, fontFamily: AbyText.mono, letterSpacing: 2),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l.commonCopy,
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: code));
                        showMessage(l.commonCopied, tone: MessageTone.success);
                      },
                    ),
                  ]),
                ),
                const SizedBox(height: AbySpace.s3),
                Text(l.recoveryCodeOnce, style: AbyText.caption.copyWith(color: c.inkMuted)),
                const SizedBox(height: AbySpace.s2),
                Obx(() => CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      value: written.value,
                      onChanged: (v) => written.value = v ?? false,
                      title: Text(l.recoveryCodeWritten),
                    )),
              ],
            ),
          ),
        ),
        actions: [
          DialogButtons(children: [
            Obx(() => FilledButton(
                  onPressed: written.value ? () => goBack<void>() : null,
                  child: Text(l.commonDone),
                )),
          ]),
        ],
      );
    }),
    barrierDismissible: false,
  );
}

/// The signed-in person types their PIN again before something sensitive.
/// True once it is right.
Future<bool> confirmOwnPin(String title) async {
  final auth = Get.find<AuthService>();
  final confirmed = await Get.dialog<bool>(Builder(builder: (context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(title),
      content: PinPad(onSubmit: (pin) async {
        switch (await auth.confirmOwnPin(pin)) {
          case SignInResult.ok:
            goBack(result: true);
            return null;
          case SignInResult.wrongPin:
            return l.pinWrong;
          case SignInResult.lockedOut:
            final me = auth.user;
            return l.pinTooManyTries(auth.lockedFor(me.number ?? me.id)?.inSeconds ?? AuthService.lockout.inSeconds);
        }
      }),
      actions: [
        DialogButtons(children: [OutlinedButton(onPressed: () => goBack<bool>(), child: Text(l.commonCancel))]),
      ],
    );
  }));
  return confirmed ?? false;
}
