/// Checks and normalises what people type into forms. Each `normalise*`
/// returns the stored form, or null when the input is not valid.
abstract final class Validators {
  /// Ghana mobile and landline numbers: "024 123 4567", "0241234567",
  /// "+233 24 123 4567", "233241234567". Stored as "+233241234567".
  static String? normalisePhone(String input) {
    final digits = input.replaceAll(RegExp(r'[\s\-().]'), '');
    final match = RegExp(r'^(?:\+?233|0)(\d{9})$').firstMatch(digits);
    return match == null ? null : '+233${match.group(1)}';
  }

  /// "+233241234567" → "024 123 4567", the way people say it.
  static String formatPhone(String stored) {
    final match = RegExp(r'^\+233(\d{2})(\d{3})(\d{4})$').firstMatch(stored);
    if (match == null) return stored;
    return '0${match.group(1)} ${match.group(2)} ${match.group(3)}';
  }

  static String? normaliseEmail(String input) {
    final email = input.trim().toLowerCase();
    return RegExp(r'^[^@\s]+@[^@\s]+\.[a-z]{2,}$').hasMatch(email) ? email : null;
  }

  /// Ghana Card personal ID: "GHA-123456789-0". Accepts lower case and
  /// missing dashes.
  static String? normaliseGhanaCard(String input) {
    final compact = input.toUpperCase().replaceAll(RegExp(r'[\s\-]'), '');
    final match = RegExp(r'^GHA(\d{9})(\d)$').firstMatch(compact);
    return match == null ? null : 'GHA-${match.group(1)}-${match.group(2)}';
  }
}
