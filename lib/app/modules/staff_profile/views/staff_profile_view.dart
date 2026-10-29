import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/repositories/staff_repository.dart';
import '../../../core/validators.dart';
import '../../../models/staff.dart';
import '../../../services/branch_service.dart';
import '../../../services/money.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/dialogs.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/layout.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/section_page.dart';
import '../../activity/widgets/activity_row.dart';
import '../controllers/staff_profile_controller.dart';
import '../widgets/details_form.dart';
import '../widgets/profile_header.dart';
import '../widgets/stat_tile.dart';

class StaffProfileView extends GetView<StaffProfileController> {
  const StaffProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.isMe ? l.profileMine : l.profileTitle),
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 64,
      ),
      body: Obx(() {
        final profile = controller.profile.value;
        if (!controller.allowed) return EmptyState(icon: Icons.lock_outline, message: l.profileNotAllowed);
        if (profile == null) return const Center(child: CircularProgressIndicator());
        final header = ProfileHeader(
          profile: profile,
          onEdit: _editDetails,
          onChangePin: _changePin,
          onChangeRole: () => _changeRole(context),
          onToggleActive: () => _toggleActive(context, profile.staff),
        );
        final details = _Details(profile: profile, stats: controller.stats.value);
        if (!context.isWide) {
          return ListView(padding: const EdgeInsets.all(AbySpace.s4), children: [
            header,
            const SizedBox(height: AbySpace.s6),
            details,
          ]);
        }
        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                width: 320,
                child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: header),
              ),
              Expanded(
                child: SingleChildScrollView(padding: const EdgeInsets.all(AbySpace.s4), child: details),
              ),
            ]),
          ),
        );
      }),
    );
  }

  Future<void> _editDetails() async {
    controller.startEditing();
    await Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.profileEdit),
        content: const DetailsForm(),
        actions: [
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          Obx(() => FilledButton(
                onPressed: controller.saving.value
                    ? null
                    : () async {
                        if (await controller.saveDetails()) goBack<void>();
                      },
                child: Text(l.commonSave),
              )),
        ],
      );
    }));
    _flush();
  }

  Future<void> _changePin() async {
    controller.startPinChange();
    await Get.dialog<void>(Builder(builder: (context) {
      final l = context.l10n;
      return AlertDialog(
        title: Text(l.staffChangePin),
        content: const PinForm(),
        actions: [
          OutlinedButton(onPressed: () => goBack<void>(), child: Text(l.commonCancel)),
          FilledButton(
            onPressed: () async {
              if (await controller.savePin()) goBack<void>();
            },
            child: Text(l.commonSave),
          ),
        ],
      );
    }));
    _flush();
  }

  Future<void> _changeRole(BuildContext context) async {
    final l = context.l10n;
    final person = controller.profile.value!.staff;
    final role = await choiceDialog<Role>(
      title: l.staffChangeRoleFor(person.name),
      options: controller.assignableRoles,
      label: (r) => roleName(l, r),
      selected: person.role,
    );
    if (role == null) return;
    await controller.changeRole(role);
    _flush();
  }

  Future<void> _toggleActive(BuildContext context, Staff person) async {
    final l = context.l10n;
    if (person.active) {
      final ok = await confirmDialog(
        title: l.staffDeactivateTitle(person.name),
        message: l.staffDeactivateBody,
        confirmLabel: l.staffDeactivate,
        danger: true,
      );
      if (!ok) return;
    }
    await controller.setActive(!person.active);
    _flush();
  }

  void _flush() {
    final text = controller.message.value;
    if (text == null) return;
    controller.message.value = null;
    showMessage(text);
  }
}

class _Details extends GetView<StaffProfileController> {
  const _Details({required this.profile, required this.stats});

  final StaffProfile profile;
  final StaffStats stats;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    String orNot(String? v) => v == null || v.isEmpty ? l.settingsNotSet : v;
    final now = DateTime.now();

