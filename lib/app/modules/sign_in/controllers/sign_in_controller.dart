import 'dart:async';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../data/branch_scope.dart';
import '../../../data/database/app_database.dart';

import '../../../data/repositories/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../core/settings.dart';
import '../../../services/device_service.dart';
import '../../../services/settings_service.dart';
import '../../../ui/l10n.dart';
import '../../../ui/recovery_code_dialog.dart';
import '../widgets/forgot_pin.dart';

/// "Who's on the till?": staff number, then PIN. No names are shown, so
/// nobody standing at the till learns who works here. A badge, or being the
/// only person on this till, skips the number.
class SignInController extends GetxController {
  final StaffRepository _staff = Get.find();
  final AuthService _auth = Get.find();
  final DeviceService _device = Get.find();
  final SettingsService _settings = Get.find();

  /// Known without a number: from a badge, or the only person here.
  final known = Rxn<Staff>();
  final fromBadge = false.obs;
  final loading = true.obs;
  String? _branch;

  /// Changes to give the PIN pad a fresh start (after a badge scan, whose
  /// characters a keyboard scanner also typed into it).
  final padKey = 0.obs;
  final badgeError = RxnString();

  // What a keyboard-mode scanner is typing.
  final _typed = StringBuffer();
  DateTime _lastKey = DateTime(2000);

  String get shopName => _settings.get(AppSettings.shopName);

  @override
  void onInit() {
    super.onInit();
    HardwareKeyboard.instance.addHandler(_onKey);
    _load();
  }

  @override
  void onClose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.onClose();
  }

  /// Collects fast typing ending in Enter: a scanner. Never swallows keys,
  /// so the PIN pad still gets them.
  bool _onKey(KeyEvent e) {
    if (e is! KeyDownEvent) return false;
    final now = DateTime.now();
    if (now.difference(_lastKey) > const Duration(milliseconds: 300)) _typed.clear();
    _lastKey = now;
    if (e.logicalKey == LogicalKeyboardKey.enter || e.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final text = _typed.toString();
      _typed.clear();
      if (text.toUpperCase().startsWith(StaffRepository.badgePrefix)) unawaited(scannedBadge(text));
      return false;
    }
    final ch = e.character;
    if (ch != null && ch.length == 1) _typed.write(ch);
    return false;
  }

  /// A badge scanned (keyboard scanner or camera): picks the person.
  Future<void> scannedBadge(String text) async {
    final person = await _staff.byBadge(text);
    if (person == null) {
      badgeError.value = appL10n().badgeUnknown;
      return;
    }
    badgeError.value = null;
    known.value = person;
    fromBadge.value = true;
    padKey.value++;
  }

  /// Back to typing a staff number after a badge scan.
  void useNumber() {
    fromBadge.value = false;
    known.value = null;
    padKey.value++;
  }

  /// An owner who forgot their PIN gets back in, and sees their new
  /// recovery code before the till opens.
  Future<void> forgotPin() async {
    final code = await showForgotPin();
    if (code == null) return;
    await showRecoveryCode(code);
    await Get.offAllNamed<void>(Routes.shell);
  }

  Future<void> _load() async {
    await _device.ready;
    await _staff.ensureNumbers();
    _branch = await Get.find<AppDatabase>().branchOf(_device.deviceId);
    final here = await _staff.list(atBranch: _branch);
    if (here.length == 1) known.value = here.first;
    loading.value = false;
  }

  /// [number] is null when the person is [known]. Returns an error message,
  /// or null once signed in.
  Future<String?> submit(String? number, String pin) async {
    final l = appL10n();
    final person = known.value;
    final result = number == null && person != null
        ? await _auth.signInAs(person, pin)
        : await _auth.signIn(number ?? '', pin, atBranch: _branch);
    switch (result) {
      case SignInResult.ok:
        await Get.offAllNamed<void>(Routes.shell);
        return null;
      case SignInResult.wrongPin:
        return number == null ? l.pinWrong : l.signInWrong;
      case SignInResult.lockedOut:
        final key = number ?? person?.number ?? person?.id ?? '';
        return l.pinTooManyTries(_auth.lockedFor(key)?.inSeconds ?? AuthService.lockout.inSeconds);
    }
  }
}
