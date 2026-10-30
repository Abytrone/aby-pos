import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/tax.dart';
import '../../../domain/pricing.dart';
import '../../../data/repositories/parked_order_repository.dart';
import '../../../models/cart_line.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../ui/customer_picker.dart';
import '../../../ui/loyalty_text.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../controllers/cart_controller.dart';
import '../controllers/till_controller.dart';
import '../views/till_view.dart' show flushTillMessage;
import 'discount_dialog.dart';
import 'line_editor.dart';

String orderTypeLabel(AppLocalizations l, OrderType t) => switch (t) {
      OrderType.takeaway => l.orderTakeaway,
      OrderType.eatIn => l.orderEatIn,
      OrderType.delivery => l.orderDelivery,
    };

/// The current sale: parked orders, lines (tap one to change it), totals
/// and the Pay button.
class CartPanel extends StatelessWidget {
  const CartPanel({super.key, required this.onPay});

  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final till = Get.find<TillController>();
    final cart = Get.find<CartController>();
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final lines = cart.lines.toList();
      final pricing = cart.pricing;
      final priced = pricing.lines;
      final parked = till.parkedOrders.toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (parked.isNotEmpty)
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(AbySpace.s3, AbySpace.s2, AbySpace.s3, 0),
                children: [for (final o in parked) _ParkedChip(order: o, till: till)],
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s2, AbySpace.s1, AbySpace.s1),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    cart.parkedName.value ?? l.cartTitle,
                    style: AbyText.heading.copyWith(color: c.ink),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (lines.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _park(till),
                    icon: const Icon(Icons.pause_circle_outline),
                    label: Text(l.parkButton),
                  ),
                PopupMenuButton<String>(
                  tooltip: l.commonMore,
                  onSelected: (v) => switch (v) {
                    'discount' => _orderDiscount(till, cart),
                    'note' => _orderNote(cart),
                    'nosale' => _noSale(till),
                    _ => _clear(cart),
                  },
                  itemBuilder: (_) => [
                    if (lines.isNotEmpty) ...[
                      PopupMenuItem(value: 'discount', child: Text(l.cartOrderDiscount)),
                      PopupMenuItem(value: 'note', child: Text(cart.note.value == null ? l.cartAddNote : l.cartEditNote)),
                      PopupMenuItem(value: 'clear', child: Text(l.cartClear)),
                    ],
                    PopupMenuItem(value: 'nosale', child: Text(l.noSaleButton)),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(AbySpace.s2, 0, AbySpace.s4, AbySpace.s1),
            child: Row(children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AbyRadius.sm),
                  onTap: () async {
                    final picked = await pickCustomer();
                    if (picked != null) cart.customer.value = picked;
                  },
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: AbySize.tapMin),
                    child: Row(children: [
                      const SizedBox(width: AbySpace.s2),
                      Icon(cart.customer.value == null ? Icons.person_add_alt : Icons.person, size: 20, color: c.blue),
                      const SizedBox(width: AbySpace.s2),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(
                            cart.customer.value == null
                                ? l.cartAddCustomer
                                : [
                                    cart.customer.value!.name,
                                    if (cart.customer.value!.owed > 0) l.customerOwes(formatMoney(cart.customer.value!.owed)),
                                  ].join('  ·  '),
                            overflow: TextOverflow.ellipsis,
                            style: AbyText.body.copyWith(color: c.blue, fontWeight: FontWeight.w700),
                          ),
                          if (cart.customer.value != null)
                            if (loyaltyText(l, cart.loyalty, cart.loyaltyStatus.value, cart.customer.value!.name) case final line?)
                              Text(
                                line,
                                overflow: TextOverflow.ellipsis,
                                style: AbyText.caption.copyWith(color: c.success, fontWeight: FontWeight.w700),
                              ),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
              if (cart.customer.value != null)
                IconButton(
                  tooltip: l.cartRemoveCustomer,
                  onPressed: () => cart.customer.value = null,
                  icon: Icon(Icons.close, size: 18, color: c.inkMuted),
                ),
            ]),
          ),
          if (cart.exchange.value != null)
            Container(
              margin: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
              padding: const EdgeInsets.fromLTRB(AbySpace.s3, AbySpace.s2, AbySpace.s1, AbySpace.s2),
              decoration: BoxDecoration(color: c.successSoft, borderRadius: BorderRadius.circular(AbyRadius.sm)),
              child: Row(children: [
                Icon(Icons.swap_horiz, color: c.success),
                const SizedBox(width: AbySpace.s2),
                Expanded(
                  child: Text(
                    l.cartExchange(formatMoney(cart.exchange.value!.credit)),
                    style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: l.cartExchangeCancel,
                  onPressed: () => cart.exchange.value = null,
                  icon: Icon(Icons.close, size: 18, color: c.inkMuted),
                ),
              ]),
            ),
          if (till.orderTypesOn && lines.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
              child: Wrap(spacing: AbySpace.s2, children: [
                for (final t in OrderType.values)
                  OptionChip(
                    label: orderTypeLabel(l, t),
                    selected: cart.orderType.value == t,
                    onTap: () => cart.orderType.value = cart.orderType.value == t ? null : t,
                  ),
              ]),
            ),
          if (cart.note.value != null)
            InkWell(
              onTap: () => _orderNote(cart),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
                child: Row(children: [
                  Icon(Icons.sticky_note_2_outlined, size: 18, color: c.inkMuted),
                  const SizedBox(width: AbySpace.s2),
                  Expanded(child: Text(cart.note.value!, style: AbyText.caption.copyWith(color: c.inkMuted))),
                ]),
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: lines.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AbySpace.s6),
                      child: Text(
                        l.cartEmpty,
                        style: AbyText.body.copyWith(color: c.inkMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const Divider(height: 1, indent: AbySpace.s4),
                    itemBuilder: (_, i) => _CartLineRow(
                      line: lines[i],
                      priced: priced.length == lines.length ? priced[i] : null,
                      onTap: () => showLineEditor(till, lines[i]),
                      onAdd: () => cart.increment(lines[i].key),
                      onSubtract: () => cart.decrement(lines[i].key),
                    ),
                  ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AbySpace.s4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (pricing.discountTotal > 0) ...[
                  _TotalRow(label: l.cartSubtotal, value: formatMoney(pricing.subtotal)),
                  _TotalRow(
                    label: pricing.orderDiscountAmount > 0 && cart.orderDiscount.value != null
                        ? l.cartDiscountWith(cart.orderDiscount.value!.name ?? cart.orderDiscount.value!.label)
                        : l.cartDiscount,
                    value: '−${formatMoney(pricing.discountTotal)}',
                    onTap: () => _orderDiscount(till, cart),
                  ),
                ],
                if (pricing.taxTotal > 0)
                  _TotalRow(
                    label: cart.taxMode == TaxMode.inclusive ? l.cartTaxIncluded : l.cartTax,
                    value: formatMoney(pricing.taxTotal),
                  ),
                Row(
                  children: [
                    Text(l.cartTotal, style: AbyText.body.copyWith(color: c.inkMuted)),
                    const Spacer(),
                    Text(
                      formatMoney(pricing.total),
                      style: AbyText.heading.copyWith(
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AbySpace.s3),
                AbyPayButton(
                  amount: toCedisForDisplay(pricing.total),
                  onPressed: lines.isEmpty ? null : onPay,
                ),
              ],
            ),
          ),
        ],
      );
    });
  }

  Future<void> _park(TillController till) async {
    final l = appL10n();
    final name = await textInputDialog(
      title: l.parkTitle,
      label: l.parkName,
      helper: l.parkNameHelp,
      initial: till.suggestedParkName,
      confirmLabel: l.parkButton,
    );
    if (name == null) return;
    await till.park(name);
    showMessage(l.parkDone(name.trim().isEmpty ? till.suggestedParkName : name.trim()), tone: MessageTone.success);
  }

  Future<void> _orderDiscount(TillController till, CartController cart) async {
    final base = cart.pricing.lines.fold(0, (s, l) => s + l.lineNet);
    final choice = await showDiscountDialog(
      title: appL10n().cartOrderDiscount,
      base: base,
      saved: till.savedDiscounts.where((d) => d.forOrders).toList(),
      reasons: till.discountReasons.toList(),
      current: cart.orderDiscount.value,
    );
    if (choice == null) return;
    await till.setOrderDiscount(choice.discount);
  }

  Future<void> _orderNote(CartController cart) async {
    final l = appL10n();
    final text = await textInputDialog(
      title: l.cartNoteTitle,
      label: l.cartNote,
      helper: l.cartNoteHelp,
      initial: cart.note.value ?? '',
    );
    if (text != null) cart.setOrderNote(text);
  }

  Future<void> _noSale(TillController till) async {
    final l = appL10n();
    final reason = await choiceDialog<String>(
      title: l.noSaleTitle,
      options: [for (final r in till.noSaleReasons) r.name],
      label: (r) => r,
    );
    if (reason == null) return;
    await till.noSale(reason);
    flushTillMessage(till);
  }

  Future<void> _clear(CartController cart) async {
    final l = appL10n();
    if (cart.lines.length > 3 &&
        !await confirmDialog(title: l.cartClearTitle, message: l.cartClearBody(cart.itemCount), confirmLabel: l.cartClear, danger: true)) {
      return;
    }
    cart.clear();
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final row = Padding(
      padding: const EdgeInsets.only(bottom: AbySpace.s1),
      child: Row(children: [
        Expanded(child: Text(label, style: AbyText.caption.copyWith(color: c.inkMuted), overflow: TextOverflow.ellipsis)),
        Text(value, style: AbyText.caption.copyWith(color: c.inkMuted, fontFeatures: const [FontFeature.tabularFigures()])),
      ]),
    );
    return onTap == null ? row : InkWell(onTap: onTap, child: row);
  }
}

