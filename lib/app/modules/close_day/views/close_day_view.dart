import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../models/day_close.dart';
import '../../../models/enums.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../controllers/close_day_controller.dart';
import '../widgets/difference_box.dart';

class CloseDayView extends GetView<CloseDayController> {
  const CloseDayView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Close day'),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
      ),
      body: Obx(() {
        final period = controller.period.value;
        if (period == null) return const Center(child: CircularProgressIndicator());
        final done = controller.closed.value;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AbySpace.s4),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (done != null)
                    _Closed(close: done, onDone: controller.done)
                  else
                    _CountForm(period: period),
                  const SizedBox(height: AbySpace.s8),
                  Text('PAST CLOSES', style: AbyText.label.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AbySpace.s2),
                  if (controller.history.isEmpty)
                    Text('No closes yet.', style: AbyText.body.copyWith(color: c.inkMuted))
                  else
                    for (final close in controller.history) _HistoryRow(close: close),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}

String _when(DateTime? t) {
  if (t == null) return 'the first sale';
  final l = t.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(l.day)}/${two(l.month)}/${l.year} ${two(l.hour)}:${two(l.minute)}';
}

class _CountForm extends GetView<CloseDayController> {
  const _CountForm({required this.period});

  final OpenPeriod period;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final moneyFormat = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    Widget line(String label, String value, {bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: AbySpace.s1),
          child: Row(children: [
            Expanded(child: Text(label, style: AbyText.body.copyWith(color: strong ? c.ink : c.inkMuted))),
            Text(value,
                style: (strong ? AbyText.heading : AbyText.body).copyWith(
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                )),
          ]),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Since ${_when(period.from)}', style: AbyText.body.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s3),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(AbySpace.s4),
            child: Column(children: [
              line('Sales', '${period.salesCount}'
                  '${period.voidedCount > 0 ? '  (${period.voidedCount} voided)' : ''}'),
              line('Total sales', formatMoney(period.salesTotal), strong: true),
              const Divider(height: AbySpace.s6),
              for (final m in PaymentMethod.values)
                line(m.label, formatMoney(period.byMethod[m] ?? 0)),
            ]),
          ),
        ),
        const SizedBox(height: AbySpace.s6),
        Text('COUNT THE DRAWER', style: AbyText.label.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s3),
        TextField(
          controller: controller.floatField,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: moneyFormat,
          decoration: const InputDecoration(
            labelText: 'Float at the start',
            prefixText: 'GH₵ ',
            helperText: 'Cash that was in the drawer before the first sale.',
          ),
        ),
        const SizedBox(height: AbySpace.s4),
        TextField(
          controller: controller.countedField,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: moneyFormat,
          style: AbyText.heading.copyWith(color: c.ink),
          decoration: const InputDecoration(labelText: 'Cash counted now', prefixText: 'GH₵ '),
        ),
        const SizedBox(height: AbySpace.s4),
        Obx(() => line('Expected in drawer',
            controller.expected == null ? '-' : formatMoney(controller.expected!),
            strong: true)),
        const SizedBox(height: AbySpace.s3),
        Obx(() => DifferenceBox(difference: controller.difference)),
        const SizedBox(height: AbySpace.s4),
        TextField(
          controller: controller.noteField,
          maxLines: 2,
          decoration: const InputDecoration(labelText: 'Note (optional)'),
        ),
        Obx(() => Padding(
              padding: const EdgeInsets.symmetric(vertical: AbySpace.s3),
              child: Text(controller.error.value ?? '',
                  style: AbyText.body.copyWith(color: c.danger)),
            )),
        Obx(() => FilledButton(
              onPressed: controller.canClose ? () => _confirm(context) : null,
              child: const Text('Close day'),
            )),
      ],
    );
  }

  Future<void> _confirm(BuildContext context) async {
    final ok = await Get.dialog<bool>(AlertDialog(
      title: const Text('Close the day?'),
      content: const Text(
          "Sales up to now can't be voided after this. New sales start a new day."),
      actions: [
        OutlinedButton(onPressed: () => Get.back(result: false), child: const Text('Not yet')),
        FilledButton(onPressed: () => Get.back(result: true), child: const Text('Close day')),
      ],
    ));
    if (ok == true) await controller.closeDay();
  }
}

class _Closed extends StatelessWidget {
  const _Closed({required this.close, required this.onDone});

  final DayClose close;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle, size: 56, color: c.success),
        const SizedBox(height: AbySpace.s3),
        Text('Day closed', textAlign: TextAlign.center, style: AbyText.title.copyWith(color: c.ink)),
        const SizedBox(height: AbySpace.s1),
        Text(
          '${close.salesCount} sales  ·  ${formatMoney(close.salesTotal)}  ·  by ${close.closedByName}',
          textAlign: TextAlign.center,
          style: AbyText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AbySpace.s4),
        DifferenceBox(difference: close.difference),
        const SizedBox(height: AbySpace.s4),
        Text("Saved on this device. Will sync when you're online.",
            textAlign: TextAlign.center, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s4),
        // TODO(print): print the cash-up slip.
        FilledButton(onPressed: onDone, child: const Text('Done')),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.close});

  final DayClose close;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final d = close.difference;
    final diffText = d == 0
        ? 'Balanced'
        : '${d > 0 ? 'Over' : 'Short'} ${formatMoney(d.abs())}';
    return Container(
      constraints: const BoxConstraints(minHeight: AbySize.tapPos),
      padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_when(close.closedAt), style: AbyText.body.copyWith(color: c.ink)),
            Text('${close.salesCount} sales  ·  ${close.closedByName}',
                style: AbyText.caption.copyWith(color: c.inkMuted)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatMoney(close.salesTotal), style: AbyText.price.copyWith(color: c.ink)),
          Text(diffText,
              style: AbyText.caption.copyWith(
                  color: d == 0 ? c.success : (d > 0 ? c.warning : c.danger))),
        ]),
      ]),
    );
  }
}
