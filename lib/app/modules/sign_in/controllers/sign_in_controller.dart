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

/// "Who's on the till?": pick a name, enter the PIN.
class SignInController extends GetxController {
  final StaffRepository _staff = Get.find();
  final AuthService _auth = Get.find();
  final DeviceService _device = Get.find();
  final SettingsService _settings = Get.find();

  final staff = <Staff>[].obs;
  final selected = Rxn<Staff>();
  final loading = true.obs;

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
    selected.value = person;
    padKey.value++;
  }

  Future<void> _load() async {
    await _device.ready;
    staff.assignAll(await _staff.list(atBranch: await Get.find<AppDatabase>().branchOf(_device.deviceId)));
    if (staff.length == 1) selected.value = staff.first;
    loading.value = false;
  }

  void select(Staff person) => selected.value = person;

  /// Returns an error message, or null once signed in.
  Future<String?> submitPin(String pin) async {
    final l = appL10n();
    final person = selected.value;
    if (person == null) return l.signInPickName;
    switch (await _auth.signIn(person, pin)) {
      case SignInResult.ok:
        await Get.offAllNamed<void>(Routes.shell);
        return null;
      case SignInResult.wrongPin:
        return l.pinWrong;
      case SignInResult.lockedOut:
        return l.pinTooManyTries(_auth.lockedFor(person.id)?.inSeconds ?? AuthService.lockout.inSeconds);
    }
  }
}
