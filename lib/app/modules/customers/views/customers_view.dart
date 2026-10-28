import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/validators.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/l10n.dart';
import '../../../ui/option_chip.dart';
import '../../../ui/section_page.dart';
import '../controllers/customers_controller.dart';
import '../widgets/customer_form.dart';
import '../widgets/vouchers_dialog.dart';

class CustomersView extends GetView<CustomersController> {
  const CustomersView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return SectionPage(
      title: l.navCustomers,
      actions: [
        OutlinedButton.icon(onPressed: showVouchers, icon: const Icon(Icons.card_giftcard), label: Text(l.voucherTitle)),
        if (controller.canManage)
          FilledButton.icon(
            onPressed: () => showCustomerForm(onSave: controller.save).then((_) => _flush()),
            icon: const Icon(Icons.person_add_alt),
            label: Text(l.customerNew),
          ),
      ],
      bottom: Padding(
        padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s4, AbySpace.s2),
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => controller.query.value = v,
              decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: l.customerSearchHint, isDense: true),
            ),
          ),
          const SizedBox(width: AbySpace.s3),
          Obx(() => OptionChip(
                label: l.customersOwing,
                selected: controller.owingOnly.value,
                onTap: () => controller.owingOnly.value = !controller.owingOnly.value,
              )),
        ]),
      ),
      child: Obx(() {
        if (controller.loading.value) return const Center(child: CircularProgressIndicator());
        final list = controller.customers.toList();
        if (list.isEmpty) return EmptyState(icon: Icons.people_outline, message: l.customersNone);
        return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
          if (controller.totalOwed > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: AbySpace.s3),
              child: Text(l.customersOwedTotal(formatMoney(controller.totalOwed)),
                  style: AbyText.body.copyWith(color: c.warning, fontWeight: FontWeight.w700)),
            ),
          for (final x in list) ...[
            InfoTile(
              title: x.name,
              subtitle: [
                if (x.phone != null) Validators.formatPhone(x.phone!),
                if (x.location != null) x.location!,
                ...x.tags,
              ].join('  ·  '),
              value: x.owed > 0
                  ? l.customerOwes(formatMoney(x.owed))
                  : x.wallet > 0
                      ? l.customerWallet(formatMoney(x.wallet))
                      : null,
              onTap: () => controller.open(x),
            ),
            const Divider(height: 1),
          ],
        ]);
      }),
    );
  }

  void _flush() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    showMessage(text);
  }
}
