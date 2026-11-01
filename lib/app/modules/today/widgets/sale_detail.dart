import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/receipt_repository.dart';
import '../../../domain/receipt/receipt_builder.dart';
import '../../../models/audit.dart';
import '../../../models/enums.dart';
import '../../../models/sale.dart';
import '../../../models/sale_detail.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/permission_labels.dart';
import '../../till/widgets/cart_panel.dart' show orderTypeLabel;

/// What can be done with a sale from its page. Null: not possible now.
class SaleActions {
  const SaleActions({this.onRefund, this.onVoid, this.onPrint, this.onSend});

  final VoidCallback? onRefund;
  final VoidCallback? onVoid;
  final VoidCallback? onPrint;
  final VoidCallback? onSend;
}

/// A sale in full: every line with its price changes and discounts (and
/// who allowed them), the totals, payments, refunds, profit for those who
/// may see costs, and its history. Full screen on a phone.
Future<void> showSaleDetail(BuildContext context, Sale sale, SaleActions actions) => Get.dialog<void>(
      context.isNarrow
          ? Dialog.fullscreen(child: _SaleDetail(sale: sale, actions: actions))
          : Dialog(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600, maxHeight: 820),
                child: _SaleDetail(sale: sale, actions: actions),
              ),
            ),
    );

class _SaleDetail extends StatefulWidget {
  const _SaleDetail({required this.sale, required this.actions});

  final Sale sale;
  final SaleActions actions;

  @override
  State<_SaleDetail> createState() => _SaleDetailState();
}

class _SaleDetailState extends State<_SaleDetail> {
  late final Future<(SaleDetail?, List<AuditEntry>)> _load = () async {
    final id = widget.sale.id;
    return (
      await ReceiptRepository(Get.find()).detail(id),
      await Get.find<AuditRepository>().list(entityId: id, limit: 50),
    );
  }();

  bool get _seesCost => Get.find<AuthService>().can(Permission.viewCostAndProfit);

