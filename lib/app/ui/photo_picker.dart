import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'dialogs.dart';
import 'l10n.dart';

/// Picks a photo (camera or files), at most 1024 px wide. Null when the
/// person cancels, or when this device cannot pick photos, which is said
/// instead of crashing (for example a build missing the picker plugin).
Future<Uint8List?> pickPhotoBytes(ImageSource source) async {
  try {
    final file = await ImagePicker().pickImage(source: source, maxWidth: 1024, imageQuality: 85);
    return file == null ? null : await file.readAsBytes();
  } on PlatformException {
    showMessage(appL10n().photoPickerUnavailable, tone: MessageTone.error);
    return null;
  }
}
