import 'dart:convert';

enum ScaleKind { serial, bluetooth }

/// What the till sends to ask for a weight. Many scales send continuously
/// and need nothing; others answer "W", "P" or ENQ (0x05).
enum ScaleRequest {
  none([]),
  w([0x57, 0x0D]),
  p([0x50, 0x0D]),
  enq([0x05]);

  const ScaleRequest(this.bytes);

  final List<int> bytes;
}

/// This device's scale: a COM port on Windows (with its speed) or a paired
/// Bluetooth scale on Android.
class ScaleTarget {
  const ScaleTarget({
    required this.kind,
    required this.address,
    String? name,
    this.baud = 9600,
    this.request = ScaleRequest.none,
  }) : name = name ?? address;

  final ScaleKind kind;

  /// "COM3", or the Bluetooth address.
  final String address;
  final String name;
  final int baud;
  final ScaleRequest request;

  static const bauds = [2400, 4800, 9600, 19200];

  String encode() =>
      jsonEncode({'kind': kind.name, 'address': address, 'name': name, 'baud': baud, 'request': request.name});

  /// Null for '' (no scale) or anything unreadable.
  static ScaleTarget? decode(String json) {
    if (json.isEmpty) return null;
    try {
      final m = jsonDecode(json) as Map<String, dynamic>;
      return ScaleTarget(
        kind: ScaleKind.values.byName(m['kind'] as String),
        address: m['address'] as String,
        name: m['name'] as String?,
        baud: (m['baud'] as num?)?.toInt() ?? 9600,
        request: ScaleRequest.values.asNameMap()[m['request']] ?? ScaleRequest.none,
      );
    } on Object {
      return null;
    }
  }
}
