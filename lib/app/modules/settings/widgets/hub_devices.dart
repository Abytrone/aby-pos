import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/settings.dart';
import '../../../data/database/app_database.dart';
import '../../../services/hub/hub_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/sync_service.dart';
import '../../../services/training_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/barcode_scanner.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

String hubErrorText(AppLocalizations l, HubError e) => switch (e) {
      HubError.alreadyLinked => l.hubErrAlreadyLinked,
      HubError.noCode => l.hubErrNoCode,
      HubError.tooManyTries => l.hubErrTooManyTries,
      HubError.wrongCode => l.hubErrWrongCode,
      HubError.notPaired => l.hubErrNotPaired,
      HubError.revoked => l.hubErrRevoked,
      HubError.unreachable => l.hubErrUnreachable,
      HubError.refused => l.hubErrRefused,
    };

String hubRoleText(AppLocalizations l, HubRole r) => switch (r) {
      HubRole.none => l.hubRoleNone,
      HubRole.hub => l.hubRoleHub,
      HubRole.member => l.hubRoleMember,
    };

String deviceRoleText(AppLocalizations l, String r) => switch (r) {
      'kitchen' => l.hubDeviceKitchen,
      'display' => l.hubDeviceDisplay,
      'owner' => l.hubDeviceOwner,
      _ => l.hubDeviceTill,
    };

/// Settings → Devices: this device's place in the shop's local hub.
Future<void> showHubDevices() => Get.to<void>(() => const _HubPage())!;

class _HubPage extends StatefulWidget {
  const _HubPage();

  @override
  State<_HubPage> createState() => _HubPageState();
}

