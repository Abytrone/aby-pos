import 'package:get/get.dart';

import '../../../data/repositories/catalog_repository.dart';
import '../../../data/repositories/role_repository.dart';
import '../../../domain/audit_details.dart';
import '../../../models/audit.dart';
import '../../../ui/l10n.dart';
import '../../../ui/permission_labels.dart';

/// Names for the ids audit entries store (roles, variants, products and
/// categories), looked up once for a whole list.
Future<Map<String, String>> auditNames(
  Iterable<AuditEntry> entries, {
  Set<String> known = const {},
}) async {
  final wanted = {for (final e in entries) ...auditIdsToName(e)}
      .difference(known);
  if (wanted.isEmpty) return {};
  final catalog = Get.find<CatalogRepository>();
  final l = appL10n();
  return {
    for (final r in await Get.find<RoleRepository>().list())
      if (wanted.contains(r.id)) r.id: roleName(l, r),
    ...await catalog.variantLabels(wanted),
    ...await catalog.itemNames(wanted),
  };
}
