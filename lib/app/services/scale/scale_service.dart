import 'dart:io';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../core/settings.dart';
import '../../domain/scale_reading.dart';
import '../../models/scale.dart';
import '../settings_service.dart';
import 'serial_port.dart';

class ScaleException implements Exception {
  const ScaleException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Reads raw bytes from one scale.
abstract interface class ScaleLink {
  /// Sends [request] and returns what the scale sent within [listen].
  Future<Uint8List> read(List<int> request, Duration listen);
}

ScaleLink scaleLinkFor(ScaleTarget t) => switch (t.kind) {
      ScaleKind.serial => SerialScaleLink(t.address, t.baud),
      ScaleKind.bluetooth => BluetoothScaleLink(t.address),
    };

/// A Bluetooth scale on Android, through MainActivity.kt.
class BluetoothScaleLink implements ScaleLink {
  BluetoothScaleLink(this.address);

  final String address;

  static const _channel = MethodChannel('aby/bluetooth');

  @override
  Future<Uint8List> read(List<int> request, Duration listen) async {
    if (!Platform.isAndroid) throw const ScaleException('This scale is set up on an Android device.');
    try {
      final bytes = await _channel.invokeMethod<Uint8List>('read', {
        'address': address,
        'request': Uint8List.fromList(request),
        'millis': listen.inMilliseconds,
      });
      return bytes ?? Uint8List(0);
    } on PlatformException catch (e) {
      throw ScaleException(e.message ?? e.code);
    } on MissingPluginException {
      throw const ScaleException('Bluetooth scales are not available on this device.');
    }
  }
}

/// This device's scale (Settings → This device → Scale). The till asks it
/// for the weight of a product sold by weight.
class ScaleService extends GetxService {
  ScaleService(this._settings, {ScaleLink Function(ScaleTarget)? links, this.listen = const Duration(milliseconds: 1500)})
      : _links = links ?? scaleLinkFor;

  final SettingsService _settings;
  final ScaleLink Function(ScaleTarget) _links;
  final Duration listen;

  ScaleTarget? get scale => ScaleTarget.decode(_settings.get(AppSettings.scale));
  bool get hasScale => scale != null;

  /// The weight on the scale, in grams. Throws [ScaleException] when the
  /// scale cannot be reached, says nothing readable, or is still moving.
  Future<int> readGrams({ScaleTarget? target}) async {
    final t = target ?? scale;
    if (t == null) throw const ScaleException('No scale is set up on this device.');
    final raw = await _links(t).read(t.request.bytes, listen);
    final reading = ScaleReading.parse(String.fromCharCodes(raw));
    if (reading == null) {
      throw ScaleException(raw.isEmpty
          ? 'The scale sent nothing. Check the cable and the speed (baud), or try another way to ask.'
          : 'The scale sent something Aby cannot read: ${_printable(raw)}');
    }
    if (!reading.stable) throw const ScaleException('The weight is still moving. Wait a moment, then read again.');
    return reading.grams;
  }

  static String _printable(Uint8List raw) {
    final s = String.fromCharCodes(raw.where((b) => b >= 32 && b < 127));
    return s.length > 40 ? '${s.substring(0, 40)}...' : s;
  }
}
