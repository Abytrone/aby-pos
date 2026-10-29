import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'dialogs.dart';
import 'l10n.dart';

/// Where a made file goes.
enum FileDestination { share, folder }

/// Offers "Share" or "Save to a folder" for a text file (CSV exports).
/// Returns true when it went somewhere.
Future<bool> shareOrSaveText(String fileName, String content) => shareOrSaveBytes(fileName, csvBytes(content));

/// CSV text as UTF-8 with a byte-order mark, so Excel reads GH₵ and accents
/// correctly.
Uint8List csvBytes(String content) => Uint8List.fromList([0xEF, 0xBB, 0xBF, ...utf8.encode(content)]);

/// Offers "Share" (WhatsApp, email...) or "Save to a folder" for a file
/// (PDF statements, CSV exports). [title] replaces "Where should the file
/// go?". Returns true when it went somewhere.
Future<bool> shareOrSaveBytes(String fileName, Uint8List bytes, {String? text, String? title}) async {
  final l = appL10n();
  final where = await choiceDialog<FileDestination>(
    title: title ?? l.exportWhere,
    options: FileDestination.values,
    label: (w) => w == FileDestination.share ? l.backupShare : l.backupSaveToFolder,
  );
  if (where == null) return false;
  return sendBytes(fileName, bytes, where, text: text);
}

/// Sends [bytes] to the share sheet or a folder the user picks. Returns
/// true when it went somewhere.
Future<bool> sendBytes(String fileName, Uint8List bytes, FileDestination where, {String? text}) async {
  final l = appL10n();
  if (where == FileDestination.folder) {
    return await FilePicker.saveFile(dialogTitle: l.backupSaveToFolder, fileName: fileName, bytes: bytes) != null;
  }
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  final result = await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], subject: fileName, text: text));
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

/// Picks a folder (Windows). Null when cancelled.
Future<String?> pickFolder(String title) => FilePicker.getDirectoryPath(dialogTitle: title);
