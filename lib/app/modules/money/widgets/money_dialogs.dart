import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/enums.dart';
import '../../../models/expense.dart';
import '../../../models/purchasing.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/photo_picker.dart';
import '../controllers/money_controller.dart';

String moneySourceLabel(AppLocalizations l, MoneySource s) => switch (s) {
      MoneySource.drawer => l.sourceDrawer,
      MoneySource.momo => l.sourceMomo,
      MoneySource.bank => l.sourceBank,
      MoneySource.ownerPocket => l.sourceOwner,
    };

/// A new expense: amount, category, where the money came from, the day,
/// the supplier, a note and a receipt photo.
Future<void> showExpenseDialog(MoneyController ctl) => Get.dialog<void>(_ExpenseDialog(ctl: ctl));

class _ExpenseDialog extends StatefulWidget {
  const _ExpenseDialog({required this.ctl});

  final MoneyController ctl;

  @override
  State<_ExpenseDialog> createState() => _ExpenseDialogState();
}

class _ExpenseDialogState extends State<_ExpenseDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String? _category;
  MoneySource _source = MoneySource.drawer;
  DateTime _day = DateTime.now();
  String? _supplier;
  Uint8List? _photo;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = context.l10n;
    final amount = parseMoney(_amount.text);
    if (amount == null || amount <= 0) return setState(() => _error = l.customerAmountInvalid);
    if (_category == null) return setState(() => _error = l.expensePickCategory);
    final error = await widget.ctl.addExpense(
      ExpenseDraft(day: _day, amount: amount, categoryId: _category!, paidFrom: _source, supplierId: _supplier, note: _note.text),
      photo: _photo,
    );
    if (error == null) {
      goBack<void>();
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.expenseNew),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: l.checkoutAmount, prefixText: 'GH₵ '),
            ),
            const SizedBox(height: AbySpace.s3),
            Text(l.expenseCategory.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final cat in widget.ctl.categories)
                OptionChip(label: cat.name, selected: _category == cat.id, onTap: () => setState(() => _category = cat.id)),
            ]),
            const SizedBox(height: AbySpace.s3),
            Text(l.expensePaidFrom.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s2),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final s in MoneySource.values)
                OptionChip(label: moneySourceLabel(l, s), selected: _source == s, onTap: () => setState(() => _source = s)),
            ]),
            if (_source == MoneySource.drawer)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s1),
                child: Text(l.expenseDrawerHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
              ),
            const SizedBox(height: AbySpace.s3),
            Row(children: [
              Expanded(
                child: InputDecorator(decoration: InputDecoration(labelText: l.expenseDay), child: Text(formatDate(_day))),
              ),
              TextButton(
                onPressed: () async {
                  final d = await showDatePicker(context: context, initialDate: _day, firstDate: DateTime(2020), lastDate: DateTime.now());
                  if (d != null) setState(() => _day = d);
                },
                child: Text(l.commonEdit),
              ),
            ]),
            if (widget.ctl.suppliers.isNotEmpty) ...[
              const SizedBox(height: AbySpace.s3),
              DropdownButtonFormField<String?>(
                initialValue: _supplier,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.expenseSupplier),
                items: [
                  DropdownMenuItem<String?>(value: null, child: Text(l.expenseNoSupplier)),
                  for (final Supplier s in widget.ctl.suppliers)
                    DropdownMenuItem<String?>(value: s.id, child: Text(s.name, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _supplier = v),
              ),
            ],
            const SizedBox(height: AbySpace.s3),
            TextField(controller: _note, decoration: InputDecoration(labelText: l.stockNoteOptional)),
            const SizedBox(height: AbySpace.s3),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final bytes = await pickPhotoBytes(ImageSource.gallery);
                  if (bytes != null) setState(() => _photo = bytes);
                },
                icon: Icon(_photo == null ? Icons.receipt_long_outlined : Icons.check_circle, color: _photo == null ? null : c.success),
                label: Text(_photo == null ? l.cashAddReceipt : l.cashReceiptAdded),
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
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(onPressed: _save, child: Text(l.commonSave)),
        ]),
      ],
    );
  }
}

