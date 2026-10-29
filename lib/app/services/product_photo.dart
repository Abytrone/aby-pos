import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// The longest a product photo may be, in bytes: they live on the till and
/// sync as files, so a menu of hundreds stays small.
const productPhotoMaxBytes = 60 * 1024;

/// Turns a picked photo into a product photo: cropped square around the
/// middle (tiles crop to 4:3 from there, so the product stays centred),
/// [side] px, and compressed until it is under [productPhotoMaxBytes].
/// Null when the bytes are not a picture.
Future<Uint8List?> squareProductPhoto(Uint8List bytes, {int side = 480}) =>
    Isolate.run(() => squareProductPhotoSync(bytes, side: side));

/// [squareProductPhoto] on this isolate (tests, and inside the isolate).
Uint8List? squareProductPhotoSync(Uint8List bytes, {int side = 480}) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  final upright = img.bakeOrientation(decoded);
  final edge = upright.width < upright.height ? upright.width : upright.height;
  final square = img.copyCrop(
    upright,
    x: (upright.width - edge) ~/ 2,
    y: (upright.height - edge) ~/ 2,
    width: edge,
    height: edge,
  );
  var size = edge > side ? side : edge;
  var image = size == edge ? square : img.copyResize(square, width: size, height: size, interpolation: img.Interpolation.average);
  // A transparent PNG would turn black as a JPEG: lay it on white, like a plate.
  if (image.hasAlpha) {
    final white = img.Image(width: image.width, height: image.height)..clear(img.ColorRgb8(255, 255, 255));
    image = img.compositeImage(white, image);
  }
  for (var quality = 85;; quality -= 10) {
    final jpg = img.encodeJpg(image, quality: quality);
    if (jpg.length <= productPhotoMaxBytes) return jpg;
    if (quality <= 45) {
      // Still too big at a low quality: a smaller picture instead.
      if (size <= 240) return jpg;
      size = (size * 0.75).round();
      image = img.copyResize(image, width: size, height: size, interpolation: img.Interpolation.average);
      quality = 95;
    }
  }
}
