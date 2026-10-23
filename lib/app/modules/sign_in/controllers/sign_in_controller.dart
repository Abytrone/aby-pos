import 'package:get/get.dart';

import '../../../data/repositories/staff_repository.dart';
import '../../../models/staff.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/device_service.dart';

/// "Who's on the till?": pick a name, enter the PIN.
class SignInController extends GetxController {
  final StaffRepository _staff = Get.find();
  final AuthService _auth = Get.find();
  final DeviceService _device = Get.find();

  final staff = <Staff>[].obs;
  final selected = Rxn<Staff>();
  final loading = true.obs;

  String get shopName => _device.shopName;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    await _device.ready;
    staff.assignAll(await _staff.list());
    if (staff.length == 1) selected.value = staff.first;
    loading.value = false;
  }

  void select(Staff person) => selected.value = person;

  /// Returns an error message, or null once signed in.
  Future<String?> submitPin(String pin) async {
    final person = selected.value;
    if (person == null) return 'Pick your name first.';
    switch (await _auth.signIn(person, pin)) {
      case SignInResult.ok:
        await Get.offAllNamed<void>(Routes.till);
        return null;
      case SignInResult.wrongPin:
        return 'Wrong PIN. Try again.';
      case SignInResult.lockedOut:
        final wait = _auth.lockedFor(person.id)?.inSeconds ?? AuthService.lockout.inSeconds;
        return 'Too many tries. Wait $wait seconds.';
    }
  }
}
