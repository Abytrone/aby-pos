import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:get/get.dart';

import '../data/repositories/staff_repository.dart';
import '../models/staff.dart';

/// Staff photos in memory, so avatars across the app load each photo once.
class StaffPhotoService extends GetxService {
  StaffPhotoService(this._staff);

  final StaffRepository _staff;

  /// staffId → photo, or null when they have none. Missing key: not loaded.
  final photos = <String, Uint8List?>{}.obs;
  final _loading = <String>{};

  Future<void> load(String staffId) async {
    if (photos.containsKey(staffId) || !_loading.add(staffId)) return;
    try {
      photos[staffId] = await _staff.photo(staffId);
    } finally {
      _loading.remove(staffId);
    }
  }

  /// Shrinks [original] and saves it; null removes the photo.
  Future<void> set(String staffId, Uint8List? original, {required Staff by}) async {
    final image = original == null ? null : await shrinkImage(original);
    await _staff.setPhoto(staffId, image, by: by);
    photos[staffId] = image;
  }
}

/// Scales a photo so its longer side is at most [maxSide] px, as PNG.
/// Phone camera photos are several MB; avatars need a few KB.
Future<Uint8List> shrinkImage(Uint8List bytes, {int maxSide = 320}) async {
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = await ui.ImageDescriptor.encoded(buffer);
  final landscape = descriptor.width >= descriptor.height;
  final longer = landscape ? descriptor.width : descriptor.height;
  final scale = longer > maxSide ? maxSide / longer : 1.0;
  final codec = await descriptor.instantiateCodec(
    targetWidth: (descriptor.width * scale).round(),
    targetHeight: (descriptor.height * scale).round(),
  );
  final frame = await codec.getNextFrame();
  final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
  frame.image.dispose();
  codec.dispose();
  descriptor.dispose();
  buffer.dispose();
  return png!.buffer.asUint8List();
}
