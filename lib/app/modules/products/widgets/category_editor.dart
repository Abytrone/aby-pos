import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../domain/category_icons.dart';

import '../../../models/catalog.dart';
import '../../../models/drafts.dart';
import '../../../models/enums.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_icons.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/product_picture.dart';
import '../../till/widgets/category_dot.dart';
import '../controllers/catalogue_controller.dart';
import '../../../ui/dialogs.dart';

/// Name, colour, picture and (optionally) the category it sits in.
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

  /// Null: worked out from the name as it is typed.
  late String? _icon = widget.category?.icon;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() {
      if (_icon == null) setState(() {});
    });
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await widget.controller.saveCategory(
      CategoryDraft(id: widget.category?.id, name: _name.text, tone: _tone, parentId: _parentId, icon: _icon),
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
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.categoriesName),
          ),
          const SizedBox(height: AbySpace.s4),
              Row(
                children: [
                  Expanded(
                    child: Text(l.categoriesColour.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                  ),
                  Text(toneLabel(l, _tone), style: AbyText.caption.copyWith(color: c.inkMuted)),
                ],
              ),
          const SizedBox(height: AbySpace.s2),
          Wrap(spacing: AbySpace.s1,
                runSpacing: AbySpace.s1, children: [
            for (final t in CategoryTone.values) _Swatch(tone: t,
                selected: _tone == t, onTap: () => setState(() => _tone = t),
              ),
          ],
              ),
              const SizedBox(height: AbySpace.s4),
              _IconPicker(
                tone: _tone,
                picked: _icon,
                guess: guessCategoryIcon(_name.text, _tone),
                // Tapping the picked one again goes back to the guess.
                onPick: (i) => setState(() => _icon = i == _icon ? null : i),
              ),
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
      ),
      actions: [
        DialogButtons(children: [
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _saving ? null : _save, child: Text(l.commonSave)),
        ]),
      ],
    );
  }
}

/// A category colour's name, for the picker and screen readers.
String toneLabel(AppLocalizations l, CategoryTone t) => switch (t) {
  CategoryTone.midnight => l.toneMidnight,
  CategoryTone.lime => l.toneLime,
  CategoryTone.blue => l.toneBlue,
  CategoryTone.coral => l.toneCoral,
  CategoryTone.amber => l.toneAmber,
  CategoryTone.teal => l.toneTeal,
  CategoryTone.violet => l.toneViolet,
  CategoryTone.rose => l.toneRose,
};

/// One colour to pick: a round swatch, ringed when it is the one picked.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.tone, required this.selected, required this.onTap});

  final CategoryTone tone;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final label = toneLabel(context.l10n, tone);
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      label: label,
      excludeSemantics: true,
      child: Tooltip(
        message: label,
        child: InkResponse(
          onTap: onTap,
          radius: AbySize.tapMin / 2,
          child: SizedBox.square(
            dimension: AbySize.tapMin,
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                width: 36,
                height: 36,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: selected ? c.primary : Colors.transparent, width: 2),
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(color: toneColor(tone, c), shape: BoxShape.circle),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The picture products without a photo show. One is always lit: the
/// owner's pick, or the guess from the name (marked "Picked from the
/// name"). Food and drink first, then everything else a shop sells.
class _IconPicker extends StatelessWidget {
  const _IconPicker({required this.tone, required this.picked, required this.guess, required this.onPick});

  final CategoryTone tone;
  final String? picked;
  final String guess;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final shown = picked ?? guess;
    Widget option(String icon) {
      final on = icon == shown;
      return Semantics(
        selected: on,
        button: true,
        label: icon.replaceAll('-', ' '),
        excludeSemantics: true,
        child: Material(
          color: on ? toneTint(tone, c) : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AbyRadius.sm),
            side: BorderSide(color: on ? c.primary : c.line, width: on ? 2 : 1),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AbyRadius.sm),
            onTap: () => onPick(icon),
            child: SizedBox.square(
              dimension: AbySize.tapMin,
              child: Center(child: AbyIcon(iconAsset(icon), size: 22, color: on ? toneIconColor(tone, c) : c.inkMuted)),
            ),
          ),
        ),
      );
    }

    Widget group(String title, List<String> icons) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s1),
        Wrap(spacing: AbySpace.s1, runSpacing: AbySpace.s1, children: [for (final i in icons) option(i)]),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.categoriesPicture.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            ),
            if (picked == null) Text(l.categoriesPictureAuto, style: AbyText.caption.copyWith(color: c.inkMuted)),
          ],
        ),
        const SizedBox(height: AbySpace.s2),
        group(l.categoriesIconsFood, foodIcons),
        const SizedBox(height: AbySpace.s3),
        group(l.categoriesIconsShop, shopIcons),
      ],
    );
  }
}
