import 'dart:io';

import 'package:flutter/services.dart';

import 'printer_link.dart';

/// Talks to MainActivity.kt: Bluetooth printers paired in Android's
/// settings, over the serial port profile most cheap printers use.
const _channel = MethodChannel('aby/bluetooth');

/// Paired devices as (name, address). Empty off Android.
Future<List<(String, String)>> pairedBluetooth() async {
  if (!Platform.isAndroid) return const [];
  try {
    final list = await _channel.invokeListMethod<Map<Object?, Object?>>('bonded') ?? const [];
    return [for (final m in list) (m['name'] as String? ?? '?', m['address'] as String)];
  } on PlatformException catch (e) {
    throw PrinterException(e.message ?? e.code);
  } on MissingPluginException {
    return const [];
  }
}

class BluetoothLink implements PrinterLink {
  BluetoothLink(this.address);

  final String address;

  @override
  Future<void> send(Uint8List bytes) async {
    if (!Platform.isAndroid) throw const PrinterException('This printer is set up on an Android device.');
    try {
      await _channel.invokeMethod<void>('write', {'address': address, 'bytes': bytes});
    } on PlatformException catch (e) {
      throw PrinterException(e.message ?? e.code);
    } on MissingPluginException {
      throw const PrinterException('Bluetooth printing is not available on this device.');
    }
  }
}
