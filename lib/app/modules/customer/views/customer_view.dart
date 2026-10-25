import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/validators.dart';
import '../../../domain/customer_documents.dart';
import '../../../models/customer.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/section_page.dart';
import '../../customers/widgets/customer_form.dart';
import '../controllers/customer_controller.dart';
import '../widgets/money_dialog.dart';

class CustomerView extends GetView<CustomerController> {
  const CustomerView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(controller.customer.value?.name ?? '')),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
      ),
      body: Obx(() {
        final x = controller.customer.value;
        if (x == null) return const Center(child: CircularProgressIndicator());
        final summary = _Summary(customer: x, view: this);
        final history = _History(view: this);
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: context.isWide
                ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 380, child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: summary)),
                    Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: history)),
                  ])
                : ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [summary, const SizedBox(height: AbySpace.s4), history]),
          ),
        );
      }),
    );
  }

  void flush() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    showMessage(text);
  }
}

class _Summary extends GetView<CustomerController> {
  const _Summary({required this.customer, required this.view});

  final Customer customer;
  final CustomerView view;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final aging = controller.aging.value;
    final stats = controller.stats.value;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(AbySpace.s4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.customerOwesLabel.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            Text(formatMoney(customer.owed), style: AbyText.title.copyWith(color: customer.owed > 0 ? c.warning : c.ink)),
            if (customer.creditLimit != null)
              Text(l.customerLimitLine(formatMoney(customer.creditLimit!), formatMoney(customer.creditLeft!)),
                  style: AbyText.caption.copyWith(color: c.inkMuted)),
            if (aging.overdue > 0)
              Text(
                l.customerOverdueLine(formatMoney(aging.days1to30), formatMoney(aging.days31to60), formatMoney(aging.over60)),
                style: AbyText.caption.copyWith(color: c.danger, fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: AbySpace.s3),
            Text(l.customerWalletLabel.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            Text(formatMoney(customer.wallet), style: AbyText.heading.copyWith(color: c.ink)),
          ]),
        ),
      ),
      const SizedBox(height: AbySpace.s3),
      if (controller.canManage) ...[
        FilledButton.icon(
          onPressed: customer.owed <= 0
              ? null
              : () => showMoneyDialog(
                    title: l.customerRecordPayment,
                    methods: controller.methods,
                    debts: controller.debts,
                    initialAmount: (customer.owed / 100).toStringAsFixed(2),
                    onSave: (a, m, r, s) => controller.repay(a, m, reference: r, forSaleId: s),
                  ).then((_) => view.flush()),
          icon: const Icon(Icons.payments_outlined),
          label: Text(l.customerRecordPayment),
        ),
        const SizedBox(height: AbySpace.s2),
        OutlinedButton.icon(
          onPressed: () => showMoneyDialog(
            title: l.customerAddToWallet,
            methods: controller.methods,
            onSave: (a, m, r, _) => controller.topUp(a, m, reference: r),
          ).then((_) => view.flush()),
          icon: const Icon(Icons.account_balance_wallet_outlined),
          label: Text(l.customerAddToWallet),
        ),
        const SizedBox(height: AbySpace.s2),
        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _statement(context),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: Text(l.customerStatement),
            ),
          ),
          const SizedBox(width: AbySpace.s2),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: customer.owed <= 0 ? null : () => _remind(context),
              icon: const Icon(Icons.chat_outlined),
              label: Text(l.customerRemind),
            ),
          ),
        ]),
        Wrap(children: [
          TextButton(
            onPressed: () => showCustomerForm(customer: customer, onSave: controller.save).then((_) => view.flush()),
            child: Text(l.customerEdit),
          ),
          if (controller.canWriteOff && customer.owed > 0)
            TextButton(onPressed: () => _writeOff(context), child: Text(l.customerWriteOff)),
          TextButton(
            onPressed: () => controller.setActive(!customer.active),
            child: Text(customer.active ? l.stockRetire : l.stockRestore),
          ),
        ]),
      ],
      const SizedBox(height: AbySpace.s3),
      GroupCard(title: l.profileContact, children: [
        InfoTile(title: l.profilePhone, value: customer.phone == null ? l.settingsNotSet : Validators.formatPhone(customer.phone!)),
        if (customer.phone2 != null) InfoTile(title: l.customerPhone2, value: Validators.formatPhone(customer.phone2!)),
        if (customer.location != null) InfoTile(title: l.customerLocation, value: customer.location),
        if (customer.birthday != null) InfoTile(title: l.customerBirthday, value: formatDate(customer.birthday!)),
        if (customer.tags.isNotEmpty) InfoTile(title: l.customerTags, value: customer.tags.join(', ')),
        if (customer.notes != null) InfoTile(title: l.profileNotes, value: customer.notes),
      ]),
      GroupCard(title: l.customerHabits, children: [
        InfoTile(title: l.customerSpend, value: formatMoney(stats.spend)),
        InfoTile(title: l.customerVisits, value: '${stats.visits}'),
        InfoTile(title: l.customerLastVisit, value: stats.lastVisit == null ? l.statusNever : formatDateTime(stats.lastVisit!)),
        if (stats.favourites.isNotEmpty) InfoTile(title: l.customerFavourites, value: stats.favourites.join(', ')),
      ]),
    ]);
  }

  Future<void> _statement(BuildContext context) async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: DateTime(now.year, now.month - 2, 1), end: now),
    );
    if (range == null) return;
    await controller.statement(range.start, range.end);
  }

  Future<void> _remind(BuildContext context) async {
    final l = context.l10n;
    final text = await textInputDialog(
      title: l.customerRemind,
      label: l.customerRemindMessage,
      initial: controller.reminderText,
      confirmLabel: l.customerRemindWhatsApp,
    );
    if (text == null) return;
    await controller.remind(text);
    view.flush();
  }

  Future<void> _writeOff(BuildContext context) async {
    final l = context.l10n;
    final amount = await textInputDialog(
      title: l.customerWriteOff,
      label: l.supplierAmount,
      initial: (customer.owed / 100).toStringAsFixed(2),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
    if (amount == null) return;
    final reason = await textInputDialog(title: l.customerWriteOff, label: l.customerWriteOffWhy);
    if (reason == null) return;
    final error = await controller.writeOff(amount, reason);
    if (error != null) showMessage(error);
    view.flush();
  }
}

