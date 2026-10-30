import 'package:flutter/services.dart';

/// One of the brand kit's drawn stand-in photos (assets/samples/[name].png)
/// for the sample shops. Null when it is missing: the product shows its
/// category icon instead.
Future<Uint8List?> loadSamplePhoto(String name) async {
  try {
    return (await rootBundle.load('assets/samples/$name.png')).buffer.asUint8List();
  } on Object {
    return null;
  }
}
