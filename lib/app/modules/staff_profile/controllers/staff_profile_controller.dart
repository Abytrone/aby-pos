import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/business_day.dart';
import '../../../core/permissions.dart';
import '../../../core/settings.dart';
import '../../../core/validators.dart';
import '../../../data/repositories/audit_repository.dart';
import '../../../data/repositories/role_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../data/repositories/staff_stats_repository.dart';
import '../../../domain/receipt/receipt_builder.dart';
import '../../../models/audit.dart';
import '../../../models/staff.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import '../../../services/pin_hasher.dart';
import '../../../services/settings_service.dart';
import '../../../services/staff_photo_service.dart';
import '../../../ui/l10n.dart';
import '../widgets/badge_dialog.dart';
import '../../../ui/photo_picker.dart';
import '../../staff/controllers/staff_controller.dart';
import '../../activity/controllers/audit_names.dart';

/// One person's profile: details, photo, security, figures and recent
/// activity. Opened with the staff ID as the route argument.
class StaffProfileController extends GetxController {
  final StaffRepository _staff = Get.find();
  final RoleRepository _roles = Get.find();
  final StaffStatsRepository _stats = Get.find();
  final AuditRepository _audit = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();
  final SettingsService _settings = Get.find();
  final StaffPhotoService _photos = Get.find();

  final String staffId = Get.arguments as String;

  final profile = Rxn<StaffProfile>();
  final stats = const StaffStats().obs;
  final activity = <AuditEntry>[].obs;

  /// Names for ids older entries stored without them.
  final activityNames = <String, String>{}.obs;
  final roles = <Role>[].obs;
  final message = RxnString();

  // The details form.
  final nameField = TextEditingController();
  final phoneField = TextEditingController();
  final emailField = TextEditingController();
  final addressField = TextEditingController();
  final emergencyNameField = TextEditingController();
  final emergencyPhoneField = TextEditingController();
  final idField = TextEditingController();
  final notesField = TextEditingController();
  final dateOfBirth = Rxn<DateTime>();
  final startedOn = Rxn<DateTime>();
  final fieldErrors = <String, String>{}.obs;
  final saving = false.obs;

  // The PIN form.
  final currentPinField = TextEditingController();
  final newPinField = TextEditingController();
  final confirmPinField = TextEditingController();
  final pinError = RxnString();

  Staff get me => _auth.user;
  bool get isMe => staffId == me.id;
  bool get canManage => _auth.can(Permission.manageStaff);

  /// Everyone may keep their own contact details and photo up to date.
  bool get canEditContact => canManage || isMe;

  /// Name, Ghana Card, dates and notes: managers only.
  bool get canEditWork => canManage;

  bool get canSeeActivity => canManage || _auth.can(Permission.viewActivityLog) || isMe;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  @override
  void onClose() {
    for (final c in [
      nameField,
      phoneField,
      emailField,
      addressField,
      emergencyNameField,
      emergencyPhoneField,
      idField,
      notesField,
      currentPinField,
      newPinField,
      confirmPinField,
    ]) {
      c.dispose();
    }
    super.onClose();
  }

  /// Other people's profiles need "Manage staff".
  bool get allowed => isMe || canManage;

  Future<void> load() async {
    if (!allowed) return;
    profile.value = await _staff.profile(staffId);
    final day = BusinessDay.containing(DateTime.now(),
        startMinutes: _settings.get(AppSettings.businessDayStart));
    stats.value = await _stats.stats(staffId, todayStart: day.start);
    if (canSeeActivity) {
      activity.assignAll(await _audit.list(actorId: staffId, limit: 25));
      activityNames.addAll(await auditNames(activity, known: activityNames.keys.toSet()));
    }
    if (canManage) roles.assignAll(await _roles.list());
  }

  // ---------------------------------------------------------------------------
  // Details

  void startEditing() {
    final p = profile.value!;
    nameField.text = p.staff.name;
    phoneField.text = p.phone == null ? '' : Validators.formatPhone(p.phone!);
    emailField.text = p.email ?? '';
    addressField.text = p.address ?? '';
    emergencyNameField.text = p.emergencyName ?? '';
    emergencyPhoneField.text = p.emergencyPhone == null ? '' : Validators.formatPhone(p.emergencyPhone!);
    idField.text = p.idNumber ?? '';
    notesField.text = p.notes ?? '';
    dateOfBirth.value = p.dateOfBirth;
    startedOn.value = p.startedOn;
    fieldErrors.clear();
  }

