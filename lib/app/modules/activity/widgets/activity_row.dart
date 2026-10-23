import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../models/audit.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/permission_labels.dart';

/// One audit entry: when, what, who (and who approved). Changes expand to
/// show before and after.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry});

  final AuditEntry entry;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final who = [
      ?entry.actorName,
      if (entry.approverName != null) l.activityApprovedBy(entry.approverName!),
    ].join('  ·  ');
    final header = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 64,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(formatTime(entry.at), style: AbyText.receiptStrong.copyWith(color: c.ink)),
            Text(formatDate(entry.at), style: AbyText.caption.copyWith(color: c.inkMuted, fontSize: 11)),
          ]),
        ),
        const SizedBox(width: AbySpace.s3),
        Container(
          width: 4,
          height: 36,
          margin: const EdgeInsets.only(right: AbySpace.s3, top: 2),
          decoration: BoxDecoration(
            color: entry.action.isSensitive ? c.warning : c.line,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(auditActionLabel(l, entry.action),
                style: AbyText.label.copyWith(color: entry.action.isSensitive ? c.warning : c.inkMuted)),
            Text(entry.summary, style: AbyText.body.copyWith(color: c.ink)),
            if (who.isNotEmpty) Text(who, style: AbyText.caption.copyWith(color: c.inkMuted)),
          ]),
        ),
      ],
    );
    final details = entry.details;
    if (details == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s3),
        child: header,
      );
    }
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s1),
      childrenPadding: const EdgeInsets.fromLTRB(80 + AbySpace.s3, 0, AbySpace.s4, AbySpace.s3),
      shape: const Border(),
      title: header,
      expandedAlignment: Alignment.centerLeft,
      children: [
        for (final key in ['before', 'after'])
          if (details.containsKey(key))
            Padding(
              padding: const EdgeInsets.only(bottom: AbySpace.s2),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(
                  width: 64,
                  child: Text(key == 'before' ? l.activityBefore : l.activityAfter,
                      style: AbyText.caption.copyWith(color: c.inkMuted)),
                ),
                Expanded(
                  child: SelectableText(
                    _pretty(details[key]),
                    style: AbyText.receipt.copyWith(color: c.ink),
                  ),
                ),
              ]),
            ),
      ],
    );
  }

  static String _pretty(Object? value) =>
      value is String ? value : const JsonEncoder.withIndent('  ').convert(value);
}
