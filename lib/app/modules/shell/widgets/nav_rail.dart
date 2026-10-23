import 'package:flutter/material.dart';

import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../controllers/shell_controller.dart';

/// Tablet and desktop navigation: Sell first, then the Manage sections
/// under a divider.
class NavRail extends StatelessWidget {
  const NavRail({
    super.key,
    required this.sections,
    required this.selected,
    required this.onSelect,
  });

  final List<ShellSection> sections;
  final ShellSection selected;
  final ValueChanged<ShellSection> onSelect;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final sell = sections.where((s) => s.workspace == Workspace.sell).toList();
    final manage = sections.where((s) => s.workspace == Workspace.manage).toList();
    return Container(
      width: 92,
      decoration: BoxDecoration(
        color: c.surfaceRaised,
        border: Border(right: BorderSide(color: c.line, width: 1.5)),
      ),
      child: SafeArea(
        right: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: AbySpace.s4),
              const AbyMark(size: 36),
              const SizedBox(height: AbySpace.s4),
              for (final s in sell) _RailItem(section: s, selected: s == selected, onTap: () => onSelect(s)),
              if (manage.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AbySpace.s3, AbySpace.s3, AbySpace.s3, AbySpace.s1),
                  child: Divider(color: c.line, height: 1),
                ),
                Text(l.navManage.toUpperCase(),
                    style: AbyText.label.copyWith(color: c.inkMuted, fontSize: 11)),
                const SizedBox(height: AbySpace.s1),
                for (final s in manage)
                  _RailItem(section: s, selected: s == selected, onTap: () => onSelect(s)),
              ],
              const SizedBox(height: AbySpace.s4),
            ],
          ),
        ),
      ),
    );
  }
}

class _RailItem extends StatelessWidget {
  const _RailItem({required this.section, required this.selected, required this.onTap});

  final ShellSection section;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final label = section.label(context.l10n);
    return Semantics(
      selected: selected,
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 56,
                height: 32,
                decoration: BoxDecoration(
                  color: selected ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  selected ? section.selectedIcon : section.icon,
                  color: selected ? c.onPrimary : c.inkMuted,
                ),
              ),
              const SizedBox(height: AbySpace.s1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? c.ink : c.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
