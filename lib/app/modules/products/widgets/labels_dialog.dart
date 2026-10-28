import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../domain/labels.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/files.dart';
import '../../../ui/l10n.dart';

/// Products → Tools → Labels: pick how many of each, make barcodes for
/// products without one, then print or save (CAT-08). [preset] gives
/// counts by variant ID (labels for a delivery).
Future<void> showLabels({Map<String, int> preset = const {}}) async {
  final menu = await Get.find<CatalogRepository>().load();
  await Get.dialog<void>(_Labels(menu: menu, preset: preset));
}

/// Labels for a delivery (INV-02): products sold as one of a received
/// item (their recipe is that item alone), one label per piece received.
Future<Map<String, int>> labelCountsFor(Map<String, int> received) async {
  final menu = await Get.find<CatalogRepository>().load();
  return {
    for (final p in menu.products)
      for (final v in p.variants)
        if (v.soleStockItem case final r? when received.containsKey(r.stockItemId) && r.quantity > 0)
          v.id: (received[r.stockItemId]! ~/ r.quantity).clamp(1, 500),
  };
}

class _Row {
  _Row(this.variantId, this.title, this.price, this.code, this.count);

  final String variantId;
  final String title;
  final int price;
  String? code;
  int count;
}

class _Labels extends StatefulWidget {
  const _Labels({required this.menu, required this.preset});

  final Catalogue menu;
  final Map<String, int> preset;

  @override
  State<_Labels> createState() => _LabelsState();
}

class _LabelsState extends State<_Labels> {
  late final List<_Row> _rows = _build(widget.menu);
  LabelFormat _format = LabelFormat.sheet;
  bool _busy = false;

  List<_Row> _build(Catalogue menu) => [
        for (final p in menu.products)
          for (final v in p.variants)
            _Row(
              v.id,
              v.name == null ? p.name : '${p.name}, ${v.name}',
              v.price,
              v.barcodes.firstOrNull,
              widget.preset[v.id] ?? 0,
            ),
      ];

  List<_Row> get _picked => [for (final r in _rows) if (r.count > 0) r];

  Future<void> _makeBarcodes() async {
    final l = context.l10n;
    final missing = [for (final r in _picked) if (r.code == null) r.variantId];
    if (missing.isEmpty) return;
    final auth = await Get.find<PermissionService>().authorize(Permission.editProducts, reason: l.labelsMakeBarcodes);
    if (auth == null) return;
    final repo = Get.find<CatalogRepository>();
    final made = await repo.generateBarcodes(missing, by: auth.authority);
    final fresh = await repo.load();
    final codes = {for (final p in fresh.products) for (final v in p.variants) v.id: v.barcodes.firstOrNull};
    setState(() {
      for (final r in _rows) {
        r.code = codes[r.variantId];
      }
    });
    showMessage(l.labelsBarcodesMade(made));
  }

  Future<void> _print() async {
    final items = [for (final r in _picked) LabelItem(name: r.title, price: r.price, code: r.code, count: r.count)];
    if (items.isEmpty) return;
    setState(() => _busy = true);
    try {
      if (_format == LabelFormat.printer) {
        final print = printService;
        if (print == null || !print.hasPrinter) return showMessage(context.l10n.printNoPrinter);
        for (final doc in Labels.paper(items)) {
          print.printDoc(doc);
        }
        showMessage(context.l10n.printSent);
      } else {
        final bytes = await Labels.pdf(items, _format);
        await shareOrSaveBytes('labels.pdf', bytes);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final picked = _picked;
    final missing = picked.where((r) => r.code == null).length;
    final total = picked.fold(0, (s, r) => s + r.count);
    return AlertDialog(
      title: Text(l.labelsTitle),
      content: SizedBox(
        width: 520,
        height: 520,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SegmentedButton<LabelFormat>(
            segments: [
              ButtonSegment(value: LabelFormat.sheet, label: Text(l.labelsSheet)),
              ButtonSegment(value: LabelFormat.roll, label: Text(l.labelsRoll)),
              ButtonSegment(value: LabelFormat.printer, label: Text(l.labelsReceiptPrinter)),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
          ),
          const SizedBox(height: AbySpace.s2),
          Text(l.labelsHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s2),
          Expanded(
            child: ListView(children: [
              for (final r in _rows)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(r.title),
                  subtitle: Text('${formatMoney(r.price)}  ·  ${r.code ?? l.labelsNoBarcode}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: l.cartOneLess,
                      onPressed: r.count == 0 ? null : () => setState(() => r.count--),
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(width: 32, child: Text('${r.count}', textAlign: TextAlign.center, style: AbyText.price)),
                    IconButton(tooltip: l.cartOneMore, onPressed: () => setState(() => r.count++), icon: const Icon(Icons.add)),
                  ]),
                ),
            ]),
          ),
          if (missing > 0)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _makeBarcodes,
                icon: const Icon(Icons.qr_code_2),
                label: Text(l.labelsMakeMissing(missing)),
              ),
            ),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton.icon(
          onPressed: total == 0 || _busy ? null : _print,
          icon: const Icon(Icons.print_outlined),
          label: Text(l.labelsPrint(total)),
        ),
      ],
    );
  }
}
