import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../models/catalog.dart';
import '../../../models/drafts.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/catalogue_controller.dart';
import 'recipe_lines.dart';

/// A group of options (toppings, sugar level) with its rules.
Future<void> showOptionGroupEditor(CatalogueController controller, [OptionGroup? group]) =>
    Get.dialog<void>(_GroupEditor(controller: controller, group: group));

class _OptionForm {
  _OptionForm({
    this.id,
    String name = '',
    String price = '',
    this.isDefault = false,
    List<RecipeLineForm>? recipe,
    this.variantId,
  })
      : name = TextEditingController(text: name),
        price = TextEditingController(text: price),
        recipe = recipe ?? [];

  final String? id;
  final TextEditingController name;
  final TextEditingController price;
  bool isDefault;
  final List<RecipeLineForm> recipe;

  /// A combo part's product variant.
  String? variantId;

  void dispose() {
    name.dispose();
    price.dispose();
    for (final r in recipe) {
      r.dispose();
    }
  }
}

class _GroupEditor extends StatefulWidget {
  const _GroupEditor({required this.controller, this.group});

  final CatalogueController controller;
  final OptionGroup? group;

  @override
  State<_GroupEditor> createState() => _GroupEditorState();
}

class _GroupEditorState extends State<_GroupEditor> {
  late final _name = TextEditingController(text: widget.group?.name ?? '');
  late final _min = TextEditingController(text: '${widget.group?.minSelect ?? 0}');
  late final _max = TextEditingController(text: widget.group?.maxSelect?.toString() ?? '');
  late bool _repeat = widget.group?.allowRepeat ?? false;
  late final List<_OptionForm> _options = [
    for (final o in widget.group?.options ?? const <Option>[])
      _OptionForm(
        id: o.id,
        name: o.name,
        price: o.priceDelta == 0 ? '' : (o.priceDelta / 100).toStringAsFixed(2),
        isDefault: o.isDefault,
        variantId: o.variantId,
        // A combo part shows its product's recipe; it has none of its own.
        recipe: o.variantId == null ? [for (final r in o.recipe) RecipeLineForm.from(r)] : [],
      ),
    if (widget.group == null) _OptionForm(),
  ];
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _min.dispose();
    _max.dispose();
    for (final o in _options) {
      o.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final items = widget.controller.stockItems;
    final options = <OptionDraft>[];
    for (final o in _options) {
      final price = o.price.text.trim().isEmpty ? 0 : parseMoney(o.price.text);
      if (price == null) {
        setState(() => _error = l.optionsPriceInvalid(o.name.text));
        return;
      }
      options.add(OptionDraft(
        id: o.id,
        name: o.name.text,
        priceDelta: price,
        isDefault: o.isDefault,
        variantId: o.variantId,
        recipe: o.variantId != null ? const [] : [for (final r in o.recipe) ?r.draft(items)],
      ));
    }
    final ok = await widget.controller.saveOptionGroup(OptionGroupDraft(
      id: widget.group?.id,
      name: _name.text,
      minSelect: int.tryParse(_min.text.trim()) ?? 0,
      maxSelect: int.tryParse(_max.text.trim()),
      allowRepeat: _repeat,
      options: options,
    ));
    if (ok) {
      Get.back<void>();
    } else {
      setState(() => _error = widget.controller.message.value);
      widget.controller.message.value = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    // Products a combo option can be: (variant ID, "Milkshake, 350 ml").
    final parts = [
      for (final p in widget.controller.catalogue.value?.products ?? const <Product>[])
        if (!p.archived)
          for (final v in p.variants) (v.id, v.name == null ? p.name : '${p.name}, ${v.name}'),
    ];
    return AlertDialog(
      title: Text(widget.group == null ? l.optionsNew : l.optionsEdit),
      content: SizedBox(
        width: 620,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _name,
              autofocus: widget.group == null,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(labelText: l.optionsName, helperText: l.optionsNameHelp),
            ),
            const SizedBox(height: AbySpace.s3),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _min,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: InputDecoration(labelText: l.optionsMin, helperText: l.optionsMinHelp),
                ),
              ),
              const SizedBox(width: AbySpace.s3),
              Expanded(
                child: TextField(
                  controller: _max,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  decoration: InputDecoration(labelText: l.optionsMax, helperText: l.optionsMaxHelp),
                ),
              ),
            ]),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l.optionsRepeat),
              subtitle: Text(l.optionsRepeatHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
              value: _repeat,
              onChanged: (v) => setState(() => _repeat = v),
            ),
            const Divider(),
            for (final o in _options)
              Card(
                margin: const EdgeInsets.only(bottom: AbySpace.s3),
                child: Padding(
                  padding: const EdgeInsets.all(AbySpace.s3),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Row(children: [
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: o.name,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(labelText: l.optionsOptionName, isDense: true),
                        ),
                      ),
                      const SizedBox(width: AbySpace.s2),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: o.price,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: l.optionsExtra, prefixText: 'GH₵ ', isDense: true),
                        ),
                      ),
                      IconButton(
                        tooltip: l.optionsRemove,
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => setState(() {
                          _options.remove(o);
                          o.dispose();
                        }),
                      ),
                    ]),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(l.optionsDefault),
                      value: o.isDefault,
                      onChanged: (v) => setState(() => o.isDefault = v ?? false),
                    ),
                    DropdownButtonFormField<String?>(
                      initialValue: parts.any((p) => p.$1 == o.variantId) ? o.variantId : null,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l.optionsComboPart, helperText: l.optionsComboPartHelp, isDense: true),
                      items: [
                        DropdownMenuItem<String?>(child: Text(l.optionsNotAProduct)),
                        for (final (id, label) in parts)
                          DropdownMenuItem<String?>(value: id, child: Text(label, overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (v) => setState(() {
                        o.variantId = v;
                        if (v != null && o.name.text.trim().isEmpty) {
                          o.name.text = parts.firstWhere((p) => p.$1 == v).$2;
                        }
                      }),
                    ),
                    const SizedBox(height: AbySpace.s2),
                    if (o.variantId == null) ...[
                      Text(l.recipeUses.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                      RecipeLinesEditor(
                        lines: o.recipe,
                        stockItems: widget.controller.stockItems,
                        onChanged: () => setState(() {}),
                      ),
                    ],
                  ]),
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => setState(() => _options.add(_OptionForm())),
                icon: const Icon(Icons.add),
                label: Text(l.optionsAdd),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        OutlinedButton(onPressed: () => Get.back<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.commonSave)),
      ],
    );
  }
}
