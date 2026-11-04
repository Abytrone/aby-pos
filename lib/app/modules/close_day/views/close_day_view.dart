import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/attendance.dart';
import '../../../core/denominations.dart';
import '../../../core/settings.dart';
import '../../../domain/receipt/receipt_builder.dart';
import '../../../models/day_close.dart';
import '../../../services/money.dart';
import '../../../services/settings_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/cash_count_dialog.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/receipt_actions.dart';
import '../controllers/close_day_controller.dart';
import '../widgets/daily_summary.dart';
import '../widgets/difference_box.dart';
import '../widgets/period_summary.dart';
import '../../../ui/dialogs.dart';

class CloseDayView extends GetView<CloseDayController> {
  const CloseDayView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.closeDayButton),
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
                  if (done != null) _Closed(close: done, onDone: controller.done) else _CountForm(period: period),
                  const SizedBox(height: AbySpace.s8),
                  if (controller.variance.isNotEmpty) ...[
                    Text(l.closeVarianceTitle.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                    const SizedBox(height: AbySpace.s2),
                    for (final e in controller.variance.entries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AbySpace.s1),
                        child: Text(
                          l.closeVarianceLine(e.key, e.value.$1, formatMoney(e.value.$2), e.value.$3),
                          style: AbyText.body.copyWith(color: e.value.$1 > 0 ? c.danger : c.ink),
                        ),
                      ),
                    const SizedBox(height: AbySpace.s6),
                  ],
                  Text(l.closePast.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AbySpace.s2),
                  if (controller.history.isEmpty)
                    Text(l.closeNone, style: AbyText.body.copyWith(color: c.inkMuted))
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

class _CountForm extends GetView<CloseDayController> {
  const _CountForm({required this.period});

  final OpenPeriod period;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final moneyFormat = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];
    return Obx(() {
      final show = controller.showExpected;
      final fixed = controller.blind && controller.revealed.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(period.from == null ? l.closeSinceFirst : l.closeSince(formatDateTime(period.from!)),
              style: AbyText.body.copyWith(color: c.inkMuted)),
          if (period.shiftOpenedBy != null)
            Text(l.closeDayStartedBy(period.shiftOpenedBy!, formatMoney(period.shiftFloat!)),
                style: AbyText.body.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s3),
          if (controller.stillClockedIn.isNotEmpty) const _StillIn(),
          if (controller.oldParked.value > 0)
            Container(
              margin: const EdgeInsets.only(bottom: AbySpace.s3),
              padding: const EdgeInsets.all(AbySpace.s3),
              decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AbyRadius.sm)),
              child: Row(children: [
                Icon(Icons.pause_circle_outline, color: c.warning),
                const SizedBox(width: AbySpace.s2),
                Expanded(child: Text(l.closeParkedWarning(controller.oldParked.value), style: AbyText.body.copyWith(color: c.ink))),
              ]),
            ),
          PeriodSummary(period: period, openingFloat: show ? controller.openingFloat : null, showCash: show),
          const SizedBox(height: AbySpace.s6),
          Text(l.closeCountTitle.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
          if (controller.blind && !controller.revealed.value)
            Text(l.closeBlindHelp, style: AbyText.caption.copyWith(color: c.inkMuted)),
          const SizedBox(height: AbySpace.s3),
          if (period.shiftFloat == null) ...[
            _Warning(icon: Icons.payments_outlined, text: l.closeDayNotStarted),
            TextField(
              controller: controller.floatField,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: moneyFormat,
              decoration: InputDecoration(labelText: l.closeFloatLabel, prefixText: 'GH₵ ', helperText: l.closeFloatHelp),
            ),
            const SizedBox(height: AbySpace.s4),
          ],
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: TextField(
                controller: controller.countedField,
                enabled: !fixed,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: moneyFormat,
                style: AbyText.heading.copyWith(color: c.ink),
                decoration: InputDecoration(labelText: l.closeCountedLabel, prefixText: 'GH₵ '),
              ),
            ),
            const SizedBox(width: AbySpace.s2),
            OutlinedButton.icon(
              onPressed: fixed
                  ? null
                  : () async {
                      final count = await showCashCount(initial: controller.cashCount.value ?? const CashCount());
                      if (count != null) controller.useCount(count);
                    },
              icon: const Icon(Icons.calculate_outlined),
              label: Text(l.countCashButton),
            ),
          ]),
          const SizedBox(height: AbySpace.s4),
          if (show) ...[
            DifferenceBox(difference: controller.difference),
            if (controller.needsReason) ...[
              const SizedBox(height: AbySpace.s3),
              TextField(
                controller: controller.reasonField,
                decoration: InputDecoration(
                  labelText: l.closeReason,
                  helperText: l.closeReasonHelp(formatMoney(controller.varianceLimit)),
                ),
              ),
            ],
          ] else
            OutlinedButton(
              onPressed: controller.counted == null ? null : controller.reveal,
              child: Text(l.closeCheckCount),
            ),
          const SizedBox(height: AbySpace.s4),
          TextField(controller: controller.noteField, maxLines: 2, decoration: InputDecoration(labelText: l.stockNoteOptional)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AbySpace.s3),
            child: Text(controller.error.value ?? '', style: AbyText.body.copyWith(color: c.danger)),
          ),
          FilledButton(
            onPressed: controller.canClose ? () => _confirm(context) : null,
            child: Text(l.closeDayButton),
          ),
        ],
      );
    });
  }

  Future<void> _confirm(BuildContext context) async {
    final l = context.l10n;
    final ok = await Get.dialog<bool>(AlertDialog(
      title: Text(l.closeConfirmTitle),
      content: Text(l.closeConfirmBody),
      actions: [
        DialogButtons(children: [
                OutlinedButton(onPressed: () => goBack(result: false), child: Text(l.closeNotYet)),
          FilledButton(onPressed: () => goBack(result: true), child: Text(l.closeDayButton)),
        ]),
      ],
    ));
    if (ok == true) await controller.closeDay();
  }
}