  /// Closes the page, then acts: refund and void open their own screens.
  void Function()? _then(VoidCallback? action) => action == null
      ? null
      : () {
          goBack<void>();
          action();
        };

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final sale = widget.sale;
    final a = widget.actions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s3, AbySpace.s2, AbySpace.s2),
          child: Row(children: [
            Expanded(
              child: Text(l.saleDetailTitle(sale.displayNumber), style: AbyText.heading.copyWith(color: c.ink)),
            ),
            Text(
              formatMoney(sale.total),
              style: AbyText.price.copyWith(
                color: sale.isVoided ? c.inkMuted : c.ink,
                decoration: sale.isVoided ? TextDecoration.lineThrough : null,
              ),
            ),
            IconButton(tooltip: MaterialLocalizations.of(context).closeButtonTooltip, onPressed: () => goBack<void>(), icon: const Icon(Icons.close)),
          ]),
        ),
        const Divider(height: 1),
        Expanded(
          child: FutureBuilder<(SaleDetail?, List<AuditEntry>)>(
            future: _load,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final (detail, history) = snap.data!;
              if (detail == null) {
                return Center(child: Text(l.saleDetailGone, style: AbyText.body.copyWith(color: c.inkMuted)));
              }
              return ListView(
                padding: const EdgeInsets.all(AbySpace.s4),
                children: _body(context, c, detail, history),
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(AbySpace.s3),
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: AbySpace.s2,
            runSpacing: AbySpace.s2,
            children: [
              if (a.onVoid != null)
                TextButton(
                  onPressed: _then(a.onVoid),
                  style: TextButton.styleFrom(foregroundColor: c.danger),
                  child: Text(l.todayVoid),
                ),
              if (a.onSend != null)
                OutlinedButton.icon(onPressed: a.onSend, icon: const Icon(Icons.send_outlined), label: Text(l.receiptSend)),
              if (a.onPrint != null)
                OutlinedButton.icon(onPressed: a.onPrint, icon: const Icon(Icons.print_outlined), label: Text(l.receiptPrint)),
              if (a.onRefund != null) FilledButton(onPressed: _then(a.onRefund), child: Text(l.todayRefund)),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _body(BuildContext context, AbyColors c, SaleDetail d, List<AuditEntry> history) {
    final l = context.l10n;
    final r = d.receipt;
    final muted = AbyText.caption.copyWith(color: c.inkMuted);
    Widget label(String text) => Padding(
          padding: const EdgeInsets.only(top: AbySpace.s6, bottom: AbySpace.s2),
          child: Text(text.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
        );
    Widget row(String left, int amount, {bool strong = false, Color? color, String? under}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              Expanded(
                child: Text(left, style: (strong ? AbyText.body.copyWith(fontWeight: FontWeight.w700) : AbyText.body).copyWith(color: color ?? c.ink)),
              ),
              Text(
                formatMoney(amount),
                style: (strong ? AbyText.price : AbyText.body).copyWith(color: color ?? c.ink),
              ),
            ]),
            if (under != null) Text(under, style: muted),
          ]),
        );

    return [
      // Who, when, for whom.
      Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
        _Tag(icon: Icons.schedule, text: formatDateTime(r.at)),
        _Tag(icon: Icons.badge_outlined, text: l.saleDetailServedBy(r.cashierName)),
        if (r.customerName != null) _Tag(icon: Icons.person_outline, text: r.customerName!),
        if (r.orderType != null) _Tag(icon: Icons.takeout_dining_outlined, text: orderTypeLabel(l, r.orderType!)),
        if (r.orderNumber != null) _Tag(icon: Icons.confirmation_number_outlined, text: l.saleDetailOrderNumber('${r.orderNumber}')),
      ]),
      if (r.voided)
        _Banner(
          color: c.danger,
          soft: c.dangerSoft,
          text: l.saleDetailVoided(d.voidedBy ?? '?', d.voidedAt == null ? '' : formatDateTime(d.voidedAt!)),
        )
      else if (r.refunded > 0)
        _Banner(
          color: c.warning,
          soft: c.warningSoft,
          text: r.refunded >= r.total ? l.saleDetailRefundedAll : l.saleDetailRefunded(formatMoney(r.refunded)),
        ),

      label(l.saleDetailItems),
      for (final line in d.lines) _Line(line: line),

      const SizedBox(height: AbySpace.s4),
      Container(
        padding: const EdgeInsets.all(AbySpace.s3),
        decoration: BoxDecoration(color: c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.md)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          row(l.saleDetailSubtotal, r.subtotal),
          if (d.lineDiscounts - d.promotions > 0) row(l.saleDetailItemDiscounts, -(d.lineDiscounts - d.promotions), color: c.success),
          if (d.promotions > 0) row(l.saleDetailPromotions, -d.promotions, color: c.success),
          if (r.orderDiscount > 0)
            row(
              l.saleDetailOrderDiscount,
              -r.orderDiscount,
              color: c.success,
              under: d.orderDiscount == null
                  ? null
                  : [
                      l.saleDetailDiscountTag(d.orderDiscount!.name ?? d.orderDiscount!.label, d.orderDiscount!.reason),
                      if (d.orderDiscount!.approvedBy != null) l.saleDetailApprovedBy(d.orderDiscount!.approvedBy!),
                    ].join(', '),
            ),
          if (r.taxTotal > 0) row(r.taxIncluded ? l.saleDetailTaxIncluded : l.saleDetailTax, r.taxTotal, color: r.taxIncluded ? c.inkMuted : null),
          if (r.rounding != 0) row(l.saleDetailRounding, r.rounding),
          const Divider(),
          row(l.saleDetailTotal, r.total, strong: true),
        ]),
      ),

      label(l.saleDetailPayments),
      for (final p in r.payments)
        row(
          p.label,
          p.amount,
          under: [
            if ((p.tendered ?? 0) > p.amount) l.saleDetailGiven(formatMoney(p.tendered!)),
            if ((p.changeGiven ?? 0) > 0) l.saleDetailChange(formatMoney(p.changeGiven!)),
            if (p.momoReference != null) l.saleDetailRef(p.momoReference!),
            ?p.customer,
          ].join('  ·  ').nullIfEmpty,
        ),

      if (_seesCost && !r.voided && d.cost > 0) ...[
        label(l.saleDetailProfit),
        Row(children: [
          Expanded(child: _Stat(label: l.saleDetailCost, value: formatMoney(d.cost))),
          const SizedBox(width: AbySpace.s2),
          Expanded(
            child: _Stat(
              label: l.saleDetailProfit,
              value: formatMoney(d.profit),
              color: d.profit < 0 ? c.danger : c.success,
            ),
          ),
          const SizedBox(width: AbySpace.s2),
          Expanded(child: _Stat(label: l.saleDetailMargin, value: d.margin == null ? '–' : '${d.margin}%')),
        ]),
      ],

      if (d.refunds.isNotEmpty) ...[
        label(l.saleDetailRefunds),
        for (final f in d.refunds)
          row(
            l.saleDetailRefundLine(formatRefundNumber(f.number), formatDateTime(f.at), f.byName, f.reason),
            -f.total,
            color: c.warning,
            under: f.approverName == null ? null : l.saleDetailApprovedBy(f.approverName!),
          ),
      ],

      if (r.note != null) ...[
        label(l.saleDetailNote),
        Text(r.note!, style: AbyText.body.copyWith(color: c.ink)),
      ],

      if (history.isNotEmpty) ...[
        label(l.saleDetailHistory),
        for (final e in history.reversed) _Event(entry: e),
      ],
    ];
  }
}

