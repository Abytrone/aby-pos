import 'dart:io';
import 'dart:typed_data';

import '../../models/receipt.dart';
import 'bluetooth_link.dart';
import 'windows_spooler.dart';

class PrinterException implements Exception {
  const PrinterException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Sends bytes to one printer.
abstract interface class PrinterLink {
  Future<void> send(Uint8List bytes);
}

PrinterLink linkFor(PrinterTarget t) => switch (t.kind) {
      PrinterKind.network => NetworkLink(t.address),
      PrinterKind.windows => WindowsSpoolerLink(t.address),
      PrinterKind.bluetooth => BluetoothLink(t.address),
    };

/// A printer on Wi-Fi or Ethernet: raw bytes to port 9100.
class NetworkLink implements PrinterLink {
  NetworkLink(String address, {this.timeout = const Duration(seconds: 5)})
      : host = address.contains(':') ? address.substring(0, address.lastIndexOf(':')) : address,
        port = address.contains(':') ? int.tryParse(address.substring(address.lastIndexOf(':') + 1)) ?? 9100 : 9100;

  final String host;
  final int port;
  final Duration timeout;

  @override
  Future<void> send(Uint8List bytes) async {
    Socket socket;
    try {
      socket = await Socket.connect(host, port, timeout: timeout);
    } on SocketException catch (e) {
      throw PrinterException('Cannot reach the printer at $host ($port): ${e.osError?.message ?? e.message}');
    }
    try {
      socket.add(bytes);
      await socket.flush().timeout(timeout);
    } on Object catch (e) {
      throw PrinterException('The printer stopped answering: $e');
    } finally {
      await socket.close().timeout(timeout, onTimeout: () => socket).catchError((Object _) => socket);
      socket.destroy();
    }
  }
}
