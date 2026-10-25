import 'dart:async';

import 'package:drift/drift.dart' show TableUpdateQuery;
import 'package:get/get.dart';

import '../../../core/permissions.dart';
import '../../../data/database/app_database.dart';
import '../../../data/repositories/customer_repository.dart';
import '../../../models/customer.dart';
import '../../../routes/app_routes.dart';
import '../../../services/auth_service.dart';
import '../../../services/permission_service.dart';
import '../../../ui/l10n.dart';

/// Manage → Customers: search by phone or name, and who owes money.
class CustomersController extends GetxController {
  final CustomerRepository _customers = Get.find();
  final AppDatabase _db = Get.find();
  final AuthService _auth = Get.find();
  final PermissionService _permissions = Get.find();

  final customers = <Customer>[].obs;
  final query = ''.obs;
  final owingOnly = false.obs;
  final loading = true.obs;
  final message = RxnString();

  StreamSubscription<void>? _changes;
  Timer? _debounce;

  bool get canManage => _auth.can(Permission.manageCustomers);

  /// Pesewas owed by everyone in the list.
  int get totalOwed => customers.fold(0, (s, c) => s + c.owed);

  @override
  void onInit() {
    super.onInit();
    everAll([query, owingOnly], (_) => _loadSoon());
    _changes = _db
        .tableUpdates(TableUpdateQuery.onAllTables([_db.customers, _db.customerLedger]))
        .listen((_) => _loadSoon());
    load();
  }

  @override
  void onClose() {
    _changes?.cancel();
    _debounce?.cancel();
    super.onClose();
  }

  void _loadSoon() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), load);
  }

  Future<void> load() async {
    customers.assignAll(await _customers.list(query: query.value, owing: owingOnly.value));
    loading.value = false;
  }

  Future<bool> save(CustomerDraft d) async {
    final auth = await _permissions.authorize(Permission.manageCustomers, reason: appL10n().customerEditReason);
    if (auth == null) return false;
    try {
      await _customers.save(d, by: auth.authority);
      message.value = appL10n().settingsSaved;
      return true;
    } on CustomerException catch (e) {
      message.value = e.message;
      return false;
    }
  }

  void open(Customer c) => Get.toNamed<void>(Routes.customer, arguments: c.id);
}
