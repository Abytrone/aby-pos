import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Encrypts hub traffic (MDV-01): AES-GCM with a 256-bit key. A sealed
/// message is JSON: nonce, cipher text and tag, base64.
abstract final class SealedBox {
  static final _aes = AesGcm.with256bits();

  /// A fresh device secret, base64.
  static String newSecret() {
    final r = Random.secure();
    return base64Encode(List<int>.generate(32, (_) => r.nextInt(256)));
  }

  /// The key a one-time pairing code stands for. Slow on purpose (PBKDF2),
  /// so the short code cannot be guessed from a recorded pairing.
  static Future<String> keyFromCode(String code, String hubId) async {
    final kdf = Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: 20000, bits: 256);
    final key = await kdf.deriveKeyFromPassword(password: code.toUpperCase(), nonce: utf8.encode('aby-hub:$hubId'));
    return base64Encode(await key.extractBytes());
  }

  static Future<String> seal(Object? message, String secret) async {
    final box = await _aes.encrypt(utf8.encode(jsonEncode(message)), secretKey: SecretKey(base64Decode(secret)));
    return jsonEncode({'n': base64Encode(box.nonce), 'c': base64Encode(box.cipherText), 't': base64Encode(box.mac.bytes)});
  }

  /// Throws when the message was not sealed with [secret] or was changed.
  static Future<Object?> open(String sealed, String secret) async {
    final m = jsonDecode(sealed) as Map<String, dynamic>;
    final clear = await _aes.decrypt(
      SecretBox(
        base64Decode(m['c'] as String),
        nonce: base64Decode(m['n'] as String),
        mac: Mac(base64Decode(m['t'] as String)),
      ),
      secretKey: SecretKey(base64Decode(secret)),
    );
    return jsonDecode(utf8.decode(clear));
  }

  static Uint8List bytes(String s) => Uint8List.fromList(utf8.encode(s));
}
