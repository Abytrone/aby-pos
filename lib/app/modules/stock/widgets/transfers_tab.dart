import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/units.dart';
import '../../../data/repositories/stock_repository.dart';
import '../../../data/repositories/transfer_repository.dart';
import '../../../models/branch.dart';
import '../../../models/enums.dart';
import '../../../models/stock.dart';
import '../../../services/auth_service.dart';
import '../../../services/branch_service.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/stock_controller.dart';

String transferStatusLabel(AppLocalizations l, TransferStatus s) => switch (s) {
      TransferStatus.sent => l.transferInTransit,
      TransferStatus.received => l.transferReceived,
      TransferStatus.cancelled => l.transferCancelled,
    };

bool get canSendStock => Get.find<AuthService>().can(Permission.adjustStock);
bool get canReceiveTransfer => Get.find<AuthService>().can(Permission.receiveStock);

/// Stock → Transfers (INV-10): stock sent to and from this branch, what is
/// on its way first.
class TransfersTab extends StatefulWidget {
  const TransfersTab({super.key});

  @override
  State<TransfersTab> createState() => _TransfersTabState();
}

class _TransfersTabState extends State<TransfersTab> {
  final TransferRepository _repo = Get.find();
  StreamSubscription<void>? _sub;
  List<StockTransfer>? _list;

  @override
  void initState() {
    super.initState();
    _sub = _repo.watch().listen((_) => unawaited(_load()));
    unawaited(_load());
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final list = await _repo.list();
    if (mounted) setState(() => _list = list);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final all = _list;
    if (all == null) return const Center(child: CircularProgressIndicator());
    if (all.isEmpty) return EmptyState(icon: Icons.local_shipping_outlined, message: l.transferNone);
    final here = Get.find<BranchService>().current.value?.id;
    final list = [...all.where((t) => t.status == TransferStatus.sent), ...all.where((t) => t.status != TransferStatus.sent)];
    return ListView.separated(
      padding: const EdgeInsets.all(AbySpace.s4),
      itemCount: list.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final t = list[i];
        final incoming = t.toBranch == here;
        final waiting = t.status == TransferStatus.sent;
        return InfoTile(
          title: '${t.code}  ·  ${incoming ? l.transferFrom(t.fromName) : l.transferTo(t.toName)}',
          subtitle: [
            formatDate(t.sentAt),
            transferStatusLabel(l, t.status),
            l.deliveriesItems(t.lines.length),
            if (t.hasDifferences) l.transferDifferences,
          ].join('  ·  '),
          value: formatMoney(t.value),
          leading: Icon(
            incoming ? Icons.call_received : Icons.call_made,
            color: !waiting
                ? (t.hasDifferences ? c.warning : c.inkMuted)
                : incoming
                    ? c.success
                    : c.blue,
          ),
          onTap: () => showTransfer(t),
        );
      },
    );
  }
}

