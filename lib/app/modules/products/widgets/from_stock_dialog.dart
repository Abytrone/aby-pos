import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../data/repositories/catalog_repository.dart';
import '../../../domain/stock_io.dart';
import '../../../models/catalog.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';

/// Tick stock items, set a margin (or markup), and each becomes a product
/// whose recipe uses it, priced from its cost. Returns how many were made.
Future<int?> showProductsFromStock(BuildContext context) => Get.dialog<int>(
      context.isNarrow ? const Dialog.fullscreen(child: _FromStock()) : const Dialog(child: _FromStock()),
    );

class _FromStock extends StatefulWidget {
  const _FromStock();

  @override
  State<_FromStock> createState() => _FromStockState();
}

class _FromStockState extends State<_FromStock> {
  static const _newCategory = '';

  final StockIo _io = Get.find();
  late final _percent = TextEditingController(text: '${Get.find<SettingsService>().get(AppSettings.targetMarginPercent)}');
  final _categoryName = TextEditingController();
  final _search = TextEditingController();

  List<StockProductPlan>? _plans;
  List<Category> _categories = const [];
  final _ticked = <String>{};

  /// Prices typed by hand: stock item ID → pesewas. They win over the rule.
  final _typed = <String, int>{};
  PriceRule _rule = PriceRule.margin;
  int _step = 50;
  /// The category for rows without their own.
  String? _categoryId;