class _HubPageState extends State<_HubPage> {
  final HubService _hub = Get.find();
  List<HubDeviceRow> _devices = const [];
  List<(String, String)> _duplicates = const [];
  bool _working = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final devices = _hub.role.value == HubRole.hub ? await _hub.devices() : const <HubDeviceRow>[];
    final duplicates = _hub.role.value == HubRole.none ? const <(String, String)>[] : await _hub.duplicates();
    if (!mounted) return;
    setState(() {
      _devices = devices;
      _duplicates = duplicates;
    });
  }

  Future<void> _run(Future<void> Function() work) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      await work();
    } on HubException catch (e) {
      showMessage(hubErrorText(appL10n(), e.error));
    } on Object catch (e) {
      showMessage(appL10n().hubCannotStart('$e'));
    } finally {
      if (mounted) setState(() => _working = false);
      await _load();
    }
  }

  Future<void> _becomeHub() async {
    final l = appL10n();
    final ok = await confirmDialog(title: l.hubBecomeTitle, message: l.hubBecomeBody, confirmLabel: l.hubBecome);
    if (ok) await _run(_hub.becomeHub);
  }

  Future<void> _join() async {
    final l = appL10n();
    List<String>? urls;
    String? code, hubId;
    if (canScanWithCamera) {
      final scanned = await scanWithCamera();
      if (scanned == null) return;
      final offer = PairingOffer.parse(scanned);
      if (offer == null) {
        showMessage(l.hubNotACode);
        return;
      }
      (urls, code, hubId) = offer;
    } else {
      final address = await textInputDialog(title: l.hubJoin, label: l.hubAddress, helper: l.hubAddressHelp, keyboardType: TextInputType.url);
      if (address == null || address.trim().isEmpty) return;
      code = await textInputDialog(title: l.hubJoin, label: l.hubCode, helper: l.hubCodeHelp);
      if (code == null || code.trim().isEmpty) return;
      final a = address.trim();
      urls = [a.startsWith('http') ? a : 'http://$a${a.contains(':') ? '' : ':8787'}'];
    }
    final ok = await confirmDialog(title: l.hubJoinTitle, message: l.hubJoinBody, confirmLabel: l.hubJoin);
    if (!ok) return;
    final name = Get.find<SettingsService>().get(AppSettings.deviceName);
    await _run(() async {
      await _hub.join(urls!, code!, hubId: hubId, deviceName: name.isEmpty ? null : name);
      showMessage(l.hubJoined);
    });
  }

  Future<void> _addDevice() async {
    final offer = await _hub.offerPairing();
    await Get.dialog<void>(_OfferDialog(offer: offer, hub: _hub));
    await _load();
  }

  Future<void> _editDevice(HubDeviceRow d) async {
    final l = appL10n();
    final action = await choiceDialog<String>(
      title: d.name,
      options: const ['rename', 'role', 'revoke'],
      label: (a) => switch (a) {
        'rename' => l.hubRename,
        'role' => l.hubSetRole,
        _ => l.hubRevoke,
      },
    );
    switch (action) {
      case 'rename':
        final name = await textInputDialog(title: l.hubRename, label: l.settingsDeviceName, initial: d.name);
        if (name != null && name.trim().isNotEmpty) await _run(() => _hub.updateDevice(d.deviceId, name: name.trim()));
      case 'role':
        final role = await choiceDialog<String>(
          title: l.hubSetRole,
          options: const ['till', 'kitchen', 'display', 'owner'],
          label: (r) => deviceRoleText(l, r),
          selected: d.role,
        );
        if (role != null) await _run(() => _hub.updateDevice(d.deviceId, role: role));
      case 'revoke':
        final ok = await confirmDialog(
          title: l.hubRevokeTitle(d.name),
          message: l.hubRevokeBody,
          confirmLabel: l.hubRevoke,
          danger: true,
        );
        if (ok) await _run(() => _hub.revoke(d.deviceId));
    }
  }

  Future<void> _leave() async {
    final l = appL10n();
    final hub = _hub.role.value == HubRole.hub;
    final ok = await confirmDialog(
      title: hub ? l.hubStopTitle : l.hubLeaveTitle,
      message: hub ? l.hubStopBody : l.hubLeaveBody,
      confirmLabel: hub ? l.hubStop : l.hubLeave,
      danger: true,
    );
    if (ok) await _run(_hub.leave);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final sync = Get.find<SyncService>();
    return Scaffold(
      appBar: AppBar(title: Text(l.hubTitle)),
      body: Obx(() {
        final role = _hub.role.value;
        final last = _hub.lastSync.value;
        final problem = _hub.problem.value;
        final online = _hub.online.value;
        final training = Get.find<TrainingService>().active.value;
        Widget card(List<Widget> children) => Card(
              margin: const EdgeInsets.only(bottom: AbySpace.s3),
              child: Padding(
                padding: const EdgeInsets.all(AbySpace.s4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
              ),
            );
        return ListView(
          padding: const EdgeInsets.all(AbySpace.s4),
          children: [
            if (_working) const LinearProgressIndicator(),
            card([
              Row(children: [
                Icon(
                  role == HubRole.none ? Icons.devices_outlined : online ? Icons.wifi : Icons.wifi_off,
                  color: role == HubRole.none ? c.inkMuted : online ? c.success : c.warning,
                ),
                const SizedBox(width: AbySpace.s2),
                Expanded(child: Text(hubRoleText(l, role), style: AbyText.heading.copyWith(color: c.ink))),
              ]),
              const SizedBox(height: AbySpace.s2),
              Text(
                switch (role) {
                  HubRole.none => l.hubNoneHelp,
                  HubRole.hub => l.hubHubHelp,
                  HubRole.member => l.hubMemberHelp,
                },
                style: AbyText.body.copyWith(color: c.inkMuted),
              ),
              if (role != HubRole.none) ...[
                const SizedBox(height: AbySpace.s2),
                Text(last == null ? l.hubNeverSynced : l.hubLastSync(relativeTime(l, last)), style: AbyText.caption.copyWith(color: c.inkMuted)),
                if (role == HubRole.member)
                  Text(l.statusSalesWaiting(sync.waitingSales.value), style: AbyText.caption.copyWith(color: c.inkMuted)),
                if (problem != null) Text(hubErrorText(l, problem), style: AbyText.body.copyWith(color: c.danger)),
              ],
              if (training) ...[
                const SizedBox(height: AbySpace.s2),
                Text(l.hubTraining, style: AbyText.body.copyWith(color: c.warning)),
              ],
              const SizedBox(height: AbySpace.s3),
              if (!training) Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                if (role == HubRole.none) ...[
                  FilledButton.icon(onPressed: _working ? null : _becomeHub, icon: const Icon(Icons.hub_outlined), label: Text(l.hubBecome)),
                  OutlinedButton.icon(
                    onPressed: _working ? null : _join,
                    icon: Icon(canScanWithCamera ? Icons.qr_code_scanner : Icons.link),
                    label: Text(l.hubJoin),
                  ),
                ],
                if (role == HubRole.hub)
                  FilledButton.icon(onPressed: _working ? null : _addDevice, icon: const Icon(Icons.add), label: Text(l.hubAddDevice)),
                if (role == HubRole.member)
                  FilledButton.icon(
                    onPressed: _working ? null : () => _run(_hub.syncNow),
                    icon: const Icon(Icons.sync),
                    label: Text(l.hubSyncNow),
                  ),
                if (role != HubRole.none)
                  TextButton(
                    onPressed: _working ? null : _leave,
                    style: TextButton.styleFrom(foregroundColor: c.danger),
                    child: Text(role == HubRole.hub ? l.hubStop : l.hubLeave),
                  ),
              ]),
            ]),
            if (role == HubRole.hub)
              card([
                Text(l.hubDevices, style: AbyText.heading.copyWith(color: c.ink)),
                if (_devices.isEmpty) Text(l.hubNoDevices, style: AbyText.body.copyWith(color: c.inkMuted)),
                for (final d in _devices)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      d.revokedAt != null ? Icons.block : Icons.point_of_sale_outlined,
                      color: d.revokedAt != null ? c.danger : c.ink,
                    ),
                    title: Text(d.name),
                    subtitle: Text([
                      deviceRoleText(l, d.role),
                      if (d.revokedAt != null)
                        l.hubRevoked
                      else
                        d.lastSeenAt == null ? l.hubNeverSynced : l.hubLastSeen(relativeTime(l, d.lastSeenAt!)),
                      if (d.appVersion != null) 'v${d.appVersion}',
                    ].join(' · ')),
                    trailing: d.revokedAt != null ? null : const Icon(Icons.more_vert),
                    onTap: d.revokedAt != null || _working ? null : () => _editDevice(d),
                  ),
              ]),
            if (_duplicates.isNotEmpty)
              card([
                Text(l.hubDuplicates, style: AbyText.heading.copyWith(color: c.ink)),
                Text(l.hubDuplicatesHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
                const SizedBox(height: AbySpace.s2),
                for (final (kind, name) in _duplicates)
                  Text('• $name (${switch (kind) {
                    'product' => l.hubKindProduct,
                    'customer' => l.hubKindCustomer,
                    _ => l.hubKindStaff,
                  }})', style: AbyText.body.copyWith(color: c.ink)),
              ]),
          ],
        );
      }),
    );
  }
}

