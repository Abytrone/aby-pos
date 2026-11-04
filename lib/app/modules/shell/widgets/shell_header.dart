import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/repositories/time_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/clock_service.dart';
import '../../../services/printing/print_service.dart';
import '../../../services/status_service.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_mark.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/layout.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/staff_avatar.dart';
import '../../../ui/status_dot.dart';
import '../controllers/shell_controller.dart';
import '../../staff/widgets/correct_hours_dialog.dart';
import 'command_bar.dart';
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
          IconButton(
            tooltip: context.l10n.commandTooltip,
            onPressed: showCommandBar,
            icon: const Icon(Icons.search),
          ),
          // "Reprint last" is one tap from anywhere.
          Obx(() {
            final print = Get.find<PrintService>();
            if (!print.hasPrinter) return const SizedBox.shrink();
            final l = context.l10n;
            return IconButton(
              tooltip: l.printReprintLast,
              onPressed: () async {
                final ok = await print.reprintLast();
                showMessage(ok ? l.printSent : l.printNothingYet, tone: ok ? MessageTone.success : MessageTone.info);
              },
              icon: Badge(
                isLabelVisible: print.queue.isNotEmpty,
                label: Text('${print.queue.length}'),
                child: const Icon(Icons.print_outlined),
              ),
            );
          }),
          _StatusChip(status: controller.status, compact: narrow),
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

/// The header's safety dot. It says what is happening now: pulsing while a
/// backup is written, "Backed up" for a moment after, and otherwise the one
/// thing that needs someone ("Copy a backup off"), not a vague warning.
class _StatusChip extends StatefulWidget {
  const _StatusChip({required this.status, required this.compact});

  final StatusService status;
  final bool compact;

  @override
  State<_StatusChip> createState() => _StatusChipState();
}

class _StatusChipState extends State<_StatusChip> {
  static const _flashFor = Duration(seconds: 4);

  Worker? _worker;
  Timer? _flashTimer;
  bool _justBackedUp = false;

  @override
  void initState() {
    super.initState();
    // On a finished backup only: a failed one has nothing to celebrate, and
    // reading the last time at start-up is not news.
    _worker = ever<DateTime?>(widget.status.lastBackupAt, (at) {
      if (at == null || !mounted || DateTime.now().difference(at) > const Duration(minutes: 1)) return;
      _flashTimer?.cancel();
      setState(() => _justBackedUp = true);
      _flashTimer = Timer(_flashFor, () {
        if (mounted) setState(() => _justBackedUp = false);
      });
    });
  }

  @override
  void dispose() {
    _worker?.dispose();
    _flashTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = Theme.of(context).extension<AbyColors>()!;
    return Obx(() {
      final running = widget.status.backingUp.value;
      final needing = widget.status.needing;
      final level = running || _justBackedUp ? StatusLevel.ok : widget.status.overall;
      final text = running
          ? l.statusBackingUp
          : _justBackedUp
              ? l.statusBackedUp
              : needing.isEmpty
                  ? l.statusAllSafe
                  : needing.length == 1
                      ? statusChipLabel(l, needing.first.item)
                      : l.statusChipMore(statusChipLabel(l, needing.first.item), needing.length - 1);
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
              StatusDot(level: level, pulse: running),
              if (!widget.compact) ...[
                const SizedBox(width: AbySpace.s2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    text,
                    key: ValueKey(text),
                    style: AbyText.caption.copyWith(color: c.ink, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ]),
          ),
        ),
      );
    });
  }
}

enum _UserAction { profile, clock, toggleBreak, switchUser, lock }

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
      final clock = Get.isRegistered<ClockService>() ? Get.find<ClockService>() : null;
      final clocked = clock?.state.value;
      return PopupMenuButton<_UserAction>(
        tooltip: l.userMenu,
        position: PopupMenuPosition.under,
        onSelected: (action) => switch (action) {
          _UserAction.profile => controller.openMyProfile(),
          _UserAction.clock => _clock(clock!, clocked == null),
          _UserAction.toggleBreak => clock!.toggleBreak(),
          _UserAction.switchUser => showQuickSwitch(controller),
          _UserAction.lock => controller.lock(),
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: _UserAction.profile,
            height: AbySize.tapPos,
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(l.profileMine),
              subtitle: user.number == null ? null : Text(l.staffNumberLabel(user.number!)),
            ),
          ),
          if (clock != null) ...[
            PopupMenuItem(
              value: _UserAction.clock,
              height: AbySize.tapPos,
              child: ListTile(
                leading: Icon(clocked == null ? Icons.login : Icons.logout),
                title: Text(clocked == null ? l.clockIn : l.clockOut),
                subtitle: clocked == null
                    ? null
                    : Text([
                        l.clockInSince(formatTime(clocked.since)),
                        if (clocked.missedClockOut()) l.timeMissedClockOut,
                      ].join('  ·  ')),
              ),
            ),
            if (clocked != null)
              PopupMenuItem(
                value: _UserAction.toggleBreak,
                height: AbySize.tapPos,
                child: ListTile(
                  leading: const Icon(Icons.free_breakfast_outlined),
                  title: Text(clocked.onBreak ? l.clockEndBreak : l.clockStartBreak),
                ),
              ),
          ],
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

Future<void> _clock(ClockService clock, bool clockIn) async {
  final l = appL10n();
  try {
    if (clockIn) {
      await clock.clockIn();
      showMessage(l.clockedIn, tone: MessageTone.success);
    } else {
      final clocked = clock.state.value;
      if (clocked != null && clocked.missedClockOut() && clock.allowMissedClockOutEdit) {
        final choice = await choiceDialog<_MissedClockOutChoice>(
          title: l.missedClockOutTitle,
          message: l.missedClockOutBody(formatDateTime(clocked.since)),
          options: _MissedClockOutChoice.values,
          label: (option) => switch (option) {
            _MissedClockOutChoice.clockOutNow => l.clockOut,
            _MissedClockOutChoice.correctTime => l.missedClockOutCorrect,
          },
        );
        if (choice == null) return;
        if (choice == _MissedClockOutChoice.correctTime) {
          final entry = await Get.find<TimeRepository>().currentEntry(Get.find<AuthService>().user.id);
          if (entry == null) {
            await clock.refresh();
            return;
          }
          await showCorrectMissedClockOut(entry);
          return;
        }
      }
      await clock.clockOut();
      showMessage(l.clockedOut, tone: MessageTone.success);
    }
  } on TimeClockException catch (e) {
    showMessage(e.message, tone: MessageTone.error);
  }
}

enum _MissedClockOutChoice { clockOutNow, correctTime }
