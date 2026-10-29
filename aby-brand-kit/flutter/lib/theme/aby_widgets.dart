// Aby components for Flutter: product tile and row, view toggle, payment chip,
// banner, empty state, confirm sheet and sale complete. Match the Aby design system.
import 'package:flutter/material.dart';
import 'aby_colors.dart';
import 'aby_icons.dart';
import 'aby_theme.dart';

AbyColors _c(BuildContext context) => Theme.of(context).extension<AbyColors>()!;

// ---------------------------------------------------------------------------
// Product categories
// ---------------------------------------------------------------------------

/// A category's colour. The owner picks one per category; at most four categories get a colour.
enum AbyTone { midnight, lime, blue, coral }

extension on AbyTone {
  Color dot(AbyColors c) => switch (this) {
        AbyTone.midnight => c.ink,
        AbyTone.lime => c.lime,
        AbyTone.blue => c.blue,
        AbyTone.coral => c.coral,
      };
  Color tint(AbyColors c) => switch (this) {
        AbyTone.midnight => c.surfaceSunken,
        AbyTone.lime => c.limeSoft,
        AbyTone.blue => c.blueSoft,
        AbyTone.coral => c.dangerSoft,
      };
  Color iconColor(AbyColors c) => switch (this) {
        AbyTone.midnight => c.inkMuted,
        AbyTone.lime => c.limeInk,
        AbyTone.blue => c.blue,
        AbyTone.coral => c.danger,
      };
  String defaultIcon() => switch (this) {
        AbyTone.midnight => AbyIcons.iceCreamCone,
        AbyTone.lime => AbyIcons.candy,
        AbyTone.blue => AbyIcons.cupSoda,
        AbyTone.coral => AbyIcons.cookie,
      };
}

String? _stockText(int? left) => left == null ? null : (left == 0 ? 'Out of stock' : '$left left');

/// The product picture: the photo if there is one, else the category icon on the category's tint.
class AbyProductThumb extends StatelessWidget {
  const AbyProductThumb({super.key, this.image, this.icon, this.tone = AbyTone.midnight, this.iconSize = 32, this.dimmed = false});
  final ImageProvider? image;
  final String? icon;
  final AbyTone tone;
  final double iconSize;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    Widget child;
    if (image != null) {
      child = Image(image: image!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
      if (dimmed) {
        child = Opacity(
          opacity: 0.6,
          child: ColorFiltered(colorFilter: const ColorFilter.matrix(_greyscale), child: child),
        );
      }
    } else {
      child = Center(child: AbyIcon(icon ?? tone.defaultIcon(), size: iconSize, color: tone.iconColor(c)));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AbyRadius.sm),
      child: ColoredBox(color: tone.tint(c), child: child),
    );
  }
}

const List<double> _greyscale = [
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0,
];

class _CountBadge extends StatelessWidget {
  const _CountBadge(this.count, {this.size = 26});
  final int count;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return Container(
      constraints: BoxConstraints(minWidth: size, minHeight: size),
      padding: const EdgeInsets.symmetric(horizontal: 7),
      decoration: BoxDecoration(
        color: c.lime,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.surfaceRaised, width: 2),
      ),
      alignment: Alignment.center,
      child: Text('$count', style: TextStyle(fontFamily: AbyText.family, fontWeight: FontWeight.w900, fontSize: 14, color: c.onLime)),
    );
  }
}

/// Grid view: one tap adds one item. 4:3 photo, name, size (or stock) and price.
class AbyProductTile extends StatelessWidget {
  const AbyProductTile({
    super.key,
    required this.name,
    required this.price,
    this.detail,
    this.left,
    this.count = 0,
    this.tone = AbyTone.midnight,
    this.image,
    this.icon,
    this.onTap,
  });

