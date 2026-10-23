import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../services/status_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/staff_avatar.dart';
import '../../../ui/status_dot.dart';
import '../controllers/shell_controller.dart';
import 'quick_switch.dart';
import 'status_centre.dart';

/// The same header on every section: shop, safety status, sync, and who is
/// signed in.
class ShellHeader extends StatelessWidget {
  const ShellHeader({super.key, required this.controller, required this.showMark});

  final ShellController controller;

  /// On phones there is no rail, so the mark sits here.
  final bool showMark;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final narrow = context.isNarrow;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AbySpace.s4, vertical: AbySpace.s2),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: c.line))),
      child: Row(
        children: [
          if (showMark) ...[const AbyMark(size: 32), const SizedBox(width: AbySpace.s3)],
          Expanded(
            child: narrow
                ? const SizedBox.shrink()
                : Obx(() => Text(
                      controller.shopName,
                      style: AbyText.heading.copyWith(color: c.ink),
                      overflow: TextOverflow.ellipsis,
                    )),
          ),
          Obx(() => _StatusChip(level: controller.status.overall, compact: narrow)),
          const SizedBox(width: AbySpace.s2),
          Obx(() {
            final badge = AbySyncBadge(
              waiting: controller.sync.waitingSales.value,
              offline: !controller.sync.online.value,
            );
            return narrow ? const SizedBox.shrink() : badge;
          }),
          const SizedBox(width: AbySpace.s2),
          _UserChip(controller: controller, compact: narrow),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.level, required this.compact});

  final StatusLevel level;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    final text = switch (level) {
      StatusLevel.ok || StatusLevel.info => l.statusAllSafe,
      StatusLevel.warning => l.statusNeedsAttention,
      StatusLevel.problem => l.statusProblem,
    };
    return Tooltip(
      message: l.statusCentreTitle,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => showStatusCentre(),
        child: Container(
          constraints: const BoxConstraints(minHeight: AbySize.tapMin, minWidth: AbySize.tapMin),
          padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            StatusDot(level: level),
            if (!compact) ...[
              const SizedBox(width: AbySpace.s2),
              Text(text, style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
            ],
          ]),
        ),
      ),
    );
  }
}

enum _UserAction { profile, switchUser, lock }

class _UserChip extends StatelessWidget {
  const _UserChip({required this.controller, required this.compact});

  final ShellController controller;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Obx(() {
      final user = controller.auth.currentUser.value;
      if (user == null) return const SizedBox.shrink();
      return PopupMenuButton<_UserAction>(
        tooltip: l.userMenu,
        position: PopupMenuPosition.under,
        onSelected: (action) => switch (action) {
          _UserAction.profile => controller.openMyProfile(),
          _UserAction.switchUser => showQuickSwitch(controller),
          _UserAction.lock => controller.lock(),
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _UserAction.profile,
            height: AbySize.tapPos,
            child: ListTile(leading: const Icon(Icons.person_outline), title: Text(l.profileMine)),
          ),
          PopupMenuItem(
            value: _UserAction.switchUser,
            height: AbySize.tapPos,
            child: ListTile(leading: const Icon(Icons.swap_horiz), title: Text(l.userSwitch)),
          ),
          PopupMenuItem(
            value: _UserAction.lock,
            height: AbySize.tapPos,
            child: ListTile(leading: const Icon(Icons.lock_outline), title: Text(l.userLock)),
          ),
        ],
        child: Container(
          constraints: const BoxConstraints(minHeight: AbySize.tapMin),
          padding: const EdgeInsets.only(left: 4, right: AbySpace.s3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: c.line, width: 1.5),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            StaffAvatar(staff: user),
            if (!compact) ...[
              const SizedBox(width: AbySpace.s2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(user.name, style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700)),
                  Text(roleName(l, user.role), style: AbyText.caption.copyWith(color: c.inkMuted, fontSize: 11)),
                ],
              ),
            ],
            const SizedBox(width: AbySpace.s1),
            Icon(Icons.expand_more, color: c.inkMuted, size: 18),
          ]),
        ),
      );
    });
  }
}
