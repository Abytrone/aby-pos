import 'dart:convert';

import 'package:drift/drift.dart';

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
