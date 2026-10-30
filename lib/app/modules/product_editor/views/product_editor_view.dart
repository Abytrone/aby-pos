import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/settings.dart';
import '../../../domain/category_icons.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_icons.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/product_picture.dart';
import '../../../ui/section_page.dart';
import '../../till/widgets/category_dot.dart';
import '../../till/widgets/variant_sheet.dart' show groupRule;
import '../controllers/product_editor_controller.dart';
import '../widgets/variant_card.dart';

class ProductEditorView extends StatelessWidget {
  const ProductEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return GetBuilder<ProductEditorController>(builder: (ctl) {
      return Scaffold(
        appBar: AppBar(
          title: Text(ctl.isNew ? l.productsNew : l.editorTitle),
          backgroundColor: c.surface,
          surfaceTintColor: Colors.transparent,
          toolbarHeight: 64,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AbySpace.s4),
              child: CompactButtons(child: FilledButton(
                onPressed: ctl.loading || ctl.saving
                    ? null
                    : () async {
                        if (await ctl.save()) {
                          goBack<void>();
                          showMessage(l.editorSaved, tone: MessageTone.success);
                        }
                      },
                child: Text(l.commonSave),
              )),
            ),
          ],
        ),
        body: ctl.loading
            ? const Center(child: CircularProgressIndicator())
            : Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
                    if (ctl.error != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: AbySpace.s4),
                        padding: const EdgeInsets.all(AbySpace.s3),
                        decoration: BoxDecoration(
                          color: c.dangerSoft,
                          borderRadius: BorderRadius.circular(AbyRadius.sm),
                        ),
                        child: Text(ctl.error!, style: AbyText.body.copyWith(color: c.danger)),
                      ),
                    _Basics(ctl: ctl),
                    const SizedBox(height: AbySpace.s6),
                    _Prices(ctl: ctl),
                    const SizedBox(height: AbySpace.s6),
                    _OptionsAndTax(ctl: ctl),
                    const SizedBox(height: AbySpace.s8),
                  ]),
                ),
              ),
      );
    });
  }
}

class _Basics extends StatelessWidget {
  const _Basics({required this.ctl});

  final ProductEditorController ctl;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final categories = ctl.catalogue!.categories;
    final category = categories.firstWhereOrNull((x) => x.id == ctl.categoryId);
    final tone = category?.tone ?? CategoryTone.midnight;
    // What the till will show: the photo, else the category's icon.
    final photo = SizedBox(
      width: 140,
      child: Column(
        children: [
          SizedBox.square(
          dimension: 120,
          child: ProductPicture(
              tone: tone,
              icon: category?.picture ?? toneIcon(tone),
              photo: ctl.photo == null ? null : MemoryImage(ctl.photo!),
              iconSize: 44,
              radius: AbyRadius.md,
            ),
          ),
          if (ctl.photo == null) ...[
            const SizedBox(height: AbySpace.s1),
            Text(
              l.editorPhotoNone,
              textAlign: TextAlign.center,
              style: AbyText.caption.copyWith(color: c.inkMuted),
            ),
          ],
      const SizedBox(height: AbySpace.s1),
      Wrap(spacing: AbySpace.s1,
            alignment: WrapAlignment.center, children: [
        FutureBuilder<bool>(
          future: ctl.cameraAvailable,
          builder: (_, snap) => snap.data == true
              ? IconButton(
                  tooltip: l.profileTakePhoto,
                  onPressed: () => ctl.pickPhoto(ImageSource.camera),
                  icon: AbyIcon(AbyIcons.camera, size: 20, color: c.ink),
                )
              : const SizedBox.shrink(),
        ),
        IconButton(
          tooltip: l.profileChoosePhoto,
          onPressed: () => ctl.pickPhoto(ImageSource.gallery),
          icon: AbyIcon(AbyIcons.image, size: 20, color: c.ink),
        ),
        if (ctl.photo != null)
          IconButton(
            tooltip: l.profileRemovePhoto,
            onPressed: ctl.removePhoto,
            icon: AbyIcon(AbyIcons.trash, size: 20, color: c.danger),
                ),
            ],
          ),
        ],
      ),
    );
    final fields = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      TextField(
        controller: ctl.name,
        autofocus: ctl.isNew,
        textCapitalization: TextCapitalization.words,
        decoration: InputDecoration(labelText: l.editorName),
      ),
      const SizedBox(height: AbySpace.s3),
      DropdownButtonFormField<String>(
        initialValue: ctl.categoryId,
        decoration: InputDecoration(labelText: l.editorCategory),
        items: [
          for (final cat in categories)
            DropdownMenuItem(
              value: cat.id,
              child: Row(children: [
                if (cat.parentId != null) const SizedBox(width: AbySpace.s4),
                CategoryDot(tone: cat.tone),
                const SizedBox(width: AbySpace.s2),
                Text(cat.name),
              ]),
            ),
        ],
        onChanged: ctl.setCategory,
      ),
      const SizedBox(height: AbySpace.s3),
      TextField(
        controller: ctl.detail,
        decoration: InputDecoration(labelText: l.editorTileLine, helperText: l.editorTileLineHelp),
      ),
      const SizedBox(height: AbySpace.s3),
      TextField(
        controller: ctl.description,
        maxLines: 2,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l.editorDescription),
      ),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l.editorOnTill),
        subtitle: Text(l.editorOnTillHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
        value: ctl.active,
        onChanged: ctl.setActive,
      ),
    ]);
    return context.isNarrow
        ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [photo, const SizedBox(height: AbySpace.s4), fields])
        : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            photo,
            const SizedBox(width: AbySpace.s6),
            Expanded(child: fields),
          ]);
  }
}

