import 'package:flutter/services.dart';

/// The brand kit's drawn stand-in photos for the demo menu, by product
/// name. Demo data only: the shop replaces them with its own photos.
const _demoPhotoFiles = {
  'Vanilla cone': 'vanilla-cone',
  'Chocolate cone': 'chocolate-cone',
  'Ice cream cup': 'chocolate-cup',
  'Ice cream tub': 'strawberry-tub',
  'Milkshake': 'milkshake',
  'Waffle': 'waffle',
};

/// Reads the demo photos from the app's assets. A missing file is skipped:
/// that product shows its category icon instead.
Future<Map<String, Uint8List>> loadDemoPhotos() async {
  final out = <String, Uint8List>{};
  for (final MapEntry(key: name, value: file) in _demoPhotoFiles.entries) {
    try {
      out[name] = (await rootBundle.load('assets/samples/$file.png')).buffer.asUint8List();
    } on Object {
      continue;
    }
  }
  return out;
}