/// One line: what, how many, the price as charged, and every change to it.
class _Line extends StatelessWidget {
  const _Line({required this.line});

  final SaleDetailLine line;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final r = line.line;
    final each = r.sellBy == SellBy.each;
    final muted = AbyText.caption.copyWith(color: c.inkMuted);
    final net = r.total - r.discount - r.promotion;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Text(
              each ? '${r.quantity} × ${r.title}' : r.title,
              style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600),
            ),
          ),
          if (net != r.total) ...[
            Text(formatMoney(r.total), style: muted.copyWith(decoration: TextDecoration.lineThrough)),
            const SizedBox(width: AbySpace.s2),
          ],
          Text(formatMoney(net), style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
        ]),
        Text(
          each
              ? '${formatMoney(r.unitPrice)} each'
              : '${ReceiptBuilder.quantity(r.quantity, r.sellBy)} @ ${formatMoney(r.unitPrice)}',
          style: muted,
        ),
        if (r.options.isNotEmpty) Text('+ ${r.options.join(', ')}', style: muted),
        if (r.note != null) Text('“${r.note}”', style: muted.copyWith(fontStyle: FontStyle.italic)),
        if (line.priceChanged || line.discount != null || r.promotion > 0)
          Padding(
            padding: const EdgeInsets.only(top: AbySpace.s1),
            child: Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s1, children: [
              if (line.priceChanged)
                _Tag(
                  icon: Icons.edit_outlined,
                  text: line.priceOverriddenBy == null
                      ? l.saleDetailPriceTyped(formatMoney(line.listPrice!))
                      : l.saleDetailPriceChanged(formatMoney(line.listPrice!), line.priceOverriddenBy!),
                  color: c.blue,
                  soft: c.blueSoft,
                ),
              if (line.discount != null && r.discount > 0)
                _Tag(
                  icon: Icons.local_offer_outlined,
                  text: [
                    '−${formatMoney(r.discount)}',
                    l.saleDetailDiscountTag(line.discount!.name ?? line.discount!.label, line.discount!.reason),
                    if (line.discount!.approvedBy != null) l.saleDetailApprovedBy(line.discount!.approvedBy!),
                  ].join('  ·  '),
                  color: c.success,
                  soft: c.successSoft,
                ),
              if (r.promotion > 0)
                _Tag(
                  icon: Icons.celebration_outlined,
                  text: '−${formatMoney(r.promotion)}  ·  ${r.promotionName ?? l.saleDetailPromotion}',
                  color: c.success,
                  soft: c.successSoft,
                ),
            ]),
          ),
      ]),
    );
  }
}

class _Event extends StatelessWidget {
  const _Event({required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final who = [
      ?entry.actorName,
      if (entry.approverName != null) l.saleDetailApprovedBy(entry.approverName!),
    ].join(', ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, right: AbySpace.s3),
          child: Container(width: 8, height: 8, decoration: BoxDecoration(color: c.lineStrong, shape: BoxShape.circle)),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auditActionLabel(l, entry.action), style: AbyText.body.copyWith(color: c.ink)),
            Text(
              [formatTime(entry.at), if (who.isNotEmpty) who, entry.summary].join('  ·  '),
              style: AbyText.caption.copyWith(color: c.inkMuted),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text, this.color, this.soft});

  final IconData icon;
  final String text;
  final Color? color;
  final Color? soft;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final ink = color ?? c.inkMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AbySpace.s2, vertical: 3),
      decoration: BoxDecoration(color: soft ?? c.surfaceSunken, borderRadius: BorderRadius.circular(AbyRadius.sm)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 14, color: ink),
        const SizedBox(width: AbySpace.s1),
        Flexible(child: Text(text, style: AbyText.caption.copyWith(color: ink))),
      ]),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.color, required this.soft, required this.text});

  final Color color;
  final Color soft;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(top: AbySpace.s3),
        padding: const EdgeInsets.all(AbySpace.s3),
        decoration: BoxDecoration(color: soft, borderRadius: BorderRadius.circular(AbyRadius.md)),
        child: Text(text, style: AbyText.body.copyWith(color: color, fontWeight: FontWeight.w600)),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      padding: const EdgeInsets.all(AbySpace.s3),
      decoration: BoxDecoration(border: Border.all(color: c.line), borderRadius: BorderRadius.circular(AbyRadius.md)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: AbyText.caption.copyWith(color: c.inkMuted)),
        Text(value, style: AbyText.price.copyWith(color: color ?? c.ink)),
      ]),
    );
  }
}

extension on String {
  String? get nullIfEmpty => isEmpty ? null : this;
}
