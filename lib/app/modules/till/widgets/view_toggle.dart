import 'package:flutter/material.dart';

import '../../../theme/aby_colors.dart';
import '../../../theme/aby_icons.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';

enum ProductView { grid, list }

/// Switches the product area between the grid and the list. It sits at the
/// right end of the category header; the choice is remembered per device.
class ViewToggle extends StatelessWidget {
  const ViewToggle({super.key, required this.value, required this.onChanged});

  final ProductView value;
  final ValueChanged<ProductView> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    Widget option(ProductView v, String icon, String label) {
      final on = v == value;
      return Semantics(
        selected: on,
        button: true,
        label: label,
        excludeSemantics: true,
        child: Tooltip(
          message: label,
          child: Material(
            color: on ? c.surfaceRaised : Colors.transparent,
            elevation: on ? 1 : 0,
            shadowColor: Colors.black26,
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              borderRadius: BorderRadius.circular(11),
              canRequestFocus: false,
              onTap: on ? null : () => onChanged(v),
              child: SizedBox(
                width: AbySize.tapMin,
                height: 42,
                child: Center(child: AbyIcon(icon, size: 22, color: on ? c.ink : c.inkMuted)),
              ),
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
        option(ProductView.grid, AbyIcons.layoutGrid, l.tillViewGrid),
        const SizedBox(width: 2),
        option(ProductView.list, AbyIcons.list, l.tillViewList),
      ]),
    );
  }
}
