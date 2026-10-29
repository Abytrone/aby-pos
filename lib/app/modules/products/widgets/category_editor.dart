import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/catalog.dart';
import '../../../models/drafts.dart';
import '../../../models/enums.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../till/widgets/category_dot.dart';
import '../controllers/catalogue_controller.dart';
import '../../../ui/dialogs.dart';

/// Name, colour and (optionally) the category it sits in.
Future<void> showCategoryEditor(CatalogueController controller, [Category? category]) =>
    Get.dialog<void>(_CategoryEditor(controller: controller, category: category));

class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.controller, this.category});

  final CatalogueController controller;
  final Category? category;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late CategoryTone _tone = widget.category?.tone ?? CategoryTone.blue;
  late String? _parentId = widget.category?.parentId;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.controller.saveCategory(
      CategoryDraft(id: widget.category?.id, name: _name.text, tone: _tone, parentId: _parentId),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) goBack<void>();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final parents = widget.controller.categories
        .where((x) => x.parentId == null && x.id != widget.category?.id)
        .toList();
    return AlertDialog(
      title: Text(widget.category == null ? l.categoriesNew : l.categoriesEdit),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.categoriesName),
          ),
          const SizedBox(height: AbySpace.s4),
          Text(l.categoriesColour.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s2),
          Wrap(spacing: AbySpace.s2, children: [
            for (final t in CategoryTone.values)
              ChoiceChip(
                avatar: CategoryDot(tone: t),
                label: Text(t.name),
                selected: _tone == t,
                onSelected: (_) => setState(() => _tone = t),
              ),
          ]),
          const SizedBox(height: AbySpace.s4),
          DropdownButtonFormField<String?>(
            initialValue: _parentId,
            decoration: InputDecoration(labelText: l.categoriesInside),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(l.categoriesTopLevel)),
              for (final p in parents) DropdownMenuItem<String?>(value: p.id, child: Text(p.name)),
            ],
            onChanged: (v) => setState(() => _parentId = v),
          ),
        ]),
      ),
      actions: [
        OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
        FilledButton(onPressed: _saving ? null : _save, child: Text(l.commonSave)),
      ],
    );
  }
}
