import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/database/app_database.dart';
import '../../../services/hub/hub_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../services/sync_service.dart';
import '../../../services/training_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_icons.dart';
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
      HubError.noSeats => l.hubErrNoSeats,
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

/// The join page on its own (first run): where to join and with which code.
Future<JoinTarget?> pickHubToJoin() => Get.to<JoinTarget>(() => _JoinPage(hub: Get.find()))!;

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

  /// Every change here needs "Manage devices", or an approver's PIN: a
  /// paired device receives all of the shop's data.
  Future<bool> _allowed() async =>
      await Get.find<PermissionService>().authorize(Permission.manageDevices, reason: appL10n().hubApprovalReason) != null;

  Future<void> _becomeHub() async {
    if (!await _allowed()) return;
    final l = appL10n();
    final ok = await confirmDialog(title: l.hubBecomeTitle, message: l.hubBecomeBody, confirmLabel: l.hubBecome);
    if (ok) await _run(_hub.becomeHub);
  }

  /// Type the code (the hub is found on the Wi-Fi), scan its QR code, or
  /// give its address when the network hides it.
  Future<void> _join() async {
    if (!await _allowed()) return;
    final l = appL10n();
    final target = await pickHubToJoin();
    if (target == null) return;
    final ok = await confirmDialog(title: l.hubJoinTitle, message: l.hubJoinBody, confirmLabel: l.hubJoin);
    if (!ok) return;
    final name = Get.find<SettingsService>().get(AppSettings.deviceName);
    await _run(() async {
      await _hub.join(target.urls, target.code, hubId: target.hubId, deviceName: name.isEmpty ? null : name);
      showMessage(l.hubJoined);
    });
  }

  Future<void> _addDevice() async {
    if (!await _allowed()) return;
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
    if (action == null || !await _allowed()) return;
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
    if (!await _allowed()) return;
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
                    icon: AbyIcon(AbyIcons.link, size: 20, color: c.ink),
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
                  Text(
                    '• $name (${switch (kind) {
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
              FittedBox(
                fit: BoxFit.scaleDown,
                child: SelectableText(
                  PairingOffer.formatCode(offer.code), style: AbyText.display.copyWith(fontFamily: AbyText.mono, fontSize: 44, color: c.ink, letterSpacing: 2),
                )),
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
      actions: [
        DialogButtons(children: [FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}

/// Where to join and with which code, from the join page.
class JoinTarget {
  const JoinTarget({required this.urls, required this.code, this.hubId});

  final List<String> urls;
  final String code;
  final String? hubId;
}

/// Join a hub by typing its code. While the code is typed, the page
/// listens for hubs on this Wi-Fi, so most of the time the code is all it
/// takes. A QR scan or the hub's address cover the rest.
class _JoinPage extends StatefulWidget {
  const _JoinPage({required this.hub});

  final HubService hub;

  @override
  State<_JoinPage> createState() => _JoinPageState();
}

class _JoinPageState extends State<_JoinPage> {
  final _code = TextEditingController();
  final _address = TextEditingController();
  List<FoundHub> _found = const [];
  FoundHub? _chosen;
  bool _looking = true;
  bool _byAddress = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
    _address.addListener(() => setState(() {}));
    unawaited(_look());
  }

  @override
  void dispose() {
    _closed = true;
    _code.dispose();
    _address.dispose();
    super.dispose();
  }

  /// Keeps listening until a hub is heard (a hub may be switched on after
  /// this page opens), then stops.
  Future<void> _look() async {
    setState(() => _looking = true);
    for (var round = 0; round < 6 && !_closed; round++) {
      final found = await widget.hub.discover();
      if (_closed) return;
      setState(() {
        _found = found;
        if (_chosen == null || !found.any((h) => h.id == _chosen!.id)) _chosen = found.length == 1 ? found.single : null;
      });
      if (found.isNotEmpty) break;
    }
    if (!_closed) setState(() => _looking = false);
  }

  String get _typed => PairingOffer.normalizeCode(_code.text);

  bool get _codeReady => _typed.length == PairingOffer.codeLength;

  JoinTarget? get _target {
    if (!_codeReady) return null;
    if (_byAddress) {
      final a = _address.text.trim();
      if (a.isEmpty) return null;
      return JoinTarget(urls: [a.startsWith('http') ? a : 'http://$a${a.contains(':') ? '' : ':8787'}'], code: _typed);
    }
    final hub = _chosen;
    return hub == null ? null : JoinTarget(urls: [hub.url], code: _typed, hubId: hub.id);
  }

  /// A pasted QR text carries the address too: join with it straight away.
  void _onCode(String text) {
    final offer = PairingOffer.parse(text);
    if (offer != null) {
      final (urls, code, hubId) = offer;
      goBack<JoinTarget>(
        result: JoinTarget(urls: urls, code: code, hubId: hubId),
      );
    }
  }

  Future<void> _scan() async {
    final scanned = await scanWithCamera();
    if (scanned == null) return;
    final offer = PairingOffer.parse(scanned);
    if (offer == null) {
      showMessage(appL10n().hubNotACode);
      return;
    }
    final (urls, code, hubId) = offer;
    goBack<JoinTarget>(
      result: JoinTarget(urls: urls, code: code, hubId: hubId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final target = _target;
    return Scaffold(
      appBar: AppBar(title: Text(l.hubJoin)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(AbySpace.s4),
            children: [
              Text(l.hubJoinSteps, style: AbyText.body.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s4),
              TextField(
                controller: _code,
                autofocus: true,
                textAlign: TextAlign.center,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                style: AbyText.title.copyWith(fontFamily: AbyText.mono, letterSpacing: 4, color: c.ink),
                inputFormatters: [_PairingCodeFormatter()],
                onChanged: _onCode,
                onSubmitted: (_) {
                  if (target != null) goBack<JoinTarget>(result: target);
                },
                decoration: InputDecoration(labelText: l.hubCode, hintText: 'ABCD-EFGH', helperText: l.hubCodeHelp),
              ),
              const SizedBox(height: AbySpace.s4),
              if (!_byAddress)
                _FoundHubs(
                  looking: _looking,
                  found: _found,
                  chosen: _chosen,
                  onChoose: (h) => setState(() => _chosen = h),
                  onLookAgain: _look,
                ),
              if (_byAddress)
                TextField(
                  controller: _address,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  decoration: InputDecoration(labelText: l.hubAddress, helperText: l.hubAddressHelp),
                ),
              const SizedBox(height: AbySpace.s2),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () => setState(() => _byAddress = !_byAddress),
                  child: Text(_byAddress ? l.hubFindOnWifi : l.hubTypeAddress),
                ),
              ),
              const SizedBox(height: AbySpace.s4),
              FilledButton(
                onPressed: target == null ? null : () => goBack<JoinTarget>(result: target),
                child: Text(l.hubJoinButton),
              ),
              if (canScanWithCamera) ...[
                const SizedBox(height: AbySpace.s3),
                OutlinedButton.icon(
                  onPressed: _scan,
                  icon: AbyIcon(AbyIcons.qrCode, size: 20, color: c.ink),
                  label: Text(l.hubScanInstead),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// What the page has heard on the Wi-Fi: still listening, one hub (taken),
/// several (pick one), or none yet.
class _FoundHubs extends StatelessWidget {
  const _FoundHubs({required this.looking, required this.found, required this.chosen, required this.onChoose, required this.onLookAgain});

  final bool looking;
  final List<FoundHub> found;
  final FoundHub? chosen;
  final ValueChanged<FoundHub> onChoose;
  final VoidCallback onLookAgain;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    Widget line(Widget lead, String text, {Color? color, Widget? trailing}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s3),
      decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.md)),
      child: Row(
        children: [
          lead,
          const SizedBox(width: AbySpace.s3),
          Expanded(
            child: Text(text, style: AbyText.body.copyWith(color: color ?? c.ink)),
          ),
          ?trailing,
        ],
      ),
    );
    if (found.isEmpty) {
      return looking
          ? line(const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)), l.hubLooking, color: c.inkMuted)
          : line(
              AbyIcon(AbyIcons.wifi, size: 20, color: c.warning),
              l.hubNoneHeard,
              trailing: TextButton(onPressed: onLookAgain, child: Text(l.hubLookAgain)),
            );
    }
    return Semantics(
      container: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (found.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: AbySpace.s2),
              child: Text(l.hubPickOne.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            ),
          for (final h in found)
            Padding(
              padding: const EdgeInsets.only(bottom: AbySpace.s2),
              child: Material(
                color: h.id == chosen?.id ? c.blueSoft : c.surfaceRaised,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AbyRadius.md),
                  side: BorderSide(color: h.id == chosen?.id ? c.blue : c.line, width: 1.5),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AbyRadius.md),
                  onTap: () => onChoose(h),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s3),
                    child: Row(
                      children: [
                        AbyIcon(
                          h.id == chosen?.id ? AbyIcons.check : AbyIcons.wifi,
                          size: 20,
                          color: h.id == chosen?.id ? c.blue : c.success,
                        ),
                        const SizedBox(width: AbySpace.s3),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.hubFound(h.name),
                                style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                              ),
                              Text(
                                h.address,
                                style: AbyText.caption.copyWith(fontFamily: AbyText.mono, color: c.inkMuted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Capitals, only the letters codes use, a dash after the first four.
/// A pasted QR text is let through whole, for the page to read.
class _PairingCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (PairingOffer.parse(newValue.text) != null) return newValue;
    final raw = PairingOffer.normalizeCode(newValue.text)
        .split('')
        .where(PairingOffer.codeChars.contains)
        .take(PairingOffer.codeLength)
        .join();
    final text = PairingOffer.formatCode(raw);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
