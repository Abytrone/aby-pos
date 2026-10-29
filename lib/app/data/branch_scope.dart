import 'package:drift/drift.dart';

import 'database/app_database.dart';

/// Rows that belong to one branch (MDV-02): a row belongs to the branch of
/// the device that wrote it, and devices not placed anywhere are in the
/// main branch. So the main branch is "every device except those placed
/// elsewhere", and another branch is "the devices placed in it".
class BranchFilter {
  const BranchFilter._(this.devices, {required this.exclude});

  /// Every branch: no filter.
  static const all = BranchFilter._([], exclude: true);

  final List<String> devices;
  final bool exclude;

  /// A condition on a device ID column in SQL; pass [variables] with it.
  String sql(String column) => devices.isEmpty
      ? (exclude ? '1 = 1' : '0 = 1')
      : '$column ${exclude ? 'NOT IN' : 'IN'} (${List.filled(devices.length, '?').join(', ')})';

  List<Variable<Object>> get variables => [for (final d in devices) Variable.withString(d)];

  /// The same condition for the query builder.
  Expression<bool> on(GeneratedColumn<String> column) => devices.isEmpty
      ? Constant(exclude)
      : exclude
          ? column.isNotIn(devices)
          : column.isIn(devices);
}

extension BranchScope on AppDatabase {
  /// The branch [deviceId] is in.
  Future<String> branchOf(String deviceId) async {
    final row = await (select(deviceBranches)..where((d) => d.id.equals(deviceId) & d.deletedAt.isNull())).getSingleOrNull();
    return row?.branchId ?? mainBranchId;
  }

  Future<BranchFilter> branchFilter(String branchId) async {
    final placed = await (select(deviceBranches)..where((d) => d.deletedAt.isNull())).get();
    return branchId == mainBranchId
        ? BranchFilter._([for (final d in placed) if (d.branchId != mainBranchId) d.id], exclude: true)
        : BranchFilter._([for (final d in placed) if (d.branchId == branchId) d.id], exclude: false);
  }

  /// Rows of the branch [deviceId] is in.
  Future<BranchFilter> branchFilterFor(String deviceId) async => branchFilter(await branchOf(deviceId));
}
