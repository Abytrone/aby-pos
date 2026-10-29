import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/database/app_database.dart';
import '../../../data/repositories/branch_repository.dart';
import '../../../models/branch.dart';
import '../../../services/auth_service.dart';
import '../../../services/branch_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/backup_controller.dart';

/// Settings → Branches (MDV-02): the shop's locations, which one this
/// device is at, and carrying data between branches in a file.
Future<void> showBranches(BackupController backups) => Get.to<void>(() => _BranchesPage(backups: backups))!;

class _BranchesPage extends StatefulWidget {
  const _BranchesPage({required this.backups});

  final BackupController backups;

  @override
  State<_BranchesPage> createState() => _BranchesPageState();
}

class _BranchesPageState extends State<_BranchesPage> {
  final BranchRepository _repo = Get.find();
  final BranchService _service = Get.find();
  List<Branch> _all = const [];
  Map<String, String> _placed = const {};

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final all = await _repo.list(includeInactive: true);
    final placed = await _repo.placements();
    await _service.load();
    if (mounted) {
      setState(() {
        _all = all;
        _placed = placed;
      });
    }
  }

  Future<void> _run(Future<void> Function() work) async {
    try {
      await work();
    } on BranchException catch (e) {
      showMessage(e.message);
    }
    await _load();
  }

  int _devicesAt(String id) =>
      id == mainBranchId ? 0 : _placed.values.where((b) => b == id).length;

  Future<void> _edit([Branch? b]) async {
    final l = appL10n();
    final draft = await Get.dialog<BranchDraft>(_BranchDialog(branch: b));
    if (draft == null) return;
    await _run(() async {
      await _repo.save(draft, by: Get.find<AuthService>().user);
      showMessage(l.settingsSaved);
    });
  }

  Future<void> _moveDevice() async {
    final l = appL10n();
    final here = _service.current.value?.id;
    final to = await choiceDialog<String>(
      title: l.branchThisDevice,
      options: [for (final b in _all) if (b.active) b.id],
      label: (id) => _all.firstWhere((b) => b.id == id).name,
      selected: here,
    );
    if (to == null || to == here) return;
    final ok = await confirmDialog(
      title: l.branchMoveTitle(_all.firstWhere((b) => b.id == to).name),
      message: l.branchMoveBody,
      confirmLabel: l.branchMove,
    );
    if (!ok) return;
    await _run(() => _repo.placeDevice(to, by: Get.find<AuthService>().user));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final here = _service.current.value;
    return Scaffold(
      appBar: AppBar(title: Text(l.branchesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _edit,
        icon: const Icon(Icons.add_business_outlined),
        label: Text(l.branchAdd),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s4, AbySpace.s4, 96),
        children: [
          Text(l.branchesHelp, style: AbyText.body.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s3),
          GroupCard(title: l.branchThisDevice, children: [
            InfoTile(
              title: here?.name ?? '',
              subtitle: l.branchThisDeviceHelp,
              leading: const Icon(Icons.storefront_outlined),
              trailing: _all.where((b) => b.active).length > 1 ? const Icon(Icons.swap_horiz) : null,
              onTap: _all.where((b) => b.active).length > 1 ? _moveDevice : null,
            ),
          ]),
          GroupCard(title: l.branchesList, children: [
            for (final b in _all)
              InfoTile(
                title: b.name,
                subtitle: [
                  if (b.id == mainBranchId) l.branchMain,
                  if (!b.active) l.branchClosed,
                  if (b.address != null) b.address!,
                  if (b.phone != null) b.phone!,
                  if (_devicesAt(b.id) > 0) l.branchDevices(_devicesAt(b.id)),
                ].join('  ·  '),
                leading: Icon(b.active ? Icons.store_outlined : Icons.store_mall_directory_outlined,
                    color: b.active ? c.ink : c.inkMuted),
                trailing: b.id == mainBranchId
                    ? null
                    : PopupMenuButton<String>(
                        onSelected: (v) => v == 'edit'
                            ? _edit(b)
                            : _run(() => _repo.setActive(b.id, active: !b.active, by: Get.find<AuthService>().user)),
                        itemBuilder: (_) => [
                          PopupMenuItem(value: 'edit', child: Text(l.commonEdit)),
                          PopupMenuItem(value: 'active', child: Text(b.active ? l.branchClose : l.branchReopen)),
                        ],
                      ),
                onTap: () => _edit(b),
              ),
          ]),
          GroupCard(title: l.branchFiles, children: [
            InfoTile(
              title: l.branchSendData,
              subtitle: l.branchSendDataHelp,
              leading: const Icon(Icons.upload_file_outlined),
              onTap: widget.backups.sendOffDevice,
            ),
            InfoTile(
              title: l.branchMerge,
              subtitle: l.branchMergeHelp,
              leading: const Icon(Icons.move_to_inbox_outlined),
              onTap: () async {
                await widget.backups.mergeBranchFile();
                await _load();
              },
            ),
          ]),
        ],
      ),
    );
  }
}

class _BranchDialog extends StatefulWidget {
  const _BranchDialog({this.branch});

  final Branch? branch;

  @override
  State<_BranchDialog> createState() => _BranchDialogState();
}

class _BranchDialogState extends State<_BranchDialog> {
  late final _name = TextEditingController(text: widget.branch?.name ?? '');
  late final _address = TextEditingController(text: widget.branch?.address ?? '');
  late final _phone = TextEditingController(text: widget.branch?.phone ?? '');

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.branch == null ? l.branchAdd : widget.branch!.name),
      content: SizedBox(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: _name, autofocus: true, decoration: InputDecoration(labelText: l.branchName)),
          TextField(controller: _address, decoration: InputDecoration(labelText: l.branchAddress)),
          TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: InputDecoration(labelText: l.branchPhone)),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () => goBack(
            result: BranchDraft(id: widget.branch?.id, name: _name.text, address: _address.text, phone: _phone.text),
          ),
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