/// Reminders like "Rent GH₵ 800 on the 1st": add, change, switch off.
Future<void> showRecurringDialog(MoneyController ctl) => Get.dialog<void>(_RecurringList(ctl: ctl));

class _RecurringList extends StatefulWidget {
  const _RecurringList({required this.ctl});

  final MoneyController ctl;

  @override
  State<_RecurringList> createState() => _RecurringListState();
}

class _RecurringListState extends State<_RecurringList> {
  List<RecurringExpense> _list = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.ctl.allRecurring();
    if (mounted) setState(() => _list = list);
  }

  Future<void> _edit([RecurringExpense? r]) async {
    if (await Get.dialog<bool>(_RecurringEditor(ctl: widget.ctl, recurring: r)) ?? false) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    String category(String id) => widget.ctl.categories.firstWhereOrNull((x) => x.id == id)?.name ?? '';
    return AlertDialog(
      title: Text(l.recurringTitle),
      content: SizedBox(
        width: 460,
        child: _list.isEmpty
            ? Text(l.recurringNone, style: AbyText.body.copyWith(color: c.inkMuted))
            : ListView(shrinkWrap: true, children: [
                for (final r in _list)
                  SwitchListTile(
                    value: r.active,
                    onChanged: (v) async {
                      await widget.ctl.setRecurringActive(r, v);
                      await _load();
                    },
                    title: Text(r.name),
                    subtitle: Text(l.recurringLine(formatMoney(r.amount), r.dayOfMonth, category(r.categoryId))),
                    secondary: IconButton(tooltip: l.commonEdit, icon: const Icon(Icons.edit_outlined), onPressed: () => _edit(r)),
                  ),
              ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text(l.recurringNew)),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}

class _RecurringEditor extends StatefulWidget {
  const _RecurringEditor({required this.ctl, this.recurring});

  final MoneyController ctl;
  final RecurringExpense? recurring;

  @override
  State<_RecurringEditor> createState() => _RecurringEditorState();
}

class _RecurringEditorState extends State<_RecurringEditor> {
  RecurringExpense? get r => widget.recurring;
  late final _name = TextEditingController(text: r?.name ?? '');
  late final _amount = TextEditingController(text: r == null ? '' : (r!.amount / 100).toStringAsFixed(2));
  late final _day = TextEditingController(text: '${r?.dayOfMonth ?? 1}');
  late String? _category = r?.categoryId;
  late MoneySource _source = r?.paidFrom ?? MoneySource.momo;
  String? _error;

  @override
  void dispose() {
    for (final f in [_name, _amount, _day]) {
      f.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(r == null ? l.recurringNew : l.recurringEdit),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextField(controller: _name, decoration: InputDecoration(labelText: l.recurringName, helperText: l.recurringNameHelp)),
            const SizedBox(height: AbySpace.s3),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: l.checkoutAmount, prefixText: 'GH₵ '),
                ),
              ),
              const SizedBox(width: AbySpace.s3),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: _day,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(labelText: l.recurringDay, helperText: '1–28'),
                ),
              ),
            ]),
            const SizedBox(height: AbySpace.s3),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final cat in widget.ctl.categories)
                OptionChip(label: cat.name, selected: _category == cat.id, onTap: () => setState(() => _category = cat.id)),
            ]),
            const SizedBox(height: AbySpace.s3),
            Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
              for (final s in MoneySource.values)
                OptionChip(label: moneySourceLabel(l, s), selected: _source == s, onTap: () => setState(() => _source = s)),
            ]),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: AbySpace.s3),
                child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
              ),
          ]),
        ),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<bool>(), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () async {
              final amount = parseMoney(_amount.text);
              if (amount == null) return setState(() => _error = l.customerAmountInvalid);
              if (_category == null) return setState(() => _error = l.expensePickCategory);
              final error = await widget.ctl.saveRecurring(
                id: r?.id,
                name: _name.text,
                categoryId: _category!,
                amount: amount,
                dayOfMonth: int.tryParse(_day.text) ?? 0,
                paidFrom: _source,
              );
              if (error == null) {
                goBack(result: true);
              } else {
                setState(() => _error = error);
              }
            },
            child: Text(l.commonSave),
              ),
        ]),
      ],
    );
  }
}

