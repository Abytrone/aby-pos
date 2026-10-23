import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// A new UUID v7 (time-ordered, random tail). Generated on the device, so
/// tills that are offline never collide.
String newId() => _uuid.v7();
