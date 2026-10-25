import 'dart:typed_data';

import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/repositories/safe_repository.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';

/// The safe: its balance, drops in and bank deposits out.
class SafeController extends GetxController {
  final SafeRepository _safe = Get.find();
  final PermissionService _permissions = Get.find();

  final balance = 0.obs;
  final entries = <SafeEntry>[].obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    balance.value = await _safe.balance();
    entries.assignAll(await _safe.entries());
    loading.value = false;
  }

  /// Returns an error to show, or null when done.
  Future<String?> deposit(String amount, {required String bank, String? reference, String? note, Uint8List? slip}) async {
    final l = appL10n();
    final pesewas = parseMoney(amount);
    if (pesewas == null || pesewas <= 0) return l.customerAmountInvalid;
    final auth = await _permissions.authorize(Permission.manageCash, reason: l.bankDepositReason(formatMoney(pesewas)));
    if (auth == null) return null;
    try {
      await _safe.deposit(pesewas, bank: bank, reference: reference, note: note, slip: slip, by: auth.authority);
      await load();
      return null;
    } on SafeException catch (e) {
      return e.message;
    }
  }
}
