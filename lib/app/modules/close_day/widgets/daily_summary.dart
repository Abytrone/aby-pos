import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../services/money.dart';
import '../../../theme/aby_mark.dart';
import '../../../ui/files.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';

/// The owner's daily summary (NTF-02): what a closed day came to.
class DailySummary {
  const DailySummary({
    required this.shopName,
    required this.closedAt,
    required this.closedBy,
    required this.sales,
    required this.count,
    required this.cashDifference,
    this.profit,
    this.topProduct,
    this.alerts = const [],
  });

  final String shopName;
  final DateTime closedAt;
  final String closedBy;

  /// Pesewas.
  final int sales;
  final int count;

  /// Counted less expected: positive over, negative short.
  final int cashDifference;

  /// Pesewas of gross profit, when costs are set.
  final int? profit;
  final String? topProduct;
  final List<String> alerts;

  /// The same as a message, for WhatsApp.
  String text(AppLocalizations l) => [
        '$shopName: ${formatDateTime(closedAt)}',
        l.summarySales(formatMoney(sales), count),
        if (profit != null) l.summaryProfit(formatMoney(profit!)),
        cashDifference == 0
            ? l.closeBalanced
            : (cashDifference > 0 ? l.closeOver(formatMoney(cashDifference)) : l.closeShort(formatMoney(-cashDifference))),
        if (topProduct != null) l.summaryTop(topProduct!),
        ...alerts,
        l.summaryClosedBy(closedBy),
      ].join('\n');
}

/// The summary as a card, with "Share" (an image, for the owner's WhatsApp).
class DailySummaryCard extends StatefulWidget {
  const DailySummaryCard({super.key, required this.summary});

  final DailySummary summary;

  @override
  State<DailySummaryCard> createState() => _DailySummaryCardState();
}

class _DailySummaryCardState extends State<DailySummaryCard> {
  final _boundary = GlobalKey();

  Future<void> _share() async {
    final l = context.l10n;
    final box = _boundary.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (box == null) return;
    final image = await box.toImage(pixelRatio: 2.5);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    if (png == null) return;
    final day = widget.summary.closedAt.toIso8601String().substring(0, 10);
    await shareOrSaveBytes('summary-$day.png', png.buffer.asUint8List(), text: widget.summary.text(l));
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final s = widget.summary;
    // Fixed light colours: the picture looks the same in WhatsApp whatever
    // the till's theme.
    const ink = Color(0xFF101322), muted = Color(0xFF5A5E6B), good = Color(0xFF14804A), bad = Color(0xFFB42318);
    Widget row(String label, String value, {Color color = ink, bool strong = false}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(children: [
            Expanded(child: Text(label, style: const TextStyle(color: muted, fontSize: 14))),
            Text(value, style: TextStyle(color: color, fontSize: strong ? 20 : 15, fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
          ]),
        );
    final diff = s.cashDifference;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      RepaintBoundary(
        key: _boundary,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFFE3E0D8))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(children: [
              const AbyMark(size: 28),
              const SizedBox(width: 10),
              Expanded(child: Text(s.shopName, style: const TextStyle(color: ink, fontSize: 17, fontWeight: FontWeight.w800))),
            ]),
            Text(formatDateTime(s.closedAt), style: const TextStyle(color: muted, fontSize: 13)),
            const Divider(height: 20),
            row(l.summarySalesLabel(s.count), formatMoney(s.sales), strong: true),
            if (s.profit != null) row(l.summaryProfitLabel, formatMoney(s.profit!)),
            row(
              l.summaryCash,
              diff == 0 ? l.closeBalanced : (diff > 0 ? l.closeOver(formatMoney(diff)) : l.closeShort(formatMoney(-diff))),
              color: diff == 0 ? good : (diff > 0 ? const Color(0xFFB4570B) : bad),
            ),
            if (s.topProduct != null) row(l.summaryTopLabel, s.topProduct!),
            for (final a in s.alerts)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('• $a', style: const TextStyle(color: Color(0xFFB4570B), fontSize: 13)),
              ),
            const SizedBox(height: 8),
            Text(l.summaryClosedBy(s.closedBy), style: const TextStyle(color: muted, fontSize: 12)),
          ]),
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _share, icon: const Icon(Icons.share_outlined), label: Text(l.summaryShare)),
    ]);
  }
}
