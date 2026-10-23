import 'dart:convert';

import 'package:drift/drift.dart';

import '../../core/permissions.dart';
import '../../models/sale.dart';

/// Stores the add-ons on a sale line as a JSON array.
class SoldAddonsConverter extends TypeConverter<List<SoldAddon>, String>
    with JsonTypeConverter2<List<SoldAddon>, String, List<dynamic>> {
  const SoldAddonsConverter();

  @override
  List<SoldAddon> fromSql(String fromDb) => fromJson(jsonDecode(fromDb) as List);

  @override
  String toSql(List<SoldAddon> value) => jsonEncode(toJson(value));

  @override
  List<SoldAddon> fromJson(List<dynamic> json) => json
      .map((e) => SoldAddon.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList();

  @override
  List<dynamic> toJson(List<SoldAddon> value) =>
      value.map((a) => a.toJson()).toList();
}

/// A role's permissions as a JSON array of names. Unknown names (from a newer
/// app version) are ignored rather than failing.
class PermissionSetConverter extends TypeConverter<Set<Permission>, String>
    with JsonTypeConverter2<Set<Permission>, String, List<dynamic>> {
  const PermissionSetConverter();

  @override
  Set<Permission> fromSql(String fromDb) => fromJson(jsonDecode(fromDb) as List);

  @override
  String toSql(Set<Permission> value) => jsonEncode(toJson(value));

  @override
  Set<Permission> fromJson(List<dynamic> json) {
    final byName = {for (final p in Permission.values) p.name: p};
    return {for (final name in json) ?byName[name]};
  }

  @override
  List<dynamic> toJson(Set<Permission> value) =>
      (value.map((p) => p.name).toList()..sort());
}
