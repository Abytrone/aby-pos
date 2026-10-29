import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/catalog.dart';
import '../../../models/drafts.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/catalogue_controller.dart';
import '../../../ui/dialogs.dart';

Future<void> showTaxEditor(CatalogueController controller, [TaxRate? rate]) =>
    Get.dialog<void>(_TaxEditor(controller: controller, rate: rate));

class _TaxEditor extends StatefulWidget {
  const _TaxEditor({required this.controller, this.rate});

  final CatalogueController controller;
  final TaxRate? rate;

  @override
  State<_TaxEditor> createState() => _TaxEditorState();
}

class _TaxEditorState extends State<_TaxEditor> {
  late final _name = TextEditingController(text: widget.rate?.name ?? '');
  late final _rate = TextEditingController(text: widget.rate?.percent.replaceAll('%', '') ?? '');
  late bool _compound = widget.rate?.compound ?? false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _rate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final bp = CatalogueController.parsePercent(_rate.text);
    if (bp == null) {
      setState(() => _error = context.l10n.taxRateInvalid);
      return;
    }
    final ok = await widget.controller.saveTaxRate(
      TaxRateDraft(id: widget.rate?.id, name: _name.text, rateBp: bp, compound: _compound),
    );
    if (ok) goBack<void>();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.rate == null ? l.taxNew : l.taxEdit),
      content: SizedBox(
        width: 380,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: l.taxName, helperText: l.taxNameHelp),
          ),
          const SizedBox(height: AbySpace.s3),
          TextField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.taxRate, suffixText: '%', errorText: _error),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.taxCompound),
            subtitle: Text(l.taxCompoundHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
            value: _compound,
            onChanged: (v) => setState(() => _compound = v),
          ),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