  /// Rows with their own category: stock item ID → category ID. Filled
  /// from each item's name where it is clear; changed on the row.
  final _rowCategory = <String, String>{};
  bool _onTill = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final plans = await _io.productPlans();
    final catalogue = await Get.find<CatalogRepository>().load(includeInactive: true);
    final categories = await Get.find<CatalogRepository>().categories();
    if (!mounted) return;
    setState(() {
      _plans = plans;
      _categories = categories;
      _categoryId = categories.firstOrNull?.id ?? _newCategory;
      for (final p in plans) {
        final guess = StockIo.suggestCategory(p.item.name, categories, catalogue.products);
        if (guess != null && categories.any((c) => c.id == guess)) _rowCategory[p.item.id] = guess;
      }
      _ticked.addAll([for (final p in plans) if (p.suggested) p.item.id]);
    });
  }

  @override
  void dispose() {
    _percent.dispose();
    _categoryName.dispose();
    _search.dispose();
    super.dispose();
  }

  int? get _percentValue => int.tryParse(_percent.text.trim());

  int? _priceOf(StockProductPlan p) {
    final typed = _typed[p.item.id];
    if (typed != null) return typed;
    final percent = _percentValue;
    return percent == null ? null : priceFromCost(p.cost, percent, _rule, step: _step);
  }

  List<StockProductPlan> get _chosen => [for (final p in _plans ?? const <StockProductPlan>[]) if (_ticked.contains(p.item.id)) p];

  Future<void> _typePrice(StockProductPlan p) async {
    final l = context.l10n;
    final current = _priceOf(p);
    final text = await textInputDialog(
      title: l.fromStockTypePrice(p.item.name),
      label: p.per.isEmpty ? l.linePrice : l.entryPricePerLabel(p.per),
      initial: current == null ? '' : (current / 100).toStringAsFixed(2),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validate: (v) => (parseMoney(v) ?? -1) < 0 ? l.tillPriceInvalid : null,
    );
    final price = text == null ? null : parseMoney(text);
    if (price == null) return;
    setState(() {
      _typed[p.item.id] = price;
      _ticked.add(p.item.id);
    });
  }

  Future<void> _make() async {
    final l = context.l10n;
    final chosen = _chosen;
    if (_rule == PriceRule.margin && (_percentValue ?? 100) >= 100 && chosen.any((p) => !_typed.containsKey(p.item.id))) {
      return setState(() => _error = l.fromStockPercentInvalid);
    }
    final missing = chosen.where((p) => _priceOf(p) == null).firstOrNull;
    if (missing != null) return _typePrice(missing);
    final auth = await Get.find<PermissionService>().authorize(Permission.editProducts, reason: l.fromStockReason);
    if (auth == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final made = await _io.createProducts(
        chosen,
        prices: {for (final p in chosen) p.item.id: _priceOf(p)!},
        categoryFor: {for (final p in chosen) if (_rowCategory[p.item.id] != null) p.item.id: _rowCategory[p.item.id]!},
        categoryId: _categoryId == _newCategory ? null : _categoryId,
        newCategory: _categoryName.text,
        onTill: _onTill,
        by: auth.authority,
      );
      goBack<int>(result: made);
      showMessage(appL10n().fromStockDone(made), tone: MessageTone.success);
    } on Exception catch (e) {
      setState(() {
        _saving = false;
        _error = e is CatalogueException ? e.message : '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final plans = _plans;
    final percent = _percentValue ?? 0;
    final chosen = _chosen;
    final q = _search.text.trim().toLowerCase();
    final shown = [for (final p in plans ?? const <StockProductPlan>[]) if (q.isEmpty || p.item.name.toLowerCase().contains(q)) p];
    String stepLabel(int s) => s == 0 ? l.bulkNoRounding : l.bulkRoundTo(formatMoney(s));

    final settings = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(l.fromStockIntro, style: AbyText.body.copyWith(color: c.inkMuted)),
      const SizedBox(height: AbySpace.s3),
      Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, crossAxisAlignment: WrapCrossAlignment.center, children: [
        SegmentedButton<PriceRule>(
          segments: [
            ButtonSegment(value: PriceRule.margin, label: Text(l.fromStockMargin)),
            ButtonSegment(value: PriceRule.markup, label: Text(l.fromStockMarkup)),
          ],
          selected: {_rule},
          onSelectionChanged: (s) => setState(() => _rule = s.first),
        ),
        SizedBox(
          width: 96,
          child: TextField(
            controller: _percent,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _error = null),
            decoration: const InputDecoration(isDense: true, suffixText: '%'),
          ),
        ),
      ]),
      const SizedBox(height: AbySpace.s1),
      Text(
        _rule == PriceRule.margin ? l.fromStockMarginHelp('$percent') : l.fromStockMarkupHelp('$percent'),
        style: AbyText.caption.copyWith(color: c.inkMuted),
      ),
      const SizedBox(height: AbySpace.s2),
      Wrap(spacing: AbySpace.s2, children: [
        for (final s in const [0, 10, 50, 100])
          ChoiceChip(label: Text(stepLabel(s)), selected: _step == s, onSelected: (_) => setState(() => _step = s)),
      ]),
      const SizedBox(height: AbySpace.s3),
      Row(children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: _categoryId,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.fromStockDefaultCategory,
              helperText: l.fromStockDefaultHelp,
              helperMaxLines: 2,
              isDense: true,
            ),
            items: [
              for (final cat in _categories) DropdownMenuItem(value: cat.id, child: Text(cat.name)),
              DropdownMenuItem(value: _newCategory, child: Text(l.fromStockNewCategory)),
            ],
            onChanged: (v) => setState(() => _categoryId = v),
          ),
        ),
        if (_categoryId == _newCategory) ...[
          const SizedBox(width: AbySpace.s2),
          Expanded(
            child: TextField(
              controller: _categoryName,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(labelText: l.fromStockNewCategoryName, isDense: true),
            ),
          ),
        ],
      ]),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(l.fromStockOnTill),
        value: _onTill,
        onChanged: (v) => setState(() => _onTill = v),
      ),
      Row(children: [
        Expanded(
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.stockSearch, isDense: true),
          ),
        ),
        TextButton(
          onPressed: () => setState(() => _ticked.addAll([for (final p in shown) p.item.id])),
          child: Text(l.fromStockAll),
        ),
        TextButton(
          onPressed: () => setState(() => _ticked.removeAll([for (final p in shown) p.item.id])),
          child: Text(l.fromStockNone),
        ),
      ]),
    ]);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640, maxHeight: 860),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s3, AbySpace.s2, AbySpace.s2),
          child: Row(children: [
            Expanded(child: Text(l.fromStockTitle, style: AbyText.heading.copyWith(color: c.ink))),
            IconButton(
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: () => goBack<int>(),
              icon: const Icon(Icons.close),
            ),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: plans == null
              ? const Center(child: CircularProgressIndicator())
              : plans.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AbySpace.s6),
                        child: Text(l.fromStockEmpty, textAlign: TextAlign.center, style: AbyText.body.copyWith(color: c.inkMuted)),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(AbySpace.s4),
                      children: [
                        settings,
                        const Divider(),
                        for (final p in shown) _row(context, c, p),
                      ],
                    ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AbySpace.s3),
          child: Row(children: [
            Expanded(
              child: _error == null
                  ? const SizedBox.shrink()
                  : Text(_error!, style: AbyText.caption.copyWith(color: c.danger)),
            ),
            OutlinedButton(onPressed: () => goBack<int>(), child: Text(l.commonCancel)),
            const SizedBox(width: AbySpace.s2),
            FilledButton(
              onPressed: chosen.isEmpty || _saving ? null : _make,
              child: Text(l.fromStockCreate(chosen.length)),
            ),
          ]),
        ),
      ]),
    );
  }

  /// The row's category, tap to change: its own, or the one for the rest.
  Widget _categoryChip(AbyColors c, StockProductPlan p) {
    final l = context.l10n;
    final own = _rowCategory[p.item.id];
    final name = own == null
        ? (_categoryId == _newCategory
            ? (_categoryName.text.trim().isEmpty ? l.fromStockNewCategory : _categoryName.text.trim())
            : _categories.where((x) => x.id == _categoryId).firstOrNull?.name ?? '?')
        : _categories.where((x) => x.id == own).firstOrNull?.name ?? '?';
    return PopupMenuButton<String>(
      tooltip: l.fromStockCategory,
      onSelected: (v) => setState(() => v.isEmpty ? _rowCategory.remove(p.item.id) : _rowCategory[p.item.id] = v),
      itemBuilder: (_) => [
        for (final cat in _categories) CheckedPopupMenuItem(value: cat.id, checked: own == cat.id, child: Text(cat.name)),
        const PopupMenuDivider(),
        CheckedPopupMenuItem(value: '', checked: own == null, child: Text(l.fromStockDefaultCategory)),
      ],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.folder_outlined, size: 14, color: own == null ? c.inkMuted : c.blue),
          const SizedBox(width: AbySpace.s1),
          Flexible(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: AbyText.caption.copyWith(color: own == null ? c.inkMuted : c.blue, fontWeight: FontWeight.w600),
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 18, color: own == null ? c.inkMuted : c.blue),
        ]),
      ),
    );
  }

  Widget _row(BuildContext context, AbyColors c, StockProductPlan p) {
    final l = context.l10n;
    final price = _priceOf(p);
    final ticked = _ticked.contains(p.item.id);
    final typed = _typed.containsKey(p.item.id);
    final muted = AbyText.caption.copyWith(color: c.inkMuted);
    final cost = p.per.isEmpty ? formatMoney(p.cost) : l.fromStockPerUnit(formatMoney(p.cost), p.per);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
      child: Row(children: [
        Checkbox(
          value: ticked,
          onChanged: (v) => setState(() => v == true ? _ticked.add(p.item.id) : _ticked.remove(p.item.id)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.item.name, style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600)),
            _categoryChip(c, p),
            Text(
              [
                if (p.cost > 0) l.fromStockCostLine(cost) else l.fromStockNoCost,
                if (p.alreadySold) l.fromStockAlreadySold,
                if (p.nameTaken) l.fromStockNameTaken,
              ].join('  ·  '),
              style: p.alreadySold || p.nameTaken ? muted.copyWith(color: c.warning) : muted,
            ),
          ]),
        ),
        InkWell(
          onTap: () => _typePrice(p),
          borderRadius: BorderRadius.circular(AbyRadius.sm),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AbySpace.s2, vertical: AbySpace.s1),
            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                if (typed) Icon(Icons.edit, size: 14, color: c.blue),
                if (typed) const SizedBox(width: AbySpace.s1),
                Text(
                  price == null ? '—' : (p.per.isEmpty ? formatMoney(price) : l.fromStockPerUnit(formatMoney(price), p.per)),
                  style: AbyText.price.copyWith(color: ticked ? c.ink : c.inkMuted),
                ),
              ]),
              if (price != null && p.cost > 0)
                Text(
                  l.fromStockProfit(formatMoney(price - p.cost)),
                  style: muted.copyWith(color: price >= p.cost ? c.success : c.danger),
                ),
            ]),
          ),
        ),
      ]),
    );
  }
}
