import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'ids.dart';

/// This machine's own ID, which a license is tied to. Windows, macOS and
/// Linux keep one that survives reinstalling Aby; elsewhere (Android) it is
/// made on first use and kept in the app's folder, so it lasts until the
/// app is uninstalled.
Future<String> readMachineId() async {
  try {
    final id = switch (Platform.operatingSystem) {
      'windows' => _windowsMachineGuid(),
      'macos' => await _macPlatformUuid(),
      'linux' => (await File('/etc/machine-id').readAsString()).trim(),
      _ => null,
    };
    if (id != null && id.isNotEmpty) return id;
  } on Object {
    // Fall back to an ID of our own.
  }
  return _installId();
}

typedef _RegGetValueC = Int32 Function(IntPtr, Pointer<Utf16>, Pointer<Utf16>, Uint32, Pointer<Uint32>, Pointer<Void>, Pointer<Uint32>);
typedef _RegGetValueD = int Function(int, Pointer<Utf16>, Pointer<Utf16>, int, Pointer<Uint32>, Pointer<Void>, Pointer<Uint32>);

/// HKLM\SOFTWARE\Microsoft\Cryptography\MachineGuid: set when Windows is
/// installed. HKEY_LOCAL_MACHINE is (HKEY)(LONG)0x80000002, sign-extended.
String? _windowsMachineGuid() {
  const hklm = -0x7FFFFFFE, rrfRtRegSz = 0x2, rrfSubkeyWow6464Key = 0x10000;
  final get = DynamicLibrary.open('advapi32.dll').lookupFunction<_RegGetValueC, _RegGetValueD>('RegGetValueW');
  final key = r'SOFTWARE\Microsoft\Cryptography'.toNativeUtf16();
  final name = 'MachineGuid'.toNativeUtf16();
  final size = calloc<Uint32>()..value = 256;
  final data = calloc<Uint16>(128);
  try {
    final status = get(hklm, key, name, rrfRtRegSz | rrfSubkeyWow6464Key, nullptr, data.cast(), size);
    return status == 0 ? data.cast<Utf16>().toDartString() : null;
  } finally {
    calloc
      ..free(key)
      ..free(name)
      ..free(size)
      ..free(data);
  }
}

Future<String?> _macPlatformUuid() async {
  final r = await Process.run('/usr/sbin/ioreg', ['-rd1', '-c', 'IOPlatformExpertDevice']);
  return RegExp(r'"IOPlatformUUID" = "([^"]+)"').firstMatch('${r.stdout}')?.group(1);
}

Future<String> _installId() async {
  final f = File(p.join((await getApplicationSupportDirectory()).path, 'aby_pos.install'));
  if (await f.exists()) {
    final id = (await f.readAsString()).trim();
    if (id.isNotEmpty) return id;
  }
  final id = newId();
  await f.parent.create(recursive: true);
  await f.writeAsString(id, flush: true);
  return id;
}
