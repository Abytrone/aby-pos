import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/today_controller.dart';
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
        FilledButton(onPressed: controller.openCloseDay, child: Text(l.closeDayButton)),
      ],
      child: Obx(() {
        if (controller.loading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        final sales = controller.sales.toList();
        // Read eagerly (the list builds lazily) so rows rebuild after a close.
        final locked = {for (final s in sales) s.id: controller.isLocked(s)};
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AbySpace.s4),
              sliver: SliverToBoxAdapter(
                child: SummaryCards(summary: controller.summary.value),
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
                itemBuilder: (context, i) => SaleRow(
                  sale: sales[i],
                  locked: locked[sales[i].id]!,
                  onVoid: !sales[i].isVoided && !locked[sales[i].id]!
                      ? () => _confirmVoid(context, sales[i])
                      : null,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: AbySpace.s8)),
          ],
        );
      }),
    );
  }

  Future<void> _confirmVoid(BuildContext context, Sale sale) async {
    final l = context.l10n;
    final confirmed = await confirmDialog(
      title: l.voidConfirmTitle(sale.displayNumber),
      message: l.voidConfirmBody(formatMoney(sale.total)),
      confirmLabel: l.voidConfirm,
      cancelLabel: l.voidKeep,
      danger: true,
    );
    if (!confirmed) return;
    final message = await controller.voidSale(sale);
    if (message != null) showMessage(message);
  }
}
