import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dialogs.dart';
import 'l10n.dart';

enum _Where { share, folder }

/// Offers "Share" or "Save to a folder" for a text file (CSV exports).
/// Returns true when it went somewhere.
Future<bool> shareOrSaveText(String fileName, String content) async {
  final l = appL10n();
  final where = await choiceDialog<_Where>(
    title: l.exportWhere,
    options: _Where.values,
    label: (w) => w == _Where.share ? l.backupShare : l.backupSaveToFolder,
  );
  if (where == null) return false;
  // A byte-order mark so Excel reads GH₵ and accents correctly.
  final bytes = Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);
  if (where == _Where.folder) {
    return await FilePicker.saveFile(dialogTitle: l.backupSaveToFolder, fileName: fileName, bytes: bytes) != null;
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  final result = await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: fileName));
  if (result.status == ShareResultStatus.unavailable) {
    showMessage(l.backupShareUnavailable);
    return false;
  }
  return result.status == ShareResultStatus.success;
}

/// Picks a text file (CSV) and reads it. Null when cancelled.
Future<String?> pickTextFile() async {
  final picked = await FilePicker.pickFile(dialogTitle: appL10n().importPick);
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  return utf8.decode(bytes, allowMalformed: true);
}