/// The Z report on the receipt printer.
void printZ(DayClose close) =>
    printOnPaper(ReceiptBuilder.dayClose(close, shopName: Get.find<SettingsService>().get(AppSettings.shopName)));

class _Closed extends StatelessWidget {
  const _Closed({required this.close, required this.onDone});

  final DayClose close;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.check_circle, size: 56, color: c.success),
        const SizedBox(height: AbySpace.s3),
        Text(l.closeDone, textAlign: TextAlign.center, style: AbyText.title.copyWith(color: c.ink)),
        const SizedBox(height: AbySpace.s1),
        Text(
          l.closeDoneLine(close.salesCount, formatMoney(close.salesTotal), close.closedByName),
          textAlign: TextAlign.center,
          style: AbyText.body.copyWith(color: c.inkMuted),
        ),
        const SizedBox(height: AbySpace.s4),
        DifferenceBox(difference: close.difference),
        if (close.varianceReason != null)
          Padding(
            padding: const EdgeInsets.only(top: AbySpace.s2),
            child: Text('“${close.varianceReason}”', textAlign: TextAlign.center, style: AbyText.body.copyWith(color: c.inkMuted)),
          ),
        const SizedBox(height: AbySpace.s4),
        Text(l.checkoutSavedHere, textAlign: TextAlign.center, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s4),
        Obx(() {
          final o = Get.find<CloseDayController>().attendanceOutcome.value;
          if (o == null) return const SizedBox.shrink();
          final names = o.$2.join(', ');
          final text = switch (o.$1) {
            CloseWithOthersIn.auto => l.closedAutoClockedOut(names),
            CloseWithOthersIn.allow => l.closedLeftOpenPaid(names),
            _ => l.closedLeftOpenReview(names),
          };
          return _Warning(icon: Icons.schedule, text: text);
        }),
        Obx(() {
          final s = Get.find<CloseDayController>().summary.value;
          if (s == null) return const SizedBox.shrink();
          return Padding(padding: const EdgeInsets.only(bottom: AbySpace.s3), child: DailySummaryCard(summary: s));
        }),
        OutlinedButton.icon(
          onPressed: () => printZ(close),
          icon: const Icon(Icons.print_outlined),
          label: Text(l.closePrintZ),
        ),
        const SizedBox(height: AbySpace.s2),
        FilledButton(onPressed: onDone, child: Text(l.commonDone)),
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
    final l = context.l10n;
    final d = close.difference;
    final diffText = d == 0 ? l.closeBalanced : (d > 0 ? l.closeOver(formatMoney(d)) : l.closeShort(formatMoney(-d)));
    return Container(
      constraints: const BoxConstraints(minHeight: AbySize.tapPos),
      padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(formatDateTime(close.closedAt), style: AbyText.body.copyWith(color: c.ink)),
            Text(
              [l.closeSales(close.salesCount), close.closedByName, ?close.varianceReason].join('  ·  '),
              style: AbyText.caption.copyWith(color: c.inkMuted),
            ),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(formatMoney(close.salesTotal), style: AbyText.price.copyWith(color: c.ink)),
          Text(diffText, style: AbyText.caption.copyWith(color: d == 0 ? c.success : (d > 0 ? c.warning : c.danger))),
        ]),
        IconButton(tooltip: l.closePrintZ, onPressed: () => printZ(close), icon: const Icon(Icons.print_outlined)),
      ]),
    );
  }
}