class _ParkedChip extends StatelessWidget {
  const _ParkedChip({required this.order, required this.till});

  final ParkedOrder order;
  final TillController till;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(right: AbySpace.s2),
      child: Material(
        color: c.surfaceSunken,
        shape: StadiumBorder(side: BorderSide(color: c.lineStrong, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: () async {
            await till.resume(order);
            flushTillMessage(till);
          },
          child: Padding(
            padding: const EdgeInsets.only(left: AbySpace.s3),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.pause_circle_outline, size: 18, color: c.inkMuted),
              const SizedBox(width: AbySpace.s1),
              Text('${order.name}  ·  ${formatMoney(order.total)}',
                  style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
              PopupMenuButton<String>(
                tooltip: l.commonMore,
                icon: Icon(Icons.more_vert, size: 18, color: c.inkMuted),
                onSelected: (v) async {
                  switch (v) {
                    case 'rename':
                      final name = await textInputDialog(title: l.parkRename, label: l.parkName, initial: order.name);
                      if (name != null) await till.renameParked(order, name);
                    case 'merge':
                      await till.mergeIntoCart(order);
                    case 'discard':
                      final ok = await confirmDialog(
                        title: l.parkDiscardTitle(order.name),
                        message: l.parkDiscardBody,
                        confirmLabel: l.parkDiscard,
                        danger: true,
                      );
                      if (ok) await till.discardParked(order);
                  }
                  flushTillMessage(till);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'rename', child: Text(l.parkRename)),
                  PopupMenuItem(value: 'merge', child: Text(l.parkMerge)),
                  PopupMenuItem(value: 'discard', child: Text(l.parkDiscard)),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _CartLineRow extends StatelessWidget {
  const _CartLineRow({
    required this.line,
    required this.onTap,
    required this.onAdd,
    required this.onSubtract,
    this.priced,
  });

  final CartLine line;

  /// With promotions applied.
  final PricedLine? priced;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onSubtract;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final per = line.product.perUnit;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s2, AbySpace.s3, AbySpace.s2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(line.title, style: AbyText.tile.copyWith(color: c.ink)),
            if (line.options.isNotEmpty)
              Text('+ ${line.optionsLine}', style: AbyText.caption.copyWith(color: c.inkMuted)),
            Text(
              [
                per == null ? l.cartEach(formatMoney(line.unitPrice)) : l.cartPer(formatMoney(line.unitPrice), per),
                if (line.priceOverridden) l.cartWas(formatMoney(line.listPrice)),
              ].join('  ·  '),
              style: AbyText.caption.copyWith(color: line.priceOverridden ? c.warning : c.inkMuted),
            ),
            if (line.note != null)
              Text('“${line.note}”', style: AbyText.caption.copyWith(color: c.inkMuted, fontStyle: FontStyle.italic)),
            if (line.discount != null)
              Text(
                l.cartLineDiscount(line.discount!.name ?? line.discount!.label, formatMoney(line.discountAmount)),
                style: AbyText.caption.copyWith(color: c.success, fontWeight: FontWeight.w700),
              ),
            if ((priced?.promotion ?? 0) > 0)
              Text(
                l.cartLineDiscount(priced!.promotionNames.join(', '), formatMoney(priced!.promotion)),
                style: AbyText.caption.copyWith(color: c.success, fontWeight: FontWeight.w700),
              ),
            const SizedBox(height: AbySpace.s1),
            Row(
              children: [
                if (line.weighed)
                  Text(line.quantityText, style: AbyText.price.copyWith(color: c.ink))
                else ...[
                  _StepButton(icon: Icons.remove, tooltip: l.cartOneLess, onPressed: onSubtract),
                  SizedBox(
                    width: 44,
                    child: Text('${line.quantity}', textAlign: TextAlign.center, style: AbyText.price.copyWith(color: c.ink)),
                  ),
                  _StepButton(icon: Icons.add, tooltip: l.cartOneMore, onPressed: onAdd),
                ],
                const Spacer(),
                Text(formatMoney(priced?.lineNet ?? line.netTotal), style: AbyText.price.copyWith(color: c.ink)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return IconButton.outlined(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, color: c.ink),
      style: IconButton.styleFrom(
        minimumSize: const Size(AbySize.tapMin, AbySize.tapMin),
        side: BorderSide(color: c.lineStrong, width: 1.5),
      ),
    );
  }
}
