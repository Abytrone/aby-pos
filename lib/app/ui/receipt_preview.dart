import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../domain/receipt/receipt_doc.dart';
import '../theme/aby_theme.dart';

/// A receipt as it will come out of the printer: the same lines, on white
/// paper, in a fixed-width font.
class ReceiptPreview extends StatelessWidget {
  const ReceiptPreview({super.key, required this.doc, required this.paper});

  final ReceiptDoc doc;
  final Paper paper;

  static const _ink = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final style = AbyText.receipt.copyWith(color: _ink, height: 1.35);
    // Width of the paper in this font, measured once.
    final painter = TextPainter(
      text: TextSpan(text: 'M' * paper.chars, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    final width = painter.width;
    painter.dispose();
    Widget lines(ReceiptBlock b, {bool bold = false, bool big = false}) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final l in layout(b, paper.chars))
              Text(
                l.isEmpty ? ' ' : l,
                softWrap: false,
                style: style.copyWith(
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
                  fontSize: big ? style.fontSize! * 2 : null,
                  height: big ? 1.1 : null,
                ),
              ),
          ],
        );
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.topCenter,
      child: Container(
        width: width + AbySpace.s4 * 2,
        padding: const EdgeInsets.all(AbySpace.s4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final b in doc.blocks)
            switch (b) {
              RQr(:final data) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
                    child: QrImageView(data: data, size: 110, padding: EdgeInsets.zero),
                  ),
                ),
              RBarcode(:final data) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: AbySpace.s2),
                    child: CustomPaint(size: Size(width * 0.7, 48), painter: BarcodePainter(data)),
                  ),
                ),
              RImage(:final png) => Center(
                  child: Image.memory(
                    png,
                    width: width * 0.6,
                    color: Colors.grey,
                    colorBlendMode: BlendMode.saturation,
                  ),
                ),
              RMark() => Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AbySpace.s2),
                    child: SvgPicture.string(abyMarkSvg, width: 28, height: 28, semanticsLabel: 'Aby'),
                  ),
                ),
              RText(:final bold, :final big) => lines(b, bold: bold, big: big),
              RRow(:final bold) => lines(b, bold: bold),
              RRule() || RFeed() => lines(b),
            },
        ]),
      ),
    );
  }
}

/// Draws a Code 128 barcode (label previews).
class BarcodePainter extends CustomPainter {
  BarcodePainter(this.data);

  final String data;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = const Color(0xFF000000);
    for (final bar in Barcode.code128().make(data, width: size.width, height: size.height).whereType<BarcodeBar>()) {
      if (bar.black) canvas.drawRect(Rect.fromLTWH(bar.left, bar.top, bar.width, bar.height), ink);
    }
  }

  @override
  bool shouldRepaint(BarcodePainter old) => old.data != data;
}
