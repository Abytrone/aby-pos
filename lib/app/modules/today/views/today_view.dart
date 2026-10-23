import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../models/sale.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../widgets/owner_approval.dart';
import '../controllers/today_controller.dart';
import '../widgets/sale_row.dart';
import '../widgets/summary_cards.dart';

class TodayView extends GetView<TodayController> {
  const TodayView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        actions: [
          if (controller.isOwner)
            TextButton(onPressed: controller.openStaff, child: const Text('Staff')),
          Padding(
            padding: const EdgeInsets.only(left: AbySpace.s2, right: AbySpace.s4),
            child: FilledButton(
              onPressed: controller.openCloseDay,
              child: const Text('Close day'),
            ),
          ),
        ],
      ),
      body: Obx(() {
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
                child: Text('SALES', style: AbyText.label.copyWith(color: c.inkMuted)),
              ),
            ),
            if (sales.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AbySpace.s6),
                  child: Text('No sales yet today.',
                      style: AbyText.body.copyWith(color: c.inkMuted)),
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
    final c = Theme.of(context).extension<AbyColors>()!;
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('Void sale ${sale.displayNumber}?'),
        content: Text(
          '${formatMoney(sale.total)} will come off today\'s takings and the '
          'items go back into stock. This cannot be undone.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Keep sale'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: c.danger),
            onPressed: () => Get.back(result: true),
            child: const Text('Void sale'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    final approvedBy = controller.needsApproval
        ? await askOwnerApproval(
            reason: 'A cashier is voiding ${sale.displayNumber}.',
            findOwner: controller.approveAsOwner,
          )
        : null;
    if (controller.needsApproval && approvedBy == null) return;
    await controller.voidSale(sale, approvedBy: approvedBy);
    final message = controller.message.value;
    if (message != null) {
      Get.showSnackbar(GetSnackBar(
        message: message,
        duration: const Duration(seconds: 3),
      ));
    }
  }
}