/// Something to check before closing, in the warning colours.
class _Warning extends StatelessWidget {
  const _Warning({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: AbySpace.s3),
      padding: const EdgeInsets.all(AbySpace.s3),
      decoration: BoxDecoration(color: c.warningSoft, borderRadius: BorderRadius.circular(AbyRadius.sm)),
      child: Row(children: [
        Icon(icon, color: c.warning),
        const SizedBox(width: AbySpace.s2),
        Expanded(child: Text(text, style: AbyText.body.copyWith(color: c.ink))),
      ]),
    );
  }
}

/// Who is still clocked in, what closing will do about it, and a way for a
/// manager to set when someone really left (with a reason).
class _StillIn extends GetView<CloseDayController> {
  const _StillIn();

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final blocked = controller.waitingForClockOut;
    final explain = switch (controller.attendance) {
      CloseWithOthersIn.block => l.closeAttendanceBlock,
      CloseWithOthersIn.allow => l.closeAttendanceAllow,
      CloseWithOthersIn.auto => l.closeAttendanceAuto,
      _ => l.closeAttendanceReview,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: AbySpace.s3),
      padding: const EdgeInsets.all(AbySpace.s3),
      decoration: BoxDecoration(
        color: blocked ? c.dangerSoft : c.warningSoft,
        borderRadius: BorderRadius.circular(AbyRadius.sm),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Icon(Icons.schedule, color: blocked ? c.danger : c.warning),
          const SizedBox(width: AbySpace.s2),
          Expanded(child: Text(l.closeAttendanceTitle, style: AbyText.body.copyWith(color: c.ink, fontWeight: FontWeight.w600))),
          TextButton(onPressed: controller.loadAttendance, child: Text(l.closeAttendanceCheck)),
        ]),
        Text(explain, style: AbyText.caption.copyWith(color: c.inkMuted)),
        const SizedBox(height: AbySpace.s2),
        for (final e in controller.stillClockedIn)
          Row(children: [
            Expanded(
              child: Text(
                '${e.staffName}  ·  ${l.closeAttendanceSince(formatTime(e.clockIn))}${e.missedClockOut() ? '  ·  ${l.timeMissedClockOut}' : ''}',
                style: AbyText.body.copyWith(color: c.ink),
              ),
            ),
            TextButton(onPressed: () => controller.correctHours(e), child: Text(l.closeAttendanceCorrect)),
          ]),
      ]),
    );
  }
}