  final String name;
  final num price;
  final String? detail;
  /// Units left; pass only when the product is low. 0 shows "Out of stock".
  final int? left;
  final int count;
  final AbyTone tone;
  final ImageProvider? image;
  final String? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    final stock = _stockText(left);
    final out = left == 0;
    return Semantics(
      button: true,
      label: '$name, ${abyMoney(price)}${stock != null ? ', $stock' : ''}${count > 0 ? ', $count in cart' : ''}',
      excludeSemantics: true,
      child: Material(
        color: c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(color: count > 0 ? c.primary : c.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AbySpace.s2),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(children: [
                  Positioned.fill(child: AbyProductThumb(image: image, icon: icon, tone: tone, dimmed: out)),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(color: tone.dot(c), shape: BoxShape.circle, border: Border.all(color: c.surfaceRaised, width: 2)),
                    ),
                  ),
                  if (count > 0) Positioned(top: 6, right: 6, child: _CountBadge(count)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(AbySpace.s1, AbySpace.s2, AbySpace.s1, AbySpace.s1),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: AbyText.tile.copyWith(fontSize: 16, height: 21 / 16, color: out ? c.inkMuted : c.ink)),
                  if (stock != null)
                    Text(stock, style: AbyText.caption.copyWith(fontWeight: FontWeight.w700, color: c.warning))
                  else if (detail != null)
                    Text(detail!, style: AbyText.caption.copyWith(color: c.inkMuted)),
                  const SizedBox(height: AbySpace.s1),
                  Text(abyMoney(price), style: AbyText.price.copyWith(color: out ? c.inkMuted : c.ink)),
                ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

/// List view: the same product as a row. Same props and tap behaviour as [AbyProductTile].
class AbyProductRow extends StatelessWidget {
  const AbyProductRow({
    super.key,
    required this.name,
    required this.price,
    this.detail,
    this.left,
    this.count = 0,
    this.tone = AbyTone.midnight,
    this.image,
    this.icon,
    this.onTap,
  });

  final String name;
  final num price;
  final String? detail;
  final int? left;
  final int count;
  final AbyTone tone;
  final ImageProvider? image;
  final String? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    final stock = _stockText(left);
    final out = left == 0;
    return Semantics(
      button: true,
      label: '$name, ${abyMoney(price)}${stock != null ? ', $stock' : ''}${count > 0 ? ', $count in cart' : ''}',
      excludeSemantics: true,
      child: Material(
        color: c.surfaceRaised,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AbyRadius.md),
          side: BorderSide(color: count > 0 ? c.primary : c.line, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AbySpace.s2, AbySpace.s2, AbySpace.s3, AbySpace.s2),
              child: Row(children: [
                SizedBox.square(
                  dimension: AbySize.thumbRow,
                  child: AbyProductThumb(image: image, icon: icon, tone: tone, iconSize: 24, dimmed: out),
                ),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Row(children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: tone.dot(c), shape: BoxShape.circle)),
                      const SizedBox(width: AbySpace.s2),
                      Flexible(
                        child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: AbyText.tile.copyWith(fontSize: 16, height: 21 / 16, color: out ? c.inkMuted : c.ink)),
                      ),
                    ]),
                    if (stock != null)
                      Text(stock, style: AbyText.caption.copyWith(fontWeight: FontWeight.w700, color: c.warning))
                    else if (detail != null)
                      Text(detail!, style: AbyText.caption.copyWith(color: c.inkMuted)),
                  ]),
                ),
                const SizedBox(width: AbySpace.s3),
                Text(abyMoney(price), style: AbyText.price.copyWith(color: out ? c.inkMuted : c.ink)),
                const SizedBox(width: AbySpace.s3),
                if (count > 0)
                  SizedBox.square(dimension: 32, child: _CountBadge(count, size: 32))
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: c.lineStrong, width: 1.5)),
                    alignment: Alignment.center,
                    child: AbyIcon(AbyIcons.plus, size: 20, color: c.inkMuted),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

enum AbyProductView { grid, list }

