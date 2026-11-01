import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/discount.dart';
import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/barcode_scanner.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/receipt_actions.dart';
import '../../../ui/section_page.dart';
import '../controllers/today_controller.dart';
import '../../../routes/app_routes.dart';
import '../widgets/cash_dialogs.dart';
import '../widgets/sale_detail.dart';
import '../widgets/sale_row.dart';
import '../widgets/summary_cards.dart';

class TodayView extends GetView<TodayController> {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return SectionPage(
      title: l.navToday,
      actions: [
        OutlinedButton.icon(onPressed: () => _find(context), icon: const Icon(Icons.search), label: Text(l.todayFind)),
        ?cameraScanButton((code) => _found(code)),
        Obx(() {
          // Read here: the menu items are built later, outside this Obx.
          final noShift = controller.shift.value == null;
          return PopupMenuButton<String>(
            tooltip: l.todayCash,
            icon: const Icon(Icons.payments_outlined),
            onSelected: (v) => _cash(context, v),
            itemBuilder: (_) => [
              if (noShift) PopupMenuItem(value: 'open', child: Text(l.dayStart)),
              PopupMenuItem(value: 'x', child: Text(l.xReportTitle)),
              PopupMenuItem(value: 'in', child: Text(l.payInTitle)),
              PopupMenuItem(value: 'out', child: Text(l.payOutTitle)),
              PopupMenuItem(value: 'drop', child: Text(l.safeDropTitle)),
              if (controller.canManageCash) ...[
                PopupMenuItem(value: 'safe', child: Text(l.safeTitle)),
                PopupMenuItem(value: 'momo', child: Text(l.momoTitle)),
              ],
              PopupMenuItem(value: 'noReceipt', child: Text(l.todayRefundNoReceipt)),
            ],
          );
        }),
        FilledButton(onPressed: controller.openCloseDay, child: Text(l.closeDayButton)),
      ],
      child: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = controller.sales.toList();
        final refunds = controller.refunds.toList();
        // Read eagerly (the list builds lazily) so rows rebuild after a close.
        final locked = {for (final s in sales) s.id: controller.isLocked(s)};
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AbySpace.s4),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (controller.shift.value != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AbySpace.s3),
                        child: Text(
                          l.dayStartedLine(
                            controller.shift.value!.openedByName,
                            formatDateTime(controller.shift.value!.openedAt),
                            formatMoney(controller.shift.value!.openingFloat),
                          ),
                          style: AbyText.body.copyWith(color: c.inkMuted),
                        ),
                      ),
                    SummaryCards(summary: controller.summary.value),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s2, AbySpace.s4, AbySpace.s2),
              sliver: SliverToBoxAdapter(
                child: Text(l.todaySales.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
              ),
            ),
            if (sales.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AbySpace.s6),
                  child: Text(l.todayNoSales, style: AbyText.body.copyWith(color: c.inkMuted)),
                ),
              )
            else
              SliverList.separated(
                itemCount: sales.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  final s = sales[i];
                  final actions = SaleActions(
                    onVoid: !s.isVoided && !locked[s.id]! && !s.hasRefunds ? () => _confirmVoid(context, s) : null,
                    onRefund: !s.isVoided && !s.fullyRefunded ? () => controller.openRefund(s.id) : null,
                    onPrint: () => printSaleReceipt(s.id),
                    onSend: s.isVoided ? null : () => sendSaleReceipt(s.id),
                  );
                  return SaleRow(
                    sale: s,
                    locked: locked[s.id]!,
                    onVoid: actions.onVoid,
                    onRefund: actions.onRefund,
                    onPrint: actions.onPrint,
                    onSend: actions.onSend,
                    onOpen: () => showSaleDetail(context, s, actions),
                  );
                },
              ),
            if (refunds.isNotEmpty) ...[
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s6, AbySpace.s4, AbySpace.s2),
                sliver: SliverToBoxAdapter(
                  child: Text(l.todayRefunds.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                ),
              ),
              SliverList.separated(
                itemCount: refunds.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final r = refunds[i];
                  return InfoTile(
                    leading: Icon(Icons.undo, color: c.warning),
                    title:
                        '${r.displayNumber}  ·  ${r.saleNumber == null ? l.todayNoReceipt : formatSaleNumber(r.saleNumber!)}',
                    subtitle: [
                      formatDateTime(r.at),
                      r.staffName,
                      if (r.approverName != null) l.todayApprovedBy(r.approverName!),
                      r.reason,
                      r.methods.join(', '),
                    ].join('  ·  '),
                    value: '−${formatMoney(r.total)}',
                    trailing: IconButton(
                      tooltip: l.refundPrintSlip,
                      onPressed: () => printRefundSlip(r.id),
                      icon: const Icon(Icons.print_outlined),
                    ),
                  );
                },
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: AbySpace.s8)),
          ],
        );
      }),
    );
  }

  Future<void> _cash(BuildContext context, String action) async {
    String? message;
    switch (action) {
      case 'open':
        if (await startDay()) await controller.reloadShift();
      case 'x':
        await showXReport(await controller.xReport());
      case 'in' || 'out':
        final payIn = action == 'in';
        final move = await showPayInOut(
          payIn: payIn,
          reasons: payIn ? controller.payInReasons.toList() : controller.payOutReasons.toList(),
          expenseCategories: controller.expenseCategories.toList(),
        );
        if (move != null) {
          message = await controller.payInOrOut(
            payIn: payIn,
            amount: move.amount,
            reason: move.reason,
            note: move.note,
            photo: move.photo,
            expenseCategoryId: move.expenseCategoryId,
          );
        }
      case 'drop':
        final l = context.l10n;
        final text = await textInputDialog(
          title: l.safeDropTitle,
          label: l.checkoutAmount,
          helper: l.safeDropHelp,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
        );
        final amount = text == null ? null : parseMoney(text);
        if (amount != null && amount > 0) message = await controller.safeDrop(amount);
      case 'safe':
        await Get.toNamed<void>(Routes.safe);
      case 'momo':
        await Get.toNamed<void>(Routes.momo);
      case 'noReceipt':
        await controller.openRefund(null);
    }
    if (message != null) showMessage(message);
  }

  Future<void> _find(BuildContext context) async {
    final l = context.l10n;
    final text = await textInputDialog(
      title: l.todayFind,
      label: l.todayFindLabel,
      helper: l.todayFindHelp,
      keyboardType: TextInputType.number,
      confirmLabel: l.todayFindButton,
    );
    if (text == null || text.trim().isEmpty) return;
    await _found(text);
  }

  /// A typed number or a scanned receipt QR code.
  Future<void> _found(String text) async {
    final id = await controller.findSale(text);
    if (id == null) {
      showMessage(appL10n().todayFindNone(text.trim()));
      return;
    }
    await controller.openRefund(id);
  }

  Future<void> _confirmVoid(BuildContext context, Sale sale) async {
    final reason = await Get.dialog<String>(_VoidDialog(sale: sale, reasons: controller.voidReasons.toList()));
    if (reason == null) return;
    final message = await controller.voidSale(sale, reason: reason);
    if (message != null) showMessage(message);
  }
}

/// "Void #00012?" with the reason picked from the shop's list.
class _VoidDialog extends StatefulWidget {
  const _VoidDialog({required this.sale, required this.reasons});

  final Sale sale;
  final List<Reason> reasons;

  @override
  State<_VoidDialog> createState() => _VoidDialogState();
}

class _VoidDialogState extends State<_VoidDialog> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return AlertDialog(
      title: Text(l.voidConfirmTitle(widget.sale.displayNumber)),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.voidConfirmBody(formatMoney(widget.sale.total))),
            const SizedBox(height: AbySpace.s4),
            Text(l.voidWhy.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            const SizedBox(height: AbySpace.s2),
            Wrap(
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              children: [
                for (final r in widget.reasons)
                  OptionChip(label: r.name, selected: _reason == r.name, onTap: () => setState(() => _reason = r.name)),
              ],
            ),
          ],
        ),
      ),
      actions: [
        DialogButtons(children: [
              OutlinedButton(onPressed: () => goBack<String>(), child: Text(l.voidKeep)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger),
            onPressed: _reason == null ? null : () => goBack(result: _reason),
            child: Text(l.voidConfirm),
          ),
        ]),
      ],
    );
  }
}
