import 'package:flutter/material.dart';

import '../../../domain/audit_details.dart';

import '../../../models/audit.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/setting_labels.dart';
import 'activity_details.dart';

/// One audit entry: when, what, who (and who approved). Entries with details
/// open to what was recorded with them.
class ActivityRow extends StatelessWidget {
  const ActivityRow({super.key, required this.entry, this.names = const {}});

  final AuditEntry entry;

  /// Names for ids older entries stored without them.
  final Map<String, String> names;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final who = [
      ?entry.actorName,
      if (entry.approverName != null) l.activityApprovedBy(entry.approverName!),
    ].join('  ·  ');
    var details = describeAuditDetails(entry, names: names);
    var summary = entry.summary;
    if (details case final SettingChange s) {
      final label = settingLabel(l, s.key);
      final before = settingValueText(l, s.key, s.before, names: names);
      final after = settingValueText(l, s.key, s.after, names: names);
      bool short(String t) => t.length <= 32 && !t.contains('\n');
      if (s.hasBefore && short(before) && short(after)) {
        // Says it all on one line; nothing left to open.
        summary = l.activitySettingChangedTo(label, before, after);
        details = null;
      } else {
        summary = l.activitySettingChanged(label);
      }
    }
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
            Text(summary, style: AbyText.body.copyWith(color: c.ink)),
            if (who.isNotEmpty) Text(who, style: AbyText.caption.copyWith(color: c.inkMuted)),
          ]),
        ),
      ],
    );
    if (details == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s3),
        child: header,
      );
    }
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s1),
      childrenPadding: EdgeInsets.fromLTRB(compact ? AbySpace.s4 : 80 + AbySpace.s3, 0, AbySpace.s4, AbySpace.s3),
      shape: const Border(),
      title: header,
      expandedAlignment: Alignment.centerLeft,
      children: [ActivityDetails(entry: entry, details: details, names: names)],
    );
  }
}
