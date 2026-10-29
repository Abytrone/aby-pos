import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/catalog.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/till_controller.dart';
import '../../../ui/dialogs.dart';

/// Pick the products on the Quick tab and drag them into order.
Future<void> showQuickArrange(TillController controller) =>
    Get.dialog<void>(_QuickArrange(controller: controller));

class _QuickArrange extends StatefulWidget {
  const _QuickArrange({required this.controller});

  final TillController controller;

  @override
  State<_QuickArrange> createState() => _QuickArrangeState();
}

class _QuickArrangeState extends State<_QuickArrange> {
  late final List<Product> _chosen = widget.controller.quickProducts;
  String _filter = '';

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final chosenIds = {for (final p in _chosen) p.id};
    final others = widget.controller.products
        .where((p) => !chosenIds.contains(p.id) && p.name.toLowerCase().contains(_filter.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(l.quickArrange),
      content: SizedBox(
        width: 460,
        height: 520,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(l.quickArrangeHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s2),
          Expanded(
            flex: 3,
            child: _chosen.isEmpty
                ? Center(child: Text(l.tillQuickEmpty, style: AbyText.body.copyWith(color: c.inkMuted)))
                : ReorderableListView.builder(
                    buildDefaultDragHandles: true,
                    itemCount: _chosen.length,
                    onReorderItem: (from, to) => setState(() => _chosen.insert(to, _chosen.removeAt(from))),
                    itemBuilder: (_, i) => ListTile(
                      key: ValueKey(_chosen[i].id),
                      leading: const Icon(Icons.drag_indicator),
                      title: Text(_chosen[i].name),
                      trailing: IconButton(
                        tooltip: l.quickRemove,
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => setState(() => _chosen.removeAt(i)),
                      ),
                    ),
                  ),
          ),
          const Divider(),
          TextField(
            onChanged: (v) => setState(() => _filter = v),
            decoration: InputDecoration(isDense: true, prefixIcon: const Icon(Icons.search), hintText: l.quickAddHint),
          ),
          Expanded(
            flex: 2,
            child: ListView(children: [
              for (final p in others)
                ListTile(
                  dense: true,
                  title: Text(p.name),
                  trailing: const Icon(Icons.add),
                  onTap: () => setState(() => _chosen.add(p)),
                ),
            ]),
          ),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(
          onPressed: () async {
            await widget.controller.arrangeQuickTab([for (final p in _chosen) p.id]);
            goBack<void>();
          },
          child: Text(l.commonSave),
        ),
      ],
    );
  }
}
