import 'package:flutter/material.dart';

import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';

/// A 56px selectable chip for POS choices (sizes, toppings, payment methods).
class OptionChip extends StatelessWidget {
  const OptionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.trailing,
    this.leading,
  });

  final String label;
  final String? trailing;
  final Widget? leading;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.blueSoft : c.surfaceRaised,
        shape: StadiumBorder(
          side: BorderSide(
            color: selected ? c.blue : c.lineStrong,
            width: selected ? 2 : 1.5,
          ),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: AbySize.tapPos,
              minWidth: AbySize.tapPos,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AbySpace.s2),
                  ],
                  // Long labels (reasons) wrap rather than overflow.
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AbySpace.s2),
                    Text(
                      trailing!,
                      style: AbyText.caption.copyWith(color: c.inkMuted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