class _History extends GetView<CustomerController> {
  const _History({required this.view});

  final CustomerView view;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final debts = controller.debts.toList();
    final entries = controller.entries.toList();
    final sales = controller.sales.toList();
    final now = DateTime.now();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (debts.isNotEmpty)
        GroupCard(title: l.customerUnpaid, children: [
          for (final d in debts)
            InfoTile(
              title: d.saleNumber == null ? formatDate(d.at) : '${formatSaleNumber(d.saleNumber!)}  ·  ${formatDate(d.at)}',
              subtitle: d.dueOn == null
                  ? null
                  : d.daysOverdue(now) > 0
                      ? l.customerDaysLate(d.daysOverdue(now))
                      : l.customerDue(formatDate(d.dueOn!)),
              value: formatMoney(d.outstanding),
            ),
        ]),
      GroupCard(
        title: l.customerAccount,
        children: entries.isEmpty
            ? [InfoTile(title: l.customerNoEntries)]
            : [
                for (final e in entries)
                  InfoTile(
                    leading: Icon(
                      e.account == CustomerAccount.credit ? Icons.menu_book_outlined : Icons.account_balance_wallet_outlined,
                      color: c.inkMuted,
                    ),
                    title: CustomerDocuments.entryLabel(e),
                    subtitle: [formatDateTime(e.at), e.byName, ?e.reference, ?e.note, if (e.approverName != null) l.todayApprovedBy(e.approverName!)]
                        .join('  ·  '),
                    value: '${e.amount > 0 ? '+' : '−'}${formatMoney(e.amount.abs())}',
                  ),
              ],
      ),
      GroupCard(
        title: l.customerSales,
        children: sales.isEmpty
            ? [InfoTile(title: l.todayNoSales)]
            : [
                for (final (_, number, at, total, status) in sales)
                  InfoTile(
                    title: '${formatSaleNumber(number)}  ·  ${formatDateTime(at)}',
                    subtitle: status == SaleStatus.voided ? l.todayVoided : null,
                    value: formatMoney(total),
                  ),
              ],
      ),
    ]);
  }
}
