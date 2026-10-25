import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/section_page.dart';
import '../controllers/momo_controller.dart';

class MomoView extends GetView<MomoController> {
  const MomoView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.momoTitle),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
        actions: [
          Obx(() => TextButton.icon(
                onPressed: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: controller.day.value,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) await controller.setDay(d);
                },
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(formatDate(controller.day.value)),
              )),
        ],
      ),
      body: Obx(() {
        if (controller.loading.value) return const Center(child: CircularProgressIndicator());
        final items = controller.items.toList();
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
              Text(l.momoHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
              const SizedBox(height: AbySpace.s3),
              GroupCard(title: l.momoSummary, children: [
                InfoTile(title: l.momoReceived(items.length), value: formatMoney(controller.total)),
                InfoTile(
                  title: l.momoCharges,
                  subtitle: l.momoChargesHelp,
                  value: formatMoney(controller.charges.value),
                  onTap: () async {
                    final text = await textInputDialog(
                      title: l.momoCharges,
                      label: l.checkoutAmount,
                      initial: (controller.charges.value / 100).toStringAsFixed(2),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    );
                    if (text != null) await controller.setCharges(text);
                  },
                ),
                InfoTile(title: l.momoNet, value: formatMoney(controller.net)),
                InfoTile(title: l.momoTicked, value: formatMoney(controller.ticked)),
                if (controller.unchecked > 0) InfoTile(title: l.momoUnchecked(controller.unchecked)),
                if (controller.missing.isNotEmpty)
                  InfoTile(
                    title: l.momoMissing(controller.missing.length),
                    value: formatMoney(controller.missing.fold(0, (s, i) => s + i.amount)),
                  ),
              ]),
              GroupCard(
                title: l.momoPayments,
                children: items.isEmpty
                    ? [InfoTile(title: l.momoNone)]
                    : [
                        for (final i in items)
                          InfoTile(
                            leading: Icon(
                              switch (i.matched) {
                                true => Icons.check_circle,
                                false => Icons.cancel,
                                null => Icons.radio_button_unchecked,
                              },
                              color: switch (i.matched) {
                                true => c.success,
                                false => c.danger,
                                null => c.inkMuted,
                              },
                            ),
                            title: '${i.reference ?? l.momoNoReference}  ·  ${formatMoney(i.amount)}',
                            subtitle: [formatDateTime(i.at), i.methodName, ?i.label].join('  ·  '),
                            onTap: () => controller.cycle(i),
                          ),
                      ],
              ),
            ]),
          ),
        );
      }),
    );
  }
}
