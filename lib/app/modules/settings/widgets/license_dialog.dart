import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/license.dart';
import '../../../core/permissions.dart';
import '../../../services/auth_service.dart';
import '../../../services/hub/hub_service.dart';
import '../../../services/license_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/training_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/files.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

String licenseProblemText(AppLocalizations l, LicenseProblem p) => switch (p) {
      LicenseProblem.unreadable => l.licenseErrUnreadable,
      LicenseProblem.forged => l.licenseErrForged,
      LicenseProblem.otherDevice => l.licenseErrOtherDevice,
      LicenseProblem.tooFewDevices => l.licenseErrTooFewDevices,
    };

/// "Mama Ama Provisions · 3 devices", "Through the hub: …" or "Not activated".
String licenseSummary(AppLocalizations l, LicenseService s) {
  final license = s.license.value;
  if (license == null) return l.licenseNotActivated;
  final text = l.licenseLicensedTo(license.shop, license.devices);
  return s.viaHub.value ? l.licenseViaHub(text) : text;
}

/// Settings → License: what this device is licensed for, its device code,
/// and where a license key goes. Changing it needs "Manage devices".
Future<void> showLicense() async {
  if (await Get.find<PermissionService>().authorize(Permission.manageDevices, reason: appL10n().licenseApprovalReason) == null) {
    return;
  }
  await Get.dialog<void>(const _LicenseDialog());
}

class _LicenseDialog extends StatefulWidget {
  const _LicenseDialog();

  @override
  State<_LicenseDialog> createState() => _LicenseDialogState();
}

class _LicenseDialogState extends State<_LicenseDialog> {
  final LicenseService _licenses = Get.find();
  final HubService _hub = Get.find();
  final _key = TextEditingController();
  String? _error;
  bool _working = false;

  @override
  void dispose() {
    _key.dispose();
    super.dispose();
  }

  Future<void> _openFile() async {
    final text = await pickTextFile();
    if (text != null) setState(() => _key.text = text.trim());
  }

  Future<void> _activate() async {
    final l = appL10n();
    if (_key.text.trim().isEmpty) return;
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      final linked = _hub.role.value == HubRole.hub ? await _hub.deviceCount() : 1;
      await _licenses.activate(_key.text, linkedDevices: linked, by: Get.find<AuthService>().currentUser.value);
      goBack<void>();
      showMessage(l.licenseActivated, tone: MessageTone.success);
    } on LicenseException catch (e) {
      setState(() => _error = licenseProblemText(l, e.problem));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final license = _licenses.license.value;
    final member = _hub.role.value == HubRole.member;
    final code = _licenses.machineCode;
    return AlertDialog(
      title: Text(license == null ? l.licenseActivateTitle : l.licenseTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (license != null) ...[
                _Row(l.licenseShop, license.shop),
                _Row(l.licenseDevices, '${license.devices}'),
                _Row(l.licenseIssued, formatDate(license.issued)),
                if (_licenses.viaHub.value) Text(l.licenseFromHub, style: AbyText.caption.copyWith(color: c.inkMuted)),
                const SizedBox(height: AbySpace.s4),
              ] else ...[
                Text(member ? l.licenseMemberHelp : l.licenseHowTo, style: AbyText.body.copyWith(color: c.ink)),
                const SizedBox(height: AbySpace.s4),
              ],
              Text(l.licenseDeviceCode, style: AbyText.label.copyWith(color: c.inkMuted)),
              Row(children: [
                Expanded(
                  child: SelectableText(
                    code.isEmpty ? '—' : code,
                    style: AbyText.heading.copyWith(fontFamily: AbyText.mono, letterSpacing: 1.5, color: c.ink),
                  ),
                ),
                if (code.isNotEmpty)
                  IconButton(
                    tooltip: l.commonCopy,
                    icon: const Icon(Icons.copy),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: code));
                      showMessage(l.commonCopied, tone: MessageTone.success);
                    },
                  ),
              ]),
              const SizedBox(height: AbySpace.s4),
              TextField(
                controller: _key,
                minLines: 3,
                maxLines: 5,
                style: AbyText.caption.copyWith(fontFamily: AbyText.mono, color: c.ink),
                decoration: InputDecoration(
                  labelText: license == null ? l.licenseKey : l.licenseReplace,
                  alignLabelWithHint: true,
                  errorText: _error,
                  errorMaxLines: 3,
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _working ? null : _openFile,
                  icon: const Icon(Icons.file_open_outlined),
                  label: Text(l.licenseOpenFile),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        DialogButtons(children: [
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
          FilledButton(onPressed: _working ? null : _activate, child: Text(l.licenseActivate)),
        ]),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AbySpace.s1),
      child: Row(children: [
        SizedBox(width: 96, child: Text(label, style: AbyText.label.copyWith(color: c.inkMuted))),
        Expanded(child: Text(value, style: AbyText.body.copyWith(color: c.ink))),
      ]),
    );
  }
}

/// Over every screen after sign-in while Aby is not activated: what still
/// works, and the way to activate. Hidden in training mode, which is open.
class LicenseBanner extends StatelessWidget {
  const LicenseBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final licenses = Get.find<LicenseService>();
    final training = Get.find<TrainingService>();
    final hub = Get.find<HubService>();
    final auth = Get.find<AuthService>();
    if (!licenses.enforce) return const SizedBox.shrink();
    return Obx(() {
      if (licenses.licensed || training.active.value) return const SizedBox.shrink();
      final l = context.l10n;
      final c = Theme.of(context).extension<AbyColors>()!;
      auth.currentUser.value;
      return Container(
        margin: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3, vertical: AbySpace.s2),
        decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AbyRadius.sm)),
        child: Row(children: [
          Icon(Icons.key_outlined, color: c.warning),
          const SizedBox(width: AbySpace.s3),
          Expanded(
            child: Text(
              hub.role.value == HubRole.member ? l.licenseBannerMember : l.licenseBanner,
              style: AbyText.body.copyWith(color: c.ink),
            ),
          ),
          if (hub.role.value != HubRole.member && auth.can(Permission.manageDevices)) ...[
            const SizedBox(width: AbySpace.s3),
            FilledButton(onPressed: showLicense, child: Text(l.licenseActivate)),
          ],
        ]),
      );
    });
  }
}