class _Prices extends StatelessWidget {
  const _Prices({required this.ctl});

  final ProductEditorController ctl;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.editorPrices.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
      const SizedBox(height: AbySpace.s1),
      Text(l.editorPricesHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
      const SizedBox(height: AbySpace.s3),
      for (final (i, v) in ctl.variants.indexed)
        VariantCard(ctl: ctl, form: v, index: i, single: ctl.variants.length == 1),
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: ctl.addVariant,
          icon: const Icon(Icons.add),
          label: Text(ctl.variants.length == 1 ? l.editorAddSizes : l.editorAddVariant),
        ),
      ),
    ]);
  }
}

class _OptionsAndTax extends StatelessWidget {
  const _OptionsAndTax({required this.ctl});

  final ProductEditorController ctl;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final groups = ctl.catalogue!.groups.where((g) => g.active).toList();
    final taxes = ctl.catalogue!.taxRates.where((t) => t.active).toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      GroupCard(title: l.editorSelling, children: [
        SwitchListTile(
          title: Text(l.editorQuickTab),
          subtitle: Text(l.editorQuickTabHelp),
          value: ctl.onQuickTab,
          onChanged: ctl.setQuickTab,
        ),
        ListTile(
          title: Text(l.editorSellBy),
          subtitle: Text(ctl.sellBy == SellBy.each ? l.editorSellByEachHelp : l.editorSellByWeightHelp),
          trailing: DropdownButton<SellBy>(
            value: ctl.sellBy,
            items: [
              for (final s in SellBy.values) DropdownMenuItem(value: s, child: Text(sellByLabel(l, s))),
            ],
            onChanged: (v) => v == null ? null : ctl.setSellBy(v),
          ),
        ),
        SwitchListTile(
          title: Text(l.editorOpenPrice),
          subtitle: Text(l.editorOpenPriceHelp),
          value: ctl.openPrice,
          onChanged: ctl.setOpenPrice,
        ),
        if (ctl.openPrice)
          Padding(
            padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s3),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: ctl.minPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.editorMinPrice, prefixText: 'GH₵ '),
                ),
              ),
              const SizedBox(width: AbySpace.s3),
              Expanded(
                child: TextField(
                  controller: ctl.maxPrice,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.editorMaxPrice, prefixText: 'GH₵ '),
                ),
              ),
            ]),
          ),
      ]),
      if (Get.find<SettingsService>().get(AppSettings.commissionMode) == 'perProduct')
        GroupCard(title: l.editorCommission, children: [
          Padding(
            padding: const EdgeInsets.all(AbySpace.s4),
            child: TextField(
              controller: ctl.commission,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.editorCommissionPer, prefixText: 'GH₵ ', helperText: l.editorCommissionHelp),
            ),
          ),
        ]),
      GroupCard(
        title: l.editorOptions,
        footer: groups.isEmpty ? l.editorNoOptions : null,
        children: [
          for (final g in groups)
            CheckboxListTile(
              title: Text(g.name),
              subtitle: Text('${groupRule(l, g)}  ·  ${g.options.map((o) => o.priceDelta == 0 ? o.name : '${o.name} +${formatMoney(o.priceDelta)}').join(', ')}'),
              value: ctl.groupIds.contains(g.id),
              onChanged: (v) => ctl.toggleGroup(g.id, v ?? false),
            ),
        ],
      ),
      GroupCard(
        title: l.editorTaxes,
        footer: taxes.isEmpty ? l.editorNoTaxes : l.editorTaxesHelp,
        children: [
          for (final t in taxes)
            CheckboxListTile(
              title: Text('${t.name}  ${t.percent}'),
              value: ctl.taxIds.contains(t.id),
              onChanged: (v) => ctl.toggleTax(t.id, v ?? false),
            ),
        ],
      ),
    ]);
  }
}

String sellByLabel(AppLocalizations l, SellBy s) => switch (s) {
      SellBy.each => l.sellByEach,
      SellBy.kg => l.sellByKg,
      SellBy.litre => l.sellByLitre,
    };
