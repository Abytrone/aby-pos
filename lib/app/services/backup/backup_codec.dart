import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Wrong password, or the file was changed or is not an Aby backup.
class BackupDecryptException implements Exception {
  const BackupDecryptException(this.message);
  final String message;

  @override
  String toString() => 'BackupDecryptException: $message';
}

/// The off-device backup file (`.abybak`):
///
/// ```
/// "ABYBAK1\n" | header length (4 bytes, big endian) | header JSON | ciphertext | GCM tag (16)
/// ```
///
/// The database is encrypted with AES-256-GCM; the key comes from the backup
/// password through PBKDF2-HMAC-SHA256. The header is authenticated too
/// (GCM associated data), so changing any byte makes decryption fail.
abstract final class BackupCodec {
  static final _magic = ascii.encode('ABYBAK1\n');
  static const defaultIterations = 120000;
  static const _tagLength = 16;

  static bool looksLikeBackup(Uint8List bytes) =>
      bytes.length > _magic.length + 4 &&
      _listEquals(bytes.sublist(0, _magic.length), _magic);

  /// Runs in a background isolate: key stretching is slow on purpose.
  static Future<Uint8List> encrypt(
    Uint8List database,
    String password, {
    int iterations = defaultIterations,
    DateTime? createdAt,
  }) =>
      Isolate.run(() => _encrypt(database, password, iterations, createdAt ?? DateTime.now()));

  static Future<Uint8List> decrypt(Uint8List file, String password) =>
      Isolate.run(() => _decrypt(file, password));

  static Future<Uint8List> _encrypt(
    Uint8List database,
    String password,
    int iterations,
    DateTime createdAt,
  ) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final nonce = List<int>.generate(12, (_) => random.nextInt(256));
    final header = utf8.encode(jsonEncode({
      'format': 'aby-backup',
      'version': 1,
      'createdAt': createdAt.toUtc().toIso8601String(),
      'kdf': {'alg': 'pbkdf2-hmac-sha256', 'iterations': iterations, 'salt': base64Encode(salt)},
      'cipher': {'alg': 'aes-256-gcm', 'nonce': base64Encode(nonce)},
    }));
    final key = await _deriveKey(password, salt, iterations);
    final box = await AesGcm.with256bits().encrypt(database, secretKey: key, nonce: nonce, aad: header);
    final out = BytesBuilder(copy: false)
      ..add(_magic)
      ..add((ByteData(4)..setUint32(0, header.length)).buffer.asUint8List())
      ..add(header)
      ..add(box.cipherText)
      ..add(box.mac.bytes);
    return out.toBytes();
  }

  static Future<Uint8List> _decrypt(Uint8List file, String password) async {
    if (!looksLikeBackup(file)) {
      throw const BackupDecryptException('This is not an Aby backup file.');
    }
    final headerLength = ByteData.sublistView(file, _magic.length, _magic.length + 4).getUint32(0);
    final headerStart = _magic.length + 4;
    final bodyStart = headerStart + headerLength;
    if (bodyStart + _tagLength > file.length) {
      throw const BackupDecryptException('The backup file is incomplete.');
    }
    final headerBytes = file.sublist(headerStart, bodyStart);
    final Map<String, dynamic> header;
    try {
      header = Map<String, dynamic>.from(jsonDecode(utf8.decode(headerBytes)) as Map);
    } catch (_) {
      throw const BackupDecryptException('The backup file is damaged.');
    }
    if (header['format'] != 'aby-backup' || header['version'] != 1) {
      throw const BackupDecryptException('This backup was made by a newer version of Aby.');
    }
    final kdf = Map<String, dynamic>.from(header['kdf'] as Map);
    final cipher = Map<String, dynamic>.from(header['cipher'] as Map);
    final key = await _deriveKey(
      password,
      base64Decode(kdf['salt'] as String),
      kdf['iterations'] as int,
    );
    final box = SecretBox(
      file.sublist(bodyStart, file.length - _tagLength),
      nonce: base64Decode(cipher['nonce'] as String),
      mac: Mac(file.sublist(file.length - _tagLength)),
    );
    try {
      final clear = await AesGcm.with256bits().decrypt(box, secretKey: key, aad: headerBytes);
      return Uint8List.fromList(clear);
    } on SecretBoxAuthenticationError {
      throw const BackupDecryptException('Wrong backup password, or the file was changed.');
    }
  }

  static Future<SecretKey> _deriveKey(String password, List<int> salt, int iterations) =>
      Pbkdf2(macAlgorithm: Hmac.sha256(), iterations: iterations, bits: 256)
          .deriveKeyFromPassword(password: password, nonce: salt);

  static bool _listEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
