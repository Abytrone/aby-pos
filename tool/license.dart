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

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:aby_pos/app/core/license.dart';
import 'package:uuid/uuid.dart';

const _keyFile = 'aby_license_private.key';
const _ledger = 'issued.csv';

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
      '  dart run tool/license.dart check <key or file>');
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
