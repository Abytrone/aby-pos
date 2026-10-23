import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../theme/aby_colors.dart';
import '../../../theme/aby_theme.dart';
import '../../../ui/format.dart';
import '../../../ui/l10n.dart';
import '../controllers/staff_profile_controller.dart';

/// The profile form. Fields only managers may change are read-only for
/// someone editing their own profile.
class DetailsForm extends GetView<StaffProfileController> {
  const DetailsForm({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final work = controller.canEditWork;

    Widget field(
      TextEditingController ctrl,
      String label,
      String key, {
      TextInputType? type,
      bool enabled = true,
      String? helper,
      int maxLines = 1,
      TextCapitalization caps = TextCapitalization.none,
      List<TextInputFormatter>? formatters,
    }) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AbySpace.s3),
          child: Obx(() => TextField(
                controller: ctrl,
                enabled: enabled,
                keyboardType: type,
                maxLines: maxLines,
                textCapitalization: caps,
                inputFormatters: formatters,
                decoration: InputDecoration(
                  labelText: label,
                  helperText: helper,
                  errorText: controller.fieldErrors[key],
                ),
              )),
        );

    Widget date(String label, Rxn<DateTime> value, {required DateTime first, required DateTime last}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AbySpace.s3),
          child: Obx(() => InkWell(
                onTap: !work
                    ? null
                    : () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: value.value ?? last,
                          firstDate: first,
                          lastDate: last,
                        );
                        if (picked != null) value.value = picked;
                      },
                child: InputDecorator(
                  isEmpty: value.value == null,
                  decoration: InputDecoration(
                    labelText: label,
                    enabled: work,
                    suffixIcon: value.value != null && work
                        ? IconButton(
                            tooltip: l.commonClear,
                            icon: const Icon(Icons.close),
                            onPressed: () => value.value = null,
                          )
                        : const Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(value.value == null ? '' : formatDate(value.value!)),
                ),
              )),
        );

    Widget heading(String text) => Padding(
          padding: const EdgeInsets.only(top: AbySpace.s3, bottom: AbySpace.s2),
          child: Text(text.toUpperCase(), style: AbyText.label.copyWith(color: c.inkMuted)),
        );

    final now = DateTime.now();
    return SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            field(controller.nameField, l.staffName, 'name',
                enabled: work, caps: TextCapitalization.words),
            heading(l.profileContact),
            field(controller.phoneField, l.profilePhone, 'phone',
                type: TextInputType.phone, helper: l.profilePhoneHelp),
            field(controller.emailField, l.profileEmail, 'email', type: TextInputType.emailAddress),
            field(controller.addressField, l.profileAddress, 'address',
                maxLines: 2, caps: TextCapitalization.sentences),
            heading(l.profileEmergency),
            field(controller.emergencyNameField, l.profileEmergencyName, 'emergencyName',
                caps: TextCapitalization.words),
            field(controller.emergencyPhoneField, l.profilePhone, 'emergencyPhone', type: TextInputType.phone),
            heading(l.profileIdentityWork),
            if (!work)
              Padding(
                padding: const EdgeInsets.only(bottom: AbySpace.s3),
                child: Text(l.profileManagerOnly, style: AbyText.caption.copyWith(color: c.inkMuted)),
              ),
            field(controller.idField, l.profileGhanaCard, 'idNumber',
                enabled: work,
                helper: l.profileGhanaCardHelp,
                caps: TextCapitalization.characters,
                formatters: [FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\- ]'))]),
            date(l.profileDateOfBirth, controller.dateOfBirth,
                first: DateTime(now.year - 90), last: DateTime(now.year - 14, now.month, now.day)),
            date(l.profileStartedOn, controller.startedOn,
                first: DateTime(now.year - 50), last: now),
            field(controller.notesField, l.profileNotes, 'notes',
                enabled: work, maxLines: 3, caps: TextCapitalization.sentences),
          ],
        ),
      ),
    );
  }
}

/// New PIN twice; your own PIN also needs the current one.
class PinForm extends GetView<StaffProfileController> {
  const PinForm({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).extension<AbyColors>()!;
    final l = context.l10n;
    final digits = [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)];
    Widget pin(TextEditingController ctrl, String label, {bool autofocus = false}) => Padding(
          padding: const EdgeInsets.only(bottom: AbySpace.s3),
          child: TextField(
            controller: ctrl,
            autofocus: autofocus,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: digits,
            decoration: InputDecoration(labelText: label),
          ),
        );
    return SizedBox(
      width: 360,
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (controller.isMe) pin(controller.currentPinField, l.profileCurrentPin, autofocus: true),
        pin(controller.newPinField, l.pinNewLabel, autofocus: !controller.isMe),
        pin(controller.confirmPinField, l.pinAgainLabel),
        Obx(() => Text(controller.pinError.value ?? '', style: AbyText.caption.copyWith(color: c.danger))),
      ]),
    );
  }
}