/// The one-time code for a new device, as a QR code and typed by hand.
class _OfferDialog extends StatelessWidget {
  const _OfferDialog({required this.offer, required this.hub});

  final PairingOffer offer;
  final HubService hub;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final addresses = [for (final u in offer.urls) u.replaceFirst('http://', '')];
    return AlertDialog(
      title: Text(l.hubAddDevice),
      content: SizedBox(
        width: 420,
        child: Obx(() {
          if (hub.offer.value == null) {
            return Text(l.hubPaired, style: AbyText.body.copyWith(color: c.success));
          }
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Text(l.hubAddHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s3),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AbySpace.s2),
              child: QrImageView(data: offer.qr, size: 220, padding: EdgeInsets.zero),
            ),
            const SizedBox(height: AbySpace.s3),
            Text(l.hubCode, style: AbyText.caption.copyWith(color: c.inkMuted)),
            SelectableText(offer.code, style: AbyText.display.copyWith(color: c.ink, letterSpacing: 4)),
            const SizedBox(height: AbySpace.s2),
            Text(l.hubAddress, style: AbyText.caption.copyWith(color: c.inkMuted)),
            for (final a in addresses) SelectableText(a, style: AbyText.receipt.copyWith(color: c.ink)),
            if (addresses.isEmpty) Text(l.screensNoNetwork, style: AbyText.body.copyWith(color: c.danger)),
            const SizedBox(height: AbySpace.s2),
            Text(l.hubCodeExpires(TimeOfDay.fromDateTime(offer.expires).format(context)),
                style: AbyText.caption.copyWith(color: c.inkMuted)),
          ]);
        }),
      ),
      actions: [FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone))],
    );
  }
}