/// One transfer, with Receive (at the branch it went to) or Call back (at
/// the branch that sent it) while it is on its way.
Future<void> showTransfer(StockTransfer t) => Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      final c = Theme.of(context).extension<AbyColors>()!;
      final here = Get.find<BranchService>().current.value?.id;
      final waiting = t.status == TransferStatus.sent;
      return AlertDialog(
        title: Text('${t.code}  ·  ${t.fromName} → ${t.toName}'),
        content: SizedBox(
          width: 460,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(
                [
                  transferStatusLabel(l, t.status),
                  l.transferSentBy(formatDateTime(t.sentAt), t.sentBy),
                  if (t.receivedAt != null) l.transferReceivedBy(formatDateTime(t.receivedAt!), t.receivedBy ?? ''),
                ].join('  ·  '),
                style: AbyText.caption.copyWith(color: c.inkMuted),
              ),
              const SizedBox(height: AbySpace.s2),
              for (final line in t.lines)
                InfoTile(
                  title: line.itemName,
                  subtitle: line.quantityReceived == null
                      ? null
                      : line.difference == 0
                          ? l.transferArrivedAll
                          : l.transferArrived(formatQuantity(line.quantityReceived!, line.unit)),
                  value: formatQuantity(line.quantitySent, line.unit),
                  leading: line.difference == 0 ? null : Icon(Icons.warning_amber, color: c.warning),
                ),
              if (t.note != null) Text('“${t.note}”', style: AbyText.caption.copyWith(color: c.inkMuted)),
            ]),
          ),
        ),
        actions: [
          DialogButtons(children: [
                if (waiting && t.fromBranch == here && canSendStock)
              TextButton(
                style: TextButton.styleFrom(foregroundColor: c.danger),
                onPressed: () async {
                  final ok = await confirmDialog(
                    title: l.transferCallBackTitle,
                    message: l.transferCallBackBody,
                    confirmLabel: l.transferCallBack,
                    danger: true,
                  );
                  if (!ok) return;
                  goBack<void>();
                  await _guard(() => Get.find<TransferRepository>().cancel(t.id, by: Get.find<AuthService>().user));
                },
                child: Text(l.transferCallBack),
              ),
            if (waiting && t.toBranch == here && canReceiveTransfer)
              FilledButton(
                onPressed: () {
                  goBack<void>();
                  unawaited(showReceiveTransfer(t));
                },
                child: Text(l.transferReceive),
              ),
            OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
          ]),
        ],
      );
    }));

Future<void> _guard(Future<void> Function() action) async {
  try {
    await action();
  } on StockException catch (e) {
    showMessage(e.message, tone: MessageTone.error);
  }
}

/// What arrived, line by line (everything, unless changed).
Future<void> showReceiveTransfer(StockTransfer t) async {
  final fields = {
    for (final line in t.lines) line.id: TextEditingController(text: quantityIn(line.quantitySent, DisplayUnit.bulk(line.unit))),
  };
  final received = await Get.dialog<Map<String, int>>(Builder(builder: (context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    String? error;
    return StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l.transferReceiveTitle(t.code)),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text(l.transferReceiveHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s3),
              for (final line in t.lines)
                Padding(
                  padding: const EdgeInsets.only(bottom: AbySpace.s2),
                  child: TextField(
                    controller: fields[line.id],
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: line.itemName,
                      helperText: l.transferSentQty(formatQuantity(line.quantitySent, line.unit)),
                      suffixText: DisplayUnit.bulk(line.unit).symbol,
                      isDense: true,
                    ),
                  ),
                ),
              if (error != null) Text(error!, style: AbyText.body.copyWith(color: c.danger)),
            ]),
          ),
        ),
        actions: [
          DialogButtons(children: [
                    OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
            FilledButton(
              onPressed: () {
                final out = <String, int>{};
                for (final line in t.lines) {
                  final q = parseQuantity(fields[line.id]!.text, DisplayUnit.bulk(line.unit));
                  if (q == null || q < 0) return setState(() => error = l.receiveLineInvalid(line.itemName));
                  out[line.id] = q;
                }
                goBack(result: out);
              },
              child: Text(l.transferReceive),
                    ),
          ]),
        ],
      ),
    );
  }));
  for (final f in fields.values) {
    f.dispose();
  }
  if (received == null) return;
  await _guard(() async {
    final done = await Get.find<TransferRepository>().receive(t.id, received: received, by: Get.find<AuthService>().user);
    showMessage(done.hasDifferences ? appL10n().transferReceivedShort : appL10n().transferReceivedAll, tone: done.hasDifferences ? MessageTone.info : MessageTone.success);
  });
}