/// The expense categories: add, rename, retire.
Future<void> showExpenseCategories(MoneyController ctl) => Get.dialog<void>(_Categories(ctl: ctl));

class _Categories extends StatefulWidget {
  const _Categories({required this.ctl});

  final MoneyController ctl;

  @override
  State<_Categories> createState() => _CategoriesState();
}

class _CategoriesState extends State<_Categories> {
  List<ExpenseCategory> _list = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final list = await widget.ctl.allCategories();
    if (mounted) setState(() => _list = list);
  }

  Future<void> _edit([ExpenseCategory? cat]) async {
    final l = context.l10n;
    final name = await textInputDialog(title: cat == null ? l.expenseCategoryNew : l.commonEdit, label: l.expenseCategory, initial: cat?.name ?? '');
    if (name == null) return;
    final error = await widget.ctl.saveCategory(id: cat?.id, name: name);
    if (error != null) showMessage(error);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.expenseCategories),
      content: SizedBox(
        width: 420,
        child: ListView(shrinkWrap: true, children: [
          for (final cat in _list)
            ListTile(
              title: Text(cat.name, style: TextStyle(color: cat.active ? c.ink : c.inkMuted)),
              onTap: () => _edit(cat),
              trailing: TextButton(
                onPressed: () async {
                  await widget.ctl.setCategoryActive(cat, !cat.active);
                  await _load();
                },
                child: Text(cat.active ? l.stockRetire : l.stockRestore),
              ),
            ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton.icon(onPressed: () => _edit(), icon: const Icon(Icons.add), label: Text(l.expenseCategoryNew)),
          FilledButton(onPressed: () => goBack<void>(), child: Text(l.commonDone)),
        ]),
      ],
    );
  }
}

/// The owner taking money home ([kind] drawing) or putting their own in.
Future<void> showOwnerMoneyDialog(MoneyController ctl, OwnerMoneyKind kind) =>
    Get.dialog<void>(_OwnerMoney(ctl: ctl, kind: kind));

class _OwnerMoney extends StatefulWidget {
  const _OwnerMoney({required this.ctl, required this.kind});

  final MoneyController ctl;
  final OwnerMoneyKind kind;

  @override
  State<_OwnerMoney> createState() => _OwnerMoneyState();
}

class _OwnerMoneyState extends State<_OwnerMoney> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  MoneySource _source = MoneySource.drawer;
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final drawing = widget.kind == OwnerMoneyKind.drawing;
    return AlertDialog(
      title: Text(drawing ? l.ownerTook : l.ownerPut),
      content: SizedBox(
        width: 400,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(drawing ? l.ownerTookHelp : l.ownerPutHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s3),
          TextField(
            controller: _amount,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l.checkoutAmount, prefixText: 'GH₵ '),
          ),
          const SizedBox(height: AbySpace.s3),
          Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
            for (final s in MoneySource.values.where((s) => s != MoneySource.ownerPocket))
              OptionChip(label: moneySourceLabel(l, s), selected: _source == s, onTap: () => setState(() => _source = s)),
          ]),
          const SizedBox(height: AbySpace.s3),
          TextField(controller: _note, decoration: InputDecoration(labelText: l.stockNoteOptional)),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: AbySpace.s3),
              child: Text(_error!, style: AbyText.body.copyWith(color: c.danger)),
            ),
        ]),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () async {
              final amount = parseMoney(_amount.text);
              if (amount == null || amount <= 0) return setState(() => _error = l.customerAmountInvalid);
              final error = await widget.ctl.ownerMoney(widget.kind, amount, _source, note: _note.text);
              if (error == null) {
                goBack<void>();
              } else {
                setState(() => _error = error);
              }
            },
            child: Text(l.commonSave),
          ),
        ]),
      ],
    );
  }
}
