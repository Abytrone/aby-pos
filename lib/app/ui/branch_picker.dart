import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/branch_service.dart';
import 'l10n.dart';

/// "All branches" or one branch, for the reports and the dashboard
/// (MDV-02). Nothing is shown while the shop has one branch.
class BranchPicker extends StatelessWidget {
  const BranchPicker({super.key, required this.onChanged});

  /// Called after the choice changes, to reload.
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final service = Get.find<BranchService>();
    return Obx(() {
      if (!service.many) return const SizedBox.shrink();
      final viewing = service.viewing.value;
      return PopupMenuButton<String>(
        tooltip: l.branchPick,
        onSelected: (id) {
          service.viewing.value = id.isEmpty ? null : id;
          onChanged();
        },
        itemBuilder: (_) => [
          CheckedPopupMenuItem(value: '', checked: viewing == null, child: Text(l.branchAll)),
          for (final b in service.branches) CheckedPopupMenuItem(value: b.id, checked: viewing == b.id, child: Text(b.name)),
        ],
        child: Chip(
          avatar: const Icon(Icons.storefront_outlined, size: 18),
          label: Text(viewing == null ? l.branchAll : service.nameOf(viewing)),
        ),
      );
    });
  }
}