/// Switches the product area between grid and list. Remember the choice per device.
class AbyViewToggle extends StatelessWidget {
  const AbyViewToggle({super.key, required this.value, required this.onChanged});
  final AbyProductView value;
  final ValueChanged<AbyProductView> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    Widget opt(AbyProductView v, String icon, String label) {
      final on = v == value;
      return Semantics(
        selected: on,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Material(
          color: on ? c.surfaceRaised : Colors.transparent,
          elevation: on ? 1 : 0,
          shadowColor: Colors.black26,
          borderRadius: BorderRadius.circular(11),
          child: InkWell(
            borderRadius: BorderRadius.circular(11),
            onTap: () => onChanged(v),
            child: SizedBox(
              width: AbySize.tapMin,
              height: 42,
              child: Center(child: AbyIcon(icon, size: 22, color: on ? c.ink : c.inkMuted)),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: c.surfaceSunken,
        borderRadius: BorderRadius.circular(AbyRadius.md),
        border: Border.all(color: c.line),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        opt(AbyProductView.grid, AbyIcons.layoutGrid, 'Grid view'),
        const SizedBox(width: 2),
        opt(AbyProductView.list, AbyIcons.list, 'List view'),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Checkout
// ---------------------------------------------------------------------------

enum AbyPayMethod { cash, momo, credit, card }

extension AbyPayMethodLabel on AbyPayMethod {
  String get label => switch (this) {
        AbyPayMethod.cash => 'Cash',
        AbyPayMethod.momo => 'Mobile money',
        AbyPayMethod.credit => 'Credit (book)',
        AbyPayMethod.card => 'Card',
      };
  String get icon => switch (this) {
        AbyPayMethod.cash => AbyIcons.banknote,
        AbyPayMethod.momo => AbyIcons.smartphone,
        AbyPayMethod.credit => AbyIcons.bookOpen,
        AbyPayMethod.card => AbyIcons.creditCard,
      };
}

/// A payment method chip. Show the methods in a row; one is always selected.
class AbyPaymentChip extends StatelessWidget {
  const AbyPaymentChip({super.key, required this.method, required this.selected, required this.onTap});
  final AbyPayMethod method;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: selected ? c.blueSoft : c.surfaceRaised,
        shape: StadiumBorder(side: BorderSide(color: selected ? c.blue : c.lineStrong, width: 1.5)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Container(
            height: AbySize.tapPos,
            padding: const EdgeInsets.fromLTRB(AbySpace.s4, 0, AbySpace.s6, 0),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              AbyIcon(selected ? AbyIcons.check : method.icon, size: 20, color: selected ? c.blue : c.inkMuted),
              const SizedBox(width: AbySpace.s2),
              Text(method.label, style: TextStyle(fontFamily: AbyText.family, fontSize: 16, fontWeight: FontWeight.w700, color: c.ink)),
            ]),
          ),
        ),
      ),
    );
  }
}

/// The panel shown the moment a sale is saved. For cash, the change due is the biggest thing on screen.
class AbySaleComplete extends StatelessWidget {
  const AbySaleComplete({
    super.key,
    required this.total,
    this.method,
    this.change,
    required this.onNewSale,
    this.onPrint,
    this.onSend,
  });

