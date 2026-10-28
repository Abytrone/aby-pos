import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/enums.dart';
import '../../../models/order.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/section_page.dart';
import '../controllers/orders_controller.dart';

String orderStatusLabel(AppLocalizations l, OrderStatus s) => switch (s) {
      OrderStatus.fresh => l.orderNew,
      OrderStatus.preparing => l.orderPreparing,
      OrderStatus.ready => l.orderReady,
      OrderStatus.collected => l.orderCollected,
    };

/// Sell → Orders: the prep board on the till itself. Tablets and TVs can
/// show the same board in a browser (Settings → Screens on other devices).
class OrdersView extends GetView<OrdersController> {
  const OrdersView({super.key});

  static const _columns = [OrderStatus.fresh, OrderStatus.preparing, OrderStatus.ready];

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return SectionPage(
      title: l.navOrders,
      child: Obx(() {
        if (controller.orders.isEmpty) return EmptyState(icon: Icons.receipt_long_outlined, message: l.ordersNone);
        final columns = [
          for (final s in _columns)
            _Column(title: orderStatusLabel(l, s), status: s, orders: controller.withStatus(s), controller: controller),
        ];
        if (context.isNarrow) {
          return ListView(padding: const EdgeInsets.all(AbySpace.s3), children: columns);
        }
        return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final c in columns) Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s3), child: c)),
        ]);
      }),
    );
  }
}

class _Column extends StatelessWidget {
  const _Column({required this.title, required this.status, required this.orders, required this.controller});

  final String title;
  final OrderStatus status;
  final List<OpenOrder> orders;
  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
        child: Text('${title.toUpperCase()}  ${orders.length}', style: AbyText.label.copyWith(color: c.inkMuted)),
      ),
      for (final o in orders) _OrderCard(order: o, controller: controller),
    ]);
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.controller});

  final OpenOrder order;
  final OrdersController controller;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final next = OrdersController.next(order.status);
    return Card(
      margin: const EdgeInsets.only(bottom: AbySpace.s3),
      child: Padding(
        padding: const EdgeInsets.all(AbySpace.s3),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Text(controller.label(order), style: AbyText.title.copyWith(color: c.ink)),
            const SizedBox(width: AbySpace.s2),
            Expanded(
              child: Text(
                [relativeTime(l, order.at), ?order.customerName].join('  ·  '),
                style: AbyText.caption.copyWith(color: c.inkMuted),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            PopupMenuButton<VoidCallback>(
              tooltip: l.commonMore,
              onSelected: (f) => f(),
              itemBuilder: (_) => [
                PopupMenuItem(value: () => controller.printTicket(order), child: Text(l.orderPrintTicket)),
                if (order.status != OrderStatus.fresh)
                  PopupMenuItem(
                    value: () => controller.move(order, OrdersController.back(order.status)),
                    child: Text(l.orderBack(orderStatusLabel(l, OrdersController.back(order.status)))),
                  ),
              ],
            ),
          ]),
          for (final line in order.lines) ...[
            Text('${line.quantity} × ${line.title}', style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            if (line.options.isNotEmpty) Text('+ ${line.options.join(', ')}', style: AbyText.caption.copyWith(color: c.inkMuted)),
            if (line.note != null) Text('“${line.note}”', style: AbyText.caption.copyWith(color: c.inkMuted)),
          ],
          if (order.note != null) Text('“${order.note}”', style: AbyText.caption.copyWith(color: c.warning)),
          const SizedBox(height: AbySpace.s2),
          FilledButton(
            onPressed: () => controller.move(order, next),
            child: Text(next == OrderStatus.collected ? l.orderMarkCollected : l.orderMoveTo(orderStatusLabel(l, next))),
          ),
        ]),
      ),
    );
  }
}
