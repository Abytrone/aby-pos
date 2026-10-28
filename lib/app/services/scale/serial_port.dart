import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'scale_service.dart';

// The few kernel32 calls needed to read a scale on a COM port (USB scales
// install as one too).

final class _CommTimeouts extends Struct {
  @Uint32()
  external int readInterval;
  @Uint32()
  external int readTotalMultiplier;
  @Uint32()
  external int readTotalConstant;
  @Uint32()
  external int writeTotalMultiplier;
  @Uint32()
  external int writeTotalConstant;
}

typedef _CreateFileC = IntPtr Function(Pointer<Utf16>, Uint32, Uint32, Pointer<Void>, Uint32, Uint32, IntPtr);
typedef _CreateFileD = int Function(Pointer<Utf16>, int, int, Pointer<Void>, int, int, int);
typedef _BuildDcbC = Int32 Function(Pointer<Utf16>, Pointer<Uint8>);
typedef _BuildDcbD = int Function(Pointer<Utf16>, Pointer<Uint8>);
typedef _HandleBufC = Int32 Function(IntPtr, Pointer<Uint8>);
typedef _HandleBufD = int Function(int, Pointer<Uint8>);
typedef _TimeoutsC = Int32 Function(IntPtr, Pointer<_CommTimeouts>);
typedef _TimeoutsD = int Function(int, Pointer<_CommTimeouts>);
typedef _IoC = Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Void>);
typedef _IoD = int Function(int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Void>);
typedef _CloseC = Int32 Function(IntPtr);
typedef _CloseD = int Function(int);
typedef _QueryDosC = Uint32 Function(Pointer<Utf16>, Pointer<Utf16>, Uint32);
typedef _QueryDosD = int Function(Pointer<Utf16>, Pointer<Utf16>, int);
typedef _LastErrorC = Uint32 Function();
typedef _LastErrorD = int Function();

const _genericRead = 0x80000000, _genericWrite = 0x40000000, _openExisting = 3, _invalidHandle = -1;

/// The DCB structure is 28 bytes; BuildCommDCB fills it from a mode string,
/// so its bit fields need no handling here.
const _dcbSize = 28;

class _Kernel {
  _Kernel() {
    final k = DynamicLibrary.open('kernel32.dll');
    createFile = k.lookupFunction<_CreateFileC, _CreateFileD>('CreateFileW');
    buildDcb = k.lookupFunction<_BuildDcbC, _BuildDcbD>('BuildCommDCBW');
    getState = k.lookupFunction<_HandleBufC, _HandleBufD>('GetCommState');
    setState = k.lookupFunction<_HandleBufC, _HandleBufD>('SetCommState');
    setTimeouts = k.lookupFunction<_TimeoutsC, _TimeoutsD>('SetCommTimeouts');
    readFile = k.lookupFunction<_IoC, _IoD>('ReadFile');
    writeFile = k.lookupFunction<_IoC, _IoD>('WriteFile');
    close = k.lookupFunction<_CloseC, _CloseD>('CloseHandle');
    queryDos = k.lookupFunction<_QueryDosC, _QueryDosD>('QueryDosDeviceW');
    lastError = k.lookupFunction<_LastErrorC, _LastErrorD>('GetLastError');
  }

  late final _CreateFileD createFile;
  late final _BuildDcbD buildDcb;
  late final _HandleBufD getState;
  late final _HandleBufD setState;
  late final _TimeoutsD setTimeouts;
  late final _IoD readFile;
  late final _IoD writeFile;
  late final _CloseD close;
  late final _QueryDosD queryDos;
  late final _LastErrorD lastError;
}

/// COM ports on this computer ("COM3"), from the device names Windows knows.
List<String> serialPorts() {
  if (!Platform.isWindows) return const [];
  final k = _Kernel();
  return using((arena) {
    const size = 65536;
    final buf = arena<Uint16>(size).cast<Utf16>();
    final n = k.queryDos(nullptr, buf, size);
    if (n == 0) return const <String>[];
    final names = String.fromCharCodes(buf.cast<Uint16>().asTypedList(n)).split('\u0000');
    final ports = names.where((s) => RegExp(r'^COM\d+$').hasMatch(s)).toSet().toList()
      ..sort((a, b) => int.parse(a.substring(3)).compareTo(int.parse(b.substring(3))));
    return ports;
  });
}

/// Opens [port] at [baud] (8 data bits, no parity, 1 stop bit), sends
/// [request], and collects what comes back for [millis].
Uint8List _read(String port, int baud, List<int> request, int millis) {
  final k = _Kernel();
  return using((arena) {
    // \\.\COM10 and up need the device prefix; it works for all.
    final h = k.createFile('\\\\.\\$port'.toNativeUtf16(allocator: arena), _genericRead | _genericWrite, 0, nullptr,
        _openExisting, 0, 0);
    if (h == _invalidHandle || h == 0) {
      throw ScaleException('Windows cannot open $port (error ${k.lastError()}). Is the scale plugged in, and '
          'is another program using it?');
    }
    try {
      final dcb = arena<Uint8>(_dcbSize);
      dcb.cast<Uint32>().value = _dcbSize;
      k.getState(h, dcb);
      if (k.buildDcb('baud=$baud parity=N data=8 stop=1'.toNativeUtf16(allocator: arena), dcb) == 0 ||
          k.setState(h, dcb) == 0) {
        throw ScaleException('Cannot set $port to $baud baud (error ${k.lastError()}).');
      }
      final t = arena<_CommTimeouts>()
        ..ref.readInterval = 50
        ..ref.readTotalMultiplier = 0
        ..ref.readTotalConstant = 100
        ..ref.writeTotalMultiplier = 0
        ..ref.writeTotalConstant = 500;
      k.setTimeouts(h, t);
      final count = arena<Uint32>();
      if (request.isNotEmpty) {
        final out = arena<Uint8>(request.length)..asTypedList(request.length).setAll(0, request);
        k.writeFile(h, out, request.length, count, nullptr);
      }
      final got = BytesBuilder();
      final buf = arena<Uint8>(256);
      final end = DateTime.now().add(Duration(milliseconds: millis));
      while (DateTime.now().isBefore(end)) {
        if (k.readFile(h, buf, 256, count, nullptr) == 0) break;
        if (count.value > 0) got.add(buf.asTypedList(count.value));
      }
      return got.takeBytes();
    } finally {
      k.close(h);
    }
  });
}

class SerialScaleLink implements ScaleLink {
  SerialScaleLink(this.port, this.baud);

  final String port;
  final int baud;

  @override
  Future<Uint8List> read(List<int> request, Duration listen) async {
    if (!Platform.isWindows) throw const ScaleException('This scale is set up on a Windows computer.');
    final (p, b, ms) = (port, baud, listen.inMilliseconds);
    final (bytes, error) = await Isolate.run(() {
      try {
        return (_read(p, b, request, ms), null);
      } on ScaleException catch (e) {
        return (null, e.message);
      }
    });
    if (error != null) throw ScaleException(error);
    return bytes!;
  }
}