  final num total;
  final String? method;
  final num? change;
  final VoidCallback onNewSale;
  final VoidCallback? onPrint;
  final VoidCallback? onSend;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    final ghost = OutlinedButton.styleFrom(
      foregroundColor: c.onMidnight,
      backgroundColor: Colors.transparent,
      side: BorderSide(color: c.lineStrong, width: 1.5),
      minimumSize: const Size.fromHeight(AbySize.tapPos),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AbyRadius.md)),
      textStyle: const TextStyle(fontFamily: AbyText.family, fontSize: 16, fontWeight: FontWeight.w700),
    );
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.fromLTRB(AbySpace.s6, AbySpace.s8, AbySpace.s6, AbySpace.s6),
        decoration: BoxDecoration(
          color: c.midnight,
          borderRadius: BorderRadius.circular(AbyRadius.lg),
          border: Border.all(color: c.line),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const _DrawnCheck(),
          const SizedBox(height: AbySpace.s4),
          Text('Sale complete', style: TextStyle(fontFamily: AbyText.family, fontSize: 24, fontWeight: FontWeight.w800, color: c.onMidnight)),
          Text('${abyMoney(total)}${method != null ? ' · $method' : ''}',
              style: TextStyle(fontFamily: AbyText.family, fontSize: 16, color: c.onMidnight.withValues(alpha: 0.8))),
          if (change != null && change! > 0) ...[
            const SizedBox(height: AbySpace.s6),
            Text('CHANGE', style: AbyText.label.copyWith(color: c.onMidnight.withValues(alpha: 0.8))),
            Text(abyMoney(change!),
                style: AbyText.total.copyWith(fontSize: 52, height: 56 / 52, color: c.onMidnight)),
          ],
          const SizedBox(height: AbySpace.s6),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: c.onMidnight,
                foregroundColor: c.midnight,
                minimumSize: const Size.fromHeight(AbySize.tapPos),
                textStyle: const TextStyle(fontFamily: AbyText.family, fontSize: 18, fontWeight: FontWeight.w800),
              ),
              onPressed: onNewSale,
              child: const Text('New sale'),
            ),
          ),
          const SizedBox(height: AbySpace.s3),
          Row(children: [
            Expanded(
              child: OutlinedButton.icon(
                style: ghost,
                onPressed: onPrint,
                icon: AbyIcon(AbyIcons.printer, size: 20, color: c.onMidnight),
                label: const Text('Print receipt'),
              ),
            ),
            const SizedBox(width: AbySpace.s3),
            Expanded(
              child: OutlinedButton.icon(
                style: ghost,
                onPressed: onSend,
                icon: AbyIcon(AbyIcons.send, size: 20, color: c.onMidnight),
                label: const Text('Send receipt'),
              ),
            ),
          ]),
        ]),
      ),
    );
  }
}

/// The lime check that draws once in 300 ms (instantly with reduced motion).
class _DrawnCheck extends StatelessWidget {
  const _DrawnCheck();

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    final reduce = MediaQuery.of(context).disableAnimations;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, t, _) => CustomPaint(size: const Size.square(56), painter: _CheckPainter(t, c.lime, c.onLime)),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter(this.t, this.fill, this.ink);
  final double t;
  final Color fill;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 48;
    canvas.drawCircle(Offset(24 * s, 24 * s), 24 * s, Paint()..color = fill);
    final path = Path()
      ..moveTo(14 * s, 24.5 * s)
      ..lineTo(21 * s, 31.5 * s)
      ..lineTo(34 * s, 17.5 * s);
    final metric = path.computeMetrics().first;
    canvas.drawPath(
      metric.extractPath(0, metric.length * t),
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5 * s
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t;
}

// ---------------------------------------------------------------------------
// Notices and confirmations
// ---------------------------------------------------------------------------

enum AbyBannerTone { offline, info, success, warning, danger }

/// A notice across the top of a screen or panel. Offline is quiet; danger only when money or data is at risk.
class AbyBanner extends StatelessWidget {
  const AbyBanner({super.key, required this.tone, required this.message, this.title, this.action, this.onAction, this.onDismiss});
  final AbyBannerTone tone;
  final String message;
  final String? title;
  final String? action;
  final VoidCallback? onAction;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    final (Color bg, Color? border, Color accent, String? icon) = switch (tone) {
      AbyBannerTone.offline => (c.surfaceRaised, c.line, c.lime, null),
      AbyBannerTone.info => (c.blueSoft, null, c.blue, AbyIcons.info),
      AbyBannerTone.success => (c.limeSoft, null, c.limeInk, AbyIcons.circleCheck),
      AbyBannerTone.warning => (c.warningSoft, null, c.warning, AbyIcons.triangleAlert),
      AbyBannerTone.danger => (c.dangerSoft, c.danger, c.danger, AbyIcons.circleAlert),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s3),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AbyRadius.md),
          border: border != null ? Border.all(color: border) : null,
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: icon == null
                ? Container(
                    margin: const EdgeInsets.only(top: 4),
                    width: AbySize.dot,
                    height: AbySize.dot,
                    decoration: BoxDecoration(color: accent, shape: BoxShape.circle, border: Border.all(color: c.limeInk, width: 1.5)),
                  )
                : AbyIcon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: AbySpace.s3),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (title != null) Text(title!, style: AbyText.body.copyWith(fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w700, color: c.ink)),
              Text(message, style: AbyText.body.copyWith(fontSize: 15, height: 22 / 15, color: c.ink)),
            ]),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                foregroundColor: c.ink,
                textStyle: const TextStyle(fontFamily: AbyText.family, fontWeight: FontWeight.w800, fontSize: 15, decoration: TextDecoration.underline),
              ),
              child: Text(action!),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: AbyIcon(AbyIcons.x, size: 20, color: c.inkMuted),
            ),
        ]),
      ),
    );
  }
}