    InfoTile copyable(String title, String? value) => InfoTile(
          title: title,
          value: orNot(value),
          trailing: value == null
              ? null
              : IconButton(
                  tooltip: l.commonCopy,
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    showMessage(l.commonCopied);
                  },
                ),
        );

    String? phone(String? p) => p == null ? null : Validators.formatPhone(p);
    final dob = profile.dateOfBirth;
    final age = dob == null ? null : (now.difference(dob).inDays / 365.25).floor();
    final started = profile.startedOn;
    final months = started == null ? null : ((now.year - started.year) * 12 + now.month - started.month);
    final diff = stats.closeDifference;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Padding(
        padding: const EdgeInsets.only(left: AbySpace.s1, bottom: AbySpace.s2),
        child: Text(l.profilePerformance.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
      ),
      Wrap(spacing: AbySpace.s3, runSpacing: AbySpace.s3, children: [
        StatTile(
          label: l.profileSalesToday,
          value: formatMoney(stats.takingsToday),
          detail: l.profileSalesCount(stats.salesToday),
        ),
        StatTile(
          label: l.profileSales30,
          value: formatMoney(stats.takings30Days),
          detail: l.profileSalesCount(stats.sales30Days),
        ),
        StatTile(label: l.profileAverageSale, value: formatMoney(stats.averageSale30Days)),
        StatTile(
          label: l.profileVoids,
          value: '${stats.voidsAsked}',
          detail: l.profileVoidsApproved(stats.voidsApproved),
        ),
        StatTile(
          label: l.profileCloses,
          value: '${stats.closes}',
          detail: stats.closes == 0
              ? null
              : diff == 0
                  ? l.profileClosesBalanced
                  : diff > 0
                      ? l.profileClosesOver(formatMoney(diff))
                      : l.profileClosesShort(formatMoney(-diff)),
          color: diff < 0 ? c.danger : null,
        ),
      ]),
      const SizedBox(height: AbySpace.s6),
      if (controller.canManage)
        GroupCard(title: l.badgeTitle, children: [
          InfoTile(
            title: profile.badgeCode == null ? l.badgeNone : l.badgeHas,
            subtitle: l.badgeHelp,
            leading: const Icon(Icons.badge_outlined),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              if (profile.badgeCode != null) ...[
                IconButton(
                  tooltip: l.receiptPrint,
                  onPressed: () => controller.showBadge('${StaffRepository.badgePrefix}${profile.badgeCode}'),
                  icon: const Icon(Icons.print_outlined),
                ),
                IconButton(tooltip: l.badgeRemove, onPressed: controller.removeBadge, icon: const Icon(Icons.close)),
              ],
              TextButton(
                onPressed: controller.newBadge,
                child: Text(profile.badgeCode == null ? l.badgeMake : l.badgeNew),
              ),
            ]),
          ),
          if (Get.find<BranchService>().many && !profile.staff.isOwner)
            InfoTile(
              title: l.staffWorksAt,
              subtitle: l.staffWorksAtHelp,
              value: profile.branchId == null ? l.branchAll : Get.find<BranchService>().nameOf(profile.branchId!),
              leading: const Icon(Icons.storefront_outlined),
              onTap: () async {
                final branches = Get.find<BranchService>().branches;
                final pick = await choiceDialog<String>(
                  title: l.staffWorksAt,
                  options: ['', for (final b in branches) b.id],
                  label: (id) => id.isEmpty ? l.branchAll : Get.find<BranchService>().nameOf(id),
                  selected: profile.branchId ?? '',
                );
                if (pick != null) await controller.setBranch(pick.isEmpty ? null : pick);
              },
            ),
          InfoTile(
            title: l.workHours,
            subtitle: l.workHoursHelp,
            value: profile.workStart == null || profile.workEnd == null
                ? l.settingsNotSet
                : '${formatMinutesOfDay(profile.workStart!)} – ${formatMinutesOfDay(profile.workEnd!)}',
            leading: const Icon(Icons.schedule),
            onTap: () async {
              TimeOfDay at(int? m, int fallback) => TimeOfDay(hour: (m ?? fallback) ~/ 60, minute: (m ?? fallback) % 60);
              final start = await showTimePicker(context: context, initialTime: at(profile.workStart, 8 * 60), helpText: l.workStarts);
              if (start == null || !context.mounted) return;
              final end = await showTimePicker(context: context, initialTime: at(profile.workEnd, 17 * 60), helpText: l.workEnds);
              if (end == null) return;
              await controller.setWorkHours(start.hour * 60 + start.minute, end.hour * 60 + end.minute);
            },
          ),
        ]),
      GroupCard(title: l.profileContact, children: [
        copyable(l.profilePhone, phone(profile.phone)),
        copyable(l.profileEmail, profile.email),
        InfoTile(title: l.profileAddress, value: orNot(profile.address)),
      ]),
      GroupCard(title: l.profileEmergency, children: [
        InfoTile(title: l.profileEmergencyName, value: orNot(profile.emergencyName)),
        copyable(l.profilePhone, phone(profile.emergencyPhone)),
      ]),
      GroupCard(title: l.profileIdentityWork, children: [
        InfoTile(
          title: l.profileGhanaCard,
          value: orNot(controller.canManage ? profile.idNumber : profile.maskedIdNumber),
        ),
        InfoTile(
          title: l.profileDateOfBirth,
          value: dob == null ? l.settingsNotSet : '${formatDate(dob)}  ·  ${l.profileAge(age!)}',
        ),
        InfoTile(
          title: l.profileStartedOn,
          value: started == null ? l.settingsNotSet : '${formatDate(started)}  ·  ${l.profileTenure(months!)}',
        ),
        InfoTile(title: l.profileNotes, value: orNot(profile.notes)),
      ]),
      GroupCard(title: l.profileSecurity, children: [
        InfoTile(
          title: l.profileLastSignIn,
          value: stats.lastSignIn == null ? l.statusNever : relativeTime(l, stats.lastSignIn!),
        ),
        InfoTile(
          title: l.profileWrongPins,
          value: '${stats.failedSignIns30Days}',
          subtitle: l.rangeMonth,
        ),
      ]),
      if (controller.canSeeActivity)
        Obx(() {
          final entries = controller.activity.toList();
          return GroupCard(
            title: l.profileRecentActivity,
            children: entries.isEmpty
                ? [InfoTile(title: l.activityEmpty)]
                : [for (final e in entries) ActivityRow(entry: e)],
          );
        }),
    ]);
  }
}
