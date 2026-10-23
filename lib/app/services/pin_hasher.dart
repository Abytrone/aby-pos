import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Salted, stretched PIN hashes: `v1$<iterations>$<salt>$<hash>` (base64).
///
/// A 4-digit PIN has only 10,000 values, so this slows a guesser down but
/// cannot stop one who has the database. Sign-in lockout does the rest.
abstract final class PinHasher {
  static const pinLength = 4;
  static const _iterations = 20000;

  static bool isValidPin(String pin) =>
      pin.length == pinLength && RegExp(r'^\d+$').hasMatch(pin);

  static String hash(String pin, {int iterations = _iterations}) {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final digest = _derive(pin, salt, iterations);
    return 'v1\$$iterations\$${base64Encode(salt)}\$${base64Encode(digest)}';
  }

  static bool verify(String pin, String stored) {
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != 'v1') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    final expected = base64Decode(parts[3]);
    final actual = _derive(pin, base64Decode(parts[2]), iterations);
    return _constantTimeEquals(expected, actual);
  }

  static List<int> _derive(String pin, List<int> salt, int iterations) {
    final hmac = Hmac(sha256, utf8.encode(pin));
    var block = hmac.convert(salt).bytes;
    final result = List<int>.from(block);
    for (var i = 1; i < iterations; i++) {
      block = hmac.convert(block).bytes;
      for (var j = 0; j < result.length; j++) {
        result[j] ^= block[j];
      }
    }
    return result;
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
