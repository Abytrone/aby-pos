import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../data/repositories/catalog_repository.dart';

/// Puts scheduled prices into effect when their day starts: at start-up
/// and then every hour. Works offline; nothing to sync for it to run.
class PriceScheduler extends GetxService {
  PriceScheduler(this._catalog);

  final CatalogRepository _catalog;
  Timer? _timer;

  @override
  void onInit() {
    super.onInit();
    _timer = Timer.periodic(const Duration(hours: 1), (_) => run());
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  Future<int> run() async {
    try {
      return await _catalog.applyDuePrices();
    } catch (e) {
      debugPrint('Scheduled prices failed: $e');
      return 0;
    }
  }
}