/// Send stock to another branch.
Future<void> showNewTransfer() async {
  final branches = Get.find<BranchService>();
  final here = branches.current.value?.id;
  final targets = [for (final b in branches.branches) if (b.id != here) b];
  if (targets.isEmpty) return showMessage(appL10n().transferNoBranches);
  final items = Get.find<StockController>().items.where((i) => i.active).toList();
  final sent = await Get.dialog<StockTransfer>(_NewTransfer(targets: targets, items: items));
  if (sent != null) {
    showMessage(appL10n().transferSent(sent.code), tone: MessageTone.success);
  }
}

class _Line {
  _Line() : quantity = TextEditingController();

  String? itemId;
  final TextEditingController quantity;
}

class _NewTransfer extends StatefulWidget {
  const _NewTransfer({required this.targets, required this.items});

  final List<Branch> targets;
  final List<StockItem> items;

  @override
  State<_NewTransfer> createState() => _NewTransferState();
}

class _NewTransferState extends State<_NewTransfer> {
  late String _to = widget.targets.first.id;
  final _lines = [_Line()];
  final _note = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    for (final l in _lines) {
      l.quantity.dispose();
    }
    super.dispose();
  }

  StockItem? _item(String? id) => widget.items.where((i) => i.id == id).firstOrNull;

  Future<void> _send() async {
    final l = context.l10n;
    final lines = <String, int>{};
    for (final line in _lines.where((x) => x.itemId != null)) {
      final item = _item(line.itemId)!;
      final q = parseQuantity(line.quantity.text, DisplayUnit.bulk(item.unit));
      if (q == null || q <= 0) return setState(() => _error = l.receiveLineInvalid(item.name));
      if (q > item.onHand) return setState(() => _error = l.transferNotEnough(item.name, formatQuantity(item.onHand, item.unit)));
      lines[item.id] = (lines[item.id] ?? 0) + q;
    }
    if (lines.isEmpty) return setState(() => _error = l.poAddItems);
    setState(() => _saving = true);
    try {
      final t = await Get.find<TransferRepository>().send(
        toBranch: _to,
        lines: lines,
        note: _note.text,
        by: Get.find<AuthService>().user,
      );
      goBack(result: t);
    } on StockException catch (e) {
      setState(() {
        _error = e.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    return AlertDialog(
      title: Text(l.transferNew),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(l.transferNewHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s3),
            DropdownButtonFormField<String>(
              initialValue: _to,
              isExpanded: true,
              decoration: InputDecoration(labelText: l.transferToBranch),
              items: [for (final b in widget.targets) DropdownMenuItem(value: b.id, child: Text(b.name))],
              onChanged: (v) => setState(() => _to = v ?? _to),
            ),
            const SizedBox(height: AbySpace.s3),
            for (final line in _lines)
              Padding(
                padding: const EdgeInsets.only(bottom: AbySpace.s2),
                child: Row(children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      initialValue: line.itemId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.recipeItem, isDense: true),
                      items: [
                        for (final i in widget.items)
                          DropdownMenuItem(
                            value: i.id,
                            child: Text('${i.name} (${formatQuantity(i.onHand, i.unit)})', overflow: TextOverflow.ellipsis),
                          ),
                      ],
                      onChanged: (v) => setState(() => line.itemId = v),
                    ),
                  ),
                  const SizedBox(width: AbySpace.s2),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: line.quantity,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: l.stockQuantity,
                        suffixText: _item(line.itemId) == null ? null : DisplayUnit.bulk(_item(line.itemId)!.unit).symbol,
                        isDense: true,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: l.recipeRemove,
                    icon: const Icon(Icons.close),
                    onPressed: _lines.length == 1 ? null : () => setState(() => _lines.remove(line)),
                  ),
                ]),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _lines.add(_Line())),
                icon: const Icon(Icons.add),
                label: Text(l.receiveAddLine),
              ),
            ),
            TextField(controller: _note, decoration: InputDecoration(labelText: l.transferNote)),
            if (_error != null) ...[
              const SizedBox(height: AbySpace.s2),
              Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
            ],
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _saving ? null : _send, child: Text(l.transferSend)),
        ]),
      ],
    );
  }
}
