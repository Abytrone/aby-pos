// Makes Aby licenses. Developer only: never ship this, and never commit the
// private key it makes.
//
//   dart run tool/license.dart keygen <folder>
//       Makes the signing key once. Prints the public key to put in
//       lib/app/core/license.dart (licensePublicKey). Back the folder up:
//       without the private key no more licenses can be made, and a new
//       key voids every license sold.
//
//   dart run tool/license.dart issue --key <folder> --shop "Mama Ama Provisions" --device K7QM-2XRA-... [--devices 3]
//       Makes a license for the device code the shop sent (Settings →
//       License on their hub, or on their only till). Prints the key to
//       send, saves it as a .abylicense file, and notes it in issued.csv.
//
//   dart run tool/license.dart check <key or .abylicense file>
//       Shows what a license says and whether this build of Aby accepts it.
//
//   dart run tool/license.dart reset --key <folder> --request K7QM-2XRA-PL3D-9WEH-101-7QXM-P3RA
//       An owner forgot their PIN and has no recovery code. Their till shows
//       a request code (Forgot your PIN? → Ask my Aby supplier). Check you
//       are talking to the owner first: this prints a reset code that sets
//       a new PIN for that staff number, once, on that device. Noted in
//       resets.csv.

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aby_pos/app/core/license.dart';
import 'package:aby_pos/app/core/pin_reset.dart';
import 'package:uuid/uuid.dart';

const _keyFile = 'aby_license_private.key';
const _ledger = 'issued.csv';
const _resets = 'resets.csv';

Future<void> main(List<String> args) async {
  if (args.isEmpty) return _usage();
  try {
    switch (args.first) {
      case 'keygen':
        await _keygen(args.skip(1).toList());
      case 'issue':
        await _issue(_options(args.skip(1).toList()));
      case 'check':
        await _check(args.skip(1).toList());
      case 'reset':
        await _reset(_options(args.skip(1).toList()));
      default:
        _usage();
    }
  } on _UsageError catch (e) {
    stderr.writeln(e.message);
    exitCode = 64;
  }
}

class _UsageError implements Exception {
  const _UsageError(this.message);
  final String message;
}

void _usage() {
  stdout.writeln('Usage:\n'
      '  dart run tool/license.dart keygen <folder>\n'
      '  dart run tool/license.dart issue --key <folder> --shop "<name>" --device <code> [--devices <n>]\n'
      '  dart run tool/license.dart check <key or file>\n'
      '  dart run tool/license.dart reset --key <folder> --request <request code>');
  exitCode = 64;
}

Map<String, String> _options(List<String> args) {
  final out = <String, String>{};
  for (var i = 0; i < args.length; i++) {
    if (!args[i].startsWith('--') || i + 1 >= args.length) throw _UsageError('Unexpected "${args[i]}".');
    out[args[i].substring(2)] = args[++i];
  }
  return out;
}

Future<void> _keygen(List<String> args) async {
  if (args.length != 1) throw const _UsageError('keygen needs the folder to keep the private key in.');
  final dir = Directory(args.single);
  final file = File('${dir.path}${Platform.pathSeparator}$_keyFile');
  if (await file.exists()) throw _UsageError('${file.path} already exists. A new key would void every license sold.');
  final r = Random.secure();
  final seed = List.generate(32, (_) => r.nextInt(256));
  await dir.create(recursive: true);
  await file.writeAsString(base64.encode(seed), flush: true);
  stdout
    ..writeln('Private key saved to ${file.path}')
    ..writeln('Back it up somewhere safe and offline. Never commit it or send it to anyone.')
    ..writeln()
    ..writeln('Public key (licensePublicKey in lib/app/core/license.dart):')
    ..writeln(await LicenseCodec.publicKeyOf(seed));
}

