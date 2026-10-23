import 'enums.dart';

/// Someone who can sign in to the till.
class Staff {
  const Staff({
    required this.id,
    required this.name,
    required this.role,
    this.active = true,
  });

  final String id;
  final String name;
  final StaffRole role;
  final bool active;

  bool get isOwner => role == StaffRole.owner;

  @override
  bool operator ==(Object other) => other is Staff && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
