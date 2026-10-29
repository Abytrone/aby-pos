import 'dart:async';

import 'package:get/get.dart';

import '../data/repositories/branch_repository.dart';
import '../models/branch.dart';

/// The shop's branches as the screens see them (MDV-02): the list, this
/// device's branch, and which branch the reports and dashboard look at.
/// With one branch nothing about branches is shown.
class BranchService extends GetxService {
  BranchService(this._repo);

  final BranchRepository _repo;

  final branches = <Branch>[].obs;
  final current = Rxn<Branch>();

  /// The branch the reports look at; null for every branch together.
  final viewing = RxnString();

  StreamSubscription<void>? _sub;

  /// More than one open branch: branch choices are shown.
  bool get many => branches.length > 1;

  String nameOf(String id) => branches.firstWhereOrNull((b) => b.id == id)?.name ?? id;

  @override
  void onInit() {
    super.onInit();
    // The first load waits for the device ID (start-up calls it).
    _sub = _repo.watch().listen((_) => unawaited(load()));
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> load() async {
    branches.assignAll(await _repo.list());
    current.value = await _repo.current();
    final v = viewing.value;
    if (v != null && !branches.any((b) => b.id == v)) viewing.value = null;
  }
}
