import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../core/settings.dart';
import '../../../data/repositories/day_close_repository.dart';
import '../../../data/repositories/parked_order_repository.dart';
import '../../../models/day_close.dart';
import '../../../services/auth_service.dart';
import '../../../services/money.dart';
import '../../../services/permission_service.dart';
import '../../../services/settings_service.dart';

/// Cash-up: compare the counted drawer with what the till expects, then
/// close the period so its sales are locked.
class CloseDayController extends GetxController {
  final DayCloseRepository _closes = Get.find();
  final AuthService _auth = Get.find();

  /// Who opened this screen (and who approved it), from TodayController.
  final Authorization? _authorization = Get.arguments as Authorization?;

  final period = Rxn<OpenPeriod>();
  final history = <DayClose>[].obs;
  final saving = false.obs;
  final error = RxnString();
  final closed = Rxn<DayClose>();

  /// Parked orders older than the warning time (they may be unpaid sales).
  final oldParked = 0.obs;

  final floatField = TextEditingController();
  final countedField = TextEditingController();
  final noteField = TextEditingController();

  final _floatText = ''.obs;
  final _countedText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    floatField.addListener(() => _floatText.value = floatField.text);
    countedField.addListener(() => _countedText.value = countedField.text);
    load();
  }

  @override
  void onClose() {
    floatField.dispose();
    countedField.dispose();
    noteField.dispose();
    super.onClose();
  }

  Future<void> load() async {
    final open = await _closes.openPeriod();
    period.value = open;
    history.assignAll(await _closes.history());
    final hours = Get.find<SettingsService>().get(AppSettings.parkedWarnHours);
    oldParked.value = await Get.find<ParkedOrderRepository>().olderThan(Duration(hours: hours));
    if (floatField.text.isEmpty && open.suggestedFloat > 0) {
      floatField.text = _plain(open.suggestedFloat);
    }
  }

  /// Blank float counts as zero.
  int? get openingFloat =>
      _floatText.value.trim().isEmpty ? 0 : parseMoney(_floatText.value);

  int? get counted => parseMoney(_countedText.value);

  int? get expected {
    final p = period.value;
    final float = openingFloat;
    return p == null || float == null ? null : p.expectedCash(float);
  }

  /// Positive when over, negative when short; null until both are entered.
  int? get difference {
    final e = expected;
    final c = counted;
    return e == null || c == null ? null : c - e;
  }

  bool get canClose =>
      !saving.value && period.value != null && openingFloat != null && counted != null;

  Future<void> closeDay() async {
    if (!canClose) return;
    saving.value = true;
    error.value = null;
    try {
      closed.value = await _closes.closeDay(
        openingFloat: openingFloat!,
        countedCash: counted!,
        closedBy: _authorization?.authority ?? _auth.user,
        note: noteField.text,
      );
      history.assignAll(await _closes.history());
    } catch (_) {
      error.value = 'Could not close the day. Try again.';
    } finally {
      saving.value = false;
    }
  }

  void done() => Get.back<void>();

  static String _plain(int pesewas) =>
      '${pesewas ~/ 100}.${(pesewas % 100).toString().padLeft(2, '0')}';
}
