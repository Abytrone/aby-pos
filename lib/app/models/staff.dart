import '../core/permissions.dart';

/// A set of permissions people can be given.
class Role {
  const Role({
    required this.id,
    required this.name,
    required this.permissions,
    this.builtIn,
    this.maxDiscountPercent = 0,
  });

  final String id;
  final String name;
  final BuiltInRole? builtIn;
  final Set<Permission> permissions;

  /// Highest manual discount allowed without approval.
  final int maxDiscountPercent;

  bool get isOwner => builtIn == BuiltInRole.owner;

  /// Owners can always do everything.
  bool allows(Permission permission) => isOwner || permissions.contains(permission);

  @override
  bool operator ==(Object other) => other is Role && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

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
  final Role role;
  final bool active;

  bool get isOwner => role.isOwner;

  bool can(Permission permission) => active && role.allows(permission);

  /// A manual discount of [percent] is within this person's limit.
  bool canDiscount(int percent) => can(Permission.sell) && (isOwner || role.maxDiscountPercent >= percent);

  @override
  bool operator ==(Object other) => other is Staff && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// Everything about a staff member beyond what sign-in needs.
class StaffProfile {
  const StaffProfile({
    required this.staff,
    required this.joinedAt,
    this.phone,
    this.email,
    this.address,
    this.emergencyName,
    this.emergencyPhone,
    this.idNumber,
    this.dateOfBirth,
    this.startedOn,
    this.notes,
  });

  final Staff staff;

  /// When the record was created in Aby.
  final DateTime joinedAt;
  final String? phone;
  final String? email;
  final String? address;
  final String? emergencyName;
  final String? emergencyPhone;

  /// Ghana Card number.
  final String? idNumber;
  final DateTime? dateOfBirth;

  /// First day of work (may be before they were added to Aby).
  final DateTime? startedOn;
  final String? notes;

  /// "GHA-•••••6789-0": enough to recognise it, not to copy it.
  String? get maskedIdNumber {
    final id = idNumber;
    if (id == null || id.length < 6) return id;
    return '${id.substring(0, 4)}${'•' * (id.length - 10).clamp(0, 99)}${id.substring(id.length - 6)}';
  }
}

/// The editable part of a profile, as typed in the form.
class StaffDetails {
  const StaffDetails({
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.emergencyName,
    this.emergencyPhone,
    this.idNumber,
    this.dateOfBirth,
    this.startedOn,
    this.notes,
  });

  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? emergencyName;
  final String? emergencyPhone;
  final String? idNumber;
  final DateTime? dateOfBirth;
  final DateTime? startedOn;
  final String? notes;
}

/// How someone has been doing. Amounts in pesewas.
class StaffStats {
  const StaffStats({
    this.salesToday = 0,
    this.takingsToday = 0,
    this.sales30Days = 0,
    this.takings30Days = 0,
    this.voidsAsked = 0,
    this.voidsApproved = 0,
    this.closes = 0,
    this.closeDifference = 0,
    this.failedSignIns30Days = 0,
    this.lastSignIn,
  });

  final int salesToday;
  final int takingsToday;
  final int sales30Days;
  final int takings30Days;

  /// Voids of their own sales (they asked) and voids they approved for others.
  final int voidsAsked;
  final int voidsApproved;

  /// Day closes they did, and the total over/short across them.
  final int closes;
  final int closeDifference;
  final int failedSignIns30Days;
  final DateTime? lastSignIn;

  int get averageSale30Days => sales30Days == 0 ? 0 : takings30Days ~/ sales30Days;
}

/// What an approver must be allowed to do: a permission and, for a
/// discount, a high enough limit.
class ApprovalNeed {
  const ApprovalNeed(this.permission, {this.discountPercent});

  final Permission permission;
  final int? discountPercent;

  bool allows(Staff s) => s.can(permission) && (discountPercent == null || s.canDiscount(discountPercent!));
}