  /// Returns true when saved.
  Future<bool> saveDetails() async {
    if (saving.value) return false;
    final l = appL10n();
    final errors = <String, String>{};
    String? optional(TextEditingController c, String key, String? Function(String) normalise, String error) {
      final text = c.text.trim();
      if (text.isEmpty) return null;
      final value = normalise(text);
      if (value == null) errors[key] = error;
      return value;
    }

    final phone = optional(phoneField, 'phone', Validators.normalisePhone, l.profilePhoneInvalid);
    final email = optional(emailField, 'email', Validators.normaliseEmail, l.profileEmailInvalid);
    final emergencyPhone =
        optional(emergencyPhoneField, 'emergencyPhone', Validators.normalisePhone, l.profilePhoneInvalid);
    final idNumber = optional(idField, 'idNumber', Validators.normaliseGhanaCard, l.profileIdInvalid);
    if (nameField.text.trim().isEmpty) errors['name'] = l.setupNameMissing;
    fieldErrors.assignAll(errors);
    if (errors.isNotEmpty) return false;

    final p = profile.value!;
    final details = StaffDetails(
      name: canEditWork ? nameField.text : p.staff.name,
      phone: phone,
      email: email,
      address: addressField.text,
      emergencyName: emergencyNameField.text,
      emergencyPhone: emergencyPhone,
      idNumber: canEditWork ? idNumber : p.idNumber,
      dateOfBirth: canEditWork ? dateOfBirth.value : p.dateOfBirth,
      startedOn: canEditWork ? startedOn.value : p.startedOn,
      notes: canEditWork ? notesField.text : p.notes,
    );
    saving.value = true;
    try {
      await _staff.updateDetails(staffId, details, by: me);
      message.value = l.profileSaved;
      await _afterChange();
      return true;
    } on StaffException catch (e) {
      fieldErrors['name'] = e.message;
      return false;
    } finally {
      saving.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Photo

  bool get hasPhoto => _photos.photos[staffId] != null;

  Future<bool> get cameraAvailable async => ImagePicker().supportsImageSource(ImageSource.camera);

  Future<void> pickPhoto(ImageSource source) async {
    if (!canEditContact) return;
    final bytes = await pickPhotoBytes(source);
    if (bytes == null) return;
    await _photos.set(staffId, bytes, by: me);
    message.value = appL10n().profilePhotoSaved;
    await _afterChange(reloadPeople: false);
  }

  Future<void> removePhoto() async {
    if (!canEditContact) return;
    await _photos.set(staffId, null, by: me);
    await _afterChange(reloadPeople: false);
  }

  // ---------------------------------------------------------------------------
  // PIN, role and status

  void startPinChange() {
    currentPinField.clear();
    newPinField.clear();
    confirmPinField.clear();
    pinError.value = null;
  }

  /// Your own PIN needs the current one; a manager sets anyone else's.
  Future<bool> savePin() async {
    final l = appL10n();
    if (!PinHasher.isValidPin(newPinField.text)) {
      pinError.value = l.pinMustBeDigits(PinHasher.pinLength);
      return false;
    }
    if (newPinField.text != confirmPinField.text) {
      pinError.value = l.pinMismatch;
      return false;
    }
    try {
      if (isMe) {
        await _staff.changeOwnPin(me, currentPinField.text, newPinField.text);
      } else {
        final auth = await _permissions.authorize(Permission.manageStaff, reason: l.profilePinReason);
        if (auth == null) return false;
        await _staff.changePin(staffId, newPinField.text, by: auth.authority);
      }
      message.value = l.staffPinChanged(profile.value!.staff.name);
      await _afterChange(reloadPeople: false);
      return true;
    } on StaffException catch (e) {
      pinError.value = e.message;
      return false;
    }
  }

  /// Only owners can make someone an owner.
  List<Role> get assignableRoles => [
        for (final r in roles)
          if (!r.isOwner || me.isOwner) r,
      ];

  Future<void> changeRole(Role role) => _run(() async {
        await _staff.changeRole(staffId, role.id, by: me);
        message.value = appL10n().staffRoleChanged(profile.value!.staff.name);
      });

  Future<void> setActive(bool active) => _run(() async {
        final l = appL10n();
        if (isMe && !active) throw StaffException(l.staffCantDeactivateSelf);
        await _staff.setActive(staffId, active: active, by: me);
        final name = profile.value!.staff.name;
        message.value = active ? l.staffReactivated(name) : l.staffDeactivated(name);
      });

  /// A new sign-in badge, printed on the receipt printer or shared as a PDF.
  Future<void> newBadge() => _run(() async {
        final code = await _staff.newBadge(staffId, by: me);
        await _afterChange();
        await showBadge(code);
      });

  Future<void> removeBadge() => _run(() async {
        await _staff.removeBadge(staffId, by: me);
        message.value = appL10n().badgeRemoved;
      });

  /// The badge as a card to print or send.
  Future<void> showBadge(String code) async {
    final p = profile.value!;
    final doc = ReceiptBuilder.badge(name: p.staff.name, shopName: _settings.get(AppSettings.shopName), code: code);
    await showBadgeDialog(doc, p.staff.name);
  }

  Future<void> setBranch(String? branchId) => _run(() async {
        await _staff.setBranch(staffId, branchId, by: me);
        message.value = appL10n().settingsSaved;
      });

  Future<void> setWorkHours(int? start, int? end) => _run(() async {
        await _staff.setWorkHours(staffId, start: start, end: end, by: me);
        message.value = appL10n().settingsSaved;
      });

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      await _afterChange();
    } on StaffException catch (e) {
      message.value = e.message;
    }
  }

  /// Keep the people list, and the signed-in person's own record, current.
  Future<void> _afterChange({bool reloadPeople = true}) async {
    await load();
    if (reloadPeople && Get.isRegistered<StaffController>()) await Get.find<StaffController>().load();
    if (isMe) _auth.currentUser.value = profile.value?.staff;
  }
}
