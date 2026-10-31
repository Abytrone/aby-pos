import 'dart:convert';
import 'dart:math';

import 'license.dart';

/// An owner's recovery code: twelve letters and digits ("K7QM-4XPA-9TRB"),
/// shown once and kept only as a hash. It sets a new PIN when the old one
/// is forgotten, then a new code replaces it.
abstract final class RecoveryCode {
  static const length = 12;

  static String generate() {
    final random = Random.secure();
    return formatDeviceCode(List.generate(length, (_) => codeChars[random.nextInt(codeChars.length)]).join());
  }

  /// As typed: capitals, no dashes or spaces. 0 and 1 are read as O and I
  /// would be, but neither is used, so they are left to fail.
  static String normalize(String typed) => typed.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
}

/// A till asking the Aby supplier to reset an owner's PIN: the device code
/// (which licence it is), the staff number and a one-time part, so a reset
/// code works once, on this device, for this person.
///
/// Read out or sent as `K7QM-2XRA-PL3D-9WEH-101-7QXM-P3RA`.
class PinResetRequest {
  const PinResetRequest({required this.device, required this.staffNumber, required this.nonce});

  /// Formatted device code ([deviceCode]).
  final String device;
  final String staffNumber;

  /// Eight letters and digits.
  final String nonce;

  factory PinResetRequest.create(String device, String staffNumber) {
    final random = Random.secure();
    return PinResetRequest(
      device: device,
      staffNumber: staffNumber,
      nonce: List.generate(8, (_) => codeChars[random.nextInt(codeChars.length)]).join(),
    );
  }

  String get code => '$device-$staffNumber-${formatDeviceCode(nonce)}';

  /// Null when [typed] is not a request code. Dashes and spaces are optional.
  static PinResetRequest? parse(String typed) {
    final t = typed.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final m = RegExp(r'^([A-Z2-9]{16})(\d{3})([A-Z2-9]{8})$').firstMatch(t);
    if (m == null) return null;
    return PinResetRequest(device: formatDeviceCode(m[1]!), staffNumber: m[2]!, nonce: m[3]!);
  }

  /// What the supplier signs.
  List<int> get _message => utf8.encode('aby-pin-reset:v1:$device:$staffNumber:$nonce');

  Map<String, String> toJson() => {'device': device, 'staff': staffNumber, 'nonce': nonce};

  static PinResetRequest fromJson(Map<String, dynamic> j) =>
      PinResetRequest(device: j['device'] as String, staffNumber: j['staff'] as String, nonce: j['nonce'] as String);
}

/// Reset codes: `ABYP.<signature>`, the supplier's Ed25519 signature of the
/// request, made with the licence key (tool/license.dart reset). The till
/// already knows the request, so the code is only the signature.
abstract final class PinResetCodec {
  static const prefix = 'ABYP.';

  /// Developer side.
  static Future<String> sign(PinResetRequest request, List<int> seed) async =>
      '$prefix${base64Url.encode(await LicenseCodec.signBytes(request._message, seed)).replaceAll('=', '')}';

  /// Whether [text] is the supplier's reset code for [request]. Spaces and
  /// line breaks, as messaging apps add them, are ignored.
  static Future<bool> verify(String text, PinResetRequest request, {String publicKey = licensePublicKey}) async {
    final t = text.replaceAll(RegExp(r'\s'), '');
    if (!t.startsWith(prefix)) return false;
    final List<int> signature;
    try {
      signature = base64Url.decode(base64Url.normalize(t.substring(prefix.length)));
    } on FormatException {
      return false;
    }
    if (signature.length != 64) return false;
    return LicenseCodec.verifyBytes(request._message, signature, publicKey: publicKey);
  }
}