/// What a screen or panel shows when there is nothing in it.
class AbyEmptyState extends StatelessWidget {
  const AbyEmptyState({super.key, required this.title, this.message, this.icon, this.action, this.onAction});
  final String title;
  final String? message;
  /// Names what's empty, e.g. [AbyIcons.shoppingBasket] for the cart.
  final String? icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s6),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: c.surfaceSunken, shape: BoxShape.circle),
              alignment: Alignment.center,
              child: AbyIcon(icon!, size: 28, color: c.inkMuted),
            ),
            const SizedBox(height: AbySpace.s3),
          ],
          Text(title, textAlign: TextAlign.center, style: AbyText.heading.copyWith(color: c.ink)),
          if (message != null) ...[
            const SizedBox(height: AbySpace.s1),
            Text(message!, textAlign: TextAlign.center, style: AbyText.body.copyWith(fontSize: 15, height: 22 / 15, color: c.inkMuted)),
          ],
          if (action != null) ...[
            const SizedBox(height: AbySpace.s3),
            OutlinedButton(
              onPressed: onAction,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              child: Text(action!),
            ),
          ],
        ]),
      ),
    );
  }
}

const _voidReasons = ['Wrong item', 'Customer changed mind', 'Duplicate', 'Other'];

/// Asks before anything that moves money or can't be undone. Returns the chosen reason
/// (or 'confirmed' when no reason is asked), or null if the cashier kept it.
Future<String?> showAbyConfirmSheet(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  bool askReason = false,
}) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => _ConfirmSheet(
      title: title,
      message: message,
      confirmLabel: confirmLabel,
      cancelLabel: cancelLabel,
      askReason: askReason,
    ),
  );
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({required this.title, required this.message, required this.confirmLabel, required this.cancelLabel, required this.askReason});
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final bool askReason;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  String? _reason;

  @override
  Widget build(BuildContext context) {
    final c = _c(context);
    final canConfirm = !widget.askReason || _reason != null;
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.fromLTRB(AbySpace.s6, AbySpace.s3, AbySpace.s6, AbySpace.s6),
          decoration: BoxDecoration(
            color: c.surfaceRaised,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AbyRadius.lg)),
          ),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AbySpace.s4),
                  decoration: BoxDecoration(color: c.lineStrong, borderRadius: BorderRadius.circular(999)),
                ),
              ),
              Text(widget.title, style: TextStyle(fontFamily: AbyText.family, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w800, color: c.ink)),
              const SizedBox(height: AbySpace.s2),
              Text(widget.message, style: AbyText.body.copyWith(color: c.inkMuted)),
              if (widget.askReason) ...[
                const SizedBox(height: AbySpace.s4),
                Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: [
                  for (final r in _voidReasons)
                    ChoiceChip(
                      label: Text(r),
                      selected: _reason == r,
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _reason = r),
                    ),
                ]),
              ],
              const SizedBox(height: AbySpace.s6),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: c.danger, side: BorderSide(color: c.danger, width: 1.5)),
                    onPressed: canConfirm ? () => Navigator.pop(context, _reason ?? 'confirmed') : null,
                    child: Text(widget.confirmLabel),
                  ),
                ),
                const SizedBox(width: AbySpace.s3),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(widget.cancelLabel),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
