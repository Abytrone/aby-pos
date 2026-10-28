import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:ffi/ffi.dart';

import 'printer_link.dart';

// The few winspool calls needed to send raw bytes to an installed printer
// (USB thermal printers on Windows install as one).

final class _DocInfo1 extends Struct {
  external Pointer<Utf16> docName;
  external Pointer<Utf16> outputFile;
  external Pointer<Utf16> datatype;
}

final class _PrinterInfo4 extends Struct {
  external Pointer<Utf16> printerName;
  external Pointer<Utf16> serverName;
  @Uint32()
  external int attributes;
}

typedef _OpenPrinterC = Int32 Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>);
typedef _OpenPrinterD = int Function(Pointer<Utf16>, Pointer<IntPtr>, Pointer<Void>);
typedef _StartDocC = Uint32 Function(IntPtr, Uint32, Pointer<_DocInfo1>);
typedef _StartDocD = int Function(int, int, Pointer<_DocInfo1>);
typedef _HandleC = Int32 Function(IntPtr);
typedef _HandleD = int Function(int);
typedef _WriteC = Int32 Function(IntPtr, Pointer<Uint8>, Uint32, Pointer<Uint32>);
typedef _WriteD = int Function(int, Pointer<Uint8>, int, Pointer<Uint32>);
typedef _EnumC = Int32 Function(Uint32, Pointer<Utf16>, Uint32, Pointer<Uint8>, Uint32, Pointer<Uint32>, Pointer<Uint32>);
typedef _EnumD = int Function(int, Pointer<Utf16>, int, Pointer<Uint8>, int, Pointer<Uint32>, Pointer<Uint32>);
typedef _LastErrorC = Uint32 Function();
typedef _LastErrorD = int Function();

const _enumLocal = 0x2, _enumConnections = 0x4;

class _Spooler {
  _Spooler() {
    final lib = DynamicLibrary.open('winspool.drv');
    open = lib.lookupFunction<_OpenPrinterC, _OpenPrinterD>('OpenPrinterW');
    startDoc = lib.lookupFunction<_StartDocC, _StartDocD>('StartDocPrinterW');
    startPage = lib.lookupFunction<_HandleC, _HandleD>('StartPagePrinter');
    write = lib.lookupFunction<_WriteC, _WriteD>('WritePrinter');
    endPage = lib.lookupFunction<_HandleC, _HandleD>('EndPagePrinter');
    endDoc = lib.lookupFunction<_HandleC, _HandleD>('EndDocPrinter');
    close = lib.lookupFunction<_HandleC, _HandleD>('ClosePrinter');
    enumPrinters = lib.lookupFunction<_EnumC, _EnumD>('EnumPrintersW');
    lastError = DynamicLibrary.open('kernel32.dll').lookupFunction<_LastErrorC, _LastErrorD>('GetLastError');
  }

  late final _OpenPrinterD open;
  late final _StartDocD startDoc;
  late final _HandleD startPage;
  late final _WriteD write;
  late final _HandleD endPage;
  late final _HandleD endDoc;
  late final _HandleD close;
  late final _EnumD enumPrinters;
  late final _LastErrorD lastError;
}

/// Installed printers on this computer, by name.
List<String> windowsPrinters() {
  if (!Platform.isWindows) return const [];
  final s = _Spooler();
  return using((arena) {
    final needed = arena<Uint32>();
    final count = arena<Uint32>();
    s.enumPrinters(_enumLocal | _enumConnections, nullptr, 4, nullptr, 0, needed, count);
    if (needed.value == 0) return const <String>[];
    final buf = arena<Uint8>(needed.value);
    if (s.enumPrinters(_enumLocal | _enumConnections, nullptr, 4, buf, needed.value, needed, count) == 0) {
      return const <String>[];
    }
    final infos = buf.cast<_PrinterInfo4>();
    return [for (var i = 0; i < count.value; i++) infos[i].printerName.toDartString()]..sort();
  });
}

/// Sends the bytes as a RAW job, so the printer's driver passes them on
/// untouched. Runs on another isolate: the spooler can be slow.
void _sendRaw(String printer, Uint8List bytes) {
  final s = _Spooler();
  using((arena) {
    final handle = arena<IntPtr>();
    if (s.open(printer.toNativeUtf16(allocator: arena), handle, nullptr) == 0) {
      throw PrinterException('Windows cannot open the printer "$printer" (error ${s.lastError()}).');
    }
    final h = handle.value;
    try {
      final doc = arena<_DocInfo1>()
        ..ref.docName = 'Aby receipt'.toNativeUtf16(allocator: arena)
        ..ref.outputFile = nullptr
        ..ref.datatype = 'RAW'.toNativeUtf16(allocator: arena);
      if (s.startDoc(h, 1, doc) == 0) {
        throw PrinterException('The printer "$printer" refused the job (error ${s.lastError()}).');
      }
      s.startPage(h);
      final data = arena<Uint8>(bytes.length)..asTypedList(bytes.length).setAll(0, bytes);
      final written = arena<Uint32>();
      final ok = s.write(h, data, bytes.length, written) != 0 && written.value == bytes.length;
      s.endPage(h);
      s.endDoc(h);
      if (!ok) throw PrinterException('Windows could not send everything to "$printer" (error ${s.lastError()}).');
    } finally {
      s.close(h);
    }
  });
}

class WindowsSpoolerLink implements PrinterLink {
  WindowsSpoolerLink(this.printerName);

  final String printerName;

  @override
  Future<void> send(Uint8List bytes) async {
    if (!Platform.isWindows) throw const PrinterException('This printer is set up on a Windows computer.');
    final name = printerName;
    final error = await Isolate.run(() {
      try {
        _sendRaw(name, bytes);
        return null;
      } on PrinterException catch (e) {
        return e.message;
      }
    });
    if (error != null) throw PrinterException(error);
  }
}