Future<void> _issue(Map<String, String> o) async {
  final keyDir = o['key'], shop = o['shop']?.trim(), device = o['device'];
  if (keyDir == null || shop == null || shop.isEmpty || device == null) {
    throw const _UsageError('issue needs --key, --shop and --device.');
  }
  final devices = int.tryParse(o['devices'] ?? '1');
  if (devices == null || devices < 1) throw const _UsageError('--devices must be 1 or more.');
  final code = normalizeDeviceCode(device);
  if (!RegExp(r'^[A-Z2-9]{4}(-[A-Z2-9]{4}){3}$').hasMatch(code)) {
    throw _UsageError('"$device" is not a device code (four groups of four, like K7QM-2XRA-PL3D-9WEH).');
  }
  final seed = base64.decode((await File('$keyDir${Platform.pathSeparator}$_keyFile').readAsString()).trim());
  final publicKey = await LicenseCodec.publicKeyOf(seed);
  if (publicKey != licensePublicKey) {
    stderr.writeln('Warning: this key is not the one in lib/app/core/license.dart; this build of Aby will refuse it.');
  }
  final license = License(id: const Uuid().v4(), shop: shop, device: code, devices: devices, issued: DateTime.now());
  final key = await LicenseCodec.sign(license, seed);
  await LicenseCodec.read(key, publicKey: publicKey);

  final safeName = shop.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '-').replaceAll(RegExp(r'^-|-$'), '');
  final out = File('$safeName-${code.substring(0, 4)}.abylicense');
  await out.writeAsString(key, flush: true);
  final ledger = File('$keyDir${Platform.pathSeparator}$_ledger');
  if (!await ledger.exists()) await ledger.writeAsString('issued,license_id,shop,device,devices\n');
  await ledger.writeAsString(
    '${license.toJson()['issued']},${license.id},"${shop.replaceAll('"', '""')}",$code,$devices\n',
    mode: FileMode.append,
    flush: true,
  );
  stdout
    ..writeln('License for $shop, device $code, $devices ${devices == 1 ? 'device' : 'devices'}:')
    ..writeln()
    ..writeln(key)
    ..writeln()
    ..writeln('Saved as ${out.absolute.path} and noted in ${ledger.path}.');
}

Future<void> _reset(Map<String, String> o) async {
  final keyDir = o['key'], typed = o['request'];
  if (keyDir == null || typed == null) throw const _UsageError('reset needs --key and --request.');
  final request = PinResetRequest.parse(typed);
  if (request == null) {
    throw _UsageError('"$typed" is not a request code (like K7QM-2XRA-PL3D-9WEH-101-7QXM-P3RA).');
  }
  final seed = base64.decode((await File('$keyDir${Platform.pathSeparator}$_keyFile').readAsString()).trim());
  if (await LicenseCodec.publicKeyOf(seed) != licensePublicKey) {
    stderr.writeln('Warning: this key is not the one in lib/app/core/license.dart; this build of Aby will refuse the code.');
  }

  // Who has a licence for this device, to check against who is asking.
  final ledger = File('$keyDir${Platform.pathSeparator}$_ledger');
  final row = RegExp('^[^,]*,[^,]*,"((?:[^"]|"")*)",${request.device},');
  final shops = <String>{
    if (await ledger.exists())
      for (final line in (await ledger.readAsLines()).skip(1))
        if (row.firstMatch(line) case final m?) m[1]!.replaceAll('""', '"'),
  };
  final code = await PinResetCodec.sign(request, seed);
  final resets = File('$keyDir${Platform.pathSeparator}$_resets');
  if (!await resets.exists()) {
    await resets.writeAsString('made,device,staff_number,request\n');
  }
  await resets.writeAsString(
    '${DateTime.now().toIso8601String()},${request.device},${request.staffNumber},${request.code}\n',
    mode: FileMode.append,
    flush: true,
  );
  stdout
    ..writeln('Device:       ${request.device}')
    ..writeln('Licensed to:  ${shops.isEmpty ? '(no licence issued for this device)' : shops.join(', ')}')
    ..writeln('Staff number: ${request.staffNumber}')
    ..writeln()
    ..writeln('Only send this once you are sure you are talking to that shop\'s owner.')
    ..writeln('It sets a new PIN for staff number ${request.staffNumber}, once, on that device only.')
    ..writeln()
    ..writeln(code)
    ..writeln()
    ..writeln('Noted in ${resets.path}.');
}

Future<void> _check(List<String> args) async {
  if (args.length != 1) throw const _UsageError('check needs a license key or a .abylicense file.');
  final f = File(args.single);
  final text = await f.exists() ? await f.readAsString() : args.single;
  try {
    final l = await LicenseCodec.read(text);
    stdout
      ..writeln('Accepted by this build of Aby.')
      ..writeln('  Shop:    ${l.shop}')
      ..writeln('  Device:  ${l.device}')
      ..writeln('  Devices: ${l.devices}')
      ..writeln('  Issued:  ${l.toJson()['issued']}')
      ..writeln('  ID:      ${l.id}');
  } on LicenseException catch (e) {
    stderr.writeln('Not accepted: ${e.problem.name}.');
    exitCode = 1;
  }
}
