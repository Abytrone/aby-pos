import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/staff.dart';
import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../../../ui/permission_labels.dart';
import '../../../ui/staff_avatar.dart';
import '../controllers/staff_profile_controller.dart';
import '../../../ui/dialogs.dart';

/// Photo, name, role and status, with the main actions.
class ProfileHeader extends GetView<StaffProfileController> {
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onChangePin,
    required this.onChangeRole,
    required this.onToggleActive,
  });

  final StaffProfile profile;
  final VoidCallback onEdit;
  final VoidCallback onChangePin;
  final VoidCallback onChangeRole;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final staff = profile.staff;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AbySpace.s6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Stack(clipBehavior: Clip.none, children: [
                StaffAvatar(staff: staff, radius: 56),
                if (controller.canEditContact)
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: IconButton.filled(
                      tooltip: l.profileChangePhoto,
                      onPressed: () => _photoMenu(context),
                      icon: const Icon(Icons.photo_camera_outlined),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: AbySpace.s4),
            Text(staff.name, textAlign: TextAlign.center, style: AbyText.title.copyWith(color: c.ink)),
            const SizedBox(height: AbySpace.s2),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: AbySpace.s2,
              runSpacing: AbySpace.s2,
              children: [
                _Pill(text: roleName(l, staff.role), color: c.blue, background: c.blueSoft),
                if (staff.number != null)
                  _Pill(text: l.staffNumberLabel(staff.number!), color: c.ink, background: c.surfaceSunken),
                staff.active
                    ? _Pill(text: l.profileActive, color: c.success, background: c.successSoft)
                    : _Pill(text: l.profileDeactivated, color: c.danger, background: c.dangerSoft),
              ],
            ),
            const SizedBox(height: AbySpace.s3),
            Text(
              l.profileInAbySince(formatDate(profile.joinedAt)),
              textAlign: TextAlign.center,
              style: AbyText.caption.copyWith(color: c.inkMuted),
            ),
            const SizedBox(height: AbySpace.s6),
            if (controller.canEditContact)
              FilledButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(l.profileEdit),
              ),
            if (controller.isMe || controller.canManage) ...[
              const SizedBox(height: AbySpace.s2),
              OutlinedButton.icon(
                onPressed: onChangePin,
                icon: const Icon(Icons.pin_outlined),
                label: Text(l.staffChangePin),
              ),
            ],
            if (controller.canManage && !controller.isMe && (!staff.isOwner || controller.me.isOwner)) ...[
              const SizedBox(height: AbySpace.s2),
              OutlinedButton.icon(
                onPressed: onChangeRole,
                icon: const Icon(Icons.badge_outlined),
                label: Text(l.staffChangeRole),
              ),
              const SizedBox(height: AbySpace.s2),
              TextButton(
                onPressed: onToggleActive,
                style: staff.active ? TextButton.styleFrom(foregroundColor: c.danger) : null,
                child: Text(staff.active ? l.staffDeactivate : l.staffReactivate),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _photoMenu(BuildContext context) async {
    final l = context.l10n;
    final surface = Theme.of(context).extension<AbyColors>()!.surfaceRaised;
    final camera = await controller.cameraAvailable;
    final hasPhoto = controller.hasPhoto;
    await Get.bottomSheet<void>(
      SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (camera)
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(l.profileTakePhoto),
              onTap: () {
                goBack<void>();
                controller.pickPhoto(ImageSource.camera);
              },
            ),
          ListTile(
            minTileHeight: 56,
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(l.profileChoosePhoto),
            onTap: () {
              goBack<void>();
              controller.pickPhoto(ImageSource.gallery);
            },
          ),
          if (hasPhoto)
            ListTile(
              minTileHeight: 56,
              leading: const Icon(Icons.delete_outline),
              title: Text(l.profileRemovePhoto),
              onTap: () {
                goBack<void>();
                controller.removePhoto();
              },
            ),
        ]),
      ),
      backgroundColor: surface,
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color, required this.background});

  final String text;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: AbySpace.s3, vertical: AbySpace.s1),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
        child: Text(text, style: AbyText.label.copyWith(color: color)),
      );
}
