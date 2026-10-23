import 'package:flutter/material.dart';

import '../theme/aby_colors.dart';
import '../theme/aby_theme.dart';

/// The frame for a section in the shell: a title row with actions, then
/// the content. Sections never build their own Scaffold or app bar.
class SectionPage extends StatelessWidget {
  const SectionPage({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.actions = const [],
    this.bottom,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  /// Under the title, e.g. tabs or a filter bar.
  final Widget? bottom;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AbySpace.s4, AbySpace.s4, AbySpace.s4, AbySpace.s2),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AbySpace.s3,
            runSpacing: AbySpace.s2,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: AbyText.title.copyWith(color: c.ink)),
                  if (subtitle != null)
                    Text(subtitle!, style: AbyText.body.copyWith(color: c.inkMuted)),
                ],
              ),
              if (actions.isNotEmpty)
                Wrap(spacing: AbySpace.s2, runSpacing: AbySpace.s2, children: actions),
            ],
          ),
        ),
        ?bottom,
        Expanded(child: child),
      ],
    );
  }
}

/// A labelled group of rows on a card (settings, details).
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.children, this.title, this.footer});

  final String? title;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Padding(
      padding: const EdgeInsets.only(bottom: AbySpace.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.only(left: AbySpace.s1, bottom: AbySpace.s2),
              child: Text(title!.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
            ),
          Card(
            margin: EdgeInsets.zero,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const Divider(height: 1),
                  children[i],
                ],
              ],
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(left: AbySpace.s1, top: AbySpace.s2),
              child: Text(footer!, style: AbyText.caption.copyWith(color: c.inkMuted)),
            ),
        ],
      ),
    );
  }
}

/// One row in a GroupCard: title, optional detail, value or trailing widget.
class InfoTile extends StatelessWidget {
  const InfoTile({
    super.key,
    required this.title,
    this.subtitle,
    this.value,
    this.leading,
    this.trailing,
    this.onTap,
    this.danger = false,
  });

  final String title;
  final String? subtitle;
  final String? value;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AbySize.tapPos),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s3),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: AbySpace.s3)],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: AbyText.body.copyWith(
                          color: danger ? c.danger : c.ink,
                          fontWeight: FontWeight.w600,
                        )),
                    if (subtitle != null)
                      Text(subtitle!, style: AbyText.caption.copyWith(color: c.inkMuted)),
                  ],
                ),
              ),
              if (value != null) ...[
                const SizedBox(width: AbySpace.s3),
                Flexible(
                  child: Text(value!,
                      textAlign: TextAlign.end,
                      style: AbyText.body.copyWith(color: c.inkMuted)),
                ),
              ],
              if (trailing != null) ...[const SizedBox(width: AbySpace.s2), trailing!]
              else if (onTap != null) ...[
                const SizedBox(width: AbySpace.s1),
                Icon(Icons.chevron_right, color: c.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AbySpace.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: c.lineStrong),
            const SizedBox(height: AbySpace.s3),
            Text(message,
                textAlign: TextAlign.center,
                style: AbyText.body.copyWith(color: c.inkMuted)),
          ],
        ),
      ),
    );
  }
}
