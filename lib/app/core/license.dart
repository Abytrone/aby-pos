import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

/// The public half of Aby's license key (Ed25519). Only licenses signed with
/// the matching private key, which never leaves the developer's machine
/// (tool/license.dart), are accepted. Changing it voids every license sold.
const licensePublicKey = 'iUP7Enb6FCGrENCVo5360TLAE1Is+/fbKRHakQ/DfYQ=';

/// What a license could not be used for, shown in the device's language.
enum LicenseProblem {
  /// Not a license key at all, or cut short when copied.
  unreadable,

  /// Changed after it was made, or not made by Aby.
  forged,

  /// Made for another device code.
  otherDevice,

  /// Fewer devices than are already linked to this hub.
  tooFewDevices,
}

class LicenseException implements Exception {
  const LicenseException(this.problem);

  final LicenseProblem problem;

  @override
  String toString() => 'LicenseException(${problem.name})';
}

/// A one-time purchase for one shop: the device that holds it (the hub, or
/// a till on its own) and how many devices, that one included, may share
/// it through the hub. It never expires.
class License {
  const License({
    required this.id,
    required this.shop,
    required this.device,
    required this.devices,
    required this.issued,
  });

  final String id;
  final String shop;

  /// The device code it is for ([deviceCode]).
  final String device;
  final int devices;
  final DateTime issued;

  Map<String, Object> toJson() => {
        'v': 1,
        'id': id,
        'shop': shop,
        'device': device,
        'devices': devices,
        'issued': issued.toIso8601String().substring(0, 10),
      };

  static License fromJson(Map<String, dynamic> j) => License(
        id: j['id'] as String,
        shop: j['shop'] as String,
        device: normalizeDeviceCode(j['device'] as String),
        devices: j['devices'] as int,
        issued: DateTime.parse(j['issued'] as String),
      );
}

/// License keys as text, so they go by WhatsApp or email:
/// `ABY1.<payload>.<signature>`, both base64url.
abstract final class LicenseCodec {
  static const prefix = 'ABY1.';
  static final _ed25519 = Ed25519();

  /// Signs [license] with the private key's 32-byte [seed]. Developer side.
  static Future<String> sign(License license, List<int> seed) async {
    final payload = utf8.encode(jsonEncode(license.toJson()));
    final keys = await _ed25519.newKeyPairFromSeed(seed);
    final signature = await _ed25519.sign(payload, keyPair: keys);
    return '$prefix${_b64(payload)}.${_b64(signature.bytes)}';
  }

  /// The public key that goes with [seed], for [licensePublicKey].
  static Future<String> publicKeyOf(List<int> seed) async {
    final keys = await _ed25519.newKeyPairFromSeed(seed);
    return base64.encode((await keys.extractPublicKey()).bytes);
  }

  /// The license in [text] if Aby made it. Spaces and line breaks, as
  /// messaging apps add them, are ignored. Throws [LicenseException].
  static Future<License> read(String text, {String publicKey = licensePublicKey}) async {
    final t = text.replaceAll(RegExp(r'\s'), '');
    final parts = t.startsWith(prefix) ? t.substring(prefix.length).split('.') : const <String>[];
    if (parts.length != 2) throw const LicenseException(LicenseProblem.unreadable);
    final List<int> payload, signature;
    try {
      payload = base64Url.decode(base64Url.normalize(parts[0]));
      signature = base64Url.decode(base64Url.normalize(parts[1]));
    } on FormatException {
      throw const LicenseException(LicenseProblem.unreadable);
    }
    final ok = await _ed25519.verify(
      payload,
      signature: Signature(signature, publicKey: SimplePublicKey(base64.decode(publicKey), type: KeyPairType.ed25519)),
    );
    if (!ok) throw const LicenseException(LicenseProblem.forged);
    try {
      return License.fromJson(jsonDecode(utf8.decode(payload)) as Map<String, dynamic>);
    } on Object {
      throw const LicenseException(LicenseProblem.unreadable);
    }
  }

  static String _b64(List<int> bytes) => base64Url.encode(bytes).replaceAll('=', '');
}

/// Letters device codes are made of: no 0/O or 1/I to mix up when read out.
const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

/// The short code a shop sends to buy a license ("K7QM-2XRA-…"), made from
/// the machine's own ID, so it stays the same through reinstalls and a
/// license file copied to another machine does not work there.
String deviceCode(String machineId) {
  final hash = sha256.convert(utf8.encode('aby-device:$machineId')).bytes;
  var bits = 0, value = 0;
  final out = StringBuffer();
  for (final b in hash) {
    value = (value << 8) | b;
    bits += 8;
    while (bits >= 5 && out.length < 16) {
      bits -= 5;
      out.write(_codeChars[(value >> bits) & 31]);
    }
    value &= (1 << bits) - 1;
    if (out.length == 16) break;
  }
  return formatDeviceCode(out.toString());
}

/// A device code as typed: capitals, without dashes or spaces.
String normalizeDeviceCode(String typed) => formatDeviceCode(typed.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), ''));

String formatDeviceCode(String c) => [for (var i = 0; i < c.length; i += 4) c.substring(i, i + 4 > c.length ? c.length : i + 4)].join('-');
