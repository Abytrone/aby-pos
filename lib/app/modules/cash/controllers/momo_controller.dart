import 'package:get/get.dart';

import '../../../data/repositories/momo_repository.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';

/// End-of-day MoMo check: tick each payment against the MoMo statement.
class MomoController extends GetxController {
  final MomoRepository _momo = Get.find();
  final AuthService _auth = Get.find();

  final day = DateTime.now().obs;
  final items = <MomoItem>[].obs;
  final charges = 0.obs;
  final loading = true.obs;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  DateTime get _start => DateTime(day.value.year, day.value.month, day.value.day);

  Future<void> load() async {
    items.assignAll(await _momo.items(_start, _start.add(const Duration(days: 1))));
    charges.value = await _momo.charges(_start);
    loading.value = false;
  }

  Future<void> setDay(DateTime d) async {
    day.value = d;
    await load();
  }

  int get total => items.fold(0, (s, i) => s + i.amount);
  int get ticked => items.where((i) => i.matched == true).fold(0, (s, i) => s + i.amount);
  List<MomoItem> get missing => items.where((i) => i.matched == false).toList();
  int get unchecked => items.where((i) => i.matched == null).length;

  /// What should have reached the MoMo wallet after charges.
  int get net => total - charges.value;

  /// Tap cycles: not checked → ticked → missing → not checked.
  Future<void> cycle(MomoItem item) async {
    final next = switch (item.matched) {
      null => true,
      true => false,
      false => null,
    };
    await _momo.check(item, next, by: _auth.user);
    await load();
  }

  Future<void> setCharges(String text) async {
    final pesewas = text.trim().isEmpty ? 0 : parseMoney(text);
    if (pesewas == null || pesewas < 0) return;
    await _momo.setCharges(_start, pesewas, by: _auth.user);
    await load();
  }
}
